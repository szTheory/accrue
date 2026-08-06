import CryptoKit
import Foundation
@testable import AccrueOfflineClientCore

enum GoldenVectorFixtureSupport {
    static func configuration(cacheURL: URL) throws -> OfflineEntitlementClient.Configuration {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let corpus = try Data(contentsOf: root.appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json"))
        let object = try JSONSerialization.jsonObject(with: corpus) as! [String: Any]
        let vector = (object["vectors"] as! [[String: Any]]).first { $0["id"] as? String == "valid_allow" }!
        let context = vector["verification_context"] as! [String: Any]
        let key = SymmetricKey(data: Data(repeating: 7, count: 32))
        return OfflineEntitlementClient.Configuration(
            issuer: context["issuer"] as! String,
            audience: context["audience"] as! String,
            accountSubject: context["account_subject"] as! String,
            deviceThumbprint: context["device_thumbprint"] as! String,
            publicJWKS: try JSONSerialization.data(withJSONObject: object["public_jwks"]!),
            cacheURL: cacheURL,
            cacheAuthenticationKey: key
        )
    }

    static func validAllowProof() throws -> Data {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let corpus = try Data(contentsOf: root.appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json"))
        let object = try JSONSerialization.jsonObject(with: corpus) as! [String: Any]
        let vector = (object["vectors"] as! [[String: Any]]).first { $0["id"] as? String == "valid_allow" }!
        return Data((vector["compact_jws"] as! String).utf8)
    }

    static let now = Date(timeIntervalSince1970: 1_700_000_001)
}
