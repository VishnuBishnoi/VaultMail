import SwiftUI

/// App password entry for providers that use SASL PLAIN auth (Yahoo, iCloud, custom).
///
/// Shows provider-specific instructions link and a SecureField for the app password.
/// Validates the connection before saving the account.
///
/// Spec ref: FR-MPROV-10 (Onboarding & Provider Selection)
struct AppPasswordEntryView: View {

    @State var email: String
    let providerConfig: ProviderConfiguration
    let manageAccounts: ManageAccountsUseCaseProtocol
    let onAccountAdded: (Account) -> Void
    let onCancel: () -> Void

    @State private var password = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: providerIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text("Sign in to \(providerConfig.displayName)")
                    .font(.title2.bold())

                Text("Enter your email and app-specific password. You can generate one in your \(providerConfig.displayName) account settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Instructions link
                if let helpURL = providerConfig.appPasswordHelpURL {
                    Link(destination: helpURL) {
                        Label("How to create an app password", systemImage: "questionmark.circle")
                            .font(.callout)
                    }
                    .accessibilityLabel("Open \(providerConfig.displayName) app password instructions")
                }

                // Form
                VStack(spacing: 12) {
                    TextField("Email address", text: $email)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #endif
                        .padding(12)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("Email address")

                    SecureField("App Password", text: $password)
                        .textContentType(.password)
                        .padding(12)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("App password")
                }
                .padding(.horizontal)

                // Error display
                if let errorMessage {
                    Label {
                        Text(errorMessage)
                            .font(.callout)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .accessibilityLabel("Error: \(errorMessage)")
                }

                Spacer()

                // Sign In button
                Button {
                    addAccount()
                } label: {
                    if isAdding {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Connecting...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || isAdding)
                .padding(.horizontal)
                .accessibilityLabel(isAdding ? "Connecting to email server" : "Sign in")
            }
            .padding(.bottom, 40)
            .navigationTitle(providerConfig.displayName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }

    // MARK: - Helpers

    private var providerIcon: String {
        switch providerConfig.identifier {
        case .icloud: return "icloud.fill"
        case .yahoo: return "envelope.fill"
        default: return "envelope.badge.shield.half.filled.fill"
        }
    }

    // MARK: - Actions

    private func addAccount() {
        isAdding = true
        errorMessage = nil

        Task {
            defer { isAdding = false }
            do {
                let account = try await manageAccounts.addAccountViaAppPassword(
                    email: email,
                    password: password,
                    providerConfig: providerConfig
                )
                onAccountAdded(account)
            } catch let error as AccountError {
                switch error {
                case .duplicateAccount(let email):
                    errorMessage = "\(email) is already added."
                case .imapValidationFailed:
                    errorMessage = "Couldn't connect to \(providerConfig.displayName). Please check your app password and try again."
                default:
                    errorMessage = "Failed to add account. Please try again."
                }
            } catch {
                errorMessage = "An unexpected error occurred. Please try again."
            }
        }
    }
}
