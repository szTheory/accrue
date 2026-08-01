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
        #expect(observations.count == 20)
        #expect(observations.contains { $0.id == "unknown_disposition" && $0.result == .reject && $0.reason == "disposition" && $0.cache == .allow })
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

    @Test("independent handles serialize replacements, preserve denial precedence, and clean candidates")
    func concurrentReplacementUsesOnePathCoordinator() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appendingPathComponent("entitlement.json").standardizedFileURL
        let firstHandle = AtomicOfflineCache(url: url)
        let secondHandle = AtomicOfflineCache(url: url)

        try firstHandle.replace(with: Data("allow-v4".utf8), disposition: .allow, revision: 4)
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? firstHandle.replace(with: Data("allow-v3".utf8), disposition: .allow, revision: 3)
            }
            group.addTask {
                try? secondHandle.replace(with: Data("deny-v4".utf8), disposition: .deny, revision: 4)
            }
        }

        #expect(try String(contentsOf: url) == "deny-v4")
        #expect(try firstHandle.candidateURLs().isEmpty)
        #expect(try secondHandle.candidateURLs().isEmpty)
    }

    @Test("recovery removes abandoned candidates without changing canonical cache")
    func recoveryKeepsCanonicalBytesAndRemovesAbandonedCandidates() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"))
        try cache.replace(with: Data("old-complete".utf8))
        let abandoned = directory.appendingPathComponent(".entitlement.json.candidate.crashed-child")
        try Data("new-incomplete".utf8).write(to: abandoned)

        try cache.recover()

        #expect(try String(contentsOf: cache.url) == "old-complete")
        #expect(try cache.candidateURLs().isEmpty)
    }
}
