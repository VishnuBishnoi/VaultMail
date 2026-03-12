import Foundation

/// Determines whether helper polling should run while the main app may be active.
public enum BackgroundExecutionArbiter {
    /// Heartbeat TTL used to suppress helper polling when main app is clearly active.
    public static let heartbeatTTL: TimeInterval = 120

    public static func shouldHelperPoll(mainAppHeartbeatAt: Date?, now: Date = Date()) -> Bool {
        guard let mainAppHeartbeatAt else { return true }
        return now.timeIntervalSince(mainAppHeartbeatAt) > heartbeatTTL
    }
}
