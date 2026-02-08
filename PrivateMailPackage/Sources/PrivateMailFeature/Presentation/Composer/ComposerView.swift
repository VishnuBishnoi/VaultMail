import SwiftUI

struct ComposerView: View {
    @Environment(\.dismiss) private var dismiss

    let mode: ComposerMode
    let fromAccount: String?

    @State private var toAddresses: [String] = []
    @State private var ccAddresses: [String] = []
    @State private var bccAddresses: [String] = []
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var attachments: [ComposerAttachmentDraft] = []

    @State private var showCC = false
    @State private var showBCC = false
    @State private var showDiscardConfirmation = false
    @State private var pendingPromptQueue: [ComposerSendPrompt] = []
    @State private var activePrompt: ComposerSendPrompt?

    @State private var initialLoaded = false

    init(mode: ComposerMode = .new, fromAccount: String? = nil) {
        self.mode = mode
        self.fromAccount = fromAccount
    }

    private var totalAttachmentBytes: Int {
        attachments.reduce(0) { $0 + $1.sizeBytes }
    }

    private var sendValidation: ComposerSendValidation {
        ComposerSendValidator.validate(
            to: toAddresses,
            cc: ccAddresses,
            bcc: bccAddresses,
            attachmentTotalBytes: totalAttachmentBytes
        )
    }

    private var invalidAddressSet: Set<String> {
        Set(sendValidation.invalidAddresses)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    fromSection
                    RecipientFieldView(title: "To", addresses: $toAddresses, invalidAddresses: invalidAddressSet)

                    if showCC {
                        RecipientFieldView(title: "CC", addresses: $ccAddresses, invalidAddresses: invalidAddressSet)
                    }
                    if showBCC {
                        RecipientFieldView(title: "BCC", addresses: $bccAddresses, invalidAddresses: invalidAddressSet)
                    }

                    HStack(spacing: 12) {
                        if !showCC {
                            Button("Add CC") { showCC = true }
                                .buttonStyle(.borderless)
                        }
                        if !showBCC {
                            Button("Add BCC") { showBCC = true }
                                .buttonStyle(.borderless)
                        }
                    }

                    TextField("Subject", text: $subject)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Subject")

                    BodyEditorView(
                        bodyText: $bodyText,
                        onInsertBold: { insertMarkdown("**bold**") },
                        onInsertItalic: { insertMarkdown("*italic*") },
                        onInsertLink: { insertMarkdown("[text](https://)") }
                    )

                    if ComposerBodyPolicy.shouldWarnAboutBodySize(bodyText) {
                        Label("Body exceeds 100KB", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    if sendValidation.exceedsAttachmentLimit {
                        Label("Attachments exceed 25 MB. Remove attachments to send.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { toolbarContent }
            .confirmationDialog("Delete draft?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .alert(
                alertTitle,
                isPresented: Binding(
                    get: { activePrompt != nil },
                    set: { if !$0 { activePrompt = nil } }
                )
            ) {
                Button("Send") { proceedPromptQueue() }
                Button("Cancel", role: .cancel) { pendingPromptQueue.removeAll() }
            }
            .task {
                guard !initialLoaded else { return }
                initialLoaded = true
                applyPrefill()
            }
        }
    }

    private var title: String {
        switch mode {
        case .new: return "New Message"
        case .reply: return "Reply"
        case .replyAll: return "Reply All"
        case .forward: return "Forward"
        }
    }

    private var alertTitle: String {
        switch activePrompt {
        case .emptySubject: return "Send without subject?"
        case .emptyBody: return "Send empty message?"
        case nil: return ""
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if hasMeaningfulContent {
                    showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            }
            .keyboardShortcut(.cancelAction)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Send") { attemptSend() }
                .disabled(!sendValidation.canSend)
                .keyboardShortcut("D", modifiers: [.command, .shift])
        }
    }

    private var fromSection: some View {
        Group {
            if let fromAccount, !fromAccount.isEmpty {
                LabeledContent("From", value: fromAccount)
                    .font(.subheadline)
            }
        }
    }

    private var hasMeaningfulContent: Bool {
        let hasRecipients = !(toAddresses + ccAddresses + bccAddresses).allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let hasSubject = !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasBody = !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAttachments = !attachments.isEmpty
        return hasRecipients || hasSubject || hasBody || hasAttachments
    }

    private func applyPrefill() {
        let prefill = ComposerPrefillBuilder.build(mode: mode, selfAddresses: Set())
        toAddresses = prefill.to
        ccAddresses = prefill.cc
        bccAddresses = prefill.bcc
        subject = prefill.subject
        bodyText = prefill.body
        attachments = prefill.attachments
        showCC = !ccAddresses.isEmpty
        showBCC = !bccAddresses.isEmpty
    }

    private func insertMarkdown(_ snippet: String) {
        if bodyText.isEmpty {
            bodyText = snippet
        } else {
            bodyText += "\n\(snippet)"
        }
    }

    private func attemptSend() {
        let prompts = ComposerSendPromptPolicy.requiredPrompts(subject: subject, body: bodyText)
        if prompts.isEmpty {
            dismiss()
            return
        }

        pendingPromptQueue = prompts
        activePrompt = pendingPromptQueue.first
    }

    private func proceedPromptQueue() {
        guard !pendingPromptQueue.isEmpty else {
            activePrompt = nil
            dismiss()
            return
        }
        pendingPromptQueue.removeFirst()
        activePrompt = pendingPromptQueue.first
        if activePrompt == nil {
            dismiss()
        }
    }
}

#Preview("New") {
    ComposerView(mode: .new, fromAccount: "me@example.com")
}

#Preview("Reply") {
    ComposerView(
        mode: .reply(
            ComposerSourceEmail(
                subject: "Project status",
                bodyPlain: "Looks good to me",
                fromAddress: "alice@example.com",
                fromName: "Alice",
                toAddresses: ["me@example.com"],
                ccAddresses: ["team@example.com"],
                dateSent: .now,
                messageId: "<id>",
                references: "<root>"
            )
        ),
        fromAccount: "me@example.com"
    )
}
