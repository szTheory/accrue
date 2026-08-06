# Phase 223: iOS-compatible Accrue offline client - Pattern Map

**Mapped:** 2026-08-06  
**Files analyzed:** 10 planned new/modified files  
**Analogs found:** 9 / 10

## File Classification

The exact split of core Swift source is discretionary. This map uses the package structure recommended in `223-RESEARCH.md`; every core source file must preserve the coupled verifier → opaque verified proof → ordering → authenticated atomic cache boundary.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `packages/accrue-offline-client/Package.swift` | config | build/package | `examples/crosswake_tracer/Package.swift` | role-match |
| `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift` | service | request-response | `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | partial-match |
| `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift` | service | file-I/O | `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | exact |
| `packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift` | utility | request-response | — | no-analog |
| `packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift` | test | request-response | `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift` | role-match |
| `packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift` | test | file-I/O | `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` | partial-match |
| `packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift` | test | process/file-I/O | `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift` | exact |
| `examples/crosswake_tracer/Package.swift` | config | build/package | `examples/crosswake_tracer/Package.swift` | exact (modify) |
| `examples/crosswake_tracer/README.md` | config/documentation | transform | `examples/crosswake_tracer/README.md` | exact (modify) |
| `.github/workflows/ci.yml` and/or `scripts/ci/verify_ios_offline_client.sh` | config | batch | `.github/workflows/ci.yml`, `scripts/ci/verify_reference_scenario_contract.sh` | role-match |

## Pattern Assignments

### `packages/accrue-offline-client/Package.swift` (config, build/package)

**Analog:** `examples/crosswake_tracer/Package.swift`

**Manifest pattern** (lines 1-22):

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccrueOfflineClient",
    platforms: [.macOS(.v10_15), .iOS(.v16)],
    products: [
        .library(name: "AccrueOfflineClient", targets: ["AccrueOfflineClient"]),
        .executable(name: "AccrueOfflineCacheCrashHarness", targets: ["AccrueOfflineCacheCrashHarness"])
    ],
    targets: [
        .target(name: "AccrueOfflineClient"),
        .executableTarget(
            name: "AccrueOfflineCacheCrashHarness",
            dependencies: ["AccrueOfflineClient"]
        ),
        .testTarget(
            name: "AccrueOfflineClientTests",
            dependencies: ["AccrueOfflineClient"]
        )
    ]
)
```

**Apply:** retain tools 6.0 and the iOS 16 floor. Change the product graph to a portable `AccrueOfflineClientCore` product plus optional Apple Keychain product. Keep the crash harness test-only/non-iOS so a core-only iOS build does not compile it.

---

### `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift` (service, request-response)

**Analog:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift`

**Imports/platform portability** (lines 1-7):

```swift
import Foundation
import CryptoKit
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif
```

**Strict ES256 and binding gate** (lines 240-276):

```swift
guard Set(header.keys) == ["alg", "typ", "kid"] else { throw GoldenVectorError.malformed }
guard header["alg"] as? String == "ES256" else { throw GoldenVectorError.algorithm }
guard header["typ"] as? String == "accrue-entitlement-proof+jwt" else { throw GoldenVectorError.type }
guard let kid = header["kid"] as? String, let key = keys.first(where: { $0.kid == kid }), key.isValid else { throw GoldenVectorError.key }
let payload = try Payload(values: values)
let publicKey: P256.Signing.PublicKey
do { publicKey = try P256.Signing.PublicKey(x963Representation: key.point) }
catch { throw GoldenVectorError.key }
guard let signature = try? P256.Signing.ECDSASignature(rawRepresentation: signatureData),
      publicKey.isValidSignature(signature, for: Data("\(parts[0]).\(parts[1])".utf8)) else { throw GoldenVectorError.signature }
guard payload.iss == context.issuer else { throw GoldenVectorError.issuer }
guard payload.aud == context.audience else { throw GoldenVectorError.audience }
guard payload.accountID == context.account else { throw GoldenVectorError.account }
guard payload.cnf == context.thumbprint else { throw GoldenVectorError.device }
```

