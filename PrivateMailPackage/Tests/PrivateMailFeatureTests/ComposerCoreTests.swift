import Foundation
import Testing
@testable import PrivateMailFeature

@Suite("ComposerCore")
struct ComposerCoreTests {

    private static func makeSourceEmail(
        subject: String = "Quarterly Update",
        body: String = "Hello team\nPlease review",
        fromAddress: String = "alice@example.com",
        fromName: String? = "Alice",
        to: [String] = ["me@example.com", "bob@example.com"],
        cc: [String] = ["carol@example.com"],
        dateSent: Date = Date(timeIntervalSince1970: 1_700_000_000),
        messageId: String = "<parent@msg>",
        references: String? = "<root@msg>"
    ) -> ComposerSourceEmail {
        ComposerSourceEmail(
            subject: subject,
            bodyPlain: body,
            fromAddress: fromAddress,
            fromName: fromName,
            toAddresses: to,
            ccAddresses: cc,
            dateSent: dateSent,
            messageId: messageId,
            references: references
        )
    }

    @Test("Reply prefills recipient, subject, quote header, inReplyTo, and references")
    func replyPrefill() {
        let source = Self.makeSourceEmail()
        let prefill = ComposerPrefillBuilder.build(
            mode: .reply(source),
            selfAddresses: ["me@example.com"],
            dateFormatter: { _ in "Jan 1, 2026" }
        )

        #expect(prefill.to == ["alice@example.com"])
        #expect(prefill.cc.isEmpty)
        #expect(prefill.subject == "Re: Quarterly Update")
        #expect(prefill.inReplyTo == "<parent@msg>")
        #expect(prefill.references == "<root@msg> <parent@msg>")
        #expect(prefill.body.contains("On Jan 1, 2026, Alice wrote:"))
        #expect(prefill.body.contains("> Hello team"))
    }

    @Test("Reply-all removes self, deduplicates, and keeps sender in To")
    func replyAllDedup() {
        let source = Self.makeSourceEmail(
            to: ["me@example.com", "bob@example.com", "alice@example.com"],
            cc: ["me@example.com", "bob@example.com", "carol@example.com"]
        )

        let prefill = ComposerPrefillBuilder.build(
            mode: .replyAll(source),
            selfAddresses: ["me@example.com"]
        )

        #expect(prefill.to == ["alice@example.com"])
        #expect(prefill.cc == ["bob@example.com", "carol@example.com"])
    }

    @Test("Forward prefill keeps attachments and forwarding header")
    func forwardPrefill() {
        let source = Self.makeSourceEmail(subject: "Fwd: Existing", references: nil)
        let attachments = [
            ComposerAttachmentDraft(filename: "a.pdf", sizeBytes: 10, isDownloaded: true),
            ComposerAttachmentDraft(filename: "b.png", sizeBytes: 20, isDownloaded: false)
        ]

        let prefill = ComposerPrefillBuilder.build(
            mode: .forward(source, attachments: attachments),
            selfAddresses: []
        )

        #expect(prefill.to.isEmpty)
        #expect(prefill.cc.isEmpty)
        #expect(prefill.subject == "Fwd: Existing")
        #expect(prefill.body.contains("---------- Forwarded message ----------"))
        #expect(prefill.attachments.count == 2)
    }

    @Test("Subject prefix is not duplicated")
    func subjectPrefixDedup() {
        #expect(ComposerPrefillBuilder.prefixedSubject("Re: Hello", prefix: "Re:") == "Re: Hello")
        #expect(ComposerPrefillBuilder.prefixedSubject("re: Hello", prefix: "Re:") == "re: Hello")
        #expect(ComposerPrefillBuilder.prefixedSubject("Hello", prefix: "Re:") == "Re: Hello")
    }

    @Test("Email validator accepts common valid emails and rejects malformed")
    func emailValidation() {
        #expect(EmailAddressValidator.isValid("alice@example.com"))
        #expect(EmailAddressValidator.isValid("a.b+c@example.co.uk"))
        #expect(!EmailAddressValidator.isValid("alice@"))
        #expect(!EmailAddressValidator.isValid("alice.example.com"))
        #expect(!EmailAddressValidator.isValid(""))
    }

    @Test("Attachment size policy hard blocks send above 25MB")
    func attachmentLimit() {
        let justUnder = 25 * 1_024 * 1_024 - 1
        let over = 25 * 1_024 * 1_024 + 1

        #expect(ComposerAttachmentPolicy.evaluate(totalSizeBytes: justUnder).canSend)
        #expect(!ComposerAttachmentPolicy.evaluate(totalSizeBytes: over).canSend)
        #expect(ComposerAttachmentPolicy.evaluate(totalSizeBytes: over).showsWarning)
    }

    @Test("Body warning triggers when body size exceeds 100KB")
    func bodySizeWarning() {
        let small = String(repeating: "a", count: 100)
        let large = String(repeating: "a", count: 102_401)

        #expect(!ComposerBodyPolicy.shouldWarnAboutBodySize(small))
        #expect(ComposerBodyPolicy.shouldWarnAboutBodySize(large))
    }

    @Test("Markdown converter supports bold italic links and escapes unsupported HTML")
    func markdownToHTML() {
        let input = "Use **bold**, *italic*, and [site](https://example.com). <script>alert(1)</script>"
        let html = ComposerMarkdownRenderer.renderToSafeHTML(input)

        #expect(html.contains("<b>bold</b>"))
        #expect(html.contains("<i>italic</i>"))
        #expect(html.contains("<a href=\"https://example.com\">site</a>"))
        #expect(!html.contains("<script>"))
    }
}
