import Testing
import Foundation
import CryptoKit
@testable import AccrueOfflineClient

struct AtomicOfflineCacheProcessTests {
    @Test("same-revision denial survives fresh processes and rejects stale or equal allow")
    func denialRestartRefusesStaleAndEqualAllow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyBytes = Data("process-cache-authentication-key-32bytes".utf8)
        let url = directory.appendingPathComponent("entitlement.json")

        try runHarness(url, key: keyBytes, arguments: ["replace", "allow", "7", "allow-r7"])
        try runHarness(url, key: keyBytes, arguments: ["replace", "deny", "7", "deny-r7"])
        try runHarness(url, key: keyBytes, arguments: ["replace", "allow", "6", "allow-r6"])
        try runHarness(url, key: keyBytes, arguments: ["replace", "allow", "7", "allow-r7-stale"])

        let cache = AtomicOfflineCache(url: url, authenticationKey: SymmetricKey(data: keyBytes))
        let envelope = try #require(try cache.recoveredEnvelope())
        #expect(envelope.payload == Data("deny-r7".utf8))
        #expect(envelope.revision == 7)
        #expect(envelope.disposition == .deny)
        #expect(try cache.candidateURLs().isEmpty)
    }

    @Test("obsolete no-key process invocation cannot replace an authenticated signed denial")
    func obsoleteNoKeyInvocationPreservesAuthenticatedDenial() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyBytes = Data("process-cache-authentication-key-32bytes".utf8)
        let url = directory.appendingPathComponent("entitlement.json")

        try runHarness(url, key: keyBytes, arguments: ["replace", "deny", "9", "deny-r9"])
        let before = try Data(contentsOf: url)

        let harness = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness")
        let process = Process()
        process.executableURL = harness
        process.arguments = [url.path, "legacy-allow", "after-directory-sync"]
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus != 0)
        #expect(try Data(contentsOf: url) == before)
        let cache = AtomicOfflineCache(url: url, authenticationKey: SymmetricKey(data: keyBytes))
        let envelope = try #require(try cache.recoveredEnvelope())
        #expect(envelope.payload == Data("deny-r9".utf8))
        #expect(envelope.revision == 9)
        #expect(envelope.disposition == .deny)
        #expect(try cache.candidateURLs().isEmpty)
    }

    private func runHarness(_ url: URL, key: Data, arguments: [String]) throws {
        let harness = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness")
        #expect(FileManager.default.isExecutableFile(atPath: harness.path))
        let process = Process()
        process.executableURL = harness
        process.arguments = [url.path] + arguments
        process.environment = ProcessInfo.processInfo.environment.merging(
            ["ACCRUE_CACHE_TEST_KEY_BASE64": key.base64EncodedString()], uniquingKeysWith: { _, new in new }
        )
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus == 0)
    }
}
