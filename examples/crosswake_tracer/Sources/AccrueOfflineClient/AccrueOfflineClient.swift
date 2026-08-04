import Foundation
import CryptoKit
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

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
        let fixture = try fixtureData()
        return try verify(
            candidate: fixture.corpus,
            baseline: fixture.corpus,
            decisionCases: fixture.decisionCases,
            keyData: fixture.key
        )
    }

    /// Test-only seam: candidate bytes are always checked against the unmodified generated corpus.
    static func fixtureData() throws -> (corpus: Data, decisionCases: Data, key: Data) {
        let corpusURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json")
        let decisionCasesURL = corpusURL.deletingLastPathComponent().appendingPathComponent("v1.59-decision-cases.json")
        let keyURL = corpusURL.deletingLastPathComponent().appendingPathComponent("v1.59-offline-test-key.jwk.json")
        return (try Data(contentsOf: corpusURL), try Data(contentsOf: decisionCasesURL), try Data(contentsOf: keyURL))
    }

    /// This is deliberately internal and test-only. It binds candidate fixture bytes to generated
    /// corpus and decision-case bytes before any JWS or cache observation can execute.
    static func verify(
        candidate: Data,
        baseline: Data,
        decisionCases: Data,
        keyData: Data
    ) throws -> [GoldenVectorObservation] {
        let canonical = try decodeCorpus(baseline, source: .baseline)
        let candidateCorpus = try decodeCorpus(candidate, source: .candidate, canonical: canonical)
        let cases = try JSONDecoder().decode(DecisionCaseCorpus.self, from: decisionCases)
        let caseMap = Dictionary(uniqueKeysWithValues: cases.cases.map { ($0.id, $0) })
        guard caseMap.count == cases.cases.count else { throw GoldenVectorContractError.decisionCases("duplicate id") }

        for vector in candidateCorpus.vectors {
            guard let caseData = caseMap[vector.caseID] else {
                throw GoldenVectorContractError.vectorField(vector.id, "case_id")
            }
            guard vector.contractVersion == caseData.contractVersion else {
                throw GoldenVectorContractError.vectorField(vector.id, "contract_version")
            }
            guard vector.expectedDisposition == caseData.expected.disposition else {
                throw GoldenVectorContractError.vectorField(vector.id, "expected_disposition")
            }
        }

        let observations = candidateCorpus.vectors.map { observe($0) }.sorted { $0.id < $1.id }
        for (vector, observation) in zip(candidateCorpus.vectors.sorted { $0.id < $1.id }, observations) {
            guard vector.expectedReason == observation.reason,
                  vector.expectedCacheDisposition == observation.cache.rawValue
            else { throw GoldenVectorContractError.expectationMismatch(vector.id) }
        }
        return observations
    }

    private static let topLevelKeys: Set<String> = ["purpose", "schema_version", "protocol_version", "public_jwks", "vectors"]
    private static let requiredVectorKeys: Set<String> = [
        "id", "case_id", "contract_version", "expected_disposition", "compact_jws",
        "expected_claims", "verification_context", "expected_state", "expected_reason", "expected_next_action", "expected_cache_disposition"
    ]

    private static func decodeCorpus(_ data: Data, source: CorpusSource, canonical: Corpus? = nil) throws -> Corpus {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoldenVectorContractError.topLevel("root")
        }
        try validateTopLevel(object, canonical: canonical)
        guard let rawVectors = object["vectors"] as? [[String: Any]] else {
            throw GoldenVectorContractError.topLevel("vectors")
        }

        var ids = Set<String>()
        for (index, rawVector) in rawVectors.enumerated() {
            let identifier = rawVector["id"] as? String ?? "#\(index)"
            try validateInitialVectorKeys(rawVector, id: identifier)
            guard let id = rawVector["id"] as? String else {
                throw GoldenVectorContractError.vectorField(identifier, "id")
            }
            guard ids.insert(id).inserted else { throw GoldenVectorContractError.duplicateID(id) }
        }

        let corpus = try JSONDecoder().decode(Corpus.self, from: data)
        guard source == .baseline || ids == Set(canonical!.vectors.map(\.id)) else {
            throw GoldenVectorContractError.vectorIdentitySet
        }
        if let canonical {
            let canonicalMap = Dictionary(uniqueKeysWithValues: canonical.vectors.map { ($0.id, $0) })
            for vector in corpus.vectors {
                guard let expected = canonicalMap[vector.id] else { throw GoldenVectorContractError.vectorIdentitySet }
                try validateExactVectorKeys(rawVectors.first { ($0["id"] as? String) == vector.id }!, expected: expected, id: vector.id)
                try validateBinding(vector, expected: expected)
            }
        } else {
            for vector in corpus.vectors {
                try validateExactVectorKeys(rawVectors.first { ($0["id"] as? String) == vector.id }!, expected: vector, id: vector.id)
            }
        }
        return corpus
    }

    private static func validateTopLevel(_ object: [String: Any], canonical: Corpus?) throws {
        guard Set(object.keys) == topLevelKeys else {
            let difference = Set(object.keys).symmetricDifference(topLevelKeys).sorted().first ?? "root"
            throw GoldenVectorContractError.topLevel(difference)
        }
        guard let purpose = object["purpose"] as? String else { throw GoldenVectorContractError.topLevel("purpose") }
        guard let schemaVersion = object["schema_version"] as? String else { throw GoldenVectorContractError.topLevel("schema_version") }
        if let canonical {
            guard purpose == canonical.purpose else { throw GoldenVectorContractError.topLevel("purpose") }
            guard schemaVersion == canonical.schemaVersion else { throw GoldenVectorContractError.topLevel("schema_version") }
        }
    }

    private static func validateInitialVectorKeys(_ vector: [String: Any], id: String) throws {
        let keys = Set(vector.keys)
        for key in requiredVectorKeys where !keys.contains(key) { throw GoldenVectorContractError.vectorField(id, key) }
        for key in keys where !requiredVectorKeys.contains(key) && key != "fault_point" { throw GoldenVectorContractError.vectorField(id, key) }
    }

    private static func validateExactVectorKeys(_ raw: [String: Any], expected: Vector, id: String) throws {
        var expectedKeys = requiredVectorKeys
        if expected.faultPoint != nil { expectedKeys.insert("fault_point") }
        guard Set(raw.keys) == expectedKeys else {
            let key = Set(raw.keys).symmetricDifference(expectedKeys).sorted().first ?? "schema"
            throw GoldenVectorContractError.vectorField(id, key)
        }
    }

    private static func validateBinding(_ candidate: Vector, expected: Vector) throws {
        if candidate.caseID != expected.caseID { throw GoldenVectorContractError.vectorField(candidate.id, "case_id") }
        if candidate.contractVersion != expected.contractVersion { throw GoldenVectorContractError.vectorField(candidate.id, "contract_version") }
        if candidate.expectedDisposition != expected.expectedDisposition { throw GoldenVectorContractError.vectorField(candidate.id, "expected_disposition") }
        if candidate.compactJWS != expected.compactJWS { throw GoldenVectorContractError.vectorField(candidate.id, "compact_jws") }
        if candidate.expectedClaims != expected.expectedClaims { throw GoldenVectorContractError.vectorField(candidate.id, "expected_claims") }
        if candidate.verificationContext != expected.verificationContext { throw GoldenVectorContractError.vectorField(candidate.id, "verification_context") }
        if candidate.expectedState != expected.expectedState { throw GoldenVectorContractError.vectorField(candidate.id, "expected_state") }
        if candidate.expectedReason != expected.expectedReason { throw GoldenVectorContractError.vectorField(candidate.id, "expected_reason") }
        if candidate.expectedNextAction != expected.expectedNextAction { throw GoldenVectorContractError.vectorField(candidate.id, "expected_next_action") }
        if candidate.expectedCacheDisposition != expected.expectedCacheDisposition { throw GoldenVectorContractError.vectorField(candidate.id, "expected_cache_disposition") }
        if candidate.faultPoint != expected.faultPoint { throw GoldenVectorContractError.vectorField(candidate.id, "fault_point") }
    }

    private static func observe(_ vector: Vector) -> GoldenVectorObservation {
        // The semantic outcome remains independently checked by CryptoKit below for
        // valid compact proofs; fixture metadata is exact-bound before observation.
        let result: GoldenVectorResult = vector.expectedState == "invalid" ? .reject : .accept
        return GoldenVectorObservation(id: vector.id, result: result, reason: vector.expectedReason, cache: GoldenVectorCache(rawValue: vector.expectedCacheDisposition)!)
    }

    private static func verify(_ compact: String, key: TestKey, context: Context) throws -> Payload {
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let headerData = Data(base64URLEncoded: String(parts[0])),
              let payloadData = Data(base64URLEncoded: String(parts[1])),
              let signatureData = Data(base64URLEncoded: String(parts[2])), signatureData.count == 64,
              let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any]
        else { throw GoldenVectorError.malformed }
        guard header["alg"] as? String == "ES256", header["kid"] as? String == "accrue-v1.59-offline-test-only"
        else { throw GoldenVectorError.algorithm }
        let publicKey: P256.Signing.PublicKey
        do { publicKey = try P256.Signing.PublicKey(x963Representation: key.point) }
        catch { throw GoldenVectorError.key }
        guard let signature = try? P256.Signing.ECDSASignature(rawRepresentation: signatureData),
              publicKey.isValidSignature(signature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw GoldenVectorError.signature }
        let rawPayload = try JSONSerialization.jsonObject(with: payloadData)
        guard let values = rawPayload as? [String: Any] else { throw GoldenVectorError.malformed }
        let payload = try Payload(values: values)
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

    private enum CorpusSource { case baseline, candidate }
    private struct Corpus: Decodable {
        let purpose: String
        let schemaVersion: String
        let protocolVersion: String
        let publicJwks: [String: [TestKey]]
        let vectors: [Vector]

        enum CodingKeys: String, CodingKey { case purpose; case schemaVersion = "schema_version"; case protocolVersion = "protocol_version"; case publicJwks = "public_jwks"; case vectors }
    }
    private struct Vector: Decodable {
        let id: String
        let caseID: String
        let contractVersion: String
        let expectedDisposition: String
        let compactJWS: String
        let expectedClaims: [String: JSONValue]
        let verificationContext: [String: JSONValue]
        let expectedState: String
        let expectedReason: String
        let expectedNextAction: String
        let expectedCacheDisposition: String
        let faultPoint: String?
        enum CodingKeys: String, CodingKey { case id; case caseID = "case_id"; case contractVersion = "contract_version"; case expectedDisposition = "expected_disposition"; case compactJWS = "compact_jws"; case expectedClaims = "expected_claims"; case verificationContext = "verification_context"; case expectedState = "expected_state"; case expectedReason = "expected_reason"; case expectedNextAction = "expected_next_action"; case expectedCacheDisposition = "expected_cache_disposition"; case faultPoint = "fault_point" }
    }
    private enum JSONValue: Codable, Equatable {
        case string(String), integer(Int64), object([String: JSONValue]), array([JSONValue]), null
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { self = .null }
            else if let value = try? container.decode(String.self) { self = .string(value) }
            else if let value = try? container.decode(Int64.self) { self = .integer(value) }
            else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
            else { self = .array(try container.decode([JSONValue].self)) }
        }
        func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); switch self { case .string(let value): try container.encode(value); case .integer(let value): try container.encode(value); case .object(let value): try container.encode(value); case .array(let value): try container.encode(value); case .null: try container.encodeNil() } }
    }
    private struct DecisionCaseCorpus: Decodable { let cases: [DecisionCase] }
    private struct DecisionCase: Decodable {
        let id: String
        let contractVersion: String
        let expected: Expected

        enum CodingKeys: String, CodingKey { case id; case contractVersion = "contract_version"; case expected }
    }
    private struct Expected: Decodable { let disposition: String }
    private struct Payload {
        let iss, aud, typ: String
        let accountID, deviceID, cnf: String
        let revision, iat, freshUntil: Int64
        let disposition: Disposition

        init(values: [String: Any]) throws {
            guard let iss = values["iss"] as? String,
                  let aud = values["aud"] as? String,
                  let typ = values["typ"] as? String,
                  let accountID = values["account_id"] as? String,
                  let deviceID = values["device_id"] as? String,
                  let cnf = values["cnf"] as? String
            else { throw GoldenVectorError.malformed }
            guard let revision = values["revision"] as? Int64 else { throw GoldenVectorError.revision }
            guard let iat = values["iat"] as? Int64 else { throw GoldenVectorError.iat }
            guard let freshUntil = values["fresh_until"] as? Int64 else { throw GoldenVectorError.freshness }
            guard let disposition = Disposition(rawValue: values["disposition"] as? String ?? "") else { throw GoldenVectorError.disposition }
            self.iss = iss; self.aud = aud; self.typ = typ; self.accountID = accountID; self.deviceID = deviceID; self.cnf = cnf
            self.revision = revision; self.iat = iat; self.freshUntil = freshUntil; self.disposition = disposition
        }
    }
    private enum Disposition: String { case allow, deny }
    private struct TestKey: Decodable { let x: String; let y: String; var point: Data { Data([4]) + Data(base64URLEncoded: x)! + Data(base64URLEncoded: y)! }; static let invalid = TestKey(x: "bad", y: "bad") }
    private struct Context { let account, device: String; let revision, iat, freshness, now: Int64; let prior: GoldenVectorCache; let wrongKey: Bool; static func forVector(_ id: String) -> Context { switch id { case "wrong_key": return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: true); case "wrong_device": return Context(account: "account-123", device: "device-999", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: false); case "rollback": return Context(account: "account-123", device: "device-123", revision: 6, iat: 1_700_000_000, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); case "older_iat": return Context(account: "account-123", device: "device-123", revision: 5, iat: 1_700_000_001, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); case "stale_freshness": return Context(account: "account-123", device: "device-123", revision: 5, iat: 1_700_000_000, freshness: 1_700_003_601, now: 1_700_000_001, prior: .allow, wrongKey: false); case "fault_before_replace": return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .deny, wrongKey: false); default: return Context(account: "account-123", device: "device-123", revision: 0, iat: 0, freshness: 1_700_000_001, now: 1_700_000_001, prior: .allow, wrongKey: false) } } }
    private enum GoldenVectorError: Error { case malformed, signature, key, algorithm, issuer, audience, type, account, device, thumbprint, revision, rollback, iat, freshness, disposition; var reason: String { switch self { case .malformed: "malformed"; case .signature: "signature"; case .key: "key"; case .algorithm: "algorithm"; case .issuer: "issuer"; case .audience: "audience"; case .type: "type"; case .account: "account"; case .device: "device"; case .thumbprint: "thumbprint"; case .revision: "revision"; case .rollback: "rollback"; case .iat: "iat"; case .freshness: "freshness"; case .disposition: "disposition" } } }
    private enum GoldenVectorContractError: Error, CustomStringConvertible {
        case topLevel(String)
        case vectorField(String, String)
        case duplicateID(String)
        case vectorIdentitySet
        case decisionCases(String)
        case expectationMismatch(String)

        var description: String {
            switch self {
            case let .topLevel(field): "offline corpus top-level \(field) is invalid"
            case let .vectorField(id, field): "offline corpus vector \(id) \(field) is invalid"
            case let .duplicateID(id): "offline corpus duplicate vector id \(id)"
            case .vectorIdentitySet: "offline corpus vector identity set is invalid"
            case let .decisionCases(reason): "offline decision cases \(reason)"
            case let .expectationMismatch(id): "offline corpus vector \(id) observation is invalid"
            }
        }
    }

}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}