**Opaque-admission boundary** (lines 543-559):

```swift
private struct VerifiedOfflineProof: Sendable {
    let compactProof: Data
    let highWater: ProofHighWater

    init(compactProof: Data, issuedAt: Int64, revision: Int64,
         freshUntil: Int64, disposition: AtomicOfflineCache.Disposition) {
        self.compactProof = compactProof
        highWater = ProofHighWater(
            issuedAt: Date(timeIntervalSince1970: TimeInterval(issuedAt)),
            revision: revision,
            freshnessDeadline: Date(timeIntervalSince1970: TimeInterval(freshUntil)),
            disposition: disposition
        )
    }
}
```

**Ordering rule** (lines 847-856):

```swift
public func accepts(newer candidate: ProofHighWater) -> Bool {
    candidate.issuedAt >= issuedAt &&
        candidate.freshnessDeadline >= freshnessDeadline &&
        ProofReplacementOrder.accepts(
            existingDisposition: disposition,
            existingRevision: revision,
            candidateDisposition: candidate.disposition,
            candidateRevision: candidate.revision
        )
}
```

**Do not copy the obsolete public API** (lines 801-826): it exposes `purchase`, `restoreEntitlements`, lifecycle triggers, and caller-constructed replacement metadata. Replace it with the single public facade, immutable `Sendable` four-state domain values, and the narrow transport protocol returning compact proof `Data`.

---

### `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift` (service, file-I/O)

**Analog:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift`

**Host-owned key construction** (lines 585-594):

```swift
public let url: URL
private let coordinator: CacheCoordinator
private let authenticationKey: SymmetricKey

/// The host supplies key material from its secure boundary. The cache never persists it.
public init(url: URL, authenticationKey: SymmetricKey) {
    self.url = url.standardizedFileURL
    coordinator = CacheCoordinatorRegistry.shared.coordinator(for: self.url.path)
    self.authenticationKey = authenticationKey
}
```

**Verified candidate, synchronize, same-volume replace, then directory sync** (lines 596-625):

```swift
fileprivate func replace(with proof: VerifiedOfflineProof, fault: Fault? = nil) throws {
    try coordinator.withLock {
        let persisted = try loadVerifiedEnvelope()
        let accepted = persisted.map { $0.highWater.accepts(newer: proof.highWater) }
            ?? coordinator.accepts(proof.highWater)
        guard accepted else { return }
        let candidate = uniqueCandidateURL()
        defer { try? FileManager.default.removeItem(at: candidate) }
        try encodedReplacement(proof).write(to: candidate)
        let handle = try FileHandle(forWritingTo: candidate)
        defer { try? handle.close() }
        try handle.synchronize()
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: candidate)
        } else {
            try FileManager.default.moveItem(at: candidate, to: url)
        }
        try synchronizeParentDirectory()
        coordinator.record(proof.highWater)
    }
}
```

**Authenticated envelope recovery** (lines 664-676):

```swift
guard FileManager.default.fileExists(atPath: url.path) else { return nil }
do { envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url)) }
catch { throw CacheError.malformedEnvelope }
guard envelope.version == 2,
      let compactProof = Data(base64Encoded: envelope.compactProof),
      let tag = Data(base64Encoded: envelope.authenticationTag)
else { throw CacheError.malformedEnvelope }
let expected = Data(HMAC<SHA256>.authenticationCode(
    for: try signedBytes(unsigned), using: authenticationKey
))
guard tag == expected else { throw CacheError.authenticationFailed }
```

**Apply:** keep `replace` internal/file-private so only the verifier-created opaque token reaches persistence. Map thrown storage/recovery failures to a bounded facade reconnect/retry outcome; do not substitute an unauthenticated candidate or silently relax synchronization failures.

---

### `packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift` (utility, request-response)

**Analog:** none in the repository.

**Use research pattern:** isolate `Security` imports in the optional Apple product. Require the host to choose service, access group, and explicit `ThisDeviceOnly` accessibility. Never make a pre-first-unlock error fall back to a weaker accessibility class; surface it as a bounded actionable failure.

---

### `packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift` and `GoldenVectorFixtureSupport.swift` (test, request-response/file-I/O)

**Analogs:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift` and tracer source.

