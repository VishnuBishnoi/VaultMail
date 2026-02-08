import Testing
@testable import PrivateMailFeature

@Suite("ForwardAttachmentResolver")
struct ForwardAttachmentResolverTests {

    @Test("blocks send when any forwarded attachment is not downloaded")
    func blocksWhenPending() {
        let attachments = [
            ComposerAttachmentDraft(filename: "a.pdf", sizeBytes: 100, isDownloaded: true),
            ComposerAttachmentDraft(filename: "b.pdf", sizeBytes: 100, isDownloaded: false)
        ]

        let result = ForwardAttachmentResolver.evaluateForwardReadiness(attachments: attachments)

        #expect(!result.canSend)
        #expect(result.pendingFilenames == ["b.pdf"])
    }

    @Test("allows send when all forwarded attachments are downloaded")
    func allowsWhenReady() {
        let attachments = [
            ComposerAttachmentDraft(filename: "a.pdf", sizeBytes: 100, isDownloaded: true)
        ]

        let result = ForwardAttachmentResolver.evaluateForwardReadiness(attachments: attachments)

        #expect(result.canSend)
        #expect(result.pendingFilenames.isEmpty)
    }
}