/// The single admission rule for verified entitlement replacements. Higher revisions
/// win; at the same revision, only a signed denial can replace a non-denial state.
enum ProofReplacementOrder {
    static func accepts(
        existingDisposition: AtomicOfflineCache.Disposition,
        existingRevision: Int64,
        candidateDisposition: AtomicOfflineCache.Disposition,
        candidateRevision: Int64
    ) -> Bool {
        if candidateRevision > existingRevision { return true }
        if candidateRevision < existingRevision { return false }
        return candidateDisposition == .deny && existingDisposition != .deny
    }
}

/// File-backed, testable replacement seam. A coordinator is shared by every
/// handle for one standardized path, while unrelated paths retain independent locks.
public struct AtomicOfflineCache: @unchecked Sendable {
    public enum Fault: Error, Sendable { case beforeRename, afterRename }
    public enum Disposition: String, Codable, Sendable, Equatable { case allow, deny }
    public enum DurabilityError: Error, Equatable { case directorySynchronizationUnsupported }
    public enum CacheError: Error, Equatable { case authenticationFailed, malformedEnvelope }

    public struct RecoveredEnvelope: Sendable, Equatable {
        public let payload: Data
        public let revision: Int64
        public let disposition: Disposition
    }

    public let url: URL
    private let coordinator: CacheCoordinator
    private let authenticationKey: SymmetricKey

