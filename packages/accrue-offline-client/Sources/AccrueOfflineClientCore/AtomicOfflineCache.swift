import CryptoKit
import Foundation

/// The authenticated persistence boundary. It deliberately accepts only the verifier's
/// file-private admission value, never caller-selected cache metadata.
struct AtomicOfflineCache: Sendable {
    private let url: URL
    private let key: SymmetricKey

    init(url: URL, key: SymmetricKey) {
        self.url = url.standardizedFileURL
        self.key = key
    }

    func replace(_ proof: VerifiedOfflineProof) throws {
        let unsigned = UnsignedEnvelope(
            version: 1,
            proof: proof.compactProof.base64EncodedString(),
            revision: proof.revision,
            issuedAt: proof.issuedAt,
            freshUntil: proof.freshUntil,
            disposition: proof.disposition
        )
        let tag = Data(HMAC<SHA256>.authenticationCode(for: try canonicalBytes(unsigned), using: key))
        let envelope = Envelope(unsigned: unsigned, tag: tag.base64EncodedString())
        let candidate = url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).candidate.\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: candidate) }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(envelope).write(to: candidate, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: candidate)
        } else {
            try FileManager.default.moveItem(at: candidate, to: url)
        }
    }

    func recoverProof() throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let raw = try Data(contentsOf: url)
        guard let object = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
              Set(object.keys) == Set(["version", "compact_proof", "revision", "iat", "fresh_until", "disposition", "authentication_tag"])
        else { throw CacheError.malformed }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: raw) }
        catch { throw CacheError.malformed }
        let unsigned = UnsignedEnvelope(version: envelope.version, proof: envelope.proof, revision: envelope.revision, issuedAt: envelope.issuedAt, freshUntil: envelope.freshUntil, disposition: envelope.disposition)
        guard envelope.version == 1,
              let proof = Data(base64Encoded: envelope.proof),
              let tag = Data(base64Encoded: envelope.tag),
              tag == Data(HMAC<SHA256>.authenticationCode(for: try canonicalBytes(unsigned), using: key))
        else { throw CacheError.authentication }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard try encoder.encode(envelope) == raw else { throw CacheError.malformed }
        return proof
    }

    private func canonicalBytes(_ value: UnsignedEnvelope) throws -> Data {
        var bytes = Data("accrue.offline.cache.v1".utf8)
        for field in [String(value.version), url.path, value.proof, String(value.revision), String(value.issuedAt), String(value.freshUntil), value.disposition] {
            let data = Data(field.utf8)
            var length = UInt64(data.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }
            bytes.append(data)
        }
        return bytes
    }

    private enum CacheError: Error { case authentication, malformed }
    private struct UnsignedEnvelope: Codable {
        let version: Int; let proof: String; let revision: Int64; let issuedAt: Int64; let freshUntil: Int64; let disposition: String
        enum CodingKeys: String, CodingKey { case version, proof = "compact_proof", revision, issuedAt = "iat", freshUntil = "fresh_until", disposition }
    }
    private struct Envelope: Codable {
        let version: Int; let proof: String; let revision: Int64; let issuedAt: Int64; let freshUntil: Int64; let disposition: String; let tag: String
        init(unsigned: UnsignedEnvelope, tag: String) { version = unsigned.version; proof = unsigned.proof; revision = unsigned.revision; issuedAt = unsigned.issuedAt; freshUntil = unsigned.freshUntil; disposition = unsigned.disposition; self.tag = tag }
        enum CodingKeys: String, CodingKey { case version, proof = "compact_proof", revision, issuedAt = "iat", freshUntil = "fresh_until", disposition, tag = "authentication_tag" }
    }
}
