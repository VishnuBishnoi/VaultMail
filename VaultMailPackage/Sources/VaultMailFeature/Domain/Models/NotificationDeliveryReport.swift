import Foundation

/// Summary of one notification processing pass.
///
/// This is intentionally lightweight so callers (background schedulers,
/// diagnostics UI) can update metadata without understanding filtering details.
public struct NotificationDeliveryReport: Sendable, Equatable {
    public let deliveredCount: Int
    public let suppressedCount: Int

    public init(deliveredCount: Int, suppressedCount: Int) {
        self.deliveredCount = deliveredCount
        self.suppressedCount = suppressedCount
    }

    public static let empty = NotificationDeliveryReport(
        deliveredCount: 0,
        suppressedCount: 0
    )
}
