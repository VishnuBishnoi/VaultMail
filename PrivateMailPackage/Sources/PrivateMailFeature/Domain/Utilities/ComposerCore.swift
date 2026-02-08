import Foundation

public struct ComposerSourceEmail: Sendable {
    public let subject: String
    public let bodyPlain: String?
    public let fromAddress: String
    public let fromName: String?
    public let toAddresses: [String]
    public let ccAddresses: [String]
    public let dateSent: Date?
    public let messageId: String
    public let references: String?

    public init(
        subject: String,
        bodyPlain: String?,
        fromAddress: String,
        fromName: String?,
        toAddresses: [String],
        ccAddresses: [String],
        dateSent: Date?,
        messageId: String,
        references: String?
    ) {
        self.subject = subject
        self.bodyPlain = bodyPlain
        self.fromAddress = fromAddress
        self.fromName = fromName
        self.toAddresses = toAddresses
        self.ccAddresses = ccAddresses
        self.dateSent = dateSent
        self.messageId = messageId
        self.references = references
    }
}

public struct ComposerAttachmentDraft: Sendable, Equatable {
    public let filename: String
    public let sizeBytes: Int
    public let isDownloaded: Bool

    public init(filename: String, sizeBytes: Int, isDownloaded: Bool) {
        self.filename = filename
        self.sizeBytes = sizeBytes
        self.isDownloaded = isDownloaded
    }
}

public enum ComposerMode: Sendable {
    case new
    case reply(ComposerSourceEmail)
    case replyAll(ComposerSourceEmail)
    case forward(ComposerSourceEmail, attachments: [ComposerAttachmentDraft])
}

public struct ComposerPrefill: Sendable, Equatable {
    public let to: [String]
    public let cc: [String]
    public let bcc: [String]
    public let subject: String
    public let body: String
    public let inReplyTo: String?
    public let references: String?
    public let attachments: [ComposerAttachmentDraft]

    public init(
        to: [String],
        cc: [String],
        bcc: [String] = [],
        subject: String,
        body: String,
        inReplyTo: String? = nil,
        references: String? = nil,
        attachments: [ComposerAttachmentDraft] = []
    ) {
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.inReplyTo = inReplyTo
        self.references = references
        self.attachments = attachments
    }
}

public enum ComposerPrefillBuilder {
    public static func build(
        mode: ComposerMode,
        selfAddresses: Set<String>,
        dateFormatter: (Date?) -> String = { date in
            guard let date else { return "Unknown date" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    ) -> ComposerPrefill {
        switch mode {
        case .new:
            return ComposerPrefill(to: [], cc: [], subject: "", body: "")

        case .reply(let source):
            let quoted = quotedReplyBody(source: source, dateFormatter: dateFormatter)
            return ComposerPrefill(
                to: [source.fromAddress],
                cc: [],
                subject: prefixedSubject(source.subject, prefix: "Re:"),
                body: quoted,
                inReplyTo: source.messageId,
                references: appendedReferences(existing: source.references, messageId: source.messageId)
            )

        case .replyAll(let source):
            let normalizedSelf = Set(selfAddresses.map { $0.lowercased() })
            var ccCandidates = source.toAddresses + source.ccAddresses

            ccCandidates.removeAll { address in
                let normalized = address.lowercased()
                return normalized == source.fromAddress.lowercased() || normalizedSelf.contains(normalized)
            }

            let dedupedCC = dedupePreservingOrder(ccCandidates)
            let quoted = quotedReplyBody(source: source, dateFormatter: dateFormatter)

            return ComposerPrefill(
                to: [source.fromAddress],
                cc: dedupedCC,
                subject: prefixedSubject(source.subject, prefix: "Re:"),
                body: quoted,
                inReplyTo: source.messageId,
                references: appendedReferences(existing: source.references, messageId: source.messageId)
            )

        case .forward(let source, let attachments):
            let header = forwardHeader(source: source, dateFormatter: dateFormatter)
            let body = [header, source.bodyPlain ?? ""]
                .joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return ComposerPrefill(
                to: [],
                cc: [],
                subject: prefixedSubject(source.subject, prefix: "Fwd:"),
                body: body,
                attachments: attachments
            )
        }
    }

    public static func prefixedSubject(_ subject: String, prefix: String) -> String {
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPrefix = prefix.lowercased()

        if trimmed.lowercased().hasPrefix(normalizedPrefix) {
            return subject
        }

        if trimmed.isEmpty {
            return prefix
        }

        return "\(prefix) \(subject)"
    }

    private static func quotedReplyBody(source: ComposerSourceEmail, dateFormatter: (Date?) -> String) -> String {
        let sender = source.fromName ?? source.fromAddress
        let header = "On \(dateFormatter(source.dateSent)), \(sender) wrote:"
        let quoted = quoteLines(source.bodyPlain ?? "")
        return "\n\n\(header)\n\(quoted)"
    }

    private static func forwardHeader(source: ComposerSourceEmail, dateFormatter: (Date?) -> String) -> String {
        let fromLine: String
        if let fromName = source.fromName, !fromName.isEmpty {
            fromLine = "From: \(fromName) <\(source.fromAddress)>"
        } else {
            fromLine = "From: \(source.fromAddress)"
        }

        let toLine = "To: \(source.toAddresses.joined(separator: ", "))"

        return [
            "---------- Forwarded message ----------",
            fromLine,
            "Date: \(dateFormatter(source.dateSent))",
            "Subject: \(source.subject)",
            toLine
        ].joined(separator: "\n")
    }

    private static func quoteLines(_ body: String) -> String {
        body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "> \($0)" }
            .joined(separator: "\n")
    }

    private static func appendedReferences(existing: String?, messageId: String) -> String {
        guard let existing, !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return messageId
        }
        return "\(existing) \(messageId)"
    }

