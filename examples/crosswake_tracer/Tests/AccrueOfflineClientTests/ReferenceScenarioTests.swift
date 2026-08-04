import Testing
import Foundation

struct ReferenceScenarioTests {
    @Test("shared scenario remains a client-safe fixture and does not promote feasibility")
    func referenceScenarioRemainsBounded() throws {
        let tracerRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let projectRoot = tracerRoot.deletingLastPathComponent().deletingLastPathComponent()
        let fixture = projectRoot.appendingPathComponent("accrue/priv/entitlements/v1.59-reference-scenarios.json")
        let report = tracerRoot.appendingPathComponent("capability-report.json")
        let object = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: fixture)) as? [String: Any])
        let scenarios = try #require(object["scenarios"] as? [[String: Any]])
        let scenario = try #require(scenarios.first { ($0["id"] as? String) == "apple_purchase_to_web_login" })
        #expect(scenario["evidence_lane"] as? String == "deterministic_conformance")
        let stripe = try #require(scenarios.first { ($0["id"] as? String) == "stripe_purchase_to_ios_login" })
        #expect(stripe["evidence_lane"] as? String == "deterministic_conformance")
        let runtime = try #require(scenarios.first { ($0["id"] as? String) == "crosswake_runtime_capability" })
        #expect(runtime["evidence_lane"] as? String == "runtime_capability")
        let reportObject = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: report)) as? [String: Any])
        #expect(reportObject["overall_status"] as? String == "feasibility_blocked")
    }
}
