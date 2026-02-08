import Foundation
import Testing
@testable import PrivateMailFeature

@Suite("SendEmailUseCase")
@MainActor
struct SendEmailUseCaseTests {

    @Test("execute persists queued email with markdown converted HTML")
    func executePersistsQueuedEmail() async throws {
        let repo = MockEmailRepository()
        let sut = SendEmailUseCase(repository: repo)
        let request = SendEmailRequest(
            accountId: "acc-1",
            fromAddress: "me@example.com",
            to: ["alice@example.com"],
            cc: ["bob@example.com"],
            bcc: [],
            subject: "Status",
            bodyText: "Hi **Alice**\nVisit [site](https://example.com)",
            inReplyTo: "<parent@msg>",
            references: "<root@msg> <parent@msg>",
            attachments: []
        )

        let email = try await sut.execute(request)

        #expect(repo.saveEmailCallCount == 1)
        #expect(email.sendState == SendState.queued.rawValue)
        #expect(email.isDraft == false)
        #expect(email.sendQueuedDate != nil)
        #expect(email.bodyPlain == request.bodyText)
        #expect(email.bodyHTML?.contains("<b>Alice</b>") == true)
        #expect(email.bodyHTML?.contains("<a href=\"https://example.com\">site</a>") == true)
        #expect(ComposerAddressCodec.decode(email.toAddresses) == ["alice@example.com"])
        #expect(ComposerAddressCodec.decode(email.ccAddresses) == ["bob@example.com"])
        #expect(ComposerAddressCodec.decode(email.bccAddresses).isEmpty)
    }

    @Test("execute persists attachment models linked to queued email")
    func executePersistsAttachments() async throws {
        let repo = MockEmailRepository()
        let sut = SendEmailUseCase(repository: repo)
        let request = SendEmailRequest(
            accountId: "acc-1",
            fromAddress: "me@example.com",
            to: ["alice@example.com"],
            cc: [],
            bcc: [],
            subject: "Files",
            bodyText: "Please see attached",
            attachments: [
                ComposerAttachmentDraft(filename: "a.pdf", sizeBytes: 1000, isDownloaded: true),
                ComposerAttachmentDraft(filename: "b.png", sizeBytes: 2000, isDownloaded: true)
            ]
        )

        _ = try await sut.execute(request)

        #expect(repo.saveAttachmentCallCount == 2)
        #expect(repo.attachments.count == 2)
        #expect(Set(repo.attachments.map(\.filename)) == ["a.pdf", "b.png"])
    }

    @Test("execute propagates repository errors")
    func executePropagatesErrors() async {
        let repo = MockEmailRepository()
        let expected = NSError(domain: "SendEmailUseCaseTests", code: 9, userInfo: nil)
        repo.errorToThrow = expected
        let sut = SendEmailUseCase(repository: repo)
        let request = SendEmailRequest(
            accountId: "acc-1",
            fromAddress: "me@example.com",
            to: ["alice@example.com"],
            cc: [],
            bcc: [],
            subject: "Status",
            bodyText: "Body",
            attachments: []
        )

        await #expect(throws: expected) {
            _ = try await sut.execute(request)
        }
    }
}
