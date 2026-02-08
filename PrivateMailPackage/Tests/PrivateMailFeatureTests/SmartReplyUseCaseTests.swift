import Foundation
import Testing
@testable import PrivateMailFeature

@Suite("SmartReplyUseCase")
struct SmartReplyUseCaseTests {

    @Test("returns up to 3 suggestions")
    func returnsMaxThree() async throws {
        let repo = MockAIRepository()
        repo.smartReplyResult = ["One", "Two", "Three", "Four"]
        let sut = SmartReplyUseCase(repository: repo)

        let email = Email(
            accountId: "acc",
            threadId: "thread",
            messageId: "<m>",
            fromAddress: "a@example.com",
            subject: "Hi"
        )

        let replies = try await sut.execute(email: email)
        #expect(replies == ["One", "Two", "Three"])
    }

    @Test("returns empty on AI failure")
    func hidesOnFailure() async {
        let repo = MockAIRepository()
        repo.errorToThrow = NSError(domain: "ai", code: 1)
        let sut = SmartReplyUseCase(repository: repo)

        let email = Email(
            accountId: "acc",
            threadId: "thread",
            messageId: "<m>",
            fromAddress: "a@example.com",
            subject: "Hi"
        )

        let replies = await sut.executeOrEmpty(email: email)
        #expect(replies.isEmpty)
    }
}
