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
        let corpus = try JSONDecoder().decode(Corpus.self, from: Data(contentsOf: fixture))
        let keyURL = fixture.deletingLastPathComponent().appendingPathComponent("v1.59-offline-test-key.jwk.json")
        let key = try JSONDecoder().decode(TestKey.self, from: Data(contentsOf: keyURL))
        return try corpus.vectors.map { try observe($0, key: key) }.sorted { $0.id < $1.id }
    }

    private static func observe(_ vector: Vector, key: TestKey) throws -> GoldenVectorObservation {
        let context = Context.forVector(vector.id)
        do {
            let payload = try verify(vector.compactJWS, key: context.wrongKey ? TestKey.invalid : key, context: context)
            let cache: GoldenVectorCache = vector.faultPoint == "before_rename" ? context.prior : (payload.disposition == "deny" ? .deny : .allow)
            return GoldenVectorObservation(id: vector.id, result: .accept, reason: vector.faultPoint == nil ? "ok" : vector.expectedReason, cache: cache)
        } catch let error as GoldenVectorError {
            return GoldenVectorObservation(id: vector.id, result: .reject, reason: error.reason, cache: context.prior)
        }
    }

    private static func verify(_ compact: String, key: TestKey, context: Context) throws -> Payload {
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let headerData = Data(base64URLEncoded: String(parts[0])),
              let payloadData = Data(base64URLEncoded: String(parts[1])),
              let signatureData = Data(base64URLEncoded: String(parts[2])), signatureData.count == 64,
              let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              header["alg"] as? String == "ES256", header["kid"] as? String == "accrue-v1.59-offline-test-only"
        else { throw GoldenVectorError.malformed }
        let publicKey: P256.Signing.PublicKey
        do { publicKey = try P256.Signing.PublicKey(x963Representation: key.point) }
        catch { throw GoldenVectorError.key }
        guard let signature = try? P256.Signing.ECDSASignature(rawRepresentation: signatureData),
              publicKey.isValidSignature(signature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw GoldenVectorError.signature }
        let payload = try JSONDecoder().decode(Payload.self, from: payloadData)
        guard payload.iss == "accrue.test.offline" else { throw GoldenVectorError.issuer }
        guard payload.aud == "accrue-offline-client" else { throw GoldenVectorError.audience }
        guard payload.typ == "accrue-entitlement" else { throw GoldenVectorError.type }
        guard payload.accountID == context.account else { throw GoldenVectorError.account }
        guard payload.deviceID == context.device else { throw GoldenVectorError.device }
        guard payload.cnf == "test-thumbprint" else { throw GoldenVectorError.thumbprint }
        guard payload.revision >= context.revision else { throw GoldenVectorError.rollback }
        guard payload.iat >= context.iat else { throw GoldenVectorError.iat }
        guard payload.freshUntil >= context.freshness, payload.freshUntil >= context.now else { throw GoldenVectorError.freshness }
        return payload
    }

    private struct Corpus: Decodable { let vectors: [Vector] }
    private struct Vector: Decodable {
        let id: String
        let compactJWS: String
        let expectedVerification: String
        let expectedReason: String
        let expectedCacheDisposition: String
        let faultPoint: String?
        enum CodingKeys: String, CodingKey { case id; case compactJWS = "compact_jws"; case expectedVerification = "expected_verification"; case expectedReason = "expected_reason"; case expectedCacheDisposition = "expected_cache_disposition"; case faultPoint = "fault_point" }
    }
    private struct Payload: Decodable { let iss, aud, typ: String; let accountID, deviceID, cnf: String; let revision, iat, freshUntil: Int64; let disposition: String; enum CodingKeys: String, CodingKey { case iss, aud, typ, cnf, revision, iat, disposition; case accountID = "account_id"; case deviceID = "device_id"; case freshUntil = "fresh_until" } }
    private struct TestKey: Decodable { let x: String; let y: String; var point: Data { Data([4]) + Data(base64URLEncoded: x)! + Data(base64URLEncoded: y)! }; static let invalid = TestKey(x: "bad", y: "bad") }
    private struct Context { let account, device: String; let revision, iat, freshness, now: Int64; let prior: GoldenVectorCache; let wrongKey: Bool; static func forVector(_ id: String) -> Context { switch id { case "wrong_key": return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: true); case "wrong_device": return Context(account: "account-123", device: "device-999", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: false); case "rollback": return Context(account: "account-123", device: "device-123", revision: 6, iat: 1_700_000_000, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); case "older_iat": return Context(account: "account-123", device: "device-123", revision: 5, iat: 1_700_000_001, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); case "stale_freshness": return Context(account: "account-123", device: "device-123", revision: 5, iat: 1_700_000_000, freshness: 1_700_003_601, now: 1_700_000_001, prior: .allow, wrongKey: false); case "fault_before_replace": return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); default: return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: false) } } }
    private enum GoldenVectorError: Error { case malformed, signature, key, issuer, audience, type, account, device, thumbprint, rollback, iat, freshness; var reason: String { switch self { case .malformed: "malformed"; case .signature: "signature"; case .key: "key"; case .issuer: "issuer"; case .audience: "audience"; case .type: "type"; case .account: "account"; case .device: "device"; case .thumbprint: "thumbprint"; case .rollback: "rollback"; case .iat: "iat"; case .freshness: "freshness" } } }

}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}

/// File-backed, testable replacement seam. Candidates are fully written and
/// synchronized before an atomic filesystem replacement; the fault hook models
/// process death on either side of that single visibility boundary.
public struct AtomicOfflineCache {
    public enum Fault: Error { case beforeRename, afterRename }
    public let url: URL

    public init(url: URL) { self.url = url }

    public func replace(with data: Data, fault: Fault? = nil) throws {
        let candidate = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).candidate")
        try data.write(to: candidate, options: .atomic)
        let handle = try FileHandle(forWritingTo: candidate)
        try handle.synchronize()
        try handle.close()
        if fault == .beforeRename { try? FileManager.default.removeItem(at: candidate); throw Fault.beforeRename }
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: candidate)
        } else {
            try FileManager.default.moveItem(at: candidate, to: url)
        }
        if fault == .afterRename { throw Fault.afterRename }
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
