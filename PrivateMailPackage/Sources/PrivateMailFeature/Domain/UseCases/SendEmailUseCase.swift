import Foundation

public struct SendEmailRequest: Sendable, Equatable {
    public let accountId: String
    public let fromAddress: String
    public let to: [String]
    public let cc: [String]
    public let bcc: [String]
    public let subject: String
    public let bodyText: String
    public let inReplyTo: String?
    public let references: String?
    public let attachments: [ComposerAttachmentDraft]

    public init(
        accountId: String,
        fromAddress: String,
        to: [String],
        cc: [String],
        bcc: [String],
        subject: String,
        bodyText: String,
        inReplyTo: String? = nil,
        references: String? = nil,
        attachments: [ComposerAttachmentDraft]
    ) {
        self.accountId = accountId
        self.fromAddress = fromAddress
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.bodyText = bodyText
        self.inReplyTo = inReplyTo
        self.references = references
        self.attachments = attachments
    }
}

@MainActor
public protocol SendEmailUseCaseProtocol {
    @discardableResult
    func execute(_ request: SendEmailRequest) async throws -> Email
}

@MainActor
public final class SendEmailUseCase: SendEmailUseCaseProtocol {
    private let repository: EmailRepositoryProtocol

    public init(repository: EmailRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    public func execute(_ request: SendEmailRequest) async throws -> Email {
        let now = Date()
        let messageId = "<\(UUID().uuidString.lowercased())@privatemail.local>"
        let threadId = UUID().uuidString
        let htmlBody = ComposerMarkdownRenderer.renderToSafeHTML(request.bodyText)
        let attachmentTotalBytes = request.attachments.reduce(0) { $0 + $1.sizeBytes }
        let sizeBytes = request.bodyText.utf8.count + attachmentTotalBytes

        let email = Email(
            accountId: request.accountId,
            threadId: threadId,
            messageId: messageId,
            inReplyTo: request.inReplyTo,
            references: request.references,
            fromAddress: request.fromAddress,
            toAddresses: ComposerAddressCodec.encode(request.to),
            ccAddresses: request.cc.isEmpty ? nil : ComposerAddressCodec.encode(request.cc),
            bccAddresses: request.bcc.isEmpty ? nil : ComposerAddressCodec.encode(request.bcc),
            subject: request.subject,
            bodyPlain: request.bodyText,
            bodyHTML: htmlBody,
            snippet: makeSnippet(request.bodyText),
            dateSent: now,
            isDraft: false,
            sizeBytes: sizeBytes,
            sendState: SendState.queued.rawValue,
            sendQueuedDate: now
        )
        try await repository.saveEmail(email)

        for draft in request.attachments {
            let attachment = Attachment(
                filename: draft.filename,
                mimeType: inferMimeType(for: draft.filename),
                sizeBytes: draft.sizeBytes,
                localPath: nil,
                isDownloaded: draft.isDownloaded
            )
            attachment.email = email
            try await repository.saveAttachment(attachment)
        }

        return email
    }

    private func makeSnippet(_ body: String, maxLength: Int = 140) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<end])
    }

    private func inferMimeType(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "txt": return "text/plain"
        case "md": return "text/markdown"
        case "heic": return "image/heic"
        default: return "application/octet-stream"
        }
    }
}
