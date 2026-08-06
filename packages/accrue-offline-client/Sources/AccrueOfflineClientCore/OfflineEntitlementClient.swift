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
        public let issuer: String; public let audience: String; public let accountSubject: String; public let deviceThumbprint: String; public let publicJWKS: Data; public let cacheURL: URL; public let cacheAuthenticationKey: SymmetricKey; public let clockHighWater: Date?
        public init(issuer: String, audience: String, accountSubject: String, deviceThumbprint: String, publicJWKS: Data, cacheURL: URL, cacheAuthenticationKey: SymmetricKey, clockHighWater: Date? = nil) {
            self.issuer = issuer; self.audience = audience; self.accountSubject = accountSubject; self.deviceThumbprint = deviceThumbprint; self.publicJWKS = publicJWKS; self.cacheURL = cacheURL; self.cacheAuthenticationKey = cacheAuthenticationKey; self.clockHighWater = clockHighWater
        }
    }

    private let configuration: Configuration
    private let cache: AtomicOfflineCache

    public init(configuration: Configuration) { self.configuration = configuration; cache = AtomicOfflineCache(url: configuration.cacheURL, key: configuration.cacheAuthenticationKey) }

    public func applyServerProof(_ proof: Data, now: Date) -> OfflineEntitlementState {
        guard !proof.isEmpty else { return invalid(.malformed) }
        do {
            let verified = try verify(proof, now: now)
            switch try cache.replace(verified, observedAt: timestamp(now), minimumObservedAt: configuration.clockHighWater.map(timestamp)) {
            case .replaced, .identical: break
            case .superseded: return invalid(.superseded)
            }
            return state(for: verified, now: now)
        } catch AtomicOfflineCache.ObservationError.clockRollback { return invalid(.clockRollback) }
        catch let error as VerificationError { return invalid(error.reason) }
        catch { return invalid(.cacheWriteFailed) }
    }

    public func loadCachedState(now: Date) -> OfflineEntitlementState {
        do {
            guard let proof = try cache.recoverProof() else { return invalid(.malformed) }
            let verified = try verify(proof, now: now)
            try cache.observe(verified, at: timestamp(now), minimumObservedAt: configuration.clockHighWater.map(timestamp))
            return state(for: verified, now: now)
        } catch AtomicOfflineCache.ObservationError.clockRollback { return invalid(.clockRollback) }
        catch let error as VerificationError { return invalid(error.reason) }
        catch { return invalid(.cacheRecoveryFailed) }
    }

    private func invalid(_ reason: OfflineEntitlementReason) -> OfflineEntitlementState { .invalid(reason: reason, nextAction: .reconnectRequired) }
    private func timestamp(_ date: Date) -> Int64 { Int64(date.timeIntervalSince1970) }
    private func state(for proof: VerifiedOfflineProof, now: Date) -> OfflineEntitlementState {
        if proof.disposition == "deny" { return .denied(reason: .signedDenial, nextAction: .reconnectRequired) }
        if Date(timeIntervalSince1970: TimeInterval(proof.freshUntil)) > now { return .fresh(reason: .ok, nextAction: .none) }
        return .staleOffline(reason: .revalidationDue, nextAction: .reconnectRequired)
    }

    private func verify(_ compactBytes: Data, now: Date) throws -> VerifiedOfflineProof {
        guard let compact = String(data: compactBytes, encoding: .utf8) else { throw VerificationError(.malformed) }
        let parts = compact.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, let headerData = Data(base64URL: String(parts[0])), let payloadData = Data(base64URL: String(parts[1])), let signature = Data(base64URL: String(parts[2])), signature.count == 64 else { throw VerificationError(.malformed) }
        do { try CanonicalJSONAdmission.validate(headerData); try CanonicalJSONAdmission.validate(payloadData) }
        catch { throw VerificationError(.malformed) }
        guard let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any], Set(header.keys) == ["alg", "typ", "kid"] else { throw VerificationError(.malformed) }
        guard header["alg"] as? String == "ES256" else { throw VerificationError(.wrongAlgorithm) }
        guard header["typ"] as? String == "accrue-entitlement-proof+jwt" else { throw VerificationError(.wrongType) }
        guard let kid = boundedString(header["kid"], maximum: 256), let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else { throw VerificationError(.malformed) }
        let key = try publicKey(kid: kid)
        guard let parsedSignature = try? P256.Signing.ECDSASignature(rawRepresentation: signature), key.isValidSignature(parsedSignature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw VerificationError(.malformed) }
        guard payload["iss"] as? String == configuration.issuer else { throw VerificationError(.wrongIssuer) }
        guard payload["aud"] as? String == configuration.audience else { throw VerificationError(.wrongAudience) }
        guard boundedString(payload["jti"], maximum: 256) != nil else { throw VerificationError(.malformed) }
        guard boundedString(payload["sub"], maximum: 256) == configuration.accountSubject else { throw VerificationError(.deviceMismatch) }
        guard let cnf = payload["cnf"] as? [String: Any], Set(cnf.keys) == ["jkt"], let jkt = boundedString(cnf["jkt"], maximum: 256) else { throw VerificationError(.malformed) }
        guard jkt == configuration.deviceThumbprint else { throw VerificationError(.deviceMismatch) }
        let common: Set<String> = ["version", "iss", "aud", "jti", "sub", "cnf", "revision", "iat", "nbf", "fresh_until", "exp", "disposition", "plans", "features", "quantities"]
        guard payload["version"] as? String == "v1.59", let disposition = payload["disposition"] as? String, ["allow", "deny"].contains(disposition), Set(payload.keys) == (disposition == "deny" ? common.union(["denial_reason"]) : common), let revision = integer(payload["revision"]), revision >= 0, let iat = integer(payload["iat"]), iat >= 0, let nbf = integer(payload["nbf"]), nbf >= iat, let freshUntil = integer(payload["fresh_until"]), freshUntil >= nbf, let exp = integer(payload["exp"]), exp >= freshUntil else { throw VerificationError(.malformed) }
        guard validStrings(payload["plans"]), validStrings(payload["features"]), validQuantities(payload["quantities"]) else { throw VerificationError(.malformed) }
        let plans = payload["plans"] as! [String]; let features = payload["features"] as! [String]; let quantities = payload["quantities"] as! [String: Any]
        if disposition == "allow" { guard plans.isEmpty == false || features.isEmpty == false || quantities.isEmpty == false else { throw VerificationError(.malformed) } }
        else { guard let reason = boundedString(payload["denial_reason"], maximum: 64), ["signed_denial", "access_unavailable", "superseded", "device_revoked"].contains(reason) else { throw VerificationError(.malformed) } }
        let timestamp = timestamp(now)
        guard configuration.clockHighWater.map({ timestamp >= Int64($0.timeIntervalSince1970) }) ?? true else { throw VerificationError(.clockRollback) }
        guard nbf <= timestamp else { throw VerificationError(.malformed) }
        guard timestamp < exp else { throw VerificationError(.hardExpired) }
        return VerifiedOfflineProof(compactProof: compactBytes, highWater: ProofHighWater(revision: revision, issuedAt: iat, freshUntil: freshUntil, disposition: disposition))
    }

    private func boundedString(_ value: Any?, maximum: Int) -> String? { guard let string = value as? String, !string.isEmpty, string.utf8.count <= maximum else { return nil }; return string }
    private func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue; guard double.isFinite, double.rounded(.towardZero) == double, double >= Double(Int64.min), double <= Double(Int64.max) else { return nil }; return number.int64Value
    }
    private func validStrings(_ value: Any?) -> Bool {
        guard let values = value as? [Any], values.count <= 100 else { return false }; let strings = values.compactMap { boundedString($0, maximum: 256) }; return strings.count == values.count && strings == strings.sorted() && Set(strings).count == strings.count
    }
    private func validQuantities(_ value: Any?) -> Bool {
        guard let values = value as? [String: Any], values.count <= 100 else { return false }
        return values.allSatisfy { boundedString($0.key, maximum: 256) != nil && (integer($0.value) ?? 0) > 0 }
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
struct VerifiedOfflineProof: Sendable { let compactProof: Data; let highWater: ProofHighWater; var disposition: String { highWater.disposition }; var freshUntil: Int64 { highWater.freshUntil } }
private struct VerificationError: Error { let reason: OfflineEntitlementReason; init(_ reason: OfflineEntitlementReason) { self.reason = reason } }
private extension Data { init?(base64URL value: String) { var base64 = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/"); base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4); self.init(base64Encoded: base64) } }
