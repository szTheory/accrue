import Testing
import Foundation
@testable import AccrueOfflineClient

struct CapabilityReportTests {
    @Test("caller-supplied evidence cannot prove feasibility at arbitrary locations")
    func callerSuppliedEvidenceRemainsBlockedAtArbitraryLocations() {
        let arbitraryLocations = [
            "test://native",
            "missing/proof.json",
            "/tmp/untrusted-proof.json",
            "../outside-report-root/proof.json"
        ]

        for location in arbitraryLocations {
            let report = CapabilityReport(
                schemaVersion: "1.0",
                capabilities: Capability.allRequired.map {
                    CapabilityEvidence(
                        capability: $0,
                        status: .proven,
                        evidenceKinds: $0.requiredEvidenceKinds,
                        location: location
                    )
                }
            )

            #expect(report.overallStatus == .feasibilityBlocked, "caller location \\(location) must not establish provenance")
        }
    }

    @Test("decoded caller capability reports cannot assert proven feasibility")
    func decodedCallerSuppliedEvidenceRemainsBlocked() throws {
        let callerReport = CapabilityReport(
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
        var object = try reportObject(try JSONEncoder().encode(callerReport))
        object["overallStatus"] = "proven"

        let decoded = try JSONDecoder().decode(
            CapabilityReport.self,
            from: try JSONSerialization.data(withJSONObject: object)
        )

        #expect(decoded.overallStatus == .feasibilityBlocked)
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
        #expect(try CheckedInCapabilityReportValidator.validate(reportURL: reportURL) == .feasibilityBlocked)
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
            try CheckedInCapabilityReportValidator.validate(JSONSerialization.data(withJSONObject: object), reportURL: reportURL)
        }
    }

    @Test("checked-in validator rejects false proof and terminal reason mutations")
    func checkedInValidatorRejectsFalseProofAndReasonMutations() throws {
        let source = try checkedInReportData()
        var allProven = try reportObject(source)
        allProven["overall_status"] = "proven"
        allProven["reason"] = "Completed proof for every required lane."
        allProven["capabilities"] = try rows(allProven).map { row in
            row.merging(["status": "proven"], uniquingKeysWith: { _, new in new })
        }
        #expect(throws: CheckedInCapabilityReportValidator.ValidationError.self) {
            try CheckedInCapabilityReportValidator.validate(try encoded(allProven), reportURL: reportURL())
        }

        var missingReason = try reportObject(source)
        missingReason.removeValue(forKey: "reason")
        #expect(throws: CheckedInCapabilityReportValidator.ValidationError.self) {
            try CheckedInCapabilityReportValidator.validate(try encoded(missingReason), reportURL: reportURL())
        }

        var proofReasonWhileBlocked = try reportObject(source)
        proofReasonWhileBlocked["reason"] = "Completed proof for every required lane."
        #expect(throws: CheckedInCapabilityReportValidator.ValidationError.self) {
            try CheckedInCapabilityReportValidator.validate(try encoded(proofReasonWhileBlocked), reportURL: reportURL())
        }
    }

    private func checkedInReportData() throws -> Data {
        try Data(contentsOf: reportURL())
    }

    private func reportURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("capability-report.json")
    }

    private func reportObject(_ data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func rows(_ object: [String: Any]) throws -> [[String: Any]] {
        try #require(object["capabilities"] as? [[String: Any]])
    }

    private func encoded(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private struct CheckedInReport: Decodable {
        let overallStatus: String
        let capabilities: [Row]
        enum CodingKeys: String, CodingKey { case overallStatus = "overall_status", capabilities }
        struct Row: Decodable { let status: String }
    }
}
