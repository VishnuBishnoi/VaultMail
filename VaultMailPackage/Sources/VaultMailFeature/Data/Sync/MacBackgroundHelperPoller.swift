import Foundation
import OSLog

/// Best-effort periodic poller intended for a macOS login-item helper process.
///
/// The poller yields to the main app when a fresh heartbeat is present to avoid
/// duplicate sync work.
@MainActor
public final class MacBackgroundHelperPoller {
    private let logger = Logger(subsystem: "com.Rajeshdara.vaultmailv.MailBackgroundHelper", category: "poller")
    private let syncEmails: SyncEmailsUseCaseProtocol
    private let manageAccounts: ManageAccountsUseCaseProtocol
    private let notificationCoordinator: NotificationSyncCoordinator
    private let settingsStore: SettingsStore

    private var pollTask: Task<Void, Never>?

    public init(
        syncEmails: SyncEmailsUseCaseProtocol,
        manageAccounts: ManageAccountsUseCaseProtocol,
        notificationCoordinator: NotificationSyncCoordinator,
        settingsStore: SettingsStore
    ) {
        self.syncEmails = syncEmails
        self.manageAccounts = manageAccounts
        self.notificationCoordinator = notificationCoordinator
        self.settingsStore = settingsStore
    }

    public func start() {
        guard pollTask == nil else { return }
        pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let delay = await self.runCycleIfNeeded()
                try? await Task.sleep(for: .seconds(delay))
            }
        }
    }

    public func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func runCycleIfNeeded() async -> TimeInterval {
        logger.notice("[HelperPoller] Cycle started")
        guard settingsStore.macLoginItemHelperEnabled, settingsStore.backgroundAlertsEnabled else {
            logger.notice(
                "[HelperPoller] Skipping cycle (helperEnabled=\(self.settingsStore.macLoginItemHelperEnabled, privacy: .public), backgroundAlertsEnabled=\(self.settingsStore.backgroundAlertsEnabled, privacy: .public))"
            )
            return AppConstants.macHelperPollIntervalSeconds
        }
        guard BackgroundExecutionArbiter.shouldHelperPoll(mainAppHeartbeatAt: settingsStore.mainAppHeartbeatAt) else {
            if let heartbeat = settingsStore.mainAppHeartbeatAt {
                let age = Date().timeIntervalSince(heartbeat)
                logger.notice("[HelperPoller] Skipping cycle (main app heartbeat age=\(Int(age), privacy: .public)s)")
                // Re-check near heartbeat TTL so helper can take over soon after app quits.
                return max(15, min(60, BackgroundExecutionArbiter.heartbeatTTL - age + 5))
            } else {
                logger.notice("[HelperPoller] Skipping cycle (main app heartbeat considered fresh)")
                return 30
            }
        }

        do {
            let accounts = try await manageAccounts.getAccounts().filter(\.isActive)
            logger.notice("[HelperPoller] Active accounts: \(accounts.count, privacy: .public)")
            for account in accounts {
                guard !Task.isCancelled else { return 15 }
                let result = try await syncEmails.syncAccount(accountId: account.id, options: .incremental)
                logger.notice(
                    "[HelperPoller] Synced account: \(account.email, privacy: .public), newEmails=\(result.newEmails.count, privacy: .public)"
                )
                notificationCoordinator.markFirstLaunchComplete()
                let report = await notificationCoordinator.didSyncNewEmailsReporting(
                    result.newEmails,
                    fromBackground: true
                )
                if report.deliveredCount > 0 {
                    settingsStore.lastBackgroundAlertAt = Date()
                    logger.notice("[HelperPoller] Delivered notifications: \(report.deliveredCount, privacy: .public)")
                } else {
                    logger.notice(
                        "[HelperPoller] No notifications delivered (suppressed=\(report.suppressedCount, privacy: .public))"
                    )
                }
            }
            settingsStore.lastBackgroundCheckAt = Date()
            logger.notice("[HelperPoller] Cycle complete")
            return AppConstants.macHelperPollIntervalSeconds
        } catch {
            logger.error("[HelperPoller] Cycle failed: \(error.localizedDescription, privacy: .public)")
            // Keep poll loop alive; background checks are best effort.
            return 60
        }
    }
}
