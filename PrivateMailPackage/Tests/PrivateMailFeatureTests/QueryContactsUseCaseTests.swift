import Foundation
import Testing
@testable import PrivateMailFeature

@Suite("QueryContactsUseCase")
@MainActor
struct QueryContactsUseCaseTests {

    @Test("returns frequency-ranked suggestions for prefix")
    func rankedByFrequency() async throws {
        let repo = MockEmailRepository()
        repo.mockContactQueryResults = [
            ContactCacheEntry(accountId: "a1", emailAddress: "alex@example.com", displayName: "Alex", lastSeenDate: .distantPast, frequency: 2),
            ContactCacheEntry(accountId: "a1", emailAddress: "alice@example.com", displayName: "Alice", lastSeenDate: .now, frequency: 8)
        ]

        let sut = QueryContactsUseCase(repository: repo)
        let suggestions = try await sut.execute(query: "al", limit: 10)

        #expect(suggestions.map(\.emailAddress) == ["alice@example.com", "alex@example.com"])
        #expect(repo.queryContactCacheCallCount == 1)
    }

    @Test("deduplicates cross-account entries by email and keeps highest frequency + latest name")
    func crossAccountDedupe() async throws {
        let repo = MockEmailRepository()
        repo.mockContactQueryResults = [
            ContactCacheEntry(
                accountId: "a1",
                emailAddress: "alice@example.com",
                displayName: "Alice Old",
                lastSeenDate: Date(timeIntervalSince1970: 100),
                frequency: 20
            ),
            ContactCacheEntry(
                accountId: "a2",
                emailAddress: "alice@example.com",
                displayName: "Alice New",
                lastSeenDate: Date(timeIntervalSince1970: 200),
                frequency: 5
            )
        ]

        let sut = QueryContactsUseCase(repository: repo)
        let suggestions = try await sut.execute(query: "ali", limit: 10)

        #expect(suggestions.count == 1)
        #expect(suggestions[0].emailAddress == "alice@example.com")
        #expect(suggestions[0].displayName == "Alice New")
        #expect(suggestions[0].frequency == 20)
    }

    @Test("returns empty for blank query")
    func blankQuery() async throws {
        let repo = MockEmailRepository()
        let sut = QueryContactsUseCase(repository: repo)

        let suggestions = try await sut.execute(query: "   ", limit: 10)

        #expect(suggestions.isEmpty)
        #expect(repo.queryContactCacheCallCount == 0)
    }
}
