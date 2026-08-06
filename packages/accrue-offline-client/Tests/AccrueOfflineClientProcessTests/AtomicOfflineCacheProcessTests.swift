import CryptoKit
import Foundation
import Testing
@testable import AccrueOfflineClientCore

struct AtomicOfflineCacheProcessTests {
    @Test("fresh processes preserve a complete authenticated denial and clean interrupted candidates")
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
        #expect(!FileManager.default.fileExists(atPath: directory.appendingPathComponent(".proof.cache.candidate.crashed-child").path))
        try run(cache, operation: "apply", proof: try fixtureProof("valid_signed_denial"))
        try run(cache, operation: "apply", proof: try fixtureProof("valid_allow"))
        #expect(client.loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001)) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
    }

    @Test("concurrent replacement processes leave a readable authenticated envelope")
    func concurrentProcessesSerialize() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = directory.appendingPathComponent("proof.cache")
        let first = try process(cache, operation: "apply", proof: try fixtureProof("valid_allow"))
        let second = try process(cache, operation: "apply", proof: try fixtureProof("valid_signed_denial"))
        try first.run(); try second.run(); first.waitUntilExit(); second.waitUntilExit()
        #expect(first.terminationStatus == 0); #expect(second.terminationStatus == 0)
        let state = try configuredClient(cache).loadCachedState(now: Date(timeIntervalSince1970: 1_700_000_001))
        #expect(state == .fresh(reason: .ok, nextAction: .none) || state == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        let bytes = try Data(contentsOf: cache)
        #expect(!bytes.contains(testKey))
    }

    private var testKey: Data { Data(repeating: 7, count: 32) }
    private func configuredClient(_ cache: URL) throws -> OfflineEntitlementClient { OfflineEntitlementClient(configuration: .init(issuer: "accrue.test.offline", audience: "accrue-offline-client", accountSubject: "synthetic-account", deviceThumbprint: "IVw958D_sxKYMg6iCHQs-vmxkOVIiRwwKlfeV6ykrCg", publicJWKS: try jwks(), cacheURL: cache, cacheAuthenticationKey: SymmetricKey(data: testKey))) }
    private func run(_ cache: URL, operation: String, proof: Data, expected: Int32 = 0) throws { let value = try process(cache, operation: operation, proof: proof); try value.run(); value.waitUntilExit(); #expect(value.terminationStatus == expected) }
    private func process(_ cache: URL, operation: String, proof: Data) throws -> Process { let value = Process(); value.executableURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness"); value.arguments = [cache.path, operation, proof.base64EncodedString()]; value.environment = ProcessInfo.processInfo.environment.merging(["ACCRUE_CACHE_TEST_KEY_BASE64": testKey.base64EncodedString(), "ACCRUE_CACHE_JWKS_BASE64": try jwks().base64EncodedString()], uniquingKeysWith: { _, new in new }); return value }
    private func fixtureProof(_ id: String) throws -> Data { let vectors = try corpus()["vectors"] as! [[String: Any]]; return Data((vectors.first { $0["id"] as? String == id }!["compact_jws"] as! String).utf8) }
    private func jwks() throws -> Data { try JSONSerialization.data(withJSONObject: corpus()["public_jwks"]!) }
    private func corpus() throws -> [String: Any] { let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(); return try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json"))) as! [String: Any] }
}
