import Foundation

/// Manages a pool of IMAP connections per account.
///
/// Enforces the maximum concurrent connection limit per account
/// (FR-SYNC-09: max 5 for Gmail) and provides checkout/return
/// semantics for connection reuse.
///
/// Spec ref: FR-SYNC-09 (Connection Management)
public actor ConnectionPool {

    // MARK: - Types

    /// A pooled connection entry.
    private struct PoolEntry {
        let client: IMAPClient
        var isCheckedOut: Bool
    }

    // MARK: - Properties

    /// Connections indexed by account ID.
    private var pools: [String: [PoolEntry]] = [:]

    /// Maximum connections per account (FR-SYNC-09: 5 for Gmail).
    private let maxConnectionsPerAccount: Int

    // MARK: - Init

    public init(maxConnectionsPerAccount: Int = AppConstants.imapMaxConnectionsPerAccount) {
        self.maxConnectionsPerAccount = maxConnectionsPerAccount
    }

    // MARK: - Checkout / Return

    /// Checks out an available connection for the given account.
    ///
    /// If no idle connection is available and the pool is not full,
    /// creates a new `IMAPClient` and connects it.
    ///
    /// - Parameters:
    ///   - accountId: Unique account identifier
    ///   - host: IMAP server hostname
    ///   - port: IMAP server port
    ///   - email: User's email address
    ///   - accessToken: OAuth access token
    /// - Returns: A connected `IMAPClient` ready for use
    /// - Throws: `IMAPError.maxRetriesExhausted` if pool is full and no connections available
    public func checkout(
        accountId: String,
        host: String,
        port: Int,
        email: String,
        accessToken: String
    ) async throws -> IMAPClient {
        var entries = pools[accountId] ?? []

        // First: try to find an idle (checked-in) connection
        for i in entries.indices {
            if !entries[i].isCheckedOut {
                let client = entries[i].client
                let connected = await client.isConnected

                if connected {
                    entries[i].isCheckedOut = true
                    pools[accountId] = entries
                    return client
                } else {
                    // Dead connection — remove it
                    entries.remove(at: i)
                    pools[accountId] = entries
                    // Try again with updated list
                    return try await checkout(
                        accountId: accountId,
                        host: host,
                        port: port,
                        email: email,
                        accessToken: accessToken
                    )
                }
            }
        }

        // Second: create a new connection if under the limit
        guard entries.count < maxConnectionsPerAccount else {
            throw IMAPError.commandFailed(
                "Connection pool exhausted: \(entries.count)/\(maxConnectionsPerAccount) for account \(accountId)"
            )
        }

        let client = IMAPClient()
        try await client.connect(host: host, port: port, email: email, accessToken: accessToken)

        entries.append(PoolEntry(client: client, isCheckedOut: true))
        pools[accountId] = entries

        return client
    }

    /// Returns a connection to the pool for reuse.
    ///
    /// - Parameters:
    ///   - client: The `IMAPClient` to return
    ///   - accountId: The account ID this client belongs to
    public func checkin(_ client: IMAPClient, accountId: String) {
        guard var entries = pools[accountId] else { return }

        for i in entries.indices {
            if entries[i].client === client {
                entries[i].isCheckedOut = false
                pools[accountId] = entries
                return
            }
        }
    }

    // MARK: - Lifecycle

    /// Disconnects all connections for a specific account.
    public func disconnectAll(accountId: String) async {
        guard let entries = pools[accountId] else { return }

        for entry in entries {
            try? await entry.client.disconnect()
        }

        pools.removeValue(forKey: accountId)
    }

    /// Disconnects all connections across all accounts.
    public func shutdown() async {
        for accountId in pools.keys {
            await disconnectAll(accountId: accountId)
        }
        pools.removeAll()
    }

    /// Returns the current connection count for an account.
    public func connectionCount(for accountId: String) -> Int {
        pools[accountId]?.count ?? 0
    }

    /// Returns the number of active (checked-out) connections for an account.
    public func activeConnectionCount(for accountId: String) -> Int {
        pools[accountId]?.filter { $0.isCheckedOut }.count ?? 0
    }
}