**Swift Testing imports and high-water test shape** (`GoldenVectorTests.swift` lines 1-29):

```swift
import Testing
import Foundation
import CryptoKit
@testable import AccrueOfflineClient

struct GoldenVectorTests {
    @Test("high-water rejects stale issuance/freshness and preserves same-revision denial")
    func highWaterOrder() {
        let issuedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let freshness = Date(timeIntervalSince1970: 1_700_003_600)
        let allowAtSeven = ProofHighWater(
            issuedAt: issuedAt, revision: 7, freshnessDeadline: freshness, disposition: .allow
        )
        let denialAtSeven = ProofHighWater(
            issuedAt: issuedAt, revision: 7, freshnessDeadline: freshness, disposition: .deny
        )
        #expect(!allowAtSeven.accepts(newer: ProofHighWater(
            issuedAt: issuedAt, revision: 6, freshnessDeadline: freshness, disposition: .deny
        )))
    }
}
```

**Fixture authority is test-only today, and must stay that way** (`AccrueOfflineClient.swift` lines 81-99):

```swift
/// Test-only seam: candidate bytes are always checked against the unmodified generated corpus.
static func fixtureData() throws -> (corpus: Data, decisionCases: Data, key: Data) {
    let corpusURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("accrue/priv/entitlements/v1.59-offline-golden-vectors.json")
    let decisionCasesURL = corpusURL.deletingLastPathComponent().appendingPathComponent("v1.59-decision-cases.json")
    let keyURL = corpusURL.deletingLastPathComponent().appendingPathComponent("v1.59-offline-test-key.jwk.json")
    return (try Data(contentsOf: corpusURL), try Data(contentsOf: decisionCasesURL), try Data(contentsOf: keyURL))
}
```

**Apply:** move this path/key/corpus loader and mutation signing helpers into package test support (injected path or checked-in test resource). Runtime core must not contain `#filePath`, fixture lookup, or test private-key handling. Cover all canonical vectors plus ES256-only/header, issuer/audience/account/device, four states, rotation, malformed data, high-water, and signed-deny precedence.

---

### `packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift` (test, process/file-I/O)

**Analog:** `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/AtomicOfflineCacheProcessTests.swift`

**Fresh-process ordering/recovery pattern** (lines 6-25):

```swift
struct AtomicOfflineCacheProcessTests {
    @Test("same-revision denial survives fresh processes and rejects stale or equal allow")
    func denialRestartRefusesStaleAndEqualAllow() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let keyBytes = Data("process-cache-authentication-key-32bytes".utf8)
        let url = directory.appendingPathComponent("entitlement.json")

        try runHarness(url, key: keyBytes, arguments: ["replace", "valid_allow"])
        try runHarness(url, key: keyBytes, arguments: ["replace", "valid_signed_denial"])
        try runHarness(url, key: keyBytes, arguments: ["replace", "valid_allow"])

        let cache = AtomicOfflineCache(url: url, authenticationKey: SymmetricKey(data: keyBytes))
        let envelope = try #require(try cache.recoveredEnvelope())
        #expect(envelope.disposition == .deny)
        #expect(try cache.candidateURLs().isEmpty)
    }
}
```

**Apply:** preserve the separate executable harness and inherited clean process test. Keep this target in macOS/Linux lanes only; do not include it in the generic iOS core compile command.

---

### `examples/crosswake_tracer/Package.swift` and `examples/crosswake_tracer/README.md` (config/documentation, build/transform)

**Analog:** themselves, plus `scripts/ci/verify_reference_scenario_contract.sh`.

**Current evidence-boundary wording** (`README.md` lines 9-11, 36-40):

```markdown
The same package also carries the Crosswake feasibility tracer below. Its
capability report remains independent of successful package compilation or
golden-vector checks.

The report is `proven` only when every required capability occurs exactly once,
has all required evidence kinds, and is `proven`.
```

