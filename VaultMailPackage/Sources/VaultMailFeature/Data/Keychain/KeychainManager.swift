import Foundation
import Security

/// Keychain-based secure storage for account credentials.
///
/// Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum
/// security. Credentials are JSON-encoded and scoped per account ID.
///
/// Supports both `AccountCredential` (OAuth + app password) and
/// legacy `OAuthToken` format with automatic migration on read.
///
/// Spec ref: Account Management spec FR-ACCT-04, AC-F-03
///           Multi-provider spec FR-MPROV-06
public actor KeychainManager: KeychainManagerProtocol {

    private let service: String

    /// Creates a KeychainManager with a configurable service name.
    /// - Parameter service: Keychain service identifier. Defaults to production value.
    ///   Use a unique value in tests for isolation.
    public init(service: String = "com.vaultmail.oauth") {
        self.service = service
    }

    // MARK: - AccountCredential API (primary)

    public func storeCredential(_ credential: AccountCredential, for accountId: String) async throws {
        let data = try encodeCredential(credential)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountId,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data,
        ]

        // Delete any existing item first to avoid errSecDuplicateItem
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    public func retrieveCredential(for accountId: String) async throws -> AccountCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unableToRetrieve(status)
        }

        return try decodeCredential(data)
    }

    public func deleteCredential(for accountId: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountId,
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Ignore "not found" — deleting something that doesn't exist is fine
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }

    public func updateCredential(_ credential: AccountCredential, for accountId: String) async throws {
        // Delete + store is simpler and safer than SecItemUpdate for JSON blobs
        try await deleteCredential(for: accountId)
        try await storeCredential(credential, for: accountId)
    }

    // MARK: - Encoding

    private func encodeCredential(_ credential: AccountCredential) throws -> Data {
        do {
            return try JSONEncoder().encode(credential)
        } catch {
            throw KeychainError.encodingFailed
        }
    }

    /// Decodes credential data with backward compatibility.
    ///
    /// Tries `AccountCredential` first. If that fails, falls back to decoding
    /// as a legacy `OAuthToken` and wraps it as `.oauth(token)`.
    /// This ensures existing Keychain entries from pre-multi-provider versions
    /// continue to work without manual migration.
    private func decodeCredential(_ data: Data) throws -> AccountCredential {
        // Try new format first
        if let credential = try? JSONDecoder().decode(AccountCredential.self, from: data) {
            return credential
        }

        // Fall back to legacy OAuthToken format
        do {
            let token = try JSONDecoder().decode(OAuthToken.self, from: data)
            return .oauth(token)
        } catch {
            throw KeychainError.decodingFailed
        }
    }
}
