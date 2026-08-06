import CryptoKit
import Foundation
@testable import AccrueOfflineClientCore

enum GoldenVectorFixtureSupport {
    struct Vector {
        let id: String
        let proof: Data
        let now: Date
        let expected: OfflineEntitlementState
    }

    static let now = Date(timeIntervalSince1970: 1_700_000_001)

    static func configuration(cacheURL: URL, jwks: Data? = nil) throws -> OfflineEntitlementClient.Configuration {
        try configuration(cacheURL: cacheURL, vectorID: "valid_allow", jwks: jwks)
    }
    static func configuration(cacheURL: URL, vectorID: String, jwks: Data? = nil) throws -> OfflineEntitlementClient.Configuration {
        let context = try rawVector(vectorID)["verification_context"] as! [String: Any]
        let suppliedJWKS: Data
        if let jwks { suppliedJWKS = jwks }
        else if (context["public_keys"] as? [Any])?.isEmpty == true { suppliedJWKS = try JSONSerialization.data(withJSONObject: ["keys": []]) }
        else { suppliedJWKS = try publicJWKS() }
        let clock = ((context["clock_high_water"] as? [String: Any])?["now"] as? Int64).map { Date(timeIntervalSince1970: TimeInterval($0)) }
        return OfflineEntitlementClient.Configuration(
            issuer: context["issuer"] as! String,
            audience: context["audience"] as! String,
            accountSubject: context["account_subject"] as! String,
            deviceThumbprint: context["device_thumbprint"] as! String,
            publicJWKS: suppliedJWKS,
            cacheURL: cacheURL,
            cacheAuthenticationKey: SymmetricKey(data: Data(repeating: 7, count: 32)),
            clockHighWater: clock
        )
    }

    static func vectors() throws -> [Vector] {
        try corpusVectors().map { value in
            Vector(
                id: value["id"] as! String,
                proof: Data((value["compact_jws"] as! String).utf8),
                now: Date(timeIntervalSince1970: TimeInterval((value["verification_context"] as! [String: Any])["now"] as! Int64)),
                expected: state(value["expected_state"] as! String, reason: value["expected_reason"] as! String, action: value["expected_next_action"] as! String)
            )
        }
    }

    static func validAllowProof() throws -> Data { try proof("valid_allow") }
    static func validDenyProof() throws -> Data { try proof("valid_signed_denial") }
    static func proof(_ id: String) throws -> Data { Data((try rawVector(id)["compact_jws"] as! String).utf8) }
    static func context(for id: String) -> [String: Any] { try! rawVector(id)["verification_context"] as! [String: Any] }
    static func publicJWKS() throws -> Data { try JSONSerialization.data(withJSONObject: corpus()["public_jwks"]!) }

    /// Test-only signer: production targets never load this private JWK or repository fixture.
    static func signedMutation(_ transform: (inout [String: Any], inout [String: Any]) -> Void) throws -> Data {
        let compact = String(data: try validAllowProof(), encoding: .utf8)!
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        var header = try JSONSerialization.jsonObject(with: Data(base64URL: parts[0])!) as! [String: Any]
        var claims = try JSONSerialization.jsonObject(with: Data(base64URL: parts[1])!) as! [String: Any]
        transform(&header, &claims)
        let headerPart = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys]).base64URL
        let payloadPart = try JSONSerialization.data(withJSONObject: claims, options: [.sortedKeys]).base64URL
        let key = try JSONSerialization.jsonObject(with: try Data(contentsOf: root().appendingPathComponent("accrue/priv/entitlements/v1.59-offline-test-key.jwk.json"))) as! [String: Any]
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: Data(base64URL: key["d"] as! String)!)
        let input = "\(headerPart).\(payloadPart)"
        return Data("\(input).\(try privateKey.signature(for: Data(input.utf8)).rawRepresentation.base64URL)".utf8)
    }
    static func signedRaw(header: String? = nil, payload: String? = nil) throws -> Data {
        let compact = String(data: try validAllowProof(), encoding: .utf8)!
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let rawHeader = header ?? String(data: Data(base64URL: parts[0])!, encoding: .utf8)!
        let rawPayload = payload ?? String(data: Data(base64URL: parts[1])!, encoding: .utf8)!
        let key = try JSONSerialization.jsonObject(with: try Data(contentsOf: root().appendingPathComponent("accrue/priv/entitlements/v1.59-offline-test-key.jwk.json"))) as! [String: Any]
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: Data(base64URL: key["d"] as! String)!)
        let input = "\(Data(rawHeader.utf8).base64URL).\(Data(rawPayload.utf8).base64URL)"
        return Data("\(input).\(try privateKey.signature(for: Data(input.utf8)).rawRepresentation.base64URL)".utf8)
    }
    static func signedPrior(revision: Int64, iat: Int64, freshUntil: Int64, disposition: String) throws -> Data {
        try signedMutation { _, claims in
            claims["revision"] = revision; claims["iat"] = iat; claims["nbf"] = iat; claims["fresh_until"] = max(freshUntil, iat); claims["disposition"] = disposition
            if disposition == "deny" { claims["denial_reason"] = "access_unavailable"; claims["plans"] = []; claims["features"] = []; claims["quantities"] = [:] }
        }
    }

    private static func state(_ name: String, reason: String, action: String) -> OfflineEntitlementState {
        let reason = OfflineEntitlementReason(rawValue: reason)!
        let action = OfflineNextAction(rawValue: action)!
        switch name {
        case "fresh": return .fresh(reason: reason, nextAction: action)
        case "stale_offline": return .staleOffline(reason: reason, nextAction: action)
        case "denied": return .denied(reason: reason, nextAction: action)
        default: return .invalid(reason: reason, nextAction: action)
        }
    }
    private static func rawVector(_ id: String) throws -> [String: Any] { try corpusVectors().first { $0["id"] as? String == id }! }
    private static func corpusVectors() throws -> [[String: Any]] { try corpus()["vectors"] as! [[String: Any]] }
    private static func corpus() throws -> [String: Any] { try JSONSerialization.jsonObject(with: Data(contentsOf: root().appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json"))) as! [String: Any] }
    private static func root() -> URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
}

private extension Data {
    init?(base64URL value: String) { var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"); base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4); self.init(base64Encoded: base64) }
    var base64URL: String { base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "") }
}
