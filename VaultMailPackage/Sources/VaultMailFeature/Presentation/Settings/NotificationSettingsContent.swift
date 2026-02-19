import SwiftUI

/// Shared notification settings content for iOS and macOS.
///
/// 6 sections: System Permission, Per-Account Toggles, Categories,
/// VIP Contacts, Muted Threads, Quiet Hours.
///
/// Spec ref: NOTIF-09, NOTIF-10, NOTIF-11, NOTIF-14, NOTIF-23
public struct NotificationSettingsContent: View {
    @Environment(SettingsStore.self) private var settings

    let accounts: [Account]

    @State private var authStatus: NotificationAuthStatus = .notDetermined
    @State private var newVIPEmail = ""

    public init(accounts: [Account]) {
        self.accounts = accounts
    }

    public var body: some View {
        Form {
            systemPermissionSection
            accountsSection
            categoriesSection
            vipContactsSection
            mutedThreadsSection
            quietHoursSection
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .task {
            await checkAuthStatus()
        }
    }

    // MARK: - System Permission Section

    @ViewBuilder
    private var systemPermissionSection: some View {
        Section {
            HStack {
                Label(authStatusLabel, systemImage: authStatusIcon)
                    .foregroundStyle(authStatusColor)
                Spacer()
                if authStatus == .notDetermined {
                    Button("Enable") {
                        Task { await requestPermission() }
                    }
                }
                #if os(iOS)
                if authStatus == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.callout)
                }
                #endif
            }
        } header: {
            Text("System Permission")
        }
    }

    private var authStatusLabel: String {
        switch authStatus {
        case .authorized, .provisional: "Notifications Enabled"
        case .denied: "Notifications Disabled in System Settings"
        case .notDetermined: "Notifications Not Yet Requested"
        }
    }

    private var authStatusIcon: String {
        switch authStatus {
        case .authorized, .provisional: "bell.badge.fill"
        case .denied: "bell.slash.fill"
        case .notDetermined: "bell"
        }
    }

    private var authStatusColor: Color {
        switch authStatus {
        case .authorized, .provisional: .green
        case .denied: .orange
        case .notDetermined: .secondary
        }
    }

    // MARK: - Accounts Section (NOTIF-09)

    @ViewBuilder
    private var accountsSection: some View {
        Section("Accounts") {
            if accounts.isEmpty {
                Text("No accounts configured.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(accounts, id: \.id) { account in
                    Toggle(account.email, isOn: Binding(
                        get: { settings.notificationsEnabled(for: account.id) },
                        set: { settings.notificationPreferences[account.id] = $0 }
                    ))
                    .accessibilityLabel("Notifications for \(account.email)")
                }
            }
        }
    }

    // MARK: - Categories Section (NOTIF-09)

    @ViewBuilder
    private var categoriesSection: some View {
        Section {
            ForEach(toggleableCategories, id: \.0) { key, label in
                Toggle(label, isOn: Binding(
                    get: { settings.notificationCategoryEnabled(for: key) },
                    set: { settings.notificationCategoryPreferences[key] = $0 }
                ))
                .accessibilityLabel("Notifications for \(label) category")
            }
        } header: {
            Text("Categories")
        } footer: {
            Text("Choose which email categories trigger notifications.")
        }
    }

    private var toggleableCategories: [(String, String)] {
        [
            (AICategory.primary.rawValue, "Primary"),
            (AICategory.social.rawValue, "Social"),
            (AICategory.promotions.rawValue, "Promotions"),
            (AICategory.updates.rawValue, "Updates"),
        ]
    }

    // MARK: - VIP Contacts Section (NOTIF-10)

    @ViewBuilder
    private var vipContactsSection: some View {
        Section {
            ForEach(Array(settings.vipContacts).sorted(), id: \.self) { email in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                    Text(email)
                }
                .swipeActions(edge: .trailing) {
                    Button("Remove", role: .destructive) {
                        settings.removeVIPContact(email)
                    }
                }
                .accessibilityLabel("VIP contact: \(email)")
            }

            HStack {
                TextField("Add VIP email", text: $newVIPEmail)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                    .accessibilityLabel("VIP email address")

                Button("Add") {
                    let trimmed = newVIPEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    settings.addVIPContact(trimmed)
                    newVIPEmail = ""
                }
                .disabled(newVIPEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text("VIP Contacts")
        } footer: {
            Text("VIP contacts always trigger notifications, even during quiet hours or when their category is disabled.")
        }
    }

    // MARK: - Muted Threads Section (NOTIF-11)

    @ViewBuilder
    private var mutedThreadsSection: some View {
        Section {
            if settings.mutedThreadIds.isEmpty {
                Text("No muted threads.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(settings.mutedThreadIds).sorted(), id: \.self) { threadId in
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(threadId)
                            .lineLimit(1)
                            .font(.caption.monospaced())
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Unmute") {
                            settings.toggleMuteThread(threadId: threadId)
                        }
                    }
                    .accessibilityLabel("Muted thread")
                }
            }
        } header: {
            Text("Muted Threads")
        } footer: {
            Text("Muted threads will never trigger notifications. Swipe to unmute.")
        }
    }

    // MARK: - Quiet Hours Section (NOTIF-14)

    @ViewBuilder
    private var quietHoursSection: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Enable Quiet Hours", isOn: $settings.quietHoursEnabled)
                .accessibilityLabel("Quiet hours")

            if settings.quietHoursEnabled {
                DatePicker(
                    "Start",
                    selection: Binding(
                        get: { minutesToDate(settings.quietHoursStart) },
                        set: { settings.quietHoursStart = dateToMinutes($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .accessibilityLabel("Quiet hours start time")

                DatePicker(
                    "End",
                    selection: Binding(
                        get: { minutesToDate(settings.quietHoursEnd) },
                        set: { settings.quietHoursEnd = dateToMinutes($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .accessibilityLabel("Quiet hours end time")
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("Notifications are silenced during quiet hours. VIP contacts override this setting.")
        }
    }

    // MARK: - Helpers

    private func checkAuthStatus() async {
        // Use the notification service from environment if available,
        // otherwise fall back to checking UNUserNotificationCenter directly.
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        let notifSettings = await center.notificationSettings()
        switch notifSettings.authorizationStatus {
        case .notDetermined: authStatus = .notDetermined
        case .authorized: authStatus = .authorized
        case .denied: authStatus = .denied
        case .provisional: authStatus = .provisional
        @unknown default: authStatus = .denied
        }
        #endif
    }

    private func requestPermission() async {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        await checkAuthStatus()
        #endif
    }

    private func minutesToDate(_ minutes: Int) -> Date {
        var comps = DateComponents()
        comps.hour = minutes / 60
        comps.minute = minutes % 60
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func dateToMinutes(_ date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
}

#if canImport(UserNotifications)
import UserNotifications
#endif
