import Foundation

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
}

public enum FeasibilityStatus: String, Codable, Sendable {
    case proven
    case feasibilityBlocked = "feasibility_blocked"
}

public enum EvidenceKind: String, Codable, Sendable {
    case nativeCompileUnit = "native_compile_unit"
    case crosswakeBridgeCompileUnit = "crosswake_bridge_compile_unit"
    case simulatorAdvisory = "simulator_advisory"
    case physicalDevice = "physical_device"
}

public struct CapabilityEvidence: Codable, Sendable, Equatable {
    public let capability: Capability
    public var status: FeasibilityStatus
    public let kind: EvidenceKind
    public let location: String

    public init(capability: Capability, status: FeasibilityStatus, kind: EvidenceKind, location: String) {
        self.capability = capability
        self.status = status
        self.kind = kind
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
              capabilities.allSatisfy({ $0.status == .proven })
        else {
            return .feasibilityBlocked
        }

        return .proven
    }
}
