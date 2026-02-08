import SwiftUI

struct RecipientFieldView: View {
    let title: String
    @Binding var addresses: [String]
    let invalidAddresses: Set<String>

    @State private var input = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(addresses, id: \.self) { address in
                            recipientChip(address)
                        }
                    }
                }

                TextField("Add recipient", text: $input)
                    .textFieldStyle(.plain)
                    .onSubmit { commitInput() }
                    .onChange(of: input) {
                        if input.contains(",") || input.contains(";") {
                            commitInput()
                        }
                    }
                    .accessibilityLabel("\(title) recipient input")
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
        }
    }

    private func recipientChip(_ address: String) -> some View {
        let isInvalid = invalidAddresses.contains(address)

        return HStack(spacing: 6) {
            if isInvalid {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Text(address)
                .lineLimit(1)
            Button {
                addresses.removeAll { $0 == address }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(address)")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isInvalid ? Color.red.opacity(0.12) : Color.secondary.opacity(0.12))
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isInvalid ? "Invalid recipient \(address)" : "Recipient \(address)")
    }

    private func commitInput() {
        let raw = input
        input = ""

        let candidates = raw
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0 == "\n" })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for value in candidates where !addresses.contains(value) {
            addresses.append(value)
        }
    }
}

#Preview {
    @Previewable @State var addresses = ["alice@example.com", "bob@example.com"]
    return RecipientFieldView(
        title: "To",
        addresses: $addresses,
        invalidAddresses: ["bob@example.com"]
    )
    .padding()
}
