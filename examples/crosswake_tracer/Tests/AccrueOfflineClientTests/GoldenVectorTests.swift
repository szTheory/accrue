import Testing
import Foundation
import CryptoKit
@testable import AccrueOfflineClient

struct GoldenVectorTests {
    @Test("proof high-water admits a same-revision signed denial but never stale allow evidence")
    func proofHighWaterUsesDenyPrecedenceAlongsideMonotonicClaims() {
        let issuedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let freshness = Date(timeIntervalSince1970: 1_700_003_600)
        let allowAtSeven = ProofHighWater(
            issuedAt: issuedAt,
            revision: 7,
            freshnessDeadline: freshness,
            disposition: .allow
        )
        let denialAtSeven = ProofHighWater(
            issuedAt: issuedAt,
            revision: 7,
            freshnessDeadline: freshness,
            disposition: .deny
        )

        #expect(allowAtSeven.accepts(newer: denialAtSeven))
        #expect(!denialAtSeven.accepts(newer: allowAtSeven))
        #expect(!allowAtSeven.accepts(newer: ProofHighWater(issuedAt: issuedAt, revision: 6, freshnessDeadline: freshness, disposition: .deny)))
        #expect(denialAtSeven.accepts(newer: ProofHighWater(issuedAt: issuedAt, revision: 8, freshnessDeadline: freshness, disposition: .allow)))
        #expect(!allowAtSeven.accepts(newer: ProofHighWater(issuedAt: issuedAt.addingTimeInterval(-1), revision: 8, freshnessDeadline: freshness, disposition: .allow)))
        #expect(!allowAtSeven.accepts(newer: ProofHighWater(issuedAt: issuedAt, revision: 8, freshnessDeadline: freshness.addingTimeInterval(-1), disposition: .allow)))
    }

    @Test("golden vectors are independently verified and converge on cache disposition")
    func goldenVectorsVerify() throws {
        let observations = try OfflineGoldenVectorVerifier.verifyFixture()

        #expect(observations.map(\.id) == observations.map(\.id).sorted())
        #expect(observations.contains { $0.id == "valid_allow" && $0.result == .accept })
        #expect(observations.contains { $0.id == "valid_signed_denial" && $0.cache == .deny })
        #expect(observations.allSatisfy { [.accept, .reject].contains($0.result) })
        #expect(observations.count == 24)
        #expect(observations.contains { $0.id == "unknown_kid" && $0.result == .reject && $0.reason == "unknown_key" && $0.cache == .allow })
    }

