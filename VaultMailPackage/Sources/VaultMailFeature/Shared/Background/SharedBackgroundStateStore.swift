import Foundation

/// Mirrors a minimal set of settings/state into an App Group container so a
/// macOS login-item helper can read them when the main app is not running.
@MainActor
public final class SharedBackgroundStateStore {
    private enum Keys {
        static let migrated = "sharedBackgroundStateMigrated"
        static let backgroundAlertsEnabled = "backgroundAlertsEnabled"
        static let macLoginItemHelperEnabled = "macLoginItemHelperEnabled"
        static let lastBackgroundCheckAt = "lastBackgroundCheckAt"
        static let lastBackgroundAlertAt = "lastBackgroundAlertAt"
        static let mainAppHeartbeatAt = "mainAppHeartbeatAt"
    }

    private let sharedDefaults: UserDefaults
    private let localDefaults: UserDefaults

    public init?(
        appGroupId: String = AppConstants.sharedAppGroupIdentifier,
        localDefaults: UserDefaults = .standard
    ) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            return nil
        }
        self.sharedDefaults = sharedDefaults
        self.localDefaults = localDefaults
        migrateIfNeeded()
    }

    private func migrateIfNeeded() {
        guard sharedDefaults.bool(forKey: Keys.migrated) == false else { return }
        let mirroredKeys = [
            Keys.backgroundAlertsEnabled,
            Keys.macLoginItemHelperEnabled,
            Keys.lastBackgroundCheckAt,
            Keys.lastBackgroundAlertAt,
            Keys.mainAppHeartbeatAt,
        ]
        for key in mirroredKeys {
            if let value = localDefaults.object(forKey: key) {
                sharedDefaults.set(value, forKey: key)
            }
        }
        sharedDefaults.set(true, forKey: Keys.migrated)
    }

    public func syncFromSettings(_ settings: SettingsStore) {
        sharedDefaults.set(settings.backgroundAlertsEnabled, forKey: Keys.backgroundAlertsEnabled)
        sharedDefaults.set(settings.macLoginItemHelperEnabled, forKey: Keys.macLoginItemHelperEnabled)
        sharedDefaults.set(settings.lastBackgroundCheckAt, forKey: Keys.lastBackgroundCheckAt)
        sharedDefaults.set(settings.lastBackgroundAlertAt, forKey: Keys.lastBackgroundAlertAt)
        sharedDefaults.set(settings.mainAppHeartbeatAt, forKey: Keys.mainAppHeartbeatAt)
    }

    public var helperEnabled: Bool {
        sharedDefaults.bool(forKey: Keys.macLoginItemHelperEnabled)
    }
}
