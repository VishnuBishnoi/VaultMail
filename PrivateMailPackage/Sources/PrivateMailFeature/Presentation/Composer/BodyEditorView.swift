import SwiftUI

struct BodyEditorView: View {
    @Binding var bodyText: String
    let onInsertBold: () -> Void
    let onInsertItalic: () -> Void
    let onInsertLink: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                toolbarButton(systemName: "bold", label: "Bold", action: onInsertBold)
                toolbarButton(systemName: "italic", label: "Italic", action: onInsertItalic)
                toolbarButton(systemName: "link", label: "Link", action: onInsertLink)
                Spacer()
            }

            TextEditor(text: $bodyText)
                .frame(minHeight: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .accessibilityLabel("Email body")
        }
    }

    private func toolbarButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemName)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(label)
    }
}

#Preview {
    @Previewable @State var bodyText = "Hello"
    return BodyEditorView(
        bodyText: $bodyText,
        onInsertBold: {},
        onInsertItalic: {},
        onInsertLink: {}
    )
    .padding()
}
