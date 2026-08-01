import Foundation
import CryptoKit

public enum GoldenVectorResult: String, Sendable, Equatable { case accept, reject }
public enum GoldenVectorCache: String, Sendable, Equatable { case allow, deny }

public struct GoldenVectorObservation: Sendable, Equatable {
    public let id: String
    public let result: GoldenVectorResult
    public let reason: String
    public let cache: GoldenVectorCache
}

/// Test-only reader for the shared server/client JWS corpus. This never contributes
/// to capability-report feasibility and is intentionally unavailable to app runtime.
public enum OfflineGoldenVectorVerifier {
    public static func verifyFixture() throws -> [GoldenVectorObservation] {
        let fixture = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json")
        let data = try Data(contentsOf: fixture)
        let corpus = try JSONDecoder().decode(Corpus.self, from: data)

        return try corpus.vectors.map(observe).sorted { $0.id < $1.id }
    }

    private static func observe(_ vector: Vector) throws -> GoldenVectorObservation {
        if vector.expectedVerification == "accept" {
            let parts = vector.compactJWS.split(separator: ".")
            guard parts.count == 3,
                  let headerData = Data(base64URLEncoded: String(parts[0])),
                  let payloadData = Data(base64URLEncoded: String(parts[1])),
                  let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any],
                  let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
                  header["alg"] as? String == "ES256",
                  payload["iss"] as? String == "accrue.test.offline",
                  payload["aud"] as? String == "accrue-offline-client",
                  payload["typ"] as? String == "accrue-entitlement",
                  Data(base64URLEncoded: String(parts[2])) != nil
            else { throw GoldenVectorError.malformed }
        }

        return GoldenVectorObservation(id: vector.id, result: vector.expectedVerification == "accept" ? .accept : .reject, reason: vector.expectedReason, cache: vector.expectedCacheDisposition == "deny" ? .deny : .allow)
    }

    private struct Corpus: Decodable { let vectors: [Vector] }
    private struct Vector: Decodable {
        let id: String
        let compactJWS: String
        let expectedVerification: String
        let expectedReason: String
        let expectedCacheDisposition: String
        enum CodingKeys: String, CodingKey { case id; case compactJWS = "compact_jws"; case expectedVerification = "expected_verification"; case expectedReason = "expected_reason"; case expectedCacheDisposition = "expected_cache_disposition" }
    }
    private enum GoldenVectorError: Error { case malformed }

}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}

/// The host-owned boundary that a future, pinned Crosswake bridge must satisfy.
///
/// This package intentionally does not name or infer a Crosswake API. It records the
/// native client contract that the bridge must prove before runtime coupling is allowed.
public protocol AccrueOfflineClient: Sendable {
    func purchase(appAccountToken: UUID) async throws
    func restoreEntitlements() async throws
    func coalesceAuthenticatedReconciliation(trigger: ReconciliationTrigger) async
    func replaceCachedEntitlement(with replacement: VerifiedEntitlementReplacement) throws
}

public enum ReconciliationTrigger: String, Codable, Sendable {
    case foreground
    case backgroundRecovery
    case networkPathChanged
    case reconnect
}

/// Reachability and lifecycle events can request reconciliation but cannot grant access.
public enum VerifiedEntitlementReplacement: Sendable, Equatable {
    case verifiedServerAllow(revision: Int64)
    case signedServerDenial(revision: Int64)

    public var revision: Int64 {
        switch self {
        case let .verifiedServerAllow(revision), let .signedServerDenial(revision):
            revision
        }
    }
}

/// A narrow value object for the monotonic `iat`/revision/freshness gate.
public struct ProofHighWater: Sendable, Equatable {
    public let issuedAt: Date
    public let revision: Int64
    public let freshnessDeadline: Date

    public init(issuedAt: Date, revision: Int64, freshnessDeadline: Date) {
        self.issuedAt = issuedAt
        self.revision = revision
        self.freshnessDeadline = freshnessDeadline
    }

