import SwiftUI

struct SmartReplyChipView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if !suggestions.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            onSelect(suggestion)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Smart reply \(suggestion)")
                    }
                }
            }
        }
    }
}

#Preview {
    SmartReplyChipView(suggestions: ["Thanks!", "Got it", "Will do"]) { _ in }
        .padding()
}
