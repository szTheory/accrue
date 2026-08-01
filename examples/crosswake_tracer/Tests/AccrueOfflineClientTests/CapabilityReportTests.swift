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
                    evidenceKinds: $0.requiredEvidenceKinds,
                    location: "test://native"
                )
            }
        )

        #expect(report.overallStatus == .proven)
    }

    @Test("missing bridge or device evidence fails feasibility closed")
    func missingEvidenceBlocksFeasibility() {
        for failure in [
            Capability.authenticatedHostTransport,
            Capability.storeKitPurchase,
            Capability.secureEnclaveKey,
            Capability.atomicVerifiedReplacement
        ] {
            var evidence = Capability.allRequired.map {
                CapabilityEvidence(
                    capability: $0,
                    status: .proven,
                    evidenceKinds: $0.requiredEvidenceKinds,
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
                CapabilityEvidence(capability: .networkCoalescing, status: .proven, evidenceKinds: [.crosswakeBridgeCompileUnit, .simulatorAdvisory], location: "simulator"),
                CapabilityEvidence(capability: .storeKitPurchase, status: .proven, evidenceKinds: [.crosswakeBridgeCompileUnit], location: "bridge"),
                CapabilityEvidence(capability: .authenticatedHostTransport, status: .proven, evidenceKinds: [.crosswakeBridgeCompileUnit, .physicalDevice], location: "device"),
                CapabilityEvidence(capability: .durableLocalState, status: .proven, evidenceKinds: [.nativeCompileUnit], location: "native")
            ]
        )

        #expect(report.capabilities.map(\.capability) == [
            .authenticatedHostTransport,
            .storeKitPurchase,
            .durableLocalState,
            .networkCoalescing
        ])
        #expect(Set(report.capabilities.flatMap(\.evidenceKinds)) == [
            .nativeCompileUnit,
            .crosswakeBridgeCompileUnit,
            .simulatorAdvisory,
            .physicalDevice
        ])
    }
}
