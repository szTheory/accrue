import CryptoKit
import Foundation

public enum OfflineEntitlementReason: String, Sendable, Equatable {
    case ok, signedDenial = "signed_denial", revalidationDue = "revalidation_due", clockRollback = "clock_rollback", deviceMismatch = "device_mismatch", hardExpired = "hard_expired", malformed, superseded, unknownKey = "unknown_key", wrongAlgorithm = "wrong_algorithm", wrongAudience = "wrong_audience", wrongIssuer = "wrong_issuer", wrongType = "wrong_type", reconnectFailed = "reconnect_failed", cacheWriteFailed = "cache_write_failed", cacheRecoveryFailed = "cache_recovery_failed"
}

public enum OfflineNextAction: String, Sendable, Equatable { case none, reconnectRequired = "reconnect_required" }

/// The closed D-02 host-display seam. A state is semantic data, not local grant authority.
public enum OfflineEntitlementState: Sendable, Equatable {
    case fresh(reason: OfflineEntitlementReason, nextAction: OfflineNextAction)
    case staleOffline(reason: OfflineEntitlementReason, nextAction: OfflineNextAction)
    case denied(reason: OfflineEntitlementReason, nextAction: OfflineNextAction)
    case invalid(reason: OfflineEntitlementReason, nextAction: OfflineNextAction)
}

public struct OfflineEntitlementClient: Sendable {
    public struct Configuration: Sendable {
        public let issuer: String; public let audience: String; public let accountSubject: String; public let deviceThumbprint: String; public let publicJWKS: Data; public let cacheURL: URL; public let cacheAuthenticationKey: SymmetricKey
        public init(issuer: String, audience: String, accountSubject: String, deviceThumbprint: String, publicJWKS: Data, cacheURL: URL, cacheAuthenticationKey: SymmetricKey) {
            self.issuer = issuer; self.audience = audience; self.accountSubject = accountSubject; self.deviceThumbprint = deviceThumbprint; self.publicJWKS = publicJWKS; self.cacheURL = cacheURL; self.cacheAuthenticationKey = cacheAuthenticationKey
        }
    }

    private let configuration: Configuration
    private let cache: AtomicOfflineCache

    public init(configuration: Configuration) { self.configuration = configuration; cache = AtomicOfflineCache(url: configuration.cacheURL, key: configuration.cacheAuthenticationKey) }

    public func applyServerProof(_ proof: Data, now: Date) -> OfflineEntitlementState {
        guard !proof.isEmpty else { return invalid(.malformed) }
        do {
            let verified = try verify(proof, now: now)
            try cache.replace(verified)
            return state(for: verified, now: now)
        } catch let error as VerificationError { return invalid(error.reason) }
        catch { return invalid(.cacheWriteFailed) }
    }

    public func loadCachedState(now: Date) -> OfflineEntitlementState {
        do {
            guard let proof = try cache.recoverProof() else { return invalid(.malformed) }
            return state(for: try verify(proof, now: now), now: now)
        } catch let error as VerificationError { return invalid(error.reason) }
        catch { return invalid(.cacheRecoveryFailed) }
    }

    private func invalid(_ reason: OfflineEntitlementReason) -> OfflineEntitlementState { .invalid(reason: reason, nextAction: .reconnectRequired) }
    private func state(for proof: VerifiedOfflineProof, now: Date) -> OfflineEntitlementState {
        if proof.disposition == "deny" { return .denied(reason: .signedDenial, nextAction: .reconnectRequired) }
        if Date(timeIntervalSince1970: TimeInterval(proof.freshUntil)) > now { return .fresh(reason: .ok, nextAction: .none) }
        return .staleOffline(reason: .revalidationDue, nextAction: .reconnectRequired)
    }

    private func verify(_ compactBytes: Data, now: Date) throws -> VerifiedOfflineProof {
        guard let compact = String(data: compactBytes, encoding: .utf8) else { throw VerificationError(.malformed) }
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, let headerData = Data(base64URL: String(parts[0])), let payloadData = Data(base64URL: String(parts[1])), let signature = Data(base64URL: String(parts[2])), signature.count == 64 else { throw VerificationError(.malformed) }
        guard let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any], Set(header.keys) == ["alg", "typ", "kid"], header["alg"] as? String == "ES256" else { throw VerificationError(.wrongAlgorithm) }
        guard header["typ"] as? String == "accrue-entitlement-proof+jwt" else { throw VerificationError(.wrongType) }
        guard let kid = header["kid"] as? String, let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else { throw VerificationError(.malformed) }
        let key = try publicKey(kid: kid)
        guard let parsedSignature = try? P256.Signing.ECDSASignature(rawRepresentation: signature), key.isValidSignature(parsedSignature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw VerificationError(.malformed) }
        guard payload["iss"] as? String == configuration.issuer else { throw VerificationError(.wrongIssuer) }
        guard payload["aud"] as? String == configuration.audience else { throw VerificationError(.wrongAudience) }
        guard payload["sub"] as? String == configuration.accountSubject, ((payload["cnf"] as? [String: Any])?["jkt"] as? String) == configuration.deviceThumbprint else { throw VerificationError(.deviceMismatch) }
        guard payload["version"] as? String == "v1.59", let disposition = payload["disposition"] as? String, ["allow", "deny"].contains(disposition), let revision = payload["revision"] as? Int64, let iat = payload["iat"] as? Int64, let nbf = payload["nbf"] as? Int64, let freshUntil = payload["fresh_until"] as? Int64, let exp = payload["exp"] as? Int64 else { throw VerificationError(.malformed) }
        let timestamp = Int64(now.timeIntervalSince1970)
        guard nbf <= timestamp else { throw VerificationError(.malformed) }
        guard timestamp < exp else { throw VerificationError(.hardExpired) }
        return VerifiedOfflineProof(compactProof: compactBytes, revision: revision, issuedAt: iat, freshUntil: freshUntil, disposition: disposition)
    }

    private func publicKey(kid: String) throws -> P256.Signing.PublicKey {
        guard let object = try? JSONSerialization.jsonObject(with: configuration.publicJWKS) as? [String: Any], let keys = object["keys"] as? [[String: Any]], let jwk = keys.first(where: { $0["kid"] as? String == kid }), jwk["kty"] as? String == "EC", jwk["crv"] as? String == "P-256", jwk["alg"] as? String == "ES256", let x = jwk["x"] as? String, let y = jwk["y"] as? String, let xData = Data(base64URL: x), let yData = Data(base64URL: y), xData.count == 32, yData.count == 32 else { throw VerificationError(.unknownKey) }
        var point = Data([0x04]); point.append(xData); point.append(yData)
        guard let key = try? P256.Signing.PublicKey(x963Representation: point) else { throw VerificationError(.unknownKey) }
        return key
    }
}

/// Internal-only verifier admission value. Its memberwise initializer is unavailable
/// outside this module, so hosts cannot construct cache replacements.
struct VerifiedOfflineProof: Sendable { let compactProof: Data; let revision: Int64; let issuedAt: Int64; let freshUntil: Int64; let disposition: String }
private struct VerificationError: Error { let reason: OfflineEntitlementReason; init(_ reason: OfflineEntitlementReason) { self.reason = reason } }
private extension Data { init?(base64URL value: String) { var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"); base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4); self.init(base64Encoded: base64) } }
