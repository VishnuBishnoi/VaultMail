#if os(macOS)
import AppKit
import OSLog
import SwiftUI
import VaultMailFeature

@main
struct MailBackgroundHelperApp: App {
    @NSApplicationDelegateAdaptor(HelperAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 1, height: 1)
        }
    }
}

@MainActor
private final class HelperAppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: AppConstants.macLoginItemBundleIdentifier, category: "lifecycle")
    private var runner: MailBackgroundHelperBootstrap?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.notice("[Helper] applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.first?.orderOut(nil)
        ProcessInfo.processInfo.disableSuddenTermination()
        ProcessInfo.processInfo.disableAutomaticTermination("VaultMail helper background polling")

        Task { @MainActor in
            if runner == nil {
                runner = await MailBackgroundHelperBootstrap.make()
                runner?.start()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessInfo.processInfo.enableAutomaticTermination("VaultMail helper background polling")
        ProcessInfo.processInfo.enableSuddenTermination()
        logger.notice("[Helper] applicationWillTerminate")
    }
}

@MainActor
private final class MailBackgroundHelperBootstrap {
    private let logger = Logger(subsystem: AppConstants.macLoginItemBundleIdentifier, category: "bootstrap")
    private let poller: MacBackgroundHelperPoller

    private init(poller: MacBackgroundHelperPoller) {
        self.poller = poller
    }

    static func make() async -> MailBackgroundHelperBootstrap? {
        do {
            let container = try ModelContainerFactory.create()
            let settingsStore = SettingsStore()
            let keychainManager = KeychainManager(accessGroup: KeychainManager.entitlementAccessGroup())
            let oauthManager = OAuthManager(clientId: AppConstants.oauthClientId)

            let accountRepo = AccountRepositoryImpl(
                modelContainer: container,
                keychainManager: keychainManager,
                oauthManager: oauthManager
            )
            let emailRepo = EmailRepositoryImpl(modelContainer: container)
            let connectionPool = ConnectionPool()

            let manageAccounts = ManageAccountsUseCase(
                repository: accountRepo,
                oauthManager: oauthManager,
                keychainManager: keychainManager,
                connectionProvider: connectionPool
            )
            let syncEmails = SyncEmailsUseCase(
                accountRepository: accountRepo,
                emailRepository: emailRepo,
                keychainManager: keychainManager,
                connectionPool: connectionPool
            )

            let filterPipeline = NotificationFilterPipeline(
                vipFilter: VIPContactFilter(settingsStore: settingsStore),
                filters: [
                    AccountNotificationFilter(settingsStore: settingsStore),
                    SpamNotificationFilter(),
                    CategoryNotificationFilter(settingsStore: settingsStore),
                    MutedThreadFilter(settingsStore: settingsStore),
                    QuietHoursFilter(settingsStore: settingsStore),
                    FocusModeFilter(),
                ]
            )
            let notificationService = NotificationService(
                center: UNUserNotificationCenterWrapper(),
                settingsStore: settingsStore,
                emailRepository: emailRepo,
                filterPipeline: filterPipeline
            )
            notificationService.registerCategories()
            Task { @MainActor in
                let bootstrapLogger = Logger(
                    subsystem: AppConstants.macLoginItemBundleIdentifier,
                    category: "bootstrap"
                )
                let status = await notificationService.authorizationStatus()
                bootstrapLogger.notice("[Helper] Notification authorization status: \(String(describing: status), privacy: .public)")
                if status == .notDetermined {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    let granted = await notificationService.requestAuthorization()
                    bootstrapLogger.notice("[Helper] Notification authorization prompt result: \(granted, privacy: .public)")
                    let updatedStatus = await notificationService.authorizationStatus()
                    bootstrapLogger.notice(
                        "[Helper] Notification authorization status after prompt: \(String(describing: updatedStatus), privacy: .public)"
                    )
                    NSApp.setActivationPolicy(.accessory)
                    NSApp.windows.first?.orderOut(nil)
                }
            }

            let coordinator = NotificationSyncCoordinator(notificationService: notificationService)
            let poller = MacBackgroundHelperPoller(
                syncEmails: syncEmails,
                manageAccounts: manageAccounts,
                notificationCoordinator: coordinator,
                settingsStore: settingsStore
            )
            Logger(subsystem: AppConstants.macLoginItemBundleIdentifier, category: "bootstrap")
                .notice("[Helper] Bootstrap complete")
            return MailBackgroundHelperBootstrap(poller: poller)
        } catch {
            Logger(subsystem: AppConstants.macLoginItemBundleIdentifier, category: "bootstrap")
                .error("[Helper] Bootstrap failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func start() {
        logger.notice("[Helper] Poller start")
        poller.start()
    }
}
#endif
