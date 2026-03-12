import Foundation
import Testing
@testable import VaultMailFeature

@Suite("SettingsStore")
struct SettingsStoreTests {

    /// Creates a SettingsStore backed by a unique, ephemeral UserDefaults suite.
    @MainActor
    private static func makeStore() -> (SettingsStore, UserDefaults) {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        return (store, defaults)
    }

    @MainActor
    private static func makeSeparateDefaults() -> (local: UserDefaults, shared: UserDefaults) {
        let local = UserDefaults(suiteName: "test.local.\(UUID().uuidString)")!
        let shared = UserDefaults(suiteName: "test.shared.\(UUID().uuidString)")!
        return (local, shared)
    }

    // MARK: - Defaults

    @Test("Default theme is system")
    @MainActor
    func defaultTheme() {
        let (store, _) = Self.makeStore()
        #expect(store.theme == .system)
    }

    @Test("Default undo send delay is 5 seconds")
    @MainActor
    func defaultUndoSendDelay() {
        let (store, _) = Self.makeStore()
        #expect(store.undoSendDelay == .fiveSeconds)
    }

    @Test("Default category visibility is all true")
    @MainActor
    func defaultCategoryVisibility() {
        let (store, _) = Self.makeStore()
        #expect(store.categoryTabVisibility[AICategory.primary.rawValue] == true)
        #expect(store.categoryTabVisibility[AICategory.social.rawValue] == true)
        #expect(store.categoryTabVisibility[AICategory.promotions.rawValue] == true)
        #expect(store.categoryTabVisibility[AICategory.updates.rawValue] == true)
    }

    @Test("Default app lock is disabled")
    @MainActor
    func defaultAppLock() {
        let (store, _) = Self.makeStore()
        #expect(store.appLockEnabled == false)
    }

    @Test("Default onboarding is not complete")
    @MainActor
    func defaultOnboarding() {
        let (store, _) = Self.makeStore()
        #expect(store.isOnboardingComplete == false)
    }

    @Test("Default sending account is nil")
    @MainActor
    func defaultSendingAccount() {
        let (store, _) = Self.makeStore()
        #expect(store.defaultSendingAccountId == nil)
    }

    @Test("Default blockRemoteImages is false")
    @MainActor
    func defaultBlockRemoteImages() {
        let (store, _) = Self.makeStore()
        #expect(store.blockRemoteImages == false)
    }

    @Test("Default blockTrackingPixels is false")
    @MainActor
    func defaultBlockTrackingPixels() {
        let (store, _) = Self.makeStore()
        #expect(store.blockTrackingPixels == false)
    }

    // MARK: - Persistence Round-Trip