    @Test("escaped duplicate JSON members fail closed in corpus, JWS header, and payload")
    func escapedDuplicateMembersFailClosed() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        let corpusText = try #require(String(data: fixture.corpus, encoding: .utf8))
        let duplicateJWK = corpusText.replacingOccurrences(
            of: #""kty": "EC""#,
            with: #""kty": "EC", "\u006bty": "EC""#,
            options: [],
            range: corpusText.range(of: #""kty": "EC""#)
        )
        #expect(try validationError(Data(duplicateJWK.utf8), fixture: fixture).contains("malformed"))

        let cache = AtomicOfflineCache(
            url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            authenticationKey: testCacheKey
        )
        let compact = try signedCandidate(revision: 8, iat: 200, freshUntil: 400, disposition: "allow")
        let duplicateHeader = try duplicateJWSMember(
            compact,
            segment: 0,
            original: #""alg":"ES256""#,
            duplicate: #""alg":"ES256","\u0061lg":"ES256""#
        )
        let duplicatePayload = try duplicateJWSMember(
            compact,
            segment: 1,
            original: #""iss":"accrue.test.offline""#,
            duplicate: #""iss":"accrue.test.offline","\u0069ss":"accrue.test.offline""#
        )

        #expect(throws: (any Error).self) {
            try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(duplicateHeader, in: cache)
        }
        #expect(throws: (any Error).self) {
            try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(duplicatePayload, in: cache)
        }
    }

    @Test("canonical corpus rejects top-level schema and value drift before observation")
    func canonicalCorpusRejectsTopLevelDrift() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        for field in ["purpose", "schema_version", "protocol_version", "public_jwks"] {
            var candidate = try corpusObject(fixture.corpus)
            candidate[field] = "mutated"
            #expect(!(try validationError(encode(candidate), fixture: fixture)).isEmpty)
        }

        var missing = try corpusObject(fixture.corpus)
        missing.removeValue(forKey: "purpose")
        #expect(try validationError(encode(missing), fixture: fixture).contains("top-level purpose"))

        var extra = try corpusObject(fixture.corpus)
        extra["unknown"] = "ignored-by-Decodable"
        #expect(try validationError(encode(extra), fixture: fixture).contains("top-level unknown"))
    }

    @Test("canonical corpus rejects every vector field and optional-key drift")
    func canonicalCorpusRejectsVectorFieldDrift() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        let fields = ["id", "case_id", "contract_version", "expected_disposition", "compact_jws", "expected_claims", "verification_context", "expected_state", "expected_reason", "expected_next_action", "expected_cache_disposition"]
        for field in fields {
            var candidate = try corpusObject(fixture.corpus)
            var vectors = candidate["vectors"] as! [[String: Any]]
            if field == "compact_jws" {
                vectors[0][field] = vectors.first { ($0["id"] as? String) == "valid_signed_denial" }![field]
            } else {
                vectors[0][field] = "mutated-\(field)"
            }
            candidate["vectors"] = vectors
            let error = try validationError(encode(candidate), fixture: fixture)
            #expect(!error.isEmpty)
        }

        var missingKey = try corpusObject(fixture.corpus)
        var vectors = missingKey["vectors"] as! [[String: Any]]
        let faultVectorIndex = vectors.firstIndex { $0["fault_point"] != nil }!
        let faultVectorID = vectors[faultVectorIndex]["id"] as! String
        var changedFault = try corpusObject(fixture.corpus)
        var changedFaultVectors = changedFault["vectors"] as! [[String: Any]]
        changedFaultVectors[faultVectorIndex]["fault_point"] = "mutated-fault"
        changedFault["vectors"] = changedFaultVectors
        #expect(try validationError(encode(changedFault), fixture: fixture).contains("vector \(faultVectorID) fault_point"))

        vectors[faultVectorIndex].removeValue(forKey: "fault_point")
        missingKey["vectors"] = vectors
        #expect(try validationError(encode(missingKey), fixture: fixture).contains("vector \(faultVectorID) fault_point"))

        var unexpectedFault = try corpusObject(fixture.corpus)
        vectors = unexpectedFault["vectors"] as! [[String: Any]]
        let normalVectorIndex = vectors.firstIndex { $0["fault_point"] == nil }!
        let normalVectorID = vectors[normalVectorIndex]["id"] as! String
        vectors[normalVectorIndex]["fault_point"] = "unexpected"
        unexpectedFault["vectors"] = vectors
        #expect(try validationError(encode(unexpectedFault), fixture: fixture).contains("vector \(normalVectorID) fault_point"))

        var unknownKey = try corpusObject(fixture.corpus)
        vectors = unknownKey["vectors"] as! [[String: Any]]
        vectors[0]["unknown"] = true
        unknownKey["vectors"] = vectors
        #expect(try validationError(encode(unknownKey), fixture: fixture).contains("vector \(vectors[0]["id"] as! String) unknown"))
    }

    @Test("canonical corpus rejects duplicate and non-identical vector identities")
    func canonicalCorpusRejectsIdentityDrift() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()

        var duplicate = try corpusObject(fixture.corpus)
        var vectors = duplicate["vectors"] as! [[String: Any]]
        vectors[1]["id"] = vectors[0]["id"]
        duplicate["vectors"] = vectors
        #expect(try validationError(encode(duplicate), fixture: fixture).contains("duplicate vector id"))

        var renamed = try corpusObject(fixture.corpus)
        vectors = renamed["vectors"] as! [[String: Any]]
        vectors[0]["id"] = "renamed"
        renamed["vectors"] = vectors
        #expect(try validationError(encode(renamed), fixture: fixture).contains("vector identity set"))

        var missing = try corpusObject(fixture.corpus)
        vectors = missing["vectors"] as! [[String: Any]]
        vectors.removeLast()
        missing["vectors"] = vectors
        #expect(try validationError(encode(missing), fixture: fixture).contains("vector identity set"))

        var extra = try corpusObject(fixture.corpus)
        vectors = extra["vectors"] as! [[String: Any]]
        vectors.append(vectors[0].merging(["id": "extra"], uniquingKeysWith: { _, new in new }))
        extra["vectors"] = vectors
        #expect(try validationError(encode(extra), fixture: fixture).contains("vector identity set"))
    }

    @Test("canonical case bindings reject unknown cases and metadata mismatches")
    func canonicalCorpusRejectsDecisionCaseBindingDrift() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        var baseline = try corpusObject(fixture.corpus)
        var vectors = baseline["vectors"] as! [[String: Any]]
        let id = vectors[0]["id"] as! String

        vectors[0]["case_id"] = "unknown_case"
        baseline["vectors"] = vectors
        #expect(try validationError(encode(baseline), baseline: encode(baseline), fixture: fixture).contains("vector \(id) case_id"))

        baseline = try corpusObject(fixture.corpus)
        vectors = baseline["vectors"] as! [[String: Any]]
        vectors[0]["contract_version"] = "v0"
        baseline["vectors"] = vectors
        #expect(try validationError(encode(baseline), baseline: encode(baseline), fixture: fixture).contains("vector \(id) contract_version"))

        baseline = try corpusObject(fixture.corpus)
        vectors = baseline["vectors"] as! [[String: Any]]
        vectors[0]["expected_disposition"] = "not-canonical"
        baseline["vectors"] = vectors
        #expect(try validationError(encode(baseline), baseline: encode(baseline), fixture: fixture).contains("vector \(id) expected_disposition"))
    }

    @Test("cache replacement exposes only the old or complete new verified state")
    func cacheReplacementIsAtomicAcrossFaults() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"), authenticationKey: testCacheKey)
        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: cache)
        #expect(try cache.recoveredEnvelope()?.disposition == .allow)
        #expect(throws: AtomicOfflineCache.Fault.beforeRename) { try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_signed_denial", in: cache, fault: .beforeRename) }
        #expect(try cache.recoveredEnvelope()?.disposition == .allow)
        #expect(throws: AtomicOfflineCache.Fault.afterRename) { try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_signed_denial", in: cache, fault: .afterRename) }
        #expect(try cache.recoveredEnvelope()?.disposition == .deny)
    }

    @Test("authenticated envelopes bind payload revision disposition and cache path")
    func authenticatedEnvelopeRejectsTampering() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let key = testCacheKey
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"), authenticationKey: key)

        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: cache)
        #expect(try cache.recoveredEnvelope()?.compactProof.starts(with: Data("eyJ".utf8)) == true)
        #expect(try cache.recoveredEnvelope()?.revision == 5)
        #expect(try cache.recoveredEnvelope()?.disposition == .allow)
        #expect(try cache.recoveredEnvelope()?.highWater.issuedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(try cache.recoveredEnvelope()?.highWater.freshnessDeadline == Date(timeIntervalSince1970: 1_700_003_600))

        var envelope = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: cache.url)) as? [String: Any])
        envelope["revision"] = 10
        try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys]).write(to: cache.url)
        #expect(throws: AtomicOfflineCache.CacheError.authenticationFailed) { try cache.recoveredEnvelope() }
    }

    @Test("fresh authenticated cache restores denial high-water before replacement")
    func freshHandleRefusesOlderAllowAfterPersistedDenial() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let key = testCacheKey
        let url = directory.appendingPathComponent("entitlement.json")

        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_signed_denial", in: AtomicOfflineCache(url: url, authenticationKey: key))
        let restarted = AtomicOfflineCache(url: url, authenticationKey: key)
        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: restarted)

        let envelope = try #require(try restarted.recoveredEnvelope())
        #expect(envelope.revision == 5)
        #expect(envelope.disposition == .deny)
    }

    @Test("reopened cache retains every high-water component before replacement")
    func persistedHighWaterRejectsHigherRevisionWithOlderIssueOrFreshness() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("entitlement.json")
        let cache = AtomicOfflineCache(url: url, authenticationKey: testCacheKey)

        let accepted = try signedCandidate(revision: 10, iat: 200, freshUntil: 400, disposition: "allow")
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(accepted, in: cache)

        let restarted = AtomicOfflineCache(url: url, authenticationKey: testCacheKey)
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(
            try signedCandidate(revision: 11, iat: 199, freshUntil: 500, disposition: "allow"), in: restarted
        )
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(
            try signedCandidate(revision: 12, iat: 200, freshUntil: 399, disposition: "allow"), in: restarted
        )

        let envelope = try #require(try restarted.recoveredEnvelope())
        #expect(envelope.compactProof == Data(accepted.utf8))
        #expect(envelope.highWater == ProofHighWater(
            issuedAt: Date(timeIntervalSince1970: 200), revision: 10,
            freshnessDeadline: Date(timeIntervalSince1970: 400), disposition: .allow
        ))
    }

    @Test("verified same-revision denial wins and unauthenticated bytes never recover")
    func verifiedOnlyAdmissionAndDenialPrecedence() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"), authenticationKey: testCacheKey)
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(try signedCandidate(revision: 8, iat: 200, freshUntil: 400, disposition: "allow"), in: cache)
        let denial = try signedCandidate(revision: 8, iat: 200, freshUntil: 400, disposition: "deny")
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(denial, in: cache)
        try OfflineGoldenVectorVerifier.replaceVerifiedTestProof(try signedCandidate(revision: 8, iat: 201, freshUntil: 401, disposition: "allow"), in: cache)
        #expect(try cache.recoveredEnvelope()?.compactProof == Data(denial.utf8))

        try Data("caller-selected bytes".utf8).write(to: cache.url)
        #expect(throws: AtomicOfflineCache.CacheError.malformedEnvelope) { try cache.recoveredEnvelope() }
    }

    @Test("independent handles serialize replacements, preserve denial precedence, and clean candidates")
    func concurrentReplacementUsesOnePathCoordinator() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("entitlement.json").standardizedFileURL
        let firstHandle = AtomicOfflineCache(url: url, authenticationKey: testCacheKey)
        let secondHandle = AtomicOfflineCache(url: url, authenticationKey: testCacheKey)

        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: firstHandle)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: firstHandle)
            }
            group.addTask {
                try? OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_signed_denial", in: secondHandle)
            }
        }

        #expect(try firstHandle.recoveredEnvelope()?.disposition == .deny)
        #expect(try firstHandle.candidateURLs().isEmpty)
        #expect(try secondHandle.candidateURLs().isEmpty)
    }

    @Test("recovery removes abandoned candidates without changing canonical cache")
    func recoveryKeepsCanonicalBytesAndRemovesAbandonedCandidates() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"), authenticationKey: testCacheKey)
        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: cache)
        let abandoned = directory.appendingPathComponent(".entitlement.json.candidate.crashed-child")
        try Data("new-incomplete".utf8).write(to: abandoned)

        try cache.recover()

        #expect(try cache.recoveredEnvelope()?.disposition == .allow)
        #expect(try cache.candidateURLs().isEmpty)
    }

    @Test("child-process crashes reopen only complete old or durable new bytes")
    func childProcessCrashRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"), authenticationKey: testCacheKey)
        try OfflineGoldenVectorVerifier.replaceVerifiedFixture("valid_allow", in: cache)

        try runCrashHarness(cache.url, fixtureID: "valid_signed_denial", point: "crash-before-rename")
        try cache.recover()
        #expect(try cache.recoveredEnvelope()?.disposition == .allow)
        #expect(try cache.candidateURLs().isEmpty)

        try runCrashHarness(cache.url, fixtureID: "valid_signed_denial", point: "crash-after-directory-sync")
        #expect(try cache.recoveredEnvelope()?.disposition == .deny)
    }

    private var testCacheKey: SymmetricKey { SymmetricKey(data: Data("test-cache-authentication-key-32bytes".utf8)) }

    private func runCrashHarness(_ url: URL, fixtureID: String, point: String) throws {
        let harness = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness")
        #expect(FileManager.default.isExecutableFile(atPath: harness.path))
        let process = Process()
        process.executableURL = harness
        process.arguments = [url.path, point, fixtureID]
        process.environment = ProcessInfo.processInfo.environment.merging(
            ["ACCRUE_CACHE_TEST_KEY_BASE64": Data("test-cache-authentication-key-32bytes".utf8).base64EncodedString()],
            uniquingKeysWith: { _, new in new }
        )
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus != 0)
    }

    private func signedCandidate(revision: Int64, iat: Int64, freshUntil: Int64, disposition: String) throws -> String {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        let corpus = try #require(JSONSerialization.jsonObject(with: fixture.corpus) as? [String: Any])
        let vectors = try #require(corpus["vectors"] as? [[String: Any]])
        let compact = try #require(vectors.first { $0["id"] as? String == "valid_allow" }?["compact_jws"] as? String)
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        var claims = try #require(JSONSerialization.jsonObject(with: Data(base64URLEncoded: String(parts[1]))!) as? [String: Any])
        claims["revision"] = revision
        claims["iat"] = iat
        claims["nbf"] = iat
        claims["fresh_until"] = freshUntil
        claims["disposition"] = disposition
        if disposition == "deny" {
            claims["denial_reason"] = "access_unavailable"
            claims["plans"] = []
            claims["features"] = []
            claims["quantities"] = [:]
        }
        let header = String(parts[0])
        let payload = try JSONSerialization.data(withJSONObject: claims, options: [.sortedKeys]).base64URLEncodedString()
        let key = try #require(JSONSerialization.jsonObject(with: fixture.key) as? [String: Any])
        let privateBytes = try #require(Data(base64URLEncoded: key["d"] as? String ?? ""))
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateBytes)
        let signingInput = "\(header).\(payload)"
        let signature = try privateKey.signature(for: Data(signingInput.utf8)).rawRepresentation.base64URLEncodedString()
        return "\(signingInput).\(signature)"
    }

    private func duplicateJWSMember(
        _ compact: String,
        segment: Int,
        original: String,
        duplicate: String
    ) throws -> String {
        var parts = compact.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let decoded = try #require(Data(base64URLEncoded: parts[segment]))
        var json = try #require(String(data: decoded, encoding: .utf8))
        let range = try #require(json.range(of: original))
        json.replaceSubrange(range, with: duplicate)
        parts[segment] = Data(json.utf8).base64URLEncodedString()
        return parts.joined(separator: ".")
    }

    private func corpusObject(_ data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func encode(_ object: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func validationError(
        _ candidate: Data,
        baseline: Data? = nil,
        fixture: (corpus: Data, decisionCases: Data, key: Data)
    ) throws -> String {
        do {
            _ = try OfflineGoldenVectorVerifier.verify(
                candidate: candidate,
                baseline: baseline ?? fixture.corpus,
                decisionCases: fixture.decisionCases,
                keyData: fixture.key
            )
            return "accepted candidate unexpectedly"
        } catch {
            return String(describing: error)
        }
    }
}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }

    func base64URLEncodedString() -> String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
