import Foundation

public protocol SmartReplyUseCaseProtocol: Sendable {
    func execute(email: Email) async throws -> [String]
    func executeOrEmpty(email: Email) async -> [String]
}

public struct SmartReplyUseCase: SmartReplyUseCaseProtocol, Sendable {
    private let repository: AIRepositoryProtocol

    public init(repository: AIRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(email: Email) async throws -> [String] {
        let suggestions = try await repository.smartReply(email: email)
        return Array(suggestions.prefix(3))
    }

    public func executeOrEmpty(email: Email) async -> [String] {
        (try? await execute(email: email)) ?? []
    }
}