    @Test("Theme persists across instances")
    @MainActor
    func themePersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.theme = .dark

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.theme == .dark)
    }

    @Test("Undo send delay persists across instances")
    @MainActor
    func undoSendDelayPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.undoSendDelay = .thirtySeconds

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.undoSendDelay == .thirtySeconds)
    }

    @Test("App lock persists across instances")
    @MainActor
    func appLockPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.appLockEnabled = true

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.appLockEnabled == true)
    }

    @Test("Onboarding complete persists across instances")
    @MainActor
    func onboardingPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.isOnboardingComplete = true

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.isOnboardingComplete == true)
    }

    @Test("Category visibility JSON persists across instances")
    @MainActor
    func categoryVisibilityPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.categoryTabVisibility[AICategory.social.rawValue] = false

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.categoryTabVisibility[AICategory.social.rawValue] == false)
        #expect(store2.categoryTabVisibility[AICategory.primary.rawValue] == true)
    }

    @Test("Notification preferences JSON persists across instances")
    @MainActor
    func notificationPreferencesPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.notificationPreferences["acc-1"] = false

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.notificationPreferences["acc-1"] == false)
    }

    @Test("Attachment cache limits JSON persists across instances")
    @MainActor
    func attachmentCacheLimitsPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.setCacheLimit(250, for: "acc-1")

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.cacheLimit(for: "acc-1") == 250)
    }

    @Test("Default sending account persists across instances")
    @MainActor
    func defaultSendingAccountPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.defaultSendingAccountId = "acc-123"

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.defaultSendingAccountId == "acc-123")
    }

    @Test("blockRemoteImages persists across instances")
    @MainActor
    func blockRemoteImagesPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.blockRemoteImages = true

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.blockRemoteImages == true)
    }

    @Test("blockTrackingPixels persists across instances")
    @MainActor
    func blockTrackingPixelsPersistence() {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        store1.blockTrackingPixels = true

        let store2 = SettingsStore(defaults: defaults, sharedDefaults: defaults)
        #expect(store2.blockTrackingPixels == true)
    }

    // MARK: - Helpers

    @Test("cacheLimit returns default 500 for unknown account")
    @MainActor
    func cacheLimitDefaultForUnknown() {
        let (store, _) = Self.makeStore()
        #expect(store.cacheLimit(for: "unknown") == 500)
    }

    @Test("notificationsEnabled returns true for unknown account")
    @MainActor
    func notificationsEnabledDefault() {
        let (store, _) = Self.makeStore()
        #expect(store.notificationsEnabled(for: "unknown") == true)
    }

    @Test("background alerts default to enabled")
    @MainActor
    func backgroundAlertsDefaultEnabled() {
        let (store, _) = Self.makeStore()
        #expect(store.backgroundAlertsEnabled == true)
        #expect(store.macLoginItemHelperEnabled == false)
    }

    @Test("Mirrored notification and background settings are written to shared defaults")
    @MainActor
    func sharedMirroringWrites() {
        let (local, shared) = Self.makeSeparateDefaults()
        let store = SettingsStore(defaults: local, sharedDefaults: shared)

        store.backgroundAlertsEnabled = false
        store.macLoginItemHelperEnabled = true
        store.notificationPreferences = ["acc-1": false]
        store.notificationCategoryPreferences = [AICategory.promotions.rawValue: false]
        store.vipContacts = ["vip@example.com"]
        store.mutedThreadIds = ["thread-1"]
        store.quietHoursEnabled = true
        store.quietHoursStart = 60
        store.quietHoursEnd = 120

        #expect(shared.object(forKey: "backgroundAlertsEnabled") as? Bool == false)
        #expect(shared.object(forKey: "macLoginItemHelperEnabled") as? Bool == true)
        #expect((shared.testJSON(forKey: "notificationPreferences") as [String: Bool]?)?["acc-1"] == false)
        #expect(
            (shared.testJSON(forKey: "notifCategoryPreferences") as [String: Bool]?)?[AICategory.promotions.rawValue] == false
        )
        #expect((shared.testJSON(forKey: "vipContacts") as [String]?)?.contains("vip@example.com") == true)
        #expect((shared.testJSON(forKey: "mutedThreadIds") as [String]?)?.contains("thread-1") == true)
        #expect(shared.object(forKey: "quietHoursEnabled") as? Bool == true)
        #expect(shared.object(forKey: "quietHoursStart") as? Int == 60)
        #expect(shared.object(forKey: "quietHoursEnd") as? Int == 120)
    }

    @Test("Store reads mirrored values from shared defaults when local defaults are empty")
    @MainActor
    func sharedFallbackReads() {
        let (local, shared) = Self.makeSeparateDefaults()
        shared.set(false, forKey: "backgroundAlertsEnabled")
        shared.set(true, forKey: "macLoginItemHelperEnabled")
        shared.set(true, forKey: "quietHoursEnabled")
        shared.set(180, forKey: "quietHoursStart")
        shared.set(300, forKey: "quietHoursEnd")
        shared.setTestJSON(["acc-shared": false], forKey: "notificationPreferences")
        shared.setTestJSON([AICategory.social.rawValue: false], forKey: "notifCategoryPreferences")
        shared.setTestJSON(["vip@shared.com"], forKey: "vipContacts")
        shared.setTestJSON(["thread-shared"], forKey: "mutedThreadIds")

        let store = SettingsStore(defaults: local, sharedDefaults: shared)
        #expect(store.backgroundAlertsEnabled == false)
        #expect(store.macLoginItemHelperEnabled == true)
        #expect(store.quietHoursEnabled == true)
        #expect(store.quietHoursStart == 180)
        #expect(store.quietHoursEnd == 300)
        #expect(store.notificationPreferences["acc-shared"] == false)
        #expect(store.notificationCategoryPreferences[AICategory.social.rawValue] == false)
        #expect(store.vipContacts.contains("vip@shared.com"))
        #expect(store.mutedThreadIds.contains("thread-shared"))
    }

    @Test("colorScheme returns correct values")
    @MainActor
    func colorSchemeMapping() {
        let (store, _) = Self.makeStore()

        store.theme = .system
        #expect(store.colorScheme == nil)

        store.theme = .light
        #expect(store.colorScheme == .light)

        store.theme = .dark
        #expect(store.colorScheme == .dark)
    }

    // MARK: - Reset

    @Test("resetAll restores all defaults")
    @MainActor
    func resetAll() {
        let (store, _) = Self.makeStore()

        // Set non-default values
        store.theme = .dark
        store.undoSendDelay = .thirtySeconds
        store.appLockEnabled = true
        store.blockRemoteImages = true
        store.blockTrackingPixels = true
        store.isOnboardingComplete = true
        store.defaultSendingAccountId = "acc-1"
        store.notificationPreferences["acc-1"] = false
        store.attachmentCacheLimits["acc-1"] = 100
        store.backgroundAlertsEnabled = false
        store.macLoginItemHelperEnabled = true
        store.lastBackgroundCheckAt = Date()
        store.lastBackgroundAlertAt = Date()

        // Reset
        store.resetAll()

        #expect(store.theme == .system)
        #expect(store.undoSendDelay == .fiveSeconds)
        #expect(store.appLockEnabled == false)
        #expect(store.blockRemoteImages == false)
        #expect(store.blockTrackingPixels == false)
        #expect(store.isOnboardingComplete == false)
        #expect(store.defaultSendingAccountId == nil)
        #expect(store.notificationPreferences.isEmpty)
        #expect(store.attachmentCacheLimits.isEmpty)
        #expect(store.backgroundAlertsEnabled == true)
        #expect(store.macLoginItemHelperEnabled == false)
        #expect(store.lastBackgroundCheckAt == nil)
        #expect(store.lastBackgroundAlertAt == nil)
    }
}

private extension UserDefaults {
    func setTestJSON<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }

    func testJSON<T: Decodable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
