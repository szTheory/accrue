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
        let actions = try #require(scenario["actions"] as? [[String: Any]])
        let purchase = try #require(actions.first)
        let command = try #require(purchase["command"] as? [String: Any])
        let payload = try #require(command["payload"] as? [String: Any])
        let transition = try #require(purchase["expected_transition"] as? [String: Any])
        let result = try #require(transition["result"] as? [String: Any])
        #expect(command["kind"] as? String == purchase["kind"] as? String)
        #expect(payload["rail"] as? String == "apple")
        #expect(result["tag"] as? String == "executed")
        #expect((transition["cache"] as? [String: Any])?["disposition"] as? String == "preserve")
        let stripe = try #require(scenarios.first { ($0["id"] as? String) == "stripe_purchase_to_ios_login" })
        #expect(stripe["evidence_lane"] as? String == "deterministic_conformance")
        for scenarioID in ["stale_downloaded_study_continuity", "offline_reconnect", "device_replacement", "key_rotation"] {
            let vector = try #require(scenarios.first { ($0["id"] as? String) == scenarioID })
            let action = try #require((vector["actions"] as? [[String: Any]])?.first)
            let taggedCommand = try #require(action["command"] as? [String: Any])
            let expected = try #require(action["expected_transition"] as? [String: Any])
            #expect(taggedCommand["kind"] as? String == action["kind"] as? String)
            #expect(expected["result"] is [String: Any])
            #expect(expected["durable"] is [String: Any])
            #expect(expected["cache"] is [String: Any])
        }
        let runtime = try #require(scenarios.first { ($0["id"] as? String) == "crosswake_runtime_capability" })
        #expect(runtime["evidence_lane"] as? String == "runtime_capability")
        let reportObject = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: report)) as? [String: Any])
        #expect(reportObject["overall_status"] as? String == "feasibility_blocked")
    }
}
