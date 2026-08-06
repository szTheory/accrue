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
}