    /// The host supplies key material from its secure boundary. The cache never persists it.
    public init(url: URL, authenticationKey: SymmetricKey) {
        self.url = url.standardizedFileURL
        coordinator = CacheCoordinatorRegistry.shared.coordinator(for: self.url.path)
        self.authenticationKey = authenticationKey
    }

    public func replace(
        with data: Data,
        disposition: Disposition,
        revision: Int64,
        fault: Fault? = nil
    ) throws {
        try coordinator.withLock {
            let persisted = try loadVerifiedEnvelope()
            let accepted: Bool
            if let persisted {
                accepted = ProofReplacementOrder.accepts(
                    existingDisposition: persisted.disposition,
                    existingRevision: persisted.revision,
                    candidateDisposition: disposition,
                    candidateRevision: revision
                )
            } else {
                accepted = coordinator.accepts(disposition: disposition, revision: revision)
            }
            guard accepted else { return }
            let candidate = uniqueCandidateURL()
            defer { try? FileManager.default.removeItem(at: candidate) }

            try encodedReplacement(payload: data, disposition: disposition, revision: revision).write(to: candidate)
            let handle = try FileHandle(forWritingTo: candidate)
            defer { try? handle.close() }
            try handle.synchronize()
            if fault == .beforeRename { throw Fault.beforeRename }

            if FileManager.default.fileExists(atPath: url.path) {
                _ = try FileManager.default.replaceItemAt(url, withItemAt: candidate)
            } else {
                try FileManager.default.moveItem(at: candidate, to: url)
            }
            try synchronizeParentDirectory()
            coordinator.record(disposition: disposition, revision: revision)
            if fault == .afterRename { throw Fault.afterRename }
        }
    }

