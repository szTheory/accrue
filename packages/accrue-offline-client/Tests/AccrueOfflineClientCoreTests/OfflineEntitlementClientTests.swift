import Foundation
import Testing
@testable import AccrueOfflineClientCore

struct OfflineEntitlementClientTests {
    @Test func tracerAcceptsCanonicalAllowAndRecoversIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache"))
        let client = OfflineEntitlementClient(configuration: configuration)

        #expect(client.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
    }

    @Test func freshClientLoadsAuthenticatedCachedStateWithoutGrantingFromPresence() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache"))
        #expect(OfflineEntitlementClient(configuration: configuration).applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        #expect(OfflineEntitlementClient(configuration: configuration).loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
    }

    @Test func malformedProofDoesNotReplaceAuthenticatedCache() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache"))
        let client = OfflineEntitlementClient(configuration: configuration)
        _ = client.applyServerProof(try GoldenVectorFixtureSupport.validAllowProof(), now: GoldenVectorFixtureSupport.now)
        #expect(client.applyServerProof(Data(), now: GoldenVectorFixtureSupport.now) == .invalid(reason: .malformed, nextAction: .reconnectRequired))
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
    }
}
