import Foundation
@testable import PrivateMailFeature

final class MockAIRepository: AIRepositoryProtocol, @unchecked Sendable {
    var smartReplyResult: [String] = []
    var errorToThrow: Error?

    func categorize(email: Email) async throws -> AICategory {
        if let errorToThrow { throw errorToThrow }
        return .uncategorized
    }

    func summarize(thread: PrivateMailFeature.Thread) async throws -> String {
        if let errorToThrow { throw errorToThrow }
        return ""
    }

    func smartReply(email: Email) async throws -> [String] {
        if let errorToThrow { throw errorToThrow }
        return smartReplyResult
    }

    func generateEmbedding(text: String) async throws -> Data {
        if let errorToThrow { throw errorToThrow }
        return Data()
    }
}
