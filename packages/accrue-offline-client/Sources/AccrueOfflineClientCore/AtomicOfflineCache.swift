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
    enum FaultStage: Hashable { case candidateWrite, candidateFileSync, atomicReplace, parentDirectorySync, rollbackRestore, rollbackDirectorySync }
    private let url: URL
    private let key: SymmetricKey
    private let coordinator: CacheCoordinator
    private let faults: Set<FaultStage>

    init(url: URL, key: SymmetricKey, fault: FaultStage? = nil, rollbackFault: FaultStage? = nil) {
        self.url = url.standardizedFileURL
        self.key = key
        coordinator = CacheCoordinatorRegistry.shared.coordinator(for: self.url.path)
        faults = Set([fault, rollbackFault].compactMap { $0 })
    }

    func replace(_ proof: VerifiedOfflineProof) throws -> Admission {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return try coordinator.withLock {
            try recoverPendingTransaction()
            let prior = try priorState()
            if case let .authenticated(persisted) = prior {
                if persisted.highWater == proof.highWater { return .identical }
                guard persisted.highWater.accepts(newer: proof.highWater) else { return .superseded }
            }

            let candidate = uniqueCandidateURL()
            let backup = uniqueBackupURL()
            let quarantine = uniqueQuarantineURL()
            let transaction = uniqueTransactionURL()
            defer { try? FileManager.default.removeItem(at: candidate) }

            if case .invalid = prior { try FileManager.default.moveItem(at: url, to: quarantine) }
            var record: TransactionRecord?
            if case .authenticated = prior {
                try FileManager.default.copyItem(at: url, to: backup)
                try synchronizeFile(at: backup)
                let prepared = TransactionRecord(phase: .prepared, candidateName: candidate.lastPathComponent, backupName: backup.lastPathComponent)
                try writeTransaction(prepared, at: transaction)
                record = prepared
            }

            do {
                try fail(.candidateWrite)
                try encodedReplacement(proof).write(to: candidate)
                try fail(.candidateFileSync)
                try synchronizeFile(at: candidate)
                try fail(.atomicReplace)
                try atomicOverwrite(destination: url, with: candidate)
                try fail(.parentDirectorySync)
                try synchronizeParentDirectory()
                if let record {
                    try writeTransaction(record.withPhase(.committed), at: transaction)
                    try cleanupTransaction(record, transaction: transaction)
                }
                try? FileManager.default.removeItem(at: quarantine)
                coordinator.record(proof.highWater)
                return .replaced
            } catch {
                if let record {
                    do {
                        try restoreAuthenticatedPrior(record, transaction: transaction)
                    } catch {
                        // The prepared record and authenticated backup stay discoverable for a fresh process.
                        throw error
                    }
                } else if case .invalid = prior, !FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.moveItem(at: quarantine, to: url)
                    try synchronizeParentDirectory()
                }
                throw error
            }
        }
    }

    func recoverProof() throws -> Data? {
        guard FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path) else { return nil }
        return try coordinator.withLock {
            try recoverPendingTransaction()
            switch try priorState() {
            case .absent: return Optional<Data>.none
            case let .authenticated(envelope): return envelope.compactProof
            case .invalid: throw CacheError.malformed
            }
        }
    }

    /// Resolves only authenticated, internal transaction state. A sidecar never becomes authority.
    private func recoverPendingTransaction() throws {
        let transactions = try transactionURLs()
        for transaction in transactions {
            let record = try loadTransaction(at: transaction)
            switch record.phase {
            case .prepared:
                try restoreAuthenticatedPrior(record, transaction: transaction)
            case .committed:
                try cleanupTransaction(record, transaction: transaction)
            }
        }
    }

    private func restoreAuthenticatedPrior(_ record: TransactionRecord, transaction: URL) throws {
        guard record.phase == .prepared else { throw CacheError.malformed }
        let backup = scopedURL(named: record.backupName, prefix: backupPrefix)
        let rollback = uniqueRollbackURL()
        defer { try? FileManager.default.removeItem(at: rollback) }
        _ = try loadVerifiedEnvelope(at: backup)
        try FileManager.default.copyItem(at: backup, to: rollback)
        try synchronizeFile(at: rollback)
        try fail(.rollbackRestore)
        try atomicOverwrite(destination: url, with: rollback)
        try fail(.rollbackDirectorySync)
        try synchronizeParentDirectory()
        let committed = record.withPhase(.committed)
        try writeTransaction(committed, at: transaction)
        try cleanupTransaction(committed, transaction: transaction)
    }

    private func cleanupTransaction(_ record: TransactionRecord, transaction: URL) throws {
        try FileManager.default.removeItem(at: scopedURL(named: record.backupName, prefix: backupPrefix))
        try FileManager.default.removeItem(at: transaction)
        try synchronizeParentDirectory()
    }

    private func encodedReplacement(_ proof: VerifiedOfflineProof) throws -> Data {
        let unsigned = UnsignedEnvelope(version: 2, compactProof: proof.compactProof.base64EncodedString(), revision: proof.highWater.revision, disposition: proof.highWater.disposition, issuedAt: proof.highWater.issuedAt, freshUntil: proof.highWater.freshUntil)
        let tag = Data(HMAC<SHA256>.authenticationCode(for: try signedBytes(unsigned), using: key)).base64EncodedString()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(unsigned: unsigned, authenticationTag: tag))
    }

    private func loadVerifiedEnvelope(at location: URL) throws -> RecoveredEnvelope {
        let raw = try Data(contentsOf: location)
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
        do { return .authenticated(try loadVerifiedEnvelope(at: url)) } catch { return .invalid }
    }
    private func fail(_ stage: FaultStage) throws { if faults.contains(stage) { throw CacheError.injected } }

    private func atomicOverwrite(destination: URL, with source: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) { _ = try FileManager.default.replaceItemAt(destination, withItemAt: source) }
        else { try FileManager.default.moveItem(at: source, to: destination) }
    }
    private func synchronizeFile(at location: URL) throws {
        let handle = try FileHandle(forWritingTo: location)
        defer { try? handle.close() }
        try handle.synchronize()
    }

    private func signedBytes(_ value: UnsignedEnvelope) throws -> Data {
        var bytes = Data("accrue.atomic-offline-cache".utf8)
        for item in [String(value.version), url.path, value.compactProof, String(value.revision), value.disposition, String(value.issuedAt), String(value.freshUntil)] {
            let data = Data(item.utf8); var length = UInt64(data.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }; bytes.append(data)
        }
        return bytes
    }

    private enum TransactionPhase: String, Codable { case prepared, committed }
    private struct TransactionRecord: Codable {
        let version: Int = 1
        let phase: TransactionPhase
        let candidateName: String
        let backupName: String
        let authenticationTag: String?
        init(phase: TransactionPhase, candidateName: String, backupName: String, authenticationTag: String? = nil) { self.phase = phase; self.candidateName = candidateName; self.backupName = backupName; self.authenticationTag = authenticationTag }
        func withPhase(_ phase: TransactionPhase) -> TransactionRecord { TransactionRecord(phase: phase, candidateName: candidateName, backupName: backupName) }
        enum CodingKeys: String, CodingKey { case version, phase; case candidateName = "candidate"; case backupName = "backup"; case authenticationTag = "authentication_tag" }
    }
    private func writeTransaction(_ record: TransactionRecord, at location: URL) throws {
        let unsigned = record.withPhase(record.phase)
        let tag = Data(HMAC<SHA256>.authenticationCode(for: try transactionBytes(unsigned), using: key)).base64EncodedString()
        let signed = TransactionRecord(phase: record.phase, candidateName: record.candidateName, backupName: record.backupName, authenticationTag: tag)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(signed).write(to: location)
        try synchronizeFile(at: location)
        try synchronizeParentDirectory()
    }
    private func loadTransaction(at location: URL) throws -> TransactionRecord {
        let raw = try Data(contentsOf: location)
        guard let record = try? JSONDecoder().decode(TransactionRecord.self, from: raw), record.version == 1,
              let supplied = record.authenticationTag.flatMap({ Data(base64Encoded: $0) }), isScopedName(record.candidateName, prefix: candidatePrefix), isScopedName(record.backupName, prefix: backupPrefix) else { throw CacheError.malformed }
        let expected = Data(HMAC<SHA256>.authenticationCode(for: try transactionBytes(record.withPhase(record.phase)), using: key))
        guard supplied == expected else { throw CacheError.authentication }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        guard try encoder.encode(record) == raw else { throw CacheError.malformed }
        return record
    }
    private func transactionBytes(_ record: TransactionRecord) throws -> Data {
        var bytes = Data("accrue.atomic-offline-cache.transaction".utf8)
        for item in [url.path, String(record.version), record.phase.rawValue, record.candidateName, record.backupName] {
            let data = Data(item.utf8); var length = UInt64(data.count).bigEndian
            withUnsafeBytes(of: &length) { bytes.append(contentsOf: $0) }; bytes.append(data)
        }
        return bytes
    }

    private var candidatePrefix: String { ".\(url.lastPathComponent).candidate." }
    private var backupPrefix: String { ".\(url.lastPathComponent).backup." }
    private var transactionPrefix: String { ".\(url.lastPathComponent).transaction." }
    private func transactionURLs() throws -> [URL] { try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(), includingPropertiesForKeys: nil).filter { isScopedName($0.lastPathComponent, prefix: transactionPrefix) } }
    private func isScopedName(_ name: String, prefix: String) -> Bool { name.hasPrefix(prefix) && !name.contains("/") && name.utf8.count <= 512 }
    private func scopedURL(named name: String, prefix: String) -> URL { precondition(isScopedName(name, prefix: prefix)); return url.deletingLastPathComponent().appendingPathComponent(name) }
    private func uniqueCandidateURL() -> URL { url.deletingLastPathComponent().appendingPathComponent("\(candidatePrefix)\(UUID().uuidString)") }
    private func uniqueBackupURL() -> URL { url.deletingLastPathComponent().appendingPathComponent("\(backupPrefix)\(UUID().uuidString)") }
    private func uniqueRollbackURL() -> URL { url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).rollback.\(UUID().uuidString)") }
    private func uniqueTransactionURL() -> URL { url.deletingLastPathComponent().appendingPathComponent("\(transactionPrefix)\(UUID().uuidString)") }
    private func uniqueQuarantineURL() -> URL { url.deletingLastPathComponent().appendingPathComponent(".\(url.lastPathComponent).quarantine.\(UUID().uuidString)") }
    private func synchronizeParentDirectory() throws {
        let descriptor = open(url.deletingLastPathComponent().path, O_RDONLY)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { _ = close(descriptor) }
        if fsync(descriptor) != 0, errno != EINVAL, errno != ENOTSUP, errno != EOPNOTSUPP { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }

    private enum CacheError: Error { case authentication, malformed, injected }
    private struct RecoveredEnvelope { let compactProof: Data; let highWater: ProofHighWater }
    private struct UnsignedEnvelope: Codable { let version: Int; let compactProof: String; let revision: Int64; let disposition: String; let issuedAt: Int64; let freshUntil: Int64; enum CodingKeys: String, CodingKey { case version, revision, disposition; case compactProof = "compact_proof"; case issuedAt = "iat"; case freshUntil = "fresh_until" } }
    private struct Envelope: Codable { let version: Int; let compactProof: String; let revision: Int64; let disposition: String; let issuedAt: Int64; let freshUntil: Int64; let authenticationTag: String; init(unsigned: UnsignedEnvelope, authenticationTag: String) { version = unsigned.version; compactProof = unsigned.compactProof; revision = unsigned.revision; disposition = unsigned.disposition; issuedAt = unsigned.issuedAt; freshUntil = unsigned.freshUntil; self.authenticationTag = authenticationTag }; enum CodingKeys: String, CodingKey { case version, revision, disposition; case compactProof = "compact_proof"; case issuedAt = "iat"; case freshUntil = "fresh_until"; case authenticationTag = "authentication_tag" } }
}

