import Foundation
import Testing
@testable import AccrueOfflineClientCore

private actor TestReconnectTransport: OfflineProofReconnectTransport {
    enum Failure: Error { case unavailable }
    private let result: Result<Data, Failure>

    init(_ result: Result<Data, Failure>) { self.result = result }
    func reconnectProof() async throws -> Data { try result.get() }
}

struct OfflineReconnectTests {
    @Test("reconnect admits returned bytes through direct proof admission")
    func reconnectUsesDirectAdmission() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache")))

        #expect(await client.reconnect(using: TestReconnectTransport(.success(try GoldenVectorFixtureSupport.validAllowProof())), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))
        #expect(await client.reconnect(using: TestReconnectTransport(.success(try GoldenVectorFixtureSupport.validDenyProof())), now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
    }

    @Test("invalid, failed, repeated, and concurrent reconnects never weaken cached authority")
    func reconnectFailuresAndOrderingPreserveCache() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let client = OfflineEntitlementClient(configuration: try GoldenVectorFixtureSupport.configuration(cacheURL: directory.appendingPathComponent("proof.cache")))
        let allow = try GoldenVectorFixtureSupport.validAllowProof()
        let deny = try GoldenVectorFixtureSupport.validDenyProof()
        #expect(await client.reconnect(using: TestReconnectTransport(.success(allow)), now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))

        #expect(await client.reconnect(using: TestReconnectTransport(.success(Data("malformed".utf8))), now: GoldenVectorFixtureSupport.now) == .invalid(reason: .malformed, nextAction: .reconnectRequired))
        #expect(await client.reconnect(using: TestReconnectTransport(.failure(.unavailable)), now: GoldenVectorFixtureSupport.now) == .invalid(reason: .reconnectFailed, nextAction: .reconnectRequired))
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .fresh(reason: .ok, nextAction: .none))

        async let first = client.reconnect(using: TestReconnectTransport(.success(allow)), now: GoldenVectorFixtureSupport.now)
        async let second = client.reconnect(using: TestReconnectTransport(.success(deny)), now: GoldenVectorFixtureSupport.now)
        _ = await (first, second)
        #expect(client.loadCachedState(now: GoldenVectorFixtureSupport.now) == .denied(reason: .signedDenial, nextAction: .reconnectRequired))
        #expect(await client.reconnect(using: TestReconnectTransport(.success(allow)), now: GoldenVectorFixtureSupport.now) == .invalid(reason: .superseded, nextAction: .reconnectRequired))
    }
}