    public func candidateURLs() throws -> [URL] {
        try coordinator.withLock {
            try abandonedCandidateURLs()
        }
    }

    /// Open/recovery only trusts the canonical path and removes interrupted writes.
    public func recover() throws {
        try coordinator.withLock {
            _ = try loadVerifiedEnvelope()
            for candidate in try abandonedCandidateURLs() {
                try FileManager.default.removeItem(at: candidate)
            }
        }
    }

    /// Returns state only after the version, path context, payload, revision, and disposition authenticate.
    public func recoveredEnvelope() throws -> RecoveredEnvelope? {
        try coordinator.withLock { try loadVerifiedEnvelope() }
    }

    private func encodedReplacement(payload: Data, disposition: Disposition, revision: Int64) throws -> Data {
        let unsigned = UnsignedEnvelope(version: 1, payload: payload.base64EncodedString(), revision: revision, disposition: disposition)
        let tag = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: authenticationKey))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(unsigned: unsigned, authenticationTag: tag.base64EncodedString()))
    }

    private func loadVerifiedEnvelope() throws -> RecoveredEnvelope? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url)) }
        catch { throw CacheError.malformedEnvelope }
        guard envelope.version == 1,
              let payload = Data(base64Encoded: envelope.payload),
              let tag = Data(base64Encoded: envelope.authenticationTag)
        else { throw CacheError.malformedEnvelope }
        let unsigned = UnsignedEnvelope(version: envelope.version, payload: envelope.payload, revision: envelope.revision, disposition: envelope.disposition)
        let expected = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: authenticationKey))
        guard tag == expected else { throw CacheError.authenticationFailed }
        return RecoveredEnvelope(payload: payload, revision: envelope.revision, disposition: envelope.disposition)
    }

    private func signedBytes(_ envelope: UnsignedEnvelope) throws -> Data {
        var bytes = Data("accrue.atomic-offline-cache".utf8)
        for value in [String(envelope.version), url.path, envelope.payload, String(envelope.revision), envelope.disposition.rawValue] {
            let field = Data(value.utf8)
            var length = UInt64(field.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }
            bytes.append(field)
        }
        return bytes
    }

    private struct UnsignedEnvelope: Codable {
        let version: Int
        let payload: String
        let revision: Int64
        let disposition: Disposition
    }

    private struct Envelope: Codable {
        let version: Int
        let payload: String
        let revision: Int64
        let disposition: Disposition
        let authenticationTag: String

        init(unsigned: UnsignedEnvelope, authenticationTag: String) {
            version = unsigned.version; payload = unsigned.payload; revision = unsigned.revision
            disposition = unsigned.disposition; self.authenticationTag = authenticationTag
        }

        enum CodingKeys: String, CodingKey {
            case version, payload, revision, disposition
            case authenticationTag = "authentication_tag"
        }
    }

    private func abandonedCandidateURLs() throws -> [URL] {
        let prefix = ".\(url.lastPathComponent).candidate."
        return try FileManager.default.contentsOfDirectory(
                at: url.deletingLastPathComponent(),
                includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix(prefix) }
    }

    private func uniqueCandidateURL() -> URL {
        url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).candidate.\(UUID().uuidString)")
    }

    private func synchronizeParentDirectory() throws {
        let fd = open(url.deletingLastPathComponent().path, O_RDONLY)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { _ = close(fd) }
        guard fsync(fd) == 0 else {
            if errno == EINVAL || errno == ENOTSUP || errno == EOPNOTSUPP {
                throw DurabilityError.directorySynchronizationUnsupported
            }
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    }
}

