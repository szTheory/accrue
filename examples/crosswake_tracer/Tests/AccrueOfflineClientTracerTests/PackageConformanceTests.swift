import Testing
@testable import AccrueOfflineClient

struct PackageConformanceTests {
    @Test("tracer consumes the standalone offline-client facade")
    func importsOfflineClientFacade() {
        _ = OfflineEntitlementClient.Configuration.self
        _ = CrosswakeTracerConformance.self
    }
}
