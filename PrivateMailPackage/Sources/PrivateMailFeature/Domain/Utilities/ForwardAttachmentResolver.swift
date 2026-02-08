import Foundation

public struct ForwardAttachmentReadiness: Sendable, Equatable {
    public let canSend: Bool
    public let pendingFilenames: [String]
}

public enum ForwardAttachmentResolver {
    public static func evaluateForwardReadiness(attachments: [ComposerAttachmentDraft]) -> ForwardAttachmentReadiness {
        let pending = attachments
            .filter { !$0.isDownloaded }
            .map(\.filename)

        return ForwardAttachmentReadiness(
            canSend: pending.isEmpty,
            pendingFilenames: pending
        )
    }
}