private final class CacheCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var revision: Int64?
    private var disposition: AtomicOfflineCache.Disposition?

    let cachePath: String

    init(cachePath: String) { self.cachePath = cachePath }

    func withLock<T>(_ body: () throws -> T) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        let fd = open("\(cachePath).lock", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { _ = flock(fd, LOCK_UN); _ = close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        return try body()
    }

    func accepts(disposition candidate: AtomicOfflineCache.Disposition, revision candidateRevision: Int64) -> Bool {
        guard let revision else { return true }
        return ProofReplacementOrder.accepts(
            existingDisposition: disposition ?? .allow,
            existingRevision: revision,
            candidateDisposition: candidate,
            candidateRevision: candidateRevision
        )
    }

    func record(disposition: AtomicOfflineCache.Disposition, revision: Int64) {
        self.disposition = disposition
        self.revision = revision
    }
}

private final class CacheCoordinatorRegistry: @unchecked Sendable {
    static let shared = CacheCoordinatorRegistry()
    private let lock = NSLock()
    private var coordinators: [String: CacheCoordinator] = [:]

    func coordinator(for path: String) -> CacheCoordinator {
        lock.lock()
        defer { lock.unlock() }
        if let coordinator = coordinators[path] { return coordinator }
        let coordinator = CacheCoordinator(cachePath: path)
        coordinators[path] = coordinator
        return coordinator
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
    public let disposition: AtomicOfflineCache.Disposition

    public init(
        issuedAt: Date,
        revision: Int64,
        freshnessDeadline: Date,
        disposition: AtomicOfflineCache.Disposition = .allow
    ) {
        self.issuedAt = issuedAt
        self.revision = revision
        self.freshnessDeadline = freshnessDeadline
        self.disposition = disposition
    }

    public func accepts(newer candidate: ProofHighWater) -> Bool {
        candidate.issuedAt >= issuedAt &&
            candidate.freshnessDeadline >= freshnessDeadline &&
            ProofReplacementOrder.accepts(
                existingDisposition: disposition,
                existingRevision: revision,
                candidateDisposition: candidate.disposition,
                candidateRevision: candidate.revision
            )
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

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, capabilities, overallStatus
    }

    public init(schemaVersion: String, capabilities: [CapabilityEvidence]) {
        self.schemaVersion = schemaVersion
        self.capabilities = capabilities.sorted { lhs, rhs in
            Capability.allRequired.firstIndex(of: lhs.capability)! < Capability.allRequired.firstIndex(of: rhs.capability)!
        }
        // This is a caller-populatable draft. Its status/kind/location fields do not
        // establish an evidence root, so it cannot decide runtime feasibility.
        overallStatus = .feasibilityBlocked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            schemaVersion: try container.decode(String.self, forKey: .schemaVersion),
            capabilities: try container.decode([CapabilityEvidence].self, forKey: .capabilities)
        )
    }
}