struct ProofHighWater: Equatable, Sendable {
    let revision: Int64; let issuedAt: Int64; let freshUntil: Int64; let disposition: String
    func accepts(newer candidate: ProofHighWater) -> Bool { candidate.issuedAt >= issuedAt && candidate.freshUntil >= freshUntil && (candidate.revision > revision || (candidate.revision == revision && candidate.disposition == "deny" && disposition != "deny")) }
}

private final class CacheCoordinator: @unchecked Sendable {
    private let lock = NSLock(); private let path: String; private var highWater: ProofHighWater?
    init(path: String) { self.path = path }
    func withLock<T>(_ body: () throws -> T) throws -> T { lock.lock(); defer { lock.unlock() }; let descriptor = open("\(path).lock", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR); guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }; defer { _ = flock(descriptor, LOCK_UN); _ = close(descriptor) }; guard flock(descriptor, LOCK_EX) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }; return try body() }
    func record(_ highWater: ProofHighWater) { self.highWater = highWater }
}
private final class CacheCoordinatorRegistry: @unchecked Sendable { static let shared = CacheCoordinatorRegistry(); private let lock = NSLock(); private var values: [String: CacheCoordinator] = [:]; func coordinator(for path: String) -> CacheCoordinator { lock.lock(); defer { lock.unlock() }; if let value = values[path] { return value }; let value = CacheCoordinator(path: path); values[path] = value; return value } }
