import Foundation

#if os(macOS)
import ServiceManagement

/// Controls the login-item helper registration lifecycle.
@MainActor
public final class MacLoginItemManager {
    public enum ManagerError: Error {
        case unavailable
    }

    public init() {}

    public func setEnabled(_ enabled: Bool) throws {
        guard AppConstants.macLoginItemHelperFeatureEnabled else {
            throw ManagerError.unavailable
        }

        let service = SMAppService.loginItem(identifier: AppConstants.macLoginItemBundleIdentifier)
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }

    public var statusDescription: String {
        let service = SMAppService.loginItem(identifier: AppConstants.macLoginItemBundleIdentifier)
        switch service.status {
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires Approval"
        case .notRegistered:
            return "Disabled"
        case .notFound:
            return "Not Found"
        @unknown default:
            return "Unknown"
        }
    }
}

#else

@MainActor
public final class MacLoginItemManager {
    public init() {}
    public func setEnabled(_ enabled: Bool) throws {}
    public var statusDescription: String { "Unavailable" }
}

#endif
