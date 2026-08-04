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

    /// Test-only cache admission seam.  The only public cache writer accepts a
    /// fixture identifier, then verifies its compact proof and binding before it
    /// reaches the durable replacement boundary.  Runtime integrations must use
    /// their production verifier to construct the same internal proof value.
    public static func replaceVerifiedFixture(
        _ fixtureID: String,
        in cache: AtomicOfflineCache,
        fault: AtomicOfflineCache.Fault? = nil
    ) throws {
        let fixture = try fixtureData()
        let corpus = try decodeCorpus(fixture.corpus, source: .baseline)
        guard let vector = corpus.vectors.first(where: { $0.id == fixtureID }) else {
            throw GoldenVectorContractError.vectorField(fixtureID, "id")
        }
        let context = try Context(vector.verificationContext)
        let payload = try verify(vector.compactJWS, keys: corpus.publicJwks["keys"] ?? [], context: context)
        try cache.replace(with: VerifiedOfflineProof(
            compactProof: Data(vector.compactJWS.utf8),
            issuedAt: payload.iat,
            revision: payload.revision,
            freshUntil: payload.freshUntil,
            disposition: payload.disposition == .deny ? .deny : .allow
        ), fault: fault)
    }

    /// Internal test seam for exercising cache ordering with independently signed
    /// candidates. It still runs the full JWS/profile/binding verification before
    /// constructing the opaque admission token; tests cannot inject a disposition,
    /// revision, issuance time, or freshness value separately from the proof.
    static func replaceVerifiedTestProof(
        _ compactProof: String,
        in cache: AtomicOfflineCache,
        fault: AtomicOfflineCache.Fault? = nil
    ) throws {
        let fixture = try fixtureData()
        let corpus = try decodeCorpus(fixture.corpus, source: .baseline)
        guard let baseline = corpus.vectors.first(where: { $0.id == "valid_allow" }) else {
            throw GoldenVectorContractError.vectorField("valid_allow", "id")
        }
        let payload = try verify(compactProof, keys: corpus.publicJwks["keys"] ?? [], context: try Context(baseline.verificationContext))
        try cache.replace(with: VerifiedOfflineProof(
            compactProof: Data(compactProof.utf8),
            issuedAt: payload.iat,
            revision: payload.revision,
            freshUntil: payload.freshUntil,
            disposition: payload.disposition == .deny ? .deny : .allow
        ), fault: fault)
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

        let observations = try candidateCorpus.vectors.map { try observe($0, jwks: candidateCorpus.publicJwks) }.sorted { $0.id < $1.id }
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
        // This also covers every decoded corpus object, including JWKS/JWK
        // metadata. Decodable/JSONSerialization otherwise silently choose a
        // duplicate member before TestKey performs its exact-key validation.
        try StrictJSON.rejectDuplicateKeys(in: data)
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

    private static func observe(_ vector: Vector, jwks: [String: [TestKey]]) throws -> GoldenVectorObservation {
        let context = try Context(vector.verificationContext)
        do {
            let payload = try verify(vector.compactJWS, keys: context.hasLocalKey ? (jwks["keys"] ?? []) : [], context: context)
            let state: String
            let reason: String
            if payload.disposition == .deny { state = "denied"; reason = "signed_denial" }
            else if payload.freshUntil > context.now { state = "fresh"; reason = "ok" }
            else { state = "stale_offline"; reason = "revalidation_due" }
            guard state == vector.expectedState else { throw GoldenVectorContractError.expectationMismatch(vector.id) }
            // A fault is evaluated against the explicitly supplied authenticated
            // prior cache.  Fixture labels never manufacture a cache outcome.
            let cache: GoldenVectorCache = vector.faultPoint == "before_rename" ? context.prior : (payload.disposition == .deny ? .deny : .allow)
            return GoldenVectorObservation(id: vector.id, result: .accept, reason: reason, cache: cache)
        } catch let error as GoldenVectorError {
            // A monotonic-order rejection retains the denial-safe high-water
            // disposition; all other verification failures retain the explicit
            // authenticated prior cache state.
            let cache: GoldenVectorCache = error.reason == "superseded" ? .deny : context.prior
            return GoldenVectorObservation(id: vector.id, result: .reject, reason: error.reason, cache: cache)
        }
    }

    private static func verify(_ compact: String, keys: [TestKey], context: Context) throws -> Payload {
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let headerData = Data(base64URLEncoded: String(parts[0])),
              let payloadData = Data(base64URLEncoded: String(parts[1])),
              let signatureData = Data(base64URLEncoded: String(parts[2])), signatureData.count == 64
        else { throw GoldenVectorError.malformed }
        // Decode only after an object-aware lexical pass. JSONSerialization keeps
        // the last duplicate member, which is not an admissible JWS profile.
        try StrictJSON.rejectDuplicateKeys(in: headerData)
        try StrictJSON.rejectDuplicateKeys(in: payloadData)
        guard let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let values = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        else { throw GoldenVectorError.malformed }
        guard Set(header.keys) == ["alg", "typ", "kid"] else { throw GoldenVectorError.malformed }
        guard header["alg"] as? String == "ES256" else { throw GoldenVectorError.algorithm }
        guard header["typ"] as? String == "accrue-entitlement-proof+jwt" else { throw GoldenVectorError.type }
        guard let kid = header["kid"] as? String, let key = keys.first(where: { $0.kid == kid }), key.isValid else { throw GoldenVectorError.key }
        let payload = try Payload(values: values)
        let publicKey: P256.Signing.PublicKey
        do { publicKey = try P256.Signing.PublicKey(x963Representation: key.point) }
        catch { throw GoldenVectorError.key }
        guard let signature = try? P256.Signing.ECDSASignature(rawRepresentation: signatureData),
              publicKey.isValidSignature(signature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw GoldenVectorError.signature }
        guard payload.version == "v1.59", !payload.jti.isEmpty else { throw GoldenVectorError.malformed }
        guard payload.iss == context.issuer else { throw GoldenVectorError.issuer }
        guard payload.aud == context.audience else { throw GoldenVectorError.audience }
        guard payload.accountID == context.account else { throw GoldenVectorError.account }
        guard payload.cnf == context.thumbprint else { throw GoldenVectorError.device }
        guard context.clockNow <= context.now else { throw GoldenVectorError.clock }
        guard payload.nbf <= context.now else { throw GoldenVectorError.notYetValid }
        guard payload.exp.map({ context.now < $0 }) ?? true else { throw GoldenVectorError.expired }
        guard payload.revision >= context.revision else { throw GoldenVectorError.rollback }
        guard !(payload.revision == context.revision && context.prior == .deny && payload.disposition == .allow) else { throw GoldenVectorError.rollback }
        guard payload.iat >= context.iat else { throw GoldenVectorError.iat }
        // Freshness controls the fresh/stale decision; it is not a hard expiry.
        guard payload.freshUntil >= context.freshness else { throw GoldenVectorError.freshness }
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
        let version, iss, aud, jti: String
        let accountID, cnf: String
        let revision, iat, nbf, freshUntil: Int64
        let exp: Int64?
        let disposition: Disposition

        init(values: [String: Any]) throws {
            let common: Set<String> = ["version", "iss", "aud", "jti", "sub", "cnf", "revision", "iat", "nbf", "fresh_until", "exp", "disposition", "plans", "features", "quantities"]
            let expected = (values["disposition"] as? String) == "deny" ? common.union(["denial_reason"]) : common
            guard Set(values.keys) == expected else { throw GoldenVectorError.malformed }
            guard let version = values["version"] as? String, version.utf8.count <= 256,
                  let iss = values["iss"] as? String,
                  let aud = values["aud"] as? String,
                  let jti = values["jti"] as? String,
                  let accountID = values["sub"] as? String,
                  let cnfMap = values["cnf"] as? [String: Any], Set(cnfMap.keys) == ["jkt"],
                  let cnf = cnfMap["jkt"] as? String, !cnf.isEmpty, cnf.utf8.count <= 256,
                  !iss.isEmpty, iss.utf8.count <= 256, !aud.isEmpty, aud.utf8.count <= 256,
                  !jti.isEmpty, jti.utf8.count <= 256, !accountID.isEmpty, accountID.utf8.count <= 256
            else { throw GoldenVectorError.malformed }
            guard let revision = values["revision"] as? Int64, revision >= 0 else { throw GoldenVectorError.malformed }
            guard let iat = values["iat"] as? Int64 else { throw GoldenVectorError.malformed }
            guard let nbf = values["nbf"] as? Int64, nbf >= 0 else { throw GoldenVectorError.malformed }
            guard let freshUntil = values["fresh_until"] as? Int64, freshUntil >= 0 else { throw GoldenVectorError.malformed }
            let exp: Int64?
            if values["exp"] is NSNull { exp = nil }
            else if let value = values["exp"] as? Int64, value >= 0 { exp = value }
            else { throw GoldenVectorError.malformed }
            guard let disposition = Disposition(rawValue: values["disposition"] as? String ?? "") else { throw GoldenVectorError.disposition }
            guard let plans = Self.normalizedStrings(values["plans"]),
                  let features = Self.normalizedStrings(values["features"]),
                  let quantities = Self.normalizedQuantities(values["quantities"]),
                  !(disposition == .allow && plans.isEmpty && features.isEmpty && quantities.isEmpty),
                  iat >= 0, iat <= nbf, nbf <= freshUntil,
                  exp.map({ freshUntil <= $0 }) ?? true else { throw GoldenVectorError.malformed }
            if disposition == .deny {
                guard let reason = values["denial_reason"] as? String,
                      ["signed_denial", "access_unavailable", "superseded", "device_revoked"].contains(reason)
                else { throw GoldenVectorError.malformed }
            }
            self.version = version; self.iss = iss; self.aud = aud; self.jti = jti; self.accountID = accountID; self.cnf = cnf
            self.revision = revision; self.iat = iat; self.nbf = nbf; self.exp = exp; self.freshUntil = freshUntil; self.disposition = disposition
        }

        private static func normalizedStrings(_ value: Any?) -> [String]? {
            guard let strings = value as? [String], strings.count <= 100,
                  strings.allSatisfy({ !$0.isEmpty && $0.utf8.count <= 256 }),
                  strings == strings.sorted(), Set(strings).count == strings.count else { return nil }
            return strings
        }

        private static func normalizedQuantities(_ value: Any?) -> [String: Int64]? {
            guard let quantities = value as? [String: Int64], quantities.count <= 100,
                  quantities.allSatisfy({ !$0.key.isEmpty && $0.key.utf8.count <= 256 && $0.value > 0 }) else { return nil }
            return quantities
        }
    }
    private enum Disposition: String { case allow, deny }
    private struct TestKey: Decodable {
        let kid: String; let kty: String; let crv: String; let use: String; let alg: String; let x: String; let y: String
        var point: Data { Data([4]) + Data(base64URLEncoded: x)! + Data(base64URLEncoded: y)! }
        var isValid: Bool { kty == "EC" && crv == "P-256" && use == "sig" && alg == "ES256" && !kid.isEmpty && Data(base64URLEncoded: x)?.count == 32 && Data(base64URLEncoded: y)?.count == 32 }
    }
    private struct Context {
        let issuer, audience, account, thumbprint: String; let revision, iat, freshness, now, clockNow: Int64; let prior: GoldenVectorCache; let hasLocalKey: Bool
        init(_ values: [String: JSONValue]) throws {
            guard case let .string(issuer)? = values["issuer"], case let .string(audience)? = values["audience"], case let .string(account)? = values["account_subject"], case let .string(thumbprint)? = values["device_thumbprint"], case let .integer(revision)? = values["accepted_revision"], case let .integer(iat)? = values["accepted_iat"], case let .integer(freshness)? = values["accepted_fresh_until"], case let .integer(now)? = values["now"] else { throw GoldenVectorError.malformed }
            self.issuer = issuer; self.audience = audience; self.account = account; self.thumbprint = thumbprint; self.revision = revision; self.iat = iat; self.freshness = freshness; self.now = now
            self.prior = (values["accepted_disposition"] == .string("deny")) ? .deny : .allow
            self.hasLocalKey = values["public_keys"] != .array([])
            if case let .object(high)? = values["clock_high_water"], case let .integer(clockNow)? = high["now"] { self.clockNow = clockNow } else { self.clockNow = 0 }
        }
    }
    private enum GoldenVectorError: Error { case malformed, signature, key, algorithm, issuer, audience, type, account, device, thumbprint, revision, rollback, iat, freshness, disposition, clock, expired, notYetValid; var reason: String { switch self { case .malformed, .signature, .revision, .disposition: "malformed"; case .iat, .freshness, .rollback: "superseded"; case .algorithm: "wrong_algorithm"; case .type: "wrong_type"; case .key: "unknown_key"; case .issuer: "wrong_issuer"; case .audience: "wrong_audience"; case .account, .device, .thumbprint: "device_mismatch"; case .clock: "clock_rollback"; case .expired: "hard_expired"; case .notYetValid: "future_not_valid" } } }
    private enum StrictJSON {
        static func rejectDuplicateKeys(in data: Data) throws {
            var parser = Parser(data)
            try parser.parseValue()
            try parser.requireEnd()
        }

        private struct Parser {
            let bytes: [UInt8]
            var index = 0

            init(_ data: Data) { bytes = Array(data) }

            mutating func requireEnd() throws {
                skipWhitespace()
                guard index == bytes.count else { throw GoldenVectorError.malformed }
            }

            mutating func parseValue() throws {
                skipWhitespace()
                guard index < bytes.count else { throw GoldenVectorError.malformed }
                switch bytes[index] {
                case 123: try parseObject()
                case 91: try parseArray()
                case 34: _ = try parseString()
                case 116: try consume("true")
                case 102: try consume("false")
                case 110: try consume("null")
                case 45, 48...57: try parseNumber()
                default: throw GoldenVectorError.malformed
                }
            }

            mutating func parseObject() throws {
                index += 1; skipWhitespace()
                if take(125) { return }
                var keys = Set<String>()
                while true {
                    skipWhitespace()
                    let key = try parseString()
                    guard keys.insert(key).inserted else { throw GoldenVectorError.malformed }
                    skipWhitespace(); guard take(58) else { throw GoldenVectorError.malformed }
                    try parseValue(); skipWhitespace()
                    if take(125) { return }
                    guard take(44) else { throw GoldenVectorError.malformed }
                }
            }

            mutating func parseArray() throws {
                index += 1; skipWhitespace()
                if take(93) { return }
                while true {
                    try parseValue(); skipWhitespace()
                    if take(93) { return }
                    guard take(44) else { throw GoldenVectorError.malformed }
                }
            }

            mutating func parseString() throws -> String {
                guard index < bytes.count, bytes[index] == 34 else { throw GoldenVectorError.malformed }
                let start = index; index += 1
                while index < bytes.count {
                    let byte = bytes[index]
                    if byte == 34 { index += 1; break }
                    if byte < 32 { throw GoldenVectorError.malformed }
                    if byte == 92 {
                        index += 1; guard index < bytes.count else { throw GoldenVectorError.malformed }
                        if bytes[index] == 117 {
                            guard index + 4 < bytes.count, bytes[(index + 1)...(index + 4)].allSatisfy(isHex) else { throw GoldenVectorError.malformed }
                            index += 4
                        } else if ![34, 92, 47, 98, 102, 110, 114, 116].contains(bytes[index]) { throw GoldenVectorError.malformed }
                    }
                    index += 1
                }
                guard index <= bytes.count, index > start + 1,
                      let decoded = try? JSONDecoder().decode(String.self, from: Data(bytes[start..<index])) else { throw GoldenVectorError.malformed }
                return decoded
            }

            mutating func parseNumber() throws {
                let start = index
                _ = take(45)
                guard index < bytes.count else { throw GoldenVectorError.malformed }
                if take(48) { } else { try digits() }
                if take(46) { try digits() }
                if take(69) || take(101) { _ = take(43) || take(45); try digits() }
                guard index > start else { throw GoldenVectorError.malformed }
            }

            mutating func digits() throws { let start = index; while index < bytes.count, bytes[index] >= 48, bytes[index] <= 57 { index += 1 }; guard index > start else { throw GoldenVectorError.malformed } }
            mutating func consume(_ value: String) throws { for byte in value.utf8 { guard take(byte) else { throw GoldenVectorError.malformed } } }
            mutating func take(_ byte: UInt8) -> Bool { guard index < bytes.count, bytes[index] == byte else { return false }; index += 1; return true }
            mutating func skipWhitespace() { while index < bytes.count, [9, 10, 13, 32].contains(bytes[index]) { index += 1 } }
            private func isHex(_ byte: UInt8) -> Bool { (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte) }
        }
    }
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

/// An opaque admission token.  Its initializer is intentionally private to this
/// file: only the JWS verifier above may couple compact bytes to authenticated
/// claims and high-water ordering metadata.
private struct VerifiedOfflineProof: Sendable {
    let compactProof: Data
    let highWater: ProofHighWater

    init(compactProof: Data, issuedAt: Int64, revision: Int64, freshUntil: Int64, disposition: AtomicOfflineCache.Disposition) {
        self.compactProof = compactProof
        highWater = ProofHighWater(
            issuedAt: Date(timeIntervalSince1970: TimeInterval(issuedAt)),
            revision: revision,
            freshnessDeadline: Date(timeIntervalSince1970: TimeInterval(freshUntil)),
            disposition: disposition
        )
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
        /// Compact JWS bytes, never a caller-selected application payload.
        public let compactProof: Data
        public let revision: Int64
        public let disposition: Disposition
        public let issuedAt: Date
        public let freshnessDeadline: Date

        @available(*, deprecated, message: "Use compactProof; cache payloads are verified compact proofs.")
        public var payload: Data { compactProof }

        public var highWater: ProofHighWater {
            ProofHighWater(issuedAt: issuedAt, revision: revision, freshnessDeadline: freshnessDeadline, disposition: disposition)
        }
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

    /// Deliberately file-private: a replacement can only be supplied by the
    /// verifier after JWS/profile/device-binding validation has succeeded.
    fileprivate func replace(with proof: VerifiedOfflineProof, fault: Fault? = nil) throws {
        try coordinator.withLock {
            let persisted = try loadVerifiedEnvelope()
            let accepted: Bool
            if let persisted {
                accepted = persisted.highWater.accepts(newer: proof.highWater)
            } else {
                accepted = coordinator.accepts(proof.highWater)
            }
            guard accepted else { return }
            let candidate = uniqueCandidateURL()
            defer { try? FileManager.default.removeItem(at: candidate) }

            try encodedReplacement(proof).write(to: candidate)
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
            coordinator.record(proof.highWater)
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

    private func encodedReplacement(_ proof: VerifiedOfflineProof) throws -> Data {
        let unsigned = UnsignedEnvelope(
            version: 2,
            compactProof: proof.compactProof.base64EncodedString(),
            revision: proof.highWater.revision,
            disposition: proof.highWater.disposition,
            issuedAt: Int64(proof.highWater.issuedAt.timeIntervalSince1970),
            freshUntil: Int64(proof.highWater.freshnessDeadline.timeIntervalSince1970)
        )
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
        guard envelope.version == 2,
              let compactProof = Data(base64Encoded: envelope.compactProof),
              let tag = Data(base64Encoded: envelope.authenticationTag)
        else { throw CacheError.malformedEnvelope }
        let unsigned = UnsignedEnvelope(version: envelope.version, compactProof: envelope.compactProof, revision: envelope.revision, disposition: envelope.disposition, issuedAt: envelope.issuedAt, freshUntil: envelope.freshUntil)
        let expected = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: authenticationKey))
        guard tag == expected else { throw CacheError.authenticationFailed }
        return RecoveredEnvelope(compactProof: compactProof, revision: envelope.revision, disposition: envelope.disposition, issuedAt: Date(timeIntervalSince1970: TimeInterval(envelope.issuedAt)), freshnessDeadline: Date(timeIntervalSince1970: TimeInterval(envelope.freshUntil)))
    }

    private func signedBytes(_ envelope: UnsignedEnvelope) throws -> Data {
        var bytes = Data("accrue.atomic-offline-cache".utf8)
        for value in [String(envelope.version), url.path, envelope.compactProof, String(envelope.revision), envelope.disposition.rawValue, String(envelope.issuedAt), String(envelope.freshUntil)] {
            let field = Data(value.utf8)
            var length = UInt64(field.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }
            bytes.append(field)
        }
        return bytes
    }

    private struct UnsignedEnvelope: Codable {
        let version: Int
        let compactProof: String
        let revision: Int64
        let disposition: Disposition
        let issuedAt: Int64
        let freshUntil: Int64

        enum CodingKeys: String, CodingKey {
            case version, revision, disposition
            case compactProof = "compact_proof"
            case issuedAt = "iat"
            case freshUntil = "fresh_until"
        }
    }

    private struct Envelope: Codable {
        let version: Int
        let compactProof: String
        let revision: Int64
        let disposition: Disposition
        let issuedAt: Int64
        let freshUntil: Int64
        let authenticationTag: String

        init(unsigned: UnsignedEnvelope, authenticationTag: String) {
            version = unsigned.version; compactProof = unsigned.compactProof; revision = unsigned.revision
            disposition = unsigned.disposition; issuedAt = unsigned.issuedAt; freshUntil = unsigned.freshUntil; self.authenticationTag = authenticationTag
        }

        enum CodingKeys: String, CodingKey {
            case version, revision, disposition
            case compactProof = "compact_proof"
            case issuedAt = "iat"
            case freshUntil = "fresh_until"
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
    private var highWater: ProofHighWater?

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

    func accepts(_ candidate: ProofHighWater) -> Bool {
        guard let highWater else { return true }
        return highWater.accepts(newer: candidate)
    }

    func record(_ highWater: ProofHighWater) {
        self.highWater = highWater
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
