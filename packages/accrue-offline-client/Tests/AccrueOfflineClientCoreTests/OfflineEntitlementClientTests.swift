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

    private func json(_ part: String) throws -> String { var value = part.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"); value += String(repeating: "=", count: (4 - value.count % 4) % 4); return String(data: try #require(Data(base64Encoded: value)), encoding: .utf8)! }
}