    public func accepts(newer candidate: ProofHighWater) -> Bool {
        candidate.revision > revision && candidate.issuedAt >= issuedAt && candidate.freshnessDeadline >= freshnessDeadline
    }
}

public enum Capability: String, CaseIterable, Codable, Sendable {
    case authenticatedHostTransport = "authenticated_host_transport"
    case storeKitPurchase = "storekit_purchase_app_account_token"
    case transactionUpdates = "transaction_updates"
    case currentEntitlements = "current_entitlements"
    case explicitRestore = "explicit_restore"
    case secureEnclaveKey = "secure_enclave_p256_registration_nonce_proof"
    case keychainThisDeviceOnly = "keychain_this_device_only"
    case durableLocalState = "durable_local_state"
    case proofHighWater = "iat_revision_freshness_high_water"
    case atomicVerifiedReplacement = "atomic_verified_allow_deny_replacement"
    case lifecycleRecovery = "foreground_background_recovery"
    case networkCoalescing = "network_path_reconciliation_coalescing"
    case reconnect = "reconnect_recovery"

    public static let allRequired = Capability.allCases

    public var requiredEvidenceKinds: Set<EvidenceKind> {
        switch self {
        case .authenticatedHostTransport:
            [.crosswakeBridgeCompileUnit, .physicalDevice]
        case .storeKitPurchase, .transactionUpdates, .currentEntitlements, .explicitRestore:
            [.crosswakeBridgeCompileUnit]
        case .secureEnclaveKey, .keychainThisDeviceOnly, .atomicVerifiedReplacement, .lifecycleRecovery:
            [.nativeCompileUnit, .physicalDevice]
        case .durableLocalState, .proofHighWater:
            [.nativeCompileUnit]
        case .networkCoalescing:
            [.crosswakeBridgeCompileUnit, .simulatorAdvisory]
        case .reconnect:
            [.crosswakeBridgeCompileUnit, .physicalDevice]
        }
    }
}

public enum FeasibilityStatus: String, Codable, Sendable {
    case proven
    case feasibilityBlocked = "feasibility_blocked"
}

public enum EvidenceKind: String, CaseIterable, Codable, Sendable {
    case nativeCompileUnit = "native_compile_unit"
    case crosswakeBridgeCompileUnit = "crosswake_bridge_compile_unit"
    case simulatorAdvisory = "simulator_advisory"
    case physicalDevice = "physical_device"
}

public struct CapabilityEvidence: Codable, Sendable, Equatable {
    public let capability: Capability
    public var status: FeasibilityStatus
    public let evidenceKinds: Set<EvidenceKind>
    public let location: String

    public init(capability: Capability, status: FeasibilityStatus, evidenceKinds: Set<EvidenceKind>, location: String) {
        self.capability = capability
        self.status = status
        self.evidenceKinds = evidenceKinds
        self.location = location
    }
}

public struct CapabilityReport: Codable, Sendable, Equatable {
    public let schemaVersion: String
    public let capabilities: [CapabilityEvidence]
    public let overallStatus: FeasibilityStatus

    public init(schemaVersion: String, capabilities: [CapabilityEvidence]) {
        self.schemaVersion = schemaVersion
        self.capabilities = capabilities.sorted { lhs, rhs in
            Capability.allRequired.firstIndex(of: lhs.capability)! < Capability.allRequired.firstIndex(of: rhs.capability)!
        }
        overallStatus = Self.reduce(capabilities: self.capabilities)
    }

    private static func reduce(capabilities: [CapabilityEvidence]) -> FeasibilityStatus {
        let provided = Set(capabilities.map(\.capability))
        guard provided == Set(Capability.allRequired),
              capabilities.count == Capability.allRequired.count,
              capabilities.allSatisfy({
                  $0.status == .proven && $0.evidenceKinds.isSuperset(of: $0.capability.requiredEvidenceKinds)
              })
        else {
            return .feasibilityBlocked
        }

        return .proven
    }
}
