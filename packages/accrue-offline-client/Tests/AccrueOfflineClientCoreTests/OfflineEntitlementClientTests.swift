import CryptoKit
import Foundation
import Testing
@testable import AccrueOfflineClientCore

struct OfflineEntitlementClientTests {
    @Test("canonical corpus rows have exact public state, reason, and action")
    func canonicalCorpusParity() throws {
        for vector in try GoldenVectorFixtureSupport.vectors() {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache"), vectorID: vector.id))
            let context = GoldenVectorFixtureSupport.context(for: vector.id)
            if let revision = context["accepted_revision"] as? Int64, revision > 0 {
                let prior = try GoldenVectorFixtureSupport.signedPrior(revision: revision, iat: context["accepted_iat"] as! Int64, freshUntil: context["accepted_fresh_until"] as! Int64, disposition: (context["accepted_disposition"] as? String) ?? "allow")
                _ = client.applyServerProof(prior, now: vector.now)
            }
            #expect(client.applyServerProof(vector.proof, now: vector.now) == vector.expected, "\(vector.id) must match the language-neutral corpus")
        }
    }

    @Test("signed binding, header, temporal, and payload mutations fail without replacing cache")
    func strictMutationsDoNotMutateCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache")))
        #expect(client.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        let mutations: [(String, Data, OfflineEntitlementReason)] = [
            ("issuer", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["iss"] = "other" }, .wrongIssuer),
            ("audience", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["aud"] = "other" }, .wrongAudience),
            ("account", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["sub"] = "other" }, .deviceMismatch),
            ("device", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["cnf"] = ["jkt": "other"] }, .deviceMismatch),
            ("version", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["version"] = "v0" }, .malformed),
            ("future nbf", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["nbf"] = Int64(1_800_000_000) }, .malformed)
        ]
        for (name, proof, reason) in mutations {
            #expect(client.applyServerProof(proof, now: GoldenVectorFixtureSupport.now) == .invalid(reason: reason, nextAction: .reconnectRequired), Comment(rawValue: name))
            #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        }
    }

    @Test("signed denial wins at equal revision and repeated input is idempotent")
    func denyPrecedenceAndIdempotency() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache")))
        let allow = try GoldenVectorFixtureSupport.validAllowProof()
        let deny = try GoldenVectorFixtureSupport.validDenyProof()
        #expect(client.applyServerProof(allow, now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        #expect(client.applyServerProof(deny, now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        #expect(client.applyServerProof(allow, now: GoldenVectorFixtureSupport.now) == .invalid(reason: .superseded, nextAction: .reconnectRequired))
        #expect(client.applyServerProof(deny, now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
    }

    @Test("genuinely signed duplicate JSON members are rejected without replacing authenticated cache")
    func signedDuplicateMembersDoNotMutateCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("proof.cache")
        let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: cache))
        #expect(client.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        let before = try Data(contentsOf: cache)
        let valid = String(data: try GoldenVectorFixtureSupport.validAllowProof(), encoding: .utf8)!
        let parts = valid.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let header = try json(parts[0]); let payload = try json(parts[1])
        let duplicateHeader = try GoldenVectorFixtureSupport.signedRaw(header: "{\"alg\":\"ES256\"," + String(header.dropFirst()), payload: payload)
        let duplicatePayload = try GoldenVectorFixtureSupport.signedRaw(payload: "{\"jti\":\"duplicate\"," + String(payload.dropFirst()))
        for proof in [duplicateHeader, duplicatePayload] {
            #expect(client.applyServerProof(proof, now: GoldenVectorFixtureSupport.now) == .invalid(reason: .malformed, nextAction: .reconnectRequired))
            #expect(try Data(contentsOf: cache) == before)
        }
    }

    @Test("verified proof replaces malformed and unauthenticated prior cache bytes")
    func verifiedRecoveryReplacesInvalidCache() throws {
        for invalid in [Data("not-json".utf8), Data("{\"version\":2}".utf8)] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let cache = directory.appendingPathComponent("proof.cache"); try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); try invalid.write(to: cache)
            let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: cache))
            #expect(client.applyServerProof(try GoldenVectorFixtureSupport.validDenyProof(), now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
            let replacement = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: cache))
            #expect(replacement.loadCachedState(now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        }
    }

    @Test("strict claim profile rejects schema and normalization variants without mutation")
    func strictClaimProfilePreservesAuthenticatedCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("proof.cache"); let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: cache))
        #expect(client.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none)); let before = try Data(contentsOf: cache)
        let variants = [
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["jti"] = "" },
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["cnf"] = ["jkt": "IVw958D_sxKYMg6iCHQs-vmxkOVIiRwwKlfeV6ykrCg", "extra": "x"] },
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["plans"] = ["z", "a"] },
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["quantities"] = ["seat": 0] },
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["revision"] = true },
            try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["denial_reason"] = "signed_denial" }
        ]
        for proof in variants { #expect(client.applyServerProof(proof, now: GoldenVectorFixtureSupport.now) == .invalid(reason: .malformed, nextAction: .reconnectRequired)); #expect(try Data(contentsOf: cache) == before) }
    }

    @Test("cache loads are read-only and distinguish absent from tampered state")
    func loadRecoveryIsReadOnly() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("proof.cache"); let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: cache))
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .invalid(reason: .malformed, nextAction: .reconnectRequired))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true); let invalid = Data("tampered".utf8); try invalid.write(to: cache)
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .invalid(reason: .cacheRecoveryFailed, nextAction: .reconnectRequired)); #expect(try Data(contentsOf: cache) == invalid)
    }

    @Test("every transactional cache fault preserves the authenticated prior envelope")
    func atomicStageFaultsPreservePriorEnvelope() throws {
        let stages: [AtomicOfflineCache.FaultStage] = [.candidateWrite, .candidateFileSync, .atomicReplace]
        for stage in stages {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString); defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("proof.cache"); let key = SymmetricKey(data: Data(repeating: 7, count: 32))
            let prior = VerifiedOfflineProof(compactProof: try GoldenVectorFixtureSupport.validAllowProof(), highWater: ProofHighWater(revision: 1, issuedAt: 1_700_000_000, freshUntil: 1_700_000_100, disposition: "allow"))
            let candidate = VerifiedOfflineProof(compactProof: try GoldenVectorFixtureSupport.validDenyProof(), highWater: ProofHighWater(revision: 2, issuedAt: 1_700_000_001, freshUntil: 1_700_000_101, disposition: "deny"))
            _ = try AtomicOfflineCache(url: url, key: key).replace(prior); let before = try Data(contentsOf: url)
            #expect(throws: (any Error).self) { try AtomicOfflineCache(url: url, key: key, fault: stage).replace(candidate) }
            #expect(try Data(contentsOf: url) == before)
            #expect(try AtomicOfflineCache(url: url, key: key).recoverProof() == prior.compactProof)
        }
    }

    @Test("late durability failures recover the exact authenticated prior envelope")
    func lateDurabilityFailureRecoversExactPrior() throws {
        let rollbackStages: [AtomicOfflineCache.FaultStage?] = [nil, .rollbackRestore, .rollbackDirectorySync]
        for rollbackStage in rollbackStages {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let cache = directory.appendingPathComponent("proof.cache")
            let configuration = try GoldenVectorFixtureSupport.configuration(cacheURL: cache)
            let priorClient = OfflineEntitlementClient(configuration: configuration)
            #expect(priorClient.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
            let before = try Data(contentsOf: cache)
            let verifiedDeny = VerifiedOfflineProof(compactProof: try GoldenVectorFixtureSupport.validDenyProof(), highWater: ProofHighWater(revision: 6, issuedAt: 1_700_000_001, freshUntil: 1_700_003_601, disposition: "deny"))
            #expect(throws: (any Error).self) { try AtomicOfflineCache(url: cache, key: configuration.cacheAuthenticationKey, fault: .parentDirectorySync, rollbackFault: rollbackStage).replace(verifiedDeny) }
            #expect(FileManager.default.fileExists(atPath: cache.path))
            let freshClient = OfflineEntitlementClient(configuration: configuration)
            #expect(freshClient.loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
            #expect(try Data(contentsOf: cache) == before)
        }
    }

    @Test("concurrent signed invalid contexts cannot persist authority")
    func concurrentInvalidContextsCannotPersist() async throws {
        let cases: [(String, Data, OfflineEntitlementReason, Date?)] = [
            ("profile", try GoldenVectorFixtureSupport.signedMutation { header, _ in header["typ"] = "other" }, .wrongType, nil),
            ("account", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["sub"] = "other-account" }, .deviceMismatch, nil),
            ("device", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["cnf"] = ["jkt": "other-device"] }, .deviceMismatch, nil),
            ("future-not-before", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["nbf"] = Int64(1_700_000_002) }, .malformed, nil),
            ("expired", try GoldenVectorFixtureSupport.signedMutation { _, claims in claims["fresh_until"] = Int64(1_700_000_000); claims["exp"] = Int64(1_700_000_001) }, .hardExpired, nil),
            ("clock-rollback", try GoldenVectorFixtureSupport.validAllowProof(), .clockRollback, Date(timeIntervalSince1970: 1_700_000_002))
        ]
        for _ in 0..<8 {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let cache = directory.appendingPathComponent("proof.cache")
            let configuration = try GoldenVectorFixtureSupport.configuration(cacheURL: cache)
            let gate = ConcurrentStartGate(expected: cases.count + 1)
            let results = await withTaskGroup(of: (String, OfflineEntitlementState).self, returning: [String: OfflineEntitlementState].self) { group in
                group.addTask {
                    await gate.arrive()
                    return ("valid", OfflineEntitlementClient(configuration: configuration).applyServerProof(try! GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now))
                }
                for (name, proof, _, clockHighWater) in cases {
                    group.addTask {
                        await gate.arrive()
                        let clientConfiguration = OfflineEntitlementClient.Configuration(issuer: configuration.issuer, audience: configuration.audience, accountSubject: configuration.accountSubject, deviceThumbprint: configuration.deviceThumbprint, publicJWKS: configuration.publicJWKS, cacheURL: cache, cacheAuthenticationKey: configuration.cacheAuthenticationKey, clockHighWater: clockHighWater)
                        return (name, OfflineEntitlementClient(configuration: clientConfiguration).applyServerProof(proof, now: GoldenVectorFixtureSupport.now))
                    }
                }
                var values: [String: OfflineEntitlementState] = [:]
                for await (name, state) in group { values[name] = state }
                return values
            }
            #expect(results["valid"] == .fresh(reason: .ok, nextAction: .none))
            for (name, _, reason, _) in cases { #expect(results[name] == .invalid(reason: reason, nextAction: .reconnectRequired), Comment(rawValue: name)) }
            #expect(OfflineEntitlementClient(configuration: configuration).loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        }
    }

    private func json(_ part: String) throws -> String { var value = part.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"); value += String(repeating: "=", count: (4 - value.count % 4) % 4); return String(data: try #require(Data(base64Encoded: value)), encoding: .utf8)! }
}

private actor ConcurrentStartGate {
    private let expected: Int
    private var arrivals = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    init(expected: Int) { self.expected = expected }
    func arrive() async {
        arrivals += 1
        if arrivals == expected { let pending = waiters; waiters.removeAll(); pending.forEach { $0.resume() }; return }
        await withCheckedContinuation { waiters.append($0) }
    }
}
