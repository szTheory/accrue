import Testing
@testable import AccrueOfflineClient

struct CapabilityReportTests {
    @Test("all required capability rows proven produce a proven report")
    func allProvenProducesProvenReport() {
        let report = CapabilityReport(
            schemaVersion: "1.0",
            capabilities: Capability.allRequired.map {
                CapabilityEvidence(
                    capability: $0,
                    status: .proven,
                    kind: .nativeCompileUnit,
                    location: "test://native"
                )
            }
        )

        #expect(report.overallStatus == .proven)
    }

    @Test("missing bridge or device evidence fails feasibility closed")
    func missingEvidenceBlocksFeasibility() {
        for failure in [
            Capability.crosswakeShellTransport,
            Capability.storeKitPurchase,
            Capability.secureEnclaveKey,
            Capability.atomicVerifiedReplacement
        ] {
            var evidence = Capability.allRequired.map {
                CapabilityEvidence(
                    capability: $0,
                    status: .proven,
                    kind: .nativeCompileUnit,
                    location: "test://native"
                )
            }
            evidence[evidence.firstIndex(where: { $0.capability == failure })!].status = .feasibilityBlocked

            #expect(CapabilityReport(schemaVersion: "1.0", capabilities: evidence).overallStatus == .feasibilityBlocked)
        }
    }

    @Test("capability rows preserve the D-10 order and evidence lanes")
    func preservesCapabilityOrderAndEvidenceKinds() {
        let report = CapabilityReport(
            schemaVersion: "1.0",
            capabilities: [
                CapabilityEvidence(capability: .networkCoalescing, status: .proven, kind: .physicalDevice, location: "device"),
                CapabilityEvidence(capability: .storeKitPurchase, status: .proven, kind: .crosswakeBridgeCompileUnit, location: "bridge"),
                CapabilityEvidence(capability: .authenticatedHostTransport, status: .proven, kind: .simulatorAdvisory, location: "simulator"),
                CapabilityEvidence(capability: .durableLocalState, status: .proven, kind: .nativeCompileUnit, location: "native")
            ]
        )

        #expect(report.capabilities.map(\.capability) == [
            .authenticatedHostTransport,
            .storeKitPurchase,
            .durableLocalState,
            .networkCoalescing
        ])
        #expect(Set(report.capabilities.map(\.kind)) == [
            .nativeCompileUnit,
            .crosswakeBridgeCompileUnit,
            .simulatorAdvisory,
            .physicalDevice
        ])
    }
}
