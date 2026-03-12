import Foundation
#if os(iOS)
import BackgroundTasks
#endif

/// Schedules periodic background email sync using iOS BGAppRefreshTask.
///
/// Registers a background task that performs incremental IMAP sync within
/// iOS's 30-second execution budget. The sync is headers-only (no bodies)
/// to stay within the time limit.
///
/// On macOS, background sync is not scheduled (macOS apps can run in
/// the background natively). IDLE monitoring handles real-time updates.
///
/// Spec ref: FR-SYNC-03 (Background refresh)
@Observable @MainActor
public final class BackgroundSyncScheduler {

    /// Background task identifier — must match Info.plist entry.
    /// Derived from the runtime bundle identifier to avoid config drift.
    public static var taskIdentifier: String {
        "\(Bundle.main.bundleIdentifier ?? "com.vaultmail.app").sync"
    }

    /// Minimum interval between background syncs (1 minute).
    /// Apple's BGTaskScheduler may still throttle based on battery and usage patterns,
    /// but requesting the minimum signals the system to run as soon as possible.
    private static let minimumInterval: TimeInterval = 1 * 60

    private let syncEmails: SyncEmailsUseCaseProtocol
    private let manageAccounts: ManageAccountsUseCaseProtocol
    private let settingsStore: SettingsStore
    private let notificationCoordinator: NotificationSyncCoordinator?

    public init(
        syncEmails: SyncEmailsUseCaseProtocol,
        manageAccounts: ManageAccountsUseCaseProtocol,
        settingsStore: SettingsStore,
        notificationCoordinator: NotificationSyncCoordinator? = nil
    ) {
        self.syncEmails = syncEmails
        self.manageAccounts = manageAccounts
        self.settingsStore = settingsStore
        self.notificationCoordinator = notificationCoordinator
    }

    // MARK: - Registration

    /// Registers the background task with the system.
    ///
    /// Must be called from `App.init()` BEFORE the app finishes launching.
    /// On macOS this is a no-op.
    public func registerTasks() {
        #if os(iOS)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            NSLog("[BackgroundSync] Launch callback fired for identifier: \(Self.taskIdentifier)")
            guard let appRefreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await self.handleBackgroundSync(task: appRefreshTask)
            }
        }
        NSLog("[BackgroundSync] Registered task: \(Self.taskIdentifier)")
        #endif
    }

    // MARK: - Scheduling

    /// Schedules the next background sync.
    ///
    /// Should be called after each foreground sync completion and after
    /// each background sync completion.
    public func scheduleNextSync() {
        #if os(iOS)
        guard settingsStore.backgroundAlertsEnabled else {
            cancelScheduledSync()
            NSLog("[BackgroundSync] Skipped scheduling because background alerts are disabled")
            return
        }

        // Keep only one pending request to avoid stacked wakes.
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date().addingTimeInterval(Self.minimumInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            NSLog("[BackgroundSync] Scheduled next sync in \(Int(Self.minimumInterval / 60)) minutes")
        } catch {
            let nsError = error as NSError
            #if targetEnvironment(simulator)
            if nsError.domain == BGTaskScheduler.errorDomain && nsError.code == 1 {
                NSLog("[BackgroundSync] Scheduler unavailable on Simulator (expected). Use LLDB _simulateLaunchForTaskWithIdentifier for testing.")
            } else {
                NSLog("[BackgroundSync] Failed to schedule on Simulator: \(error)")
            }
            #else
            NSLog("[BackgroundSync] Failed to schedule: \(error)")
            #endif
        }
        #endif
    }

    public func cancelScheduledSync() {
        #if os(iOS)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        NSLog("[BackgroundSync] Cancelled pending task request")
        #endif
    }

    // MARK: - Execution

    #if os(iOS)
    /// Handles a background sync task within the ~30-second budget.
    ///
    /// Performs incremental sync for all active accounts. The sync engine
    /// uses UID-based incremental fetch which is fast enough for background.
    private func handleBackgroundSync(task: BGAppRefreshTask) async {
        NSLog("[BackgroundSync] handleBackgroundSync started")
        func completeTask(success: Bool, reason: String) {
            NSLog("[BackgroundSync] Completing task success=\(success) reason=\(reason)")
            task.setTaskCompleted(success: success)
        }

        guard settingsStore.backgroundAlertsEnabled else {
            cancelScheduledSync()
            completeTask(success: true, reason: "background alerts disabled")
            return
        }

        // Schedule the next sync before this one finishes
        scheduleNextSync()

        // Set up expiration handler
        let syncTask = Task { @MainActor in
            await self.performBackgroundSyncWork()
        }

        // If iOS kills the task (budget exceeded), cancel gracefully
        task.expirationHandler = {
            syncTask.cancel()
            NSLog("[BackgroundSync] Expired — cancelled sync task")
        }

        let result = await syncTask.value
        completeTask(success: result.success, reason: result.reason)
    }

    private func performBackgroundSyncWork() async -> (success: Bool, reason: String) {
        do {
            let accounts = try await manageAccounts.getAccounts()
            let activeAccounts = accounts.filter { $0.isActive }
            if activeAccounts.isEmpty {
                return (true, "no active accounts")
            }

            var isFirst = true
            var skippedAccounts = 0
            for account in activeAccounts {
                guard !Task.isCancelled else {
                    NSLog("[BackgroundSync] Cancelled before completing all accounts")
                    return (false, "sync task cancelled")
                }

                do {
                    let result = try await syncEmails.syncAccount(
                        accountId: account.id,
                        options: .incremental
                    )
                    NSLog("[BackgroundSync] Synced account: \(account.email)")
                    if isFirst {
                        notificationCoordinator?.markFirstLaunchComplete()
                        isFirst = false
                    }
                    let report = await notificationCoordinator?.didSyncNewEmailsReporting(
                        result.newEmails,
                        fromBackground: true
                    )
                    if (report?.deliveredCount ?? 0) > 0 {
                        settingsStore.lastBackgroundAlertAt = Date()
                    }
                } catch {
                    if shouldSkipAccountForCredentialIssue(error) {
                        skippedAccounts += 1
                        NSLog("[BackgroundSync] Skipping account \(account.email) due to credential issue: \(error)")
                        continue
                    }
                    throw error
                }
            }

            settingsStore.lastBackgroundCheckAt = Date()
            if skippedAccounts > 0 {
                return (true, "sync finished with \(skippedAccounts) skipped account(s)")
            }
            return (true, "sync finished")
        } catch {
            NSLog("[BackgroundSync] Failed: \(error)")
            return (false, "sync failed")
        }
    }

    private func shouldSkipAccountForCredentialIssue(_ error: Error) -> Bool {
        guard case .tokenRefreshFailed(let reason) = error as? SyncError else { return false }
        return reason.contains("No credentials found for account")
            || reason.contains("OAuth token expired for account")
    }
    #endif
}
