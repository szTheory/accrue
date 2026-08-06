import CryptoKit
import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// The sole durable authority boundary. Only verifier-created proofs cross it.
struct AtomicOfflineCache: @unchecked Sendable {
    enum Admission { case replaced, identical, superseded }
    enum FaultStage { case candidateWrite, candidateFileSync, atomicReplace, parentDirectorySync, authenticatedRecovery }
    private let url: URL
    private let key: SymmetricKey
    private let coordinator: CacheCoordinator
    private let fault: FaultStage?

    init(url: URL, key: SymmetricKey, fault: FaultStage? = nil) {
        self.url = url.standardizedFileURL
        self.key = key
        coordinator = CacheCoordinatorRegistry.shared.coordinator(for: self.url.path)
        self.fault = fault
    }

    func replace(_ proof: VerifiedOfflineProof) throws -> Admission {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return try coordinator.withLock {
            let prior = try priorState()
            if case let .authenticated(persisted) = prior {
                if persisted.highWater == proof.highWater { return .identical }
                guard persisted.highWater.accepts(newer: proof.highWater) else { return .superseded }
            }
            let candidate = uniqueCandidateURL()
            let backup = uniqueBackupURL()
            let quarantine = uniqueQuarantineURL()
            defer { try? FileManager.default.removeItem(at: candidate) }
            if case .invalid = prior { try FileManager.default.moveItem(at: url, to: quarantine) }
            if case .authenticated = prior { try FileManager.default.copyItem(at: url, to: backup) }
            do {
            try fail(.candidateWrite); try encodedReplacement(proof).write(to: candidate)
            let handle = try FileHandle(forWritingTo: candidate)
            defer { try? handle.close() }
            try fail(.candidateFileSync); try handle.synchronize()
            try fail(.atomicReplace)
            if FileManager.default.fileExists(atPath: url.path) { _ = try FileManager.default.replaceItemAt(url, withItemAt: candidate) }
            else { try FileManager.default.moveItem(at: candidate, to: url) }
            try fail(.parentDirectorySync); try synchronizeParentDirectory()
            try? FileManager.default.removeItem(at: backup); try? FileManager.default.removeItem(at: quarantine)
            coordinator.record(proof.highWater)
            return .replaced
            } catch {
                if case .authenticated = prior {
                    do { try fail(.authenticatedRecovery); if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }; try FileManager.default.moveItem(at: backup, to: url); try synchronizeParentDirectory() } catch { }
                } else if case .invalid = prior, !FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.moveItem(at: quarantine, to: url) }
                throw error
            }
        }
    }

    func recoverProof() throws -> Data? {
        try coordinator.withLock {
            guard case let .authenticated(envelope) = try priorState() else { return nil }
            return envelope.compactProof
        }
    }

    private func encodedReplacement(_ proof: VerifiedOfflineProof) throws -> Data {
        let unsigned = UnsignedEnvelope(version: 2, compactProof: proof.compactProof.base64EncodedString(), revision: proof.highWater.revision, disposition: proof.highWater.disposition, issuedAt: proof.highWater.issuedAt, freshUntil: proof.highWater.freshUntil)
        let tag = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: key)).base64EncodedString()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(unsigned: unsigned, authenticationTag: tag))
    }

    private func loadVerifiedEnvelope() throws -> RecoveredEnvelope? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let raw = try Data(contentsOf: url)
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: raw), envelope.version == 2,
              let proof = Data(base64Encoded: envelope.compactProof), let tag = Data(base64Encoded: envelope.authenticationTag) else { throw CacheError.malformed }
        let unsigned = UnsignedEnvelope(version: envelope.version, compactProof: envelope.compactProof, revision: envelope.revision, disposition: envelope.disposition, issuedAt: envelope.issuedAt, freshUntil: envelope.freshUntil)
        let expected = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: key))
        guard tag == expected else { throw CacheError.authentication }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        guard try encoder.encode(envelope) == raw else { throw CacheError.malformed }
        return RecoveredEnvelope(compactProof: proof, highWater: ProofHighWater(revision: envelope.revision, issuedAt: envelope.issuedAt, freshUntil: envelope.freshUntil, disposition: envelope.disposition))
    }
    private enum PriorState { case absent, authenticated(RecoveredEnvelope), invalid }
    private func priorState() throws -> PriorState {
        guard FileManager.default.fileExists(atPath: url.path) else { return .absent }
        do { return .authenticated(try loadVerifiedEnvelope()!) } catch { return .invalid }
    }
    private func fail(_ stage: FaultStage) throws { if fault == stage { throw CacheError.injected } }

    private func signedBytes(_ value: UnsignedEnvelope) throws -> Data {
        var bytes = Data("accrue.atomic-offline-cache".utf8)
        for item in [String(value.version), url.path, value.compactProof, String(value.revision), value.disposition, String(value.issuedAt), String(value.freshUntil)] {
            let data = Data(item.utf8); var length = UInt64(data.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }; bytes.append(data)
        }
        return bytes
    }

    private func abandonedCandidateURLs() throws -> [URL] {
        let prefix = ".\(url.lastPathComponent).candidate."
        return try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil).filter { $0.lastPathComponent.hasPrefix(prefix) }
    }
    private func uniqueCandidateURL() -> URL { url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).candidate.\(UUID().uuidString)") }
    private func uniqueBackupURL() -> URL { url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).backup.\(UUID().uuidString)") }
    private func uniqueQuarantineURL() -> URL { url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).quarantine.\(UUID().uuidString)") }
    private func synchronizeParentDirectory() throws {
        let descriptor = open(url.deletingLastPathComponent().path, O_RDONLY)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { _ = close(descriptor) }
        // Darwin/APFS may not support directory fsync; replacement is still atomic.
        if fsync(descriptor) != 0, errno != EINVAL, errno != ENOTSUP, errno != EOPNOTSUPP { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }

    private enum CacheError: Error { case authentication, malformed, injected }
    private struct RecoveredEnvelope { let compactProof: Data; let highWater: ProofHighWater }
    private struct UnsignedEnvelope: Codable { let version: Int; let compactProof: String; let revision: Int64; let disposition: String; let issuedAt: Int64; let freshUntil: Int64; enum CodingKeys: String, CodingKey { case version, revision, disposition; case compactProof = "compact_proof"; case issuedAt = "iat"; case freshUntil = "fresh_until" } }
    private struct Envelope: Codable { let version: Int; let compactProof: String; let revision: Int64; let disposition: String; let issuedAt: Int64; let freshUntil: Int64; let authenticationTag: String; init(unsigned: UnsignedEnvelope, authenticationTag: String) { version = unsigned.version; compactProof = unsigned.compactProof; revision = unsigned.revision; disposition = unsigned.disposition; issuedAt = unsigned.issuedAt; freshUntil = unsigned.freshUntil; self.authenticationTag = authenticationTag }; enum CodingKeys: String, CodingKey { case version, revision, disposition; case compactProof = "compact_proof"; case issuedAt = "iat"; case freshUntil = "fresh_until"; case authenticationTag = "authentication_tag" } }
}

