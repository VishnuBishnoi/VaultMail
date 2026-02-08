import SwiftUI
import UniformTypeIdentifiers

struct AttachmentPickerView: View {
    @Binding var attachments: [ComposerAttachmentDraft]
    @State private var showFileImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showFileImporter = true
            } label: {
                Label("Attach File", systemImage: "paperclip")
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("A", modifiers: [.command, .shift])
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: true
            ) { result in
                guard case .success(let urls) = result else { return }
                addAttachments(from: urls)
            }

            if !attachments.isEmpty {
                ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(attachment.filename)
                                .font(.subheadline)
                            Text(ByteCountFormatter.string(fromByteCount: Int64(attachment.sizeBytes), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            attachments.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove attachment \(attachment.filename)")
                    }
                }
            }
        }
    }

    private func addAttachments(from urls: [URL]) {
        for url in urls {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .nameKey])
            let size = values?.fileSize ?? 0
            let name = values?.name ?? url.lastPathComponent
            attachments.append(
                ComposerAttachmentDraft(
                    filename: name,
                    sizeBytes: size,
                    isDownloaded: true
                )
            )
        }
    }
}

#Preview {
    @Previewable @State var attachments: [ComposerAttachmentDraft] = [
        .init(filename: "report.pdf", sizeBytes: 1024, isDownloaded: true)
    ]

    return AttachmentPickerView(attachments: $attachments)
        .padding()
}
