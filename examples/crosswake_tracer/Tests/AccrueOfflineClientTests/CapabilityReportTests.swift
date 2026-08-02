import Testing
import Foundation
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

    @Test("unsupported public capability report schemas fail feasibility closed")
    func unsupportedSchemaBlocksOtherwiseProvenReport() {
        let evidence = Capability.allRequired.map {
            CapabilityEvidence(
                capability: $0,
                status: .proven,
                evidenceKinds: $0.requiredEvidenceKinds,
                location: "test://native"
            )
        }

        #expect(CapabilityReport(schemaVersion: "2.0", capabilities: evidence).overallStatus == .feasibilityBlocked)
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

    @Test("checked-in capability report remains feasibility blocked without bridge and device evidence")
    func checkedInCapabilityReportRemainsBlocked() throws {
        let reportURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("capability-report.json")
        let report = try JSONDecoder().decode(CheckedInReport.self, from: Data(contentsOf: reportURL))
        #expect(report.overallStatus == "feasibility_blocked")
        #expect(report.capabilities.allSatisfy { $0.status == "feasibility_blocked" })
        #expect(try CheckedInCapabilityReportValidator.validate(Data(contentsOf: reportURL)) == .feasibilityBlocked)
    }

    @Test("checked-in report rejects duplicate, mixed, and false-proven capability states")
    func checkedInReportValidatorRejectsIncoherentStates() throws {
        let reportURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("capability-report.json")
        let source = try Data(contentsOf: reportURL)
        var object = try #require(JSONSerialization.jsonObject(with: source) as? [String: Any])
        var rows = try #require(object["capabilities"] as? [[String: Any]])
        rows[1]["capability"] = rows[0]["capability"]
        object["capabilities"] = rows
        #expect(throws: CheckedInCapabilityReportValidator.ValidationError.self) {
            try CheckedInCapabilityReportValidator.validate(JSONSerialization.data(withJSONObject: object))
        }
    }

    private struct CheckedInReport: Decodable {
        let overallStatus: String
        let capabilities: [Row]
        enum CodingKeys: String, CodingKey { case overallStatus = "overall_status", capabilities }
        struct Row: Decodable { let status: String }
    }
}