struct ProofHighWater: Equatable, Sendable {
    let revision: Int64; let issuedAt: Int64; let freshUntil: Int64; let disposition: String
    func accepts(newer candidate: ProofHighWater) -> Bool {
        candidate.issuedAt >= issuedAt && candidate.freshUntil >= freshUntil && (candidate.revision > revision || (candidate.revision == revision && candidate.disposition == "deny" && disposition != "deny"))
    }
}

private final class CacheCoordinator: @unchecked Sendable {
    private let lock = NSLock(); private let path: String; private var highWater: ProofHighWater?
    init(path: String) { self.path = path }
    func withLock<T>(_ body: () throws -> T) throws -> T { lock.lock(); defer { lock.unlock() }; let descriptor = open("\(path).lock", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR); guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }; defer { _ = flock(descriptor, LOCK_UN); _ = close(descriptor) }; guard flock(descriptor, LOCK_EX) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }; return try body() }
    func record(_ highWater: ProofHighWater) { self.highWater = highWater }
}
private final class CacheCoordinatorRegistry: @unchecked Sendable { static let shared = CacheCoordinatorRegistry(); private let lock = NSLock(); private var values: [String: CacheCoordinator] = [:]; func coordinator(for path: String) -> CacheCoordinator { lock.lock(); defer { lock.unlock() }; if let value = values[path] { return value }; let value = CacheCoordinator(path: path); values[path] = value; return value } }
