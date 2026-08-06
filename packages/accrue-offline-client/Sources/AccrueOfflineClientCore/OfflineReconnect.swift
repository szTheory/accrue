import Foundation

/// A host-owned authenticated request that returns only a compact entitlement proof.
/// Implementations retain responsibility for endpoints, credentials, request shape, and retries.
public protocol OfflineProofReconnectTransport: Sendable {
    func reconnectProof() async throws -> Data
}

public extension OfflineEntitlementClient {
    /// Obtains a host-authenticated proof and admits it through the normal verifier and cache boundary.
    func reconnect(using transport: some OfflineProofReconnectTransport, now: Date) async -> OfflineEntitlementState {
        do {
            return applyServerProof(try await transport.reconnectProof(), now: now)
        } catch {
            return .invalid(reason: .reconnectFailed, nextAction: .reconnectRequired)
        }
    }
}
