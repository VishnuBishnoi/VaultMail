import Foundation
import SwiftData

/// Local contact cache used by composer autocomplete.
///
/// This data is derived from synced email headers and never leaves device.
/// Scoped per account and cascade-deleted when account is removed.
@Model
public final class ContactCacheEntry {
    @Attribute(.unique) public var id: String
    public var accountId: String
    public var emailAddress: String
    public var displayName: String?
    public var lastSeenDate: Date
    public var frequency: Int

    public var account: Account?

    public init(
        id: String? = nil,
        accountId: String,
        emailAddress: String,
        displayName: String? = nil,
        lastSeenDate: Date = .now,
        frequency: Int = 1
    ) {
        let normalizedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.id = id ?? "\(accountId)::\(normalizedEmail)"
        self.accountId = accountId
        self.emailAddress = normalizedEmail
        self.displayName = displayName
        self.lastSeenDate = lastSeenDate
        self.frequency = frequency
    }
}
