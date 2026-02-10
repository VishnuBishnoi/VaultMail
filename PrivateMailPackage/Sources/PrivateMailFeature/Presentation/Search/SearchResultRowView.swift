import SwiftUI

/// Individual search result row displaying an email match with metadata.
///
/// Shows sender, subject, body snippet, date, attachment indicator,
/// unread dot, and a semantic match badge when applicable.
///
/// Spec ref: FR-SEARCH-01, AC-S-01
struct SearchResultRowView: View {
    let result: SearchResult
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top row: unread indicator + sender + date
            HStack {
                if !result.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }

                Text(senderDisplayName)
                    .font(.subheadline.weight(result.isRead ? .regular : .semibold))
                    .lineLimit(1)

                Spacer()

                Text(result.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Subject line
            Text(result.subject)
                .font(.subheadline.weight(result.isRead ? .regular : .semibold))
                .lineLimit(1)

            // Snippet + indicators
            HStack(spacing: 4) {
                Text(result.snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                if result.hasAttachment {
                    Image(systemName: "paperclip")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                matchSourceBadge
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Computed Properties

    private var senderDisplayName: String {
        result.senderName.isEmpty ? result.senderEmail : result.senderName
    }

    // MARK: - Match Source Badge

    @ViewBuilder
    private var matchSourceBadge: some View {
        switch result.matchSource {
        case .semantic:
            Image(systemName: "brain")
                .font(.caption2)
                .foregroundStyle(.purple)
                .accessibilityLabel("Semantic match")
        case .both:
            Image(systemName: "brain")
                .font(.caption2)
                .foregroundStyle(.purple)
                .accessibilityLabel("Keyword and semantic match")
        case .keyword:
            EmptyView()
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let readStatus = result.isRead ? "" : "Unread. "
        let attachment = result.hasAttachment ? "Has attachment. " : ""
        let matchType: String
        switch result.matchSource {
        case .semantic:
            matchType = "Semantic match. "
        case .both:
            matchType = "Keyword and semantic match. "
        case .keyword:
            matchType = ""
        }
        return "\(readStatus)\(senderDisplayName). \(result.subject). \(attachment)\(matchType)\(result.snippet)"
    }
}