**CI keeps the tracer test and release/evidence contract independently invoked** (`verify_reference_scenario_contract.sh` lines 92-107):

```bash
if [ "$ROOT_DIR" = "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" ] &&
  [ "${V159_SKIP_RELEASE_CONTRACT:-false}" != "true" ]; then
  (
    cd "$ACCRUE_DIR"
    mix test test/accrue/entitlements/reference_scenarios_test.exs \
      test/accrue/entitlements/reference_scenario_*_test.exs \
      test/accrue/entitlements/repair_drills_test.exs \
      --seed 458442 --max-failures 1
  )
  (cd "$ROOT_DIR/examples/crosswake_tracer" && swift test)
  bash "$ROOT_DIR/scripts/ci/verify_adoption_proof_matrix.sh"
fi
```

**Apply:** make the tracer a local-path consumer of the new package and revise its README from package adoption docs to feasibility-tracer docs. Preserve its `feasibility_blocked` report and independent tests; package success must never mutate/report it as `proven`.

---

### `.github/workflows/ci.yml` and/or `scripts/ci/verify_ios_offline_client.sh` (config, batch)

**Analogs:** `.github/workflows/ci.yml` and `scripts/ci/verify_reference_scenario_contract.sh`.

**Existing merge-gate step style** (`.github/workflows/ci.yml` lines 73-80):

```yaml
      - name: Adoption proof matrix contract
        run: bash scripts/ci/verify_adoption_proof_matrix.sh

      - name: Reference scenario public-contract gate
        run: bash scripts/ci/verify_reference_scenario_contract.sh
```

**Shell guard/fail pattern** (`verify_reference_scenario_contract.sh` lines 1-21):

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
fail() { echo "verify_reference_scenario_contract: FAIL: $1" >&2; exit 1; }

for file in "$fixture" "$scenarios" "$matrix" "$capability_report" "$physical_evidence" "$workflow"; do
  [ -f "$file" ] || fail "missing required file ${file#$ROOT_DIR/}"
done
```

**Apply:** add a merge-blocking macOS iOS-SDK compile lane for only the public core product at `arm64-apple-ios16.0`; keep package unit tests and process/fault tests distinct. Follow the existing workflow’s named-step style and avoid altering unrelated current CI edits.

## Shared Patterns

### Verification and admission

**Source:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` lines 240-276, 543-559.  
**Apply to:** every `applyServerProof` and reconnect response path.

Strictly validate the exact JWS profile and ES256 signature/bindings before constructing the private `VerifiedOfflineProof`; callers never provide revision, disposition, or cache metadata independently.

### Denial-safe ordering and authenticated durability

**Source:** `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` lines 581-625, 644-676, 847-856.  
**Apply to:** core cache store, recovery, direct application, and reconnect.

Load and authenticate existing envelope before admission; require nondecreasing issuance/freshness plus revision order, with same-revision signed denial stronger than allow. Candidate writes are synchronized and atomically replaced on the destination volume; recovery reads only the canonical HMAC-authenticated envelope.

### Host ownership and runtime-honesty documentation

**Source:** `accrue/guides/first_adopter_ios_bridge.md` lines 9-16 and 43-58; `examples/crosswake_tracer/README.md` lines 9-11, 42-48.  
**Apply to:** public package README/API docs and tracer README.

Hosts own networking/authentication, StoreKit, Keychain policy, routing, and UI. A stale proof only preserves downloaded-study continuity; compilation/vectors/simulator tests never establish physical-device Crosswake feasibility.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift` | utility | request-response | Repository has no Security/Keychain implementation; use the Phase 223 explicit-host-configuration contract and Apple Security APIs while keeping it outside core. |

## Metadata

**Analog search scope:** `examples/crosswake_tracer/`, `accrue/guides/`, `scripts/ci/`, `.github/workflows/ci.yml`  
**Files scanned:** 11  
**Pattern extraction date:** 2026-08-06
