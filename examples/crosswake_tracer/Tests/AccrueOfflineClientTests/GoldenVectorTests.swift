import Testing
@testable import AccrueOfflineClient

struct GoldenVectorTests {
    @Test("golden vectors are independently verified and converge on cache disposition")
    func goldenVectorsVerify() throws {
        let observations = try OfflineGoldenVectorVerifier.verifyFixture()

        #expect(observations.map(\.id) == observations.map(\.id).sorted())
        #expect(observations.contains { $0.id == "valid_allow" && $0.result == .accept })
        #expect(observations.contains { $0.id == "valid_signed_denial" && $0.cache == .deny })
        #expect(observations.allSatisfy { [.accept, .reject].contains($0.result) })
    }
}