    private static func dedupePreservingOrder(_ emails: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for email in emails {
            let normalized = email.lowercased()
            guard !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            result.append(email)
        }

        return result
    }
}

public enum ComposerAddressCodec {
    public static func decode(_ json: String?) -> [String] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    public static func encode(_ addresses: [String]) -> String {
        guard let data = try? JSONEncoder().encode(addresses),
              let value = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return value
    }
}

public enum EmailAddressValidator {
    private static let regex = try? NSRegularExpression(
        pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$",
        options: []
    )

    public static func isValid(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let regex else { return false }

        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex.firstMatch(in: trimmed, options: [], range: range) != nil
    }
}

public struct ComposerAttachmentPolicyResult: Sendable, Equatable {
    public let totalSizeBytes: Int
    public let showsWarning: Bool
    public let canSend: Bool
}

public enum ComposerAttachmentPolicy {
    public static let maxTotalSizeBytes = 25 * 1_024 * 1_024

    public static func evaluate(totalSizeBytes: Int) -> ComposerAttachmentPolicyResult {
        let exceedsLimit = totalSizeBytes > maxTotalSizeBytes
        return ComposerAttachmentPolicyResult(
            totalSizeBytes: totalSizeBytes,
            showsWarning: exceedsLimit,
            canSend: !exceedsLimit
        )
    }
}

public enum ComposerBodyPolicy {
    public static let warningThresholdBytes = 100 * 1_024

    public static func shouldWarnAboutBodySize(_ body: String) -> Bool {
        body.utf8.count > warningThresholdBytes
    }
}

public enum ComposerMarkdownRenderer {
    public static func renderToSafeHTML(_ text: String) -> String {
        let escaped = escapeHTML(text)
        let linksApplied = replace(pattern: #"\[([^\]]+)\]\((https?://[^\s)]+)\)"#, in: escaped) { groups in
            guard groups.count == 3 else { return groups.first ?? "" }
            let label = groups[1]
            let url = groups[2]
            return "<a href=\"\(url)\">\(label)</a>"
        }
        let boldApplied = replace(pattern: #"\*\*([^*]+)\*\*"#, in: linksApplied) { groups in
            guard groups.count == 2 else { return groups.first ?? "" }
            return "<b>\(groups[1])</b>"
        }
        let italicApplied = replace(pattern: #"\*([^*]+)\*"#, in: boldApplied) { groups in
            guard groups.count == 2 else { return groups.first ?? "" }
            return "<i>\(groups[1])</i>"
        }

        return italicApplied.replacingOccurrences(of: "\n", with: "<br>")
    }

    private static func replace(pattern: String, in text: String, transform: ([String]) -> String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsrange).reversed()

        var output = text
        for match in matches {
            guard let range = Range(match.range, in: output) else { continue }
            var groups: [String] = []
            for idx in 0..<match.numberOfRanges {
                let mr = match.range(at: idx)
                if let r = Range(mr, in: output) {
                    groups.append(String(output[r]))
                } else {
                    groups.append("")
                }
            }
            output.replaceSubrange(range, with: transform(groups))
        }

        return output
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
