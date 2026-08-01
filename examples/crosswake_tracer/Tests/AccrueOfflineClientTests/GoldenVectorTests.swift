import Testing
import Foundation
@testable import AccrueOfflineClient

struct GoldenVectorTests {
    @Test("golden vectors are independently verified and converge on cache disposition")
    func goldenVectorsVerify() throws {
        let observations = try OfflineGoldenVectorVerifier.verifyFixture()

        #expect(observations.map(\.id) == observations.map(\.id).sorted())
        #expect(observations.contains { $0.id == "valid_allow" && $0.result == .accept })
        #expect(observations.contains { $0.id == "valid_signed_denial" && $0.cache == .deny })
        #expect(observations.allSatisfy { [.accept, .reject].contains($0.result) })
        let observed = Dictionary(uniqueKeysWithValues: observations.map { ($0.id, "\($0.result.rawValue):\($0.reason):\($0.cache.rawValue)") })
        #expect(observed["wrong_signature"] == "reject:signature:allow")
        #expect(observed["wrong_key"] == "reject:key:allow")
        #expect(observed["wrong_device"] == "reject:device:allow")
        #expect(observed["rollback"] == "reject:rollback:deny")
        #expect(observed["older_iat"] == "reject:iat:deny")
        #expect(observed["stale_freshness"] == "reject:freshness:allow")
        #expect(observed["fault_before_replace"] == "accept:fault_before_replace:deny")
        #expect(observed["fault_after_replace"] == "accept:fault_after_replace:deny")
    }

    @Test("cache replacement exposes only the old or complete new verified state")
    func cacheReplacementIsAtomicAcrossFaults() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"))
        try cache.replace(with: Data("deny".utf8))
        #expect(try String(contentsOf: cache.url) == "deny")
        #expect(throws: AtomicOfflineCache.Fault.beforeRename) { try cache.replace(with: Data("allow".utf8), fault: AtomicOfflineCache.Fault.beforeRename) }
        #expect(try String(contentsOf: cache.url) == "deny")
        #expect(throws: AtomicOfflineCache.Fault.afterRename) { try cache.replace(with: Data("deny-new".utf8), fault: AtomicOfflineCache.Fault.afterRename) }
        #expect(try String(contentsOf: cache.url) == "deny-new")
    }
}
