import CryptoKit
import Foundation
import Testing
@testable import AccrueOfflineClientCore

struct AtomicOfflineCacheProcessTests {
    @Test("fresh processes preserve a complete authenticated denial across interrupted candidates")
    func restartAndCandidateRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("proof.cache")
        try run(cache, operation: "apply", proof: try fixtureProof("valid_allow"))
        let before = try Data(contentsOf: cache)
        try run(cache, operation: "crash-before-apply", proof: try fixtureProof("valid_signed_denial"), expected: 75)
        #expect(try Data(contentsOf: cache) == before)
        let client = try configuredClient(cache)
        #expect(client.loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001)) == .fresh(reason: .ok, nextAction: .none))
        try run(cache, operation: "apply", proof: try fixtureProof("valid_signed_denial"))
        try run(cache, operation: "apply", proof: try fixtureProof("valid_allow"), expected: 65)
        #expect(client.loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001)) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
    }

    @Test("equal revision allow and denial races always converge to denial")
    func concurrentProcessesSerialize() throws {
        for _ in 0..<8 {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let cache = directory.appendingPathComponent("proof.cache")
            let first = try process(cache, operation: "apply", proof: try fixtureProof("valid_allow"))
            let second = try process(cache, operation: "apply", proof: try fixtureProof("valid_signed_denial"))
            try first.run(); try second.run(); first.waitUntilExit(); second.waitUntilExit()
            #expect(second.terminationStatus == 0)
            #expect(first.terminationStatus == 0 || first.terminationStatus == 65)
            #expect(try configuredClient(cache).loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001)) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
            #expect(!(try Data(contentsOf: cache)).contains(testKey))
        }
    }

    @Test("harness exposes rejected admission as a nonzero process result")
    func invalidAdmissionFailsHarness() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try run(directory.appendingPathComponent("proof.cache"), operation: "apply", proof: Data("malformed".utf8), expected: 65)
    }

    @Test("fresh process recovers each late rollback failure")
    func freshProcessRecoversLateRollbackFailures() throws {
        for rollbackFault in [AtomicOfflineCache.FaultStage.rollbackRestore, .rollbackDirectorySync] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: directory) }
            let cache = directory.appendingPathComponent("proof.cache")
            let client = try configuredClient(cache)
            #expect(client.applyServerProof(try fixtureProof("valid_allow"), now: Date(timeIntervalSince1970: 1_700_000_001)) == .fresh(reason: .ok, nextAction: .none))
            let before = try Data(contentsOf: cache)
            let candidate = VerifiedOfflineProof(compactProof: try fixtureProof("valid_signed_denial"), highWater: ProofHighWater(revision: 6, issuedAt: 1_700_000_001, freshUntil: 1_700_003_601, disposition: "deny"))
            #expect(throws: (any Error).self) { try AtomicOfflineCache(url: cache, key: SymmetricKey(data: testKey), fault: .parentDirectorySync, rollbackFault: rollbackFault).replace(candidate) }
            try run(cache, operation: "load", expected: 0)
            #expect(try Data(contentsOf: cache) == before)
            #expect(try configuredClient(cache).loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001)) == .fresh(reason: .ok, nextAction: .none))
            let artifacts = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.contains(".backup.") || $0.contains(".transaction.") || $0.contains(".candidate.") }
            #expect(artifacts.isEmpty)
        }
    }

    private var testKey: Data { Data(repeating: 7, count: 32) }
    private func configuredClient(_ cache: URL) throws -> OfflineEntitlementClient { OfflineEntitlementClient(configuration: .init(issuer: "accrue.test.offline", audience: "accrue-offline-client", accountSubject: "synthetic-account", deviceThumbprint: "IVw958D_sxKYMg6iCHQs-vmxkOVIiRwwKlfeV6ykrCg", publicJWKS: try jwks(), cacheURL: cache, cacheAuthenticationKey: SymmetricKey(data: testKey))) }
    private func run(_ cache: URL, operation: String, proof: Data = Data(), expected: Int32 = 0) throws { let value = try process(cache, operation: operation, proof: proof); try value.run(); value.waitUntilExit(); #expect(value.terminationStatus == expected) }
    private func process(_ cache: URL, operation: String, proof: Data) throws -> Process { let value = Process(); value.executableURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness"); value.arguments = operation == "load" ? [cache.path, operation] : [cache.path, operation, proof.base64EncodedString()]; value.environment = ProcessInfo.processInfo.environment.merging(["ACCRUE_CACHE_TEST_KEY_BASE64": testKey.base64EncodedString(), "ACCRUE_CACHE_JWKS_BASE64": try jwks().base64EncodedString()], uniquingKeysWith: { _, new in new }); return value }
    private func fixtureProof(_ id: String) throws -> Data { let vectors = try corpus()["vectors"] as! [[String: Any]]; return Data((vectors.first { $0["id"] as? String == id }!["compact_jws"] as! String).utf8) }
    private func jwks() throws -> Data { try JSONSerialization.data(withJSONObject: corpus()["public_jwks"]!) }
    private func corpus() throws -> [String: Any] { let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(); return try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json"))) as! [String: Any] }
}
