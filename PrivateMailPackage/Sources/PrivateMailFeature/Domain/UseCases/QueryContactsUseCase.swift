import Foundation

public struct ContactSuggestion: Sendable, Equatable {
    public let emailAddress: String
    public let displayName: String?
    public let frequency: Int
    public let lastSeenDate: Date

    public init(emailAddress: String, displayName: String?, frequency: Int, lastSeenDate: Date) {
        self.emailAddress = emailAddress
        self.displayName = displayName
        self.frequency = frequency
        self.lastSeenDate = lastSeenDate
    }
}

@MainActor
public protocol QueryContactsUseCaseProtocol {
    func execute(query: String, limit: Int) async throws -> [ContactSuggestion]
}

/// Query contact cache for recipient autocomplete.
/// Merges cross-account entries by email and keeps:
/// - highest frequency
/// - most recent displayName
@MainActor
public final class QueryContactsUseCase: QueryContactsUseCaseProtocol {
    private let repository: EmailRepositoryProtocol

    public init(repository: EmailRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String, limit: Int = 10) async throws -> [ContactSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let entries = try await repository.queryContactCache(prefix: trimmed, limit: max(limit * 2, 20))

        var byEmail: [String: ContactSuggestion] = [:]
        for entry in entries {
            let key = entry.emailAddress.lowercased()
            if let existing = byEmail[key] {
                let highestFrequency = max(existing.frequency, entry.frequency)
                let newerDate = max(existing.lastSeenDate, entry.lastSeenDate)
                let latestDisplayName: String?
                if entry.lastSeenDate >= existing.lastSeenDate {
                    latestDisplayName = entry.displayName ?? existing.displayName
                } else {
                    latestDisplayName = existing.displayName
                }

                byEmail[key] = ContactSuggestion(
                    emailAddress: existing.emailAddress,
                    displayName: latestDisplayName,
                    frequency: highestFrequency,
                    lastSeenDate: newerDate
                )
            } else {
                byEmail[key] = ContactSuggestion(
                    emailAddress: entry.emailAddress,
                    displayName: entry.displayName,
                    frequency: entry.frequency,
                    lastSeenDate: entry.lastSeenDate
                )
            }
        }

        return byEmail.values
            .sorted {
                if $0.frequency != $1.frequency { return $0.frequency > $1.frequency }
                if $0.lastSeenDate != $1.lastSeenDate { return $0.lastSeenDate > $1.lastSeenDate }
                return $0.emailAddress < $1.emailAddress
            }
            .prefix(limit)
            .map { $0 }
    }
}