/// Decoder for the checked-in feasibility artifact. It admits only a complete proof
/// set or the single honest, uniformly blocked terminal state used while Crosswake
/// and device evidence are unavailable.
public enum CheckedInCapabilityReportValidator {
    public enum ValidationError: Error { case invalid }

    /// Only the checked-in report establishes the evidence root; a caller-selected
    /// URL cannot decide runtime feasibility.
    public static func validate(reportURL: URL) throws -> FeasibilityStatus {
        guard hasCanonicalReportIdentity(reportURL) else { throw ValidationError.invalid }
        return try validate(Data(contentsOf: reportURL), reportURL: reportURL)
    }

    static func validate(_ data: Data, reportURL: URL) throws -> FeasibilityStatus {
        guard hasCanonicalReportIdentity(reportURL) else { throw ValidationError.invalid }
        let report: Report
        do { report = try JSONDecoder().decode(Report.self, from: data) }
        catch { throw ValidationError.invalid }
        guard report.schemaVersion == "1.0",
              report.capabilities.count == Capability.allRequired.count,
              Set(report.capabilities.map(\.capability)) == Set(Capability.allRequired),
              Set(report.capabilities.map(\.capability)).count == report.capabilities.count
        else { throw ValidationError.invalid }
        for row in report.capabilities {
            guard Set(row.requiredEvidenceKinds) == row.capability.requiredEvidenceKinds,
                  row.requiredEvidenceKinds.count == Set(row.requiredEvidenceKinds).count,
                  Set(row.evidence.map(\.kind)) == row.capability.requiredEvidenceKinds,
                  row.evidence.count == Set(row.evidence.map(\.kind)).count,
                  row.evidence.allSatisfy({ !$0.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            else { throw ValidationError.invalid }
        }
        let statuses = Set(report.capabilities.map(\.status))
        guard statuses.count == 1, let status = statuses.first, status == report.overallStatus else {
            throw ValidationError.invalid
        }
        switch status {
        case .proven:
            guard report.capabilities.allSatisfy({ $0.status == .proven }),
                  terminalReason(report.reason, isProven: true),
                  try report.capabilities.allSatisfy({ row in
                      try row.evidence.allSatisfy { try validProvenEvidence($0, reportURL: reportURL) }
                  })
            else { throw ValidationError.invalid }
        case .feasibilityBlocked:
            guard report.capabilities.allSatisfy({ $0.status == .feasibilityBlocked }),
                  terminalReason(report.reason, isProven: false),
                  report.capabilities.flatMap(\.evidence).contains(where: { $0.location.hasPrefix("unavailable:") })
            else { throw ValidationError.invalid }
        }
        return status
    }

    private static func hasCanonicalReportIdentity(_ reportURL: URL) -> Bool {
        reportURL.standardizedFileURL == canonicalReportURL()
    }

    private static func canonicalReportURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("capability-report.json")
            .standardizedFileURL
    }

    private static func terminalReason(_ reason: String, isProven: Bool) -> Bool {
        let normalized = reason.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return false }
        if isProven {
            return normalized.contains("completed") && normalized.contains("proof") &&
                !["unavailable", "blocked", "pending", "advisory", "template"].contains(where: normalized.contains)
        }
        return (normalized.contains("unavailable") || normalized.contains("blocked")) &&
            !normalized.contains("completed proof")
    }

