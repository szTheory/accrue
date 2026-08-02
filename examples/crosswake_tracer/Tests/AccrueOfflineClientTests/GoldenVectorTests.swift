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

    @Test("canonical corpus rejects top-level schema and value drift before observation")
    func canonicalCorpusRejectsTopLevelDrift() throws {
        let fixture = try OfflineGoldenVectorVerifier.fixtureData()
        for field in ["purpose", "schema_version"] {
            var candidate = try corpusObject(fixture.corpus)
            candidate[field] = "mutated"
            #expect(try validationError(encode(candidate), fixture: fixture).contains("top-level \(field)"))
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
        let fields = ["id", "case_id", "contract_version", "expected_disposition", "compact_jws", "expected_verification", "expected_reason", "expected_cache_disposition"]
        for field in fields {
            var candidate = try corpusObject(fixture.corpus)
            var vectors = candidate["vectors"] as! [[String: Any]]
            let originalID = vectors[0]["id"] as! String
            if field == "compact_jws" {
                vectors[0][field] = vectors.first { ($0["id"] as? String) == "valid_signed_denial" }![field]
            } else {
                vectors[0][field] = "mutated-\(field)"
            }
            candidate["vectors"] = vectors
            let error = try validationError(encode(candidate), fixture: fixture)
            #expect(error.contains(field == "id" ? "vector identity set" : "vector \(originalID) \(field)"))
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

    @Test("child-process crashes reopen only complete old or durable new bytes")
    func childProcessCrashRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = AtomicOfflineCache(url: directory.appendingPathComponent("entitlement.json"))
        try cache.replace(with: Data("old-complete".utf8))

        try runCrashHarness(cache.url, payload: "new-before", point: "before-rename")
        try AtomicOfflineCache(url: cache.url).recover()
        #expect(try String(contentsOf: cache.url) == "old-complete")
        #expect(try cache.candidateURLs().isEmpty)

        try runCrashHarness(cache.url, payload: "new-durable", point: "after-directory-sync")
        #expect(try String(contentsOf: cache.url) == "new-durable")
    }

    private func runCrashHarness(_ url: URL, payload: String, point: String) throws {
        let harness = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug/AccrueOfflineCacheCrashHarness")
        #expect(FileManager.default.isExecutableFile(atPath: harness.path))
        let process = Process()
        process.executableURL = harness
        process.arguments = [url.path, payload, point]
        try process.run()
        process.waitUntilExit()
        #expect(process.terminationStatus != 0)
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