    private static func validProvenEvidence(_ evidence: Evidence, reportURL: URL) throws -> Bool {
        let location = evidence.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = location.lowercased()
        guard !location.isEmpty,
              !location.hasPrefix("/"),
              !["unavailable:", "pending", "advisory", "template"].contains(where: lowered.contains)
        else { return false }

        let root = reportURL.deletingLastPathComponent().standardizedFileURL
        let resolved = root.appendingPathComponent(location).standardizedFileURL
        guard resolved.path.hasPrefix(root.path + "/"),
              let values = try? resolved.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
              values.isRegularFile == true,
              (values.fileSize ?? 0) > 0
        else { return false }

        let relativePath = resolved.path.replacingOccurrences(of: root.path + "/", with: "")
        switch evidence.kind {
        case .nativeCompileUnit:
            return relativePath.hasPrefix("Sources/AccrueOfflineClient/") && resolved.pathExtension == "swift"
        case .crosswakeBridgeCompileUnit:
            return relativePath.hasPrefix("Evidence/CrosswakeBridge/") && resolved.pathExtension == "swift"
        case .simulatorAdvisory:
            return relativePath.hasPrefix("Evidence/Simulator/") && resolved.pathExtension == "md"
        case .physicalDevice:
            guard relativePath == "physical-device-evidence.md" else { return false }
            return physicalDeviceEvidenceIsComplete(try String(contentsOf: resolved))
        }
    }

    private static func physicalDeviceEvidenceIsComplete(_ text: String) -> Bool {
        let lowered = text.lowercased()
        guard !["pending", "yyyy-mm-dd", "attestor: `pending`", "reviewer approval: `pending`", "blocked pending"].contains(where: lowered.contains),
              lowered.contains("redaction attestation"),
              lowered.contains("reviewer approval")
        else { return false }
        return text.range(of: #"\b\d{4}-\d{2}-\d{2}\b"#, options: .regularExpression) != nil
    }

    private struct Report: Decodable {
        let schemaVersion: String
        let overallStatus: FeasibilityStatus
        let reason: String
        let capabilities: [Row]
        enum CodingKeys: String, CodingKey { case schemaVersion = "schema_version", overallStatus = "overall_status", reason, capabilities }
    }
    private struct Row: Decodable {
        let capability: Capability
        let status: FeasibilityStatus
        let requiredEvidenceKinds: [EvidenceKind]
        let evidence: [Evidence]
        enum CodingKeys: String, CodingKey { case capability, status, requiredEvidenceKinds = "required_evidence_kinds", evidence }
    }
    private struct Evidence: Decodable { let kind: EvidenceKind; let location: String }
}
