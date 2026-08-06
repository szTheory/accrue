---
phase: 223-ios-compatible-accrue-offline-client
verified: 2026-08-06T16:04:29Z
status: gaps_found
score: 17/28 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "A host receives canonical-vector-conformant strict ES256 proof verification before a proof can replace cached state."
    status: failed
    reason: "The verifier admits signed inputs that violate the claimed canonical JSON/claim profile. JSONSerialization accepts duplicate members; verify() neither rejects duplicates nor validates jti, exact cnf shape, normalized non-empty allow benefits/positive quantities, or the allowed deny reasons."
    artifacts:
      - path: "packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift"
        issue: "Lines 63-78 use lossy JSON object decoding and only validate a small subset of required claims."
    missing:
      - "Reject duplicate JSON object members in JWS header and payload before decoding."
      - "Validate the complete canonical claim schema and add signed adversarial tests."
  - truth: "A verified newer allow or signed deny can replace cached state through direct apply or reconnect while cache failure handling preserves a complete authenticated cache."
    status: failed
    reason: "replace(_:) reads and authenticates the existing cache before writing. A malformed or HMAC-invalid file throws instead of being quarantined/replaced, so applyServerProof and reconnect return cache_write_failed and cannot recover by persisting a valid newly verified proof."
    artifacts:
      - path: "packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift"
        issue: "Lines 25-29 propagate invalid-existing-cache failure before the candidate write path."
    missing:
      - "Under the existing lock, distinguish absent/invalid cache from authenticated prior state and safely replace or quarantine only invalid data."
      - "Add recovery tests proving a valid direct and reconnect proof restores service after malformed and HMAC-invalid cache bytes."
  - truth: "Concurrent/interrupted replacement cannot weaken signed-deny ordering and all claimed durability failures preserve the prior complete authenticated cache."
    status: failed
    reason: "The process concurrency test expressly accepts either fresh or denied after concurrent allow/deny writers, and durability testing covers only crash-before-apply rather than the declared candidate-write, sync, replacement, and directory-sync failures."
    artifacts:
      - path: "packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift"
        issue: "Line 34 accepts .fresh, which contradicts equal-revision signed-deny precedence; no fault injection covers the other durability boundaries."
    missing:
      - "Use equal-revision allow/deny concurrent fixtures and require denied as the final state."
      - "Make the harness fail on admission failure and add deterministic fault injection for each atomic-write/sync stage."
behavior_unverified_items:
  - truth: "loadCachedState returns bounded invalid states for absent, tampered, and unrecoverable cache without mutating a prior authenticated cache."
    test: "Seed a valid cache, then exercise absent, malformed, and HMAC-invalid files through loadCachedState and compare bytes before/after."
    expected: "Absent returns invalid(malformed); invalid recovery returns invalid(cache_recovery_failed); no call changes the valid authenticated cache."
    why_human: "The full suite has no test for these recovery transitions; source inspection cannot prove every filesystem error path."
  - truth: "Malformed proof input leaves the prior authenticated cache unchanged."
    test: "Admit a valid proof, then submit empty, truncated, null-equivalent, and malformed proof bytes and reload the cache."
    expected: "Every submission returns invalid(malformed) and the original authenticated proof remains recoverable."
    why_human: "Tests cover a few signed mutations but not the complete empty/truncated/null-equivalent transition set."
  - truth: "Concurrent verification cannot bypass profile, account, device, or time checks."
    test: "Run concurrent valid and each invalid-context proof admissions against the same cache and inspect final state."
    expected: "Only a verified, ordered candidate is retained; invalid candidates never become authority."
    why_human: "There is no focused concurrent-invalid verification test; the current process test only checks readable output."
---

# Phase 223: iOS-compatible Accrue offline client Verification Report

**Phase Goal:** Extract the verified Crosswake tracer foundation into an iOS-compatible, reusable SwiftPM offline client while retaining canonical ES256 verification, device binding, high-water and signed-deny ordering, verified atomic cache replacement, and an honest iOS compilation boundary.

**Verified:** 2026-08-06T16:04:29Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Roadmap SC1: standalone client retains canonical verification, high-water ordering, and allow/deny replacement | ✗ FAILED | `verify` admits duplicate-key and semantically malformed signed JWS payloads; the strict authority boundary is not retained. |
| 2 | Roadmap SC2: only verified device-bound ES256 proof replaces state; stale never grants | ✗ FAILED | Device binding and stale mapping exist, but a signed proof that violates the canonical profile can pass `verify` and be persisted. |
| 3 | Roadmap SC3: reconnect/direct replacement survives cache failure without losing a complete authenticated cache | ✗ FAILED | `AtomicOfflineCache.replace` throws on corrupt existing bytes before replacement, blocking a fresh verified proof. |
| 4 | Roadmap SC4: tests prove corpus, malformed/rotation/order/crash recovery and iOS compile lane is merge-blocking | ✗ FAILED | The lane and compile target exist, but its concurrent test allows the forbidden allow-wins outcome and durability coverage is incomplete. |
| 5 | Roadmap SC5: host/StoreKit/UI/device-runtime concerns remain out of scope | ✓ VERIFIED | Runtime sources contain no StoreKit, UI, Crosswake bridge, fixture/key loader, or device-runtime claim; CI source-boundary scan enforces this. |
| 6 | P01 cached facade authenticates canonical envelope and bounds absent/tampered recovery | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `loadCachedState` calls `recoverProof` then `verify` (lines 44-50); no test exercises absent/tampered/recovery transitions. |
| 7 | P01 exposes exactly four immutable Sendable states with bounded vocabulary | ✓ VERIFIED | `OfflineEntitlementState` has only fresh, staleOffline, denied, invalid and its reason/action enums are `Sendable` (lines 4-16). |
| 8 | P01 direct proof admission enforces exact canonical ES256/JWS profile | ✗ FAILED | Duplicate keys and required-claim semantics are not rejected (lines 63-78). |
| 9 | P01 stale continuity is not local grant authority | ✓ VERIFIED | `state(for:) maps stale proof only to `.staleOffline(...reconnectRequired)` and exposes no grant API (lines 52-57). |
| 10 | P01 malformed/empty proof preserves prior cache | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Empty proof is rejected before `replace` (line 32); the full edge set has no behavioral test. |
| 11 | P02 corpus and decision cases run from test-only neutral fixtures | ✓ VERIFIED | `canonicalCorpusParity` iterates all fixture vectors; fixture loaders and test key remain under `Tests/`/harness. |
| 12 | P02 equal-revision signed deny wins over allow | ✓ VERIFIED | Sequential test proves allow → deny → allow yields denied/superseded (tests lines 41-52). |
| 13 | P02 iteration/concurrent candidates cannot change denial precedence | ✗ FAILED | Concurrent process assertion accepts either `.fresh` or `.denied` (process test line 34). |
| 14 | P02 repeated proof application is idempotent | ✓ VERIFIED | Reapplying deny has the same public state and cache result (tests lines 46-52). |
| 15 | P02 parallel/interrupted replacement leaves one complete authenticated envelope | ✗ FAILED | The only interruption is before apply; it does not prove all declared atomic-write failure stages, and concurrency permits ordering failure. |
| 16 | P02 repeated verification has no new authority | ✓ VERIFIED | Identical proof results are covered by `denyPrecedenceAndIdempotency`; verifier inputs are immutable configuration/proof values. |
| 17 | P02 concurrent verification cannot bypass checks | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Shared verification path is visible, but no concurrent-invalid-context test exercises this invariant. |
| 18 | P02 every declared durability failure preserves the previous authenticated cache | ✗ FAILED | No injected candidate-write/sync/replace/directory-sync cases; corrupt existing cache blocks later valid replacement. |
| 19 | P03 reconnect remains host-owned and transports compact bytes only | ✓ VERIFIED | `OfflineProofReconnectTransport` returns `Data`; protocol owns no endpoint, credentials, or commerce surface. |
| 20 | P03 reconnect reuses direct verified admission | ✓ VERIFIED | `reconnect` delegates exactly to `applyServerProof` (OfflineReconnect.swift:11-16), with passing direct-admission test. |
| 21 | P03 repeated reconnect cannot weaken cached authority | ✓ VERIFIED | Focused reconnect test covers repeat allow/deny ordering and final denied state. |
| 22 | P03 concurrent reconnect uses the same ordering/atomic boundary | ✓ VERIFIED | Both async reconnects delegate to `applyServerProof`; focused test expects final denied state (OfflineReconnectTests:38-42). |
| 23 | P03 Apple helper is explicit ThisDeviceOnly policy without key custody | ✓ VERIFIED | Apple helper tests assert exact accessibility constants and absence of key-custody operation. |
| 24 | P04 tracer is a local-path conformance consumer | ✓ VERIFIED | `examples/crosswake_tracer/Package.swift:11-18` declares the package path and imports only the core product. |
| 25 | P04 iOS 16 core compilation is a merge-blocking lane | ✓ VERIFIED | CI job `ios-offline-client` runs on macOS and calls the gate; independent `swiftc -target arm64-apple-ios16.0` compilation passed. |
| 26 | P04 deterministic checks cannot promote feasibility evidence | ✓ VERIFIED | Gate hashes evidence before/after and requires all statuses `feasibility_blocked` (script lines 20-24, 48-54). |
| 27 | P04 docs identify host ownership and stale non-grant semantics | ✓ VERIFIED | Package README and narrow transport/core interfaces keep those responsibilities outside the client. |
| 28 | P04 installed runtime excludes fixtures/keys/host product claims | ✓ VERIFIED | Runtime-source scan finds none; gate rejects `#filePath`, fixtures, Crosswake, StoreKit, SwiftUI, and UIKit in core. |

**Score:** 17/28 truths verified (3 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `Package.swift` | iOS 16 SwiftPM core/Apple products | ✓ VERIFIED | Two library products exist; manifest targets keep crash harness out of core product. |
| `OfflineEntitlementClient.swift` | narrow facade and strict admission | ⚠️ PARTIAL | Facade is wired, but its verifier is not strict/canonical as required. |
| `AtomicOfflineCache.swift` | verified atomic replacement/recovery | ⚠️ PARTIAL | HMAC envelope and lock exist; corrupt cache prevents valid replacement. |
| Core and process test targets | corpus/order/recovery proof | ⚠️ PARTIAL | All 10 tests pass, but the concurrency assertion permits the prohibited state and fault coverage is incomplete. |
| `OfflineReconnect.swift` | host-owned byte transport | ✓ VERIFIED | Calls the exact public direct-admission method. |
| Apple helper | explicit ThisDeviceOnly policy | ✓ VERIFIED | Policy-only target and tests present. |
| CI gate and tracer consumer | iOS lane and non-promoting integration | ✓ VERIFIED | Wired in CI and local path dependency. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `applyServerProof` | `VerifiedOfflineProof` | `verify` | ⚠️ PARTIAL | Link exists (lines 34-35), but the verifier accepts non-canonical signed inputs. |
| `VerifiedOfflineProof` | `AtomicOfflineCache` | `replace` | ✓ WIRED | Only verifier-created module-internal value reaches `replace`. |
| `loadCachedState` | authenticated canonical cache recovery | `recoverProof` then `verify` | ✓ WIRED | Lines 44-49 recover, reverify, and derive public state. |
| `reconnect` | `applyServerProof` | returned `Data` | ✓ WIRED | Direct delegation at OfflineReconnect.swift:13. |
| Crosswake tracer | standalone package | SwiftPM path dependency | ✓ WIRED | Package dependency and product wiring verified. |
| CI workflow | iOS gate | macOS named job | ✓ WIRED | `.github/workflows/ci.yml:134-143`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `OfflineEntitlementClient` | compact proof | host direct input/reconnect transport, then cache envelope | Yes, via caller/verified cache | ⚠️ PARTIAL — malformed signed data is not fully rejected. |
| Crosswake tracer | offline-client product | local SwiftPM dependency | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Package public tests | `swift test --package-path packages/accrue-offline-client` | 10 tests passed | ✓ PASS (insufficient to prove the failed strict/recovery cases) |
| iOS core compilation | `xcrun --sdk iphoneos swiftc -parse-as-library -target arm64-apple-ios16.0 ...Core/*.swift` | exit 0 | ✓ PASS |
| SwiftPM manifest | `swift package ... dump-package` | Core and Apple library products; iOS 16 platform | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- |
| IOS-01 | 01, 02, 04 | iOS client matches canonical proof/high-water/allow-deny replacement | ✗ BLOCKED | Strict canonical proof admission and concurrent denial-proof defects. |
| IOS-02 | 01, 02, 03, 04 | ES256 server proof/device binding/stale-study continuity | ✗ BLOCKED | Device/stale paths exist, but malformed signed canonical-profile proofs are admitted. |
| IOS-03 | 02, 03, 04 | authenticated reconnect replaces only with verified newer allow/signed deny | ✗ BLOCKED | Reconnect shares verification, but corrupt cache prevents a valid replacement and recovery. |

No Phase 223 requirement is orphaned: all three are declared by its plans. `REQUIREMENTS.md` still marks IOS-01..03 Pending.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `OfflineEntitlementClient.swift` | 63-78 | Lossy duplicate-key JSON decode and partial claim validation | 🛑 Blocker | Can persist a semantically non-canonical signed proof. |
| `AtomicOfflineCache.swift` | 25-29 | Invalid old cache aborts all replacement | 🛑 Blocker | Tampering/corruption creates persistent denial of service. |
| `AtomicOfflineCacheProcessTests.swift` | 34 | Test accepts fresh or denied after concurrent allow/deny | 🛑 Blocker | Claimed signed-deny ordering is not actually verified. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in Phase 223 runtime sources.

### Human Verification Required

Automated gaps take precedence. The three present-but-behavior-unverified cache/concurrency transitions are retained in frontmatter and must be exercised after the blocking fixes.

### Gaps Summary

Phase 223 is not achieved. The package is importable, compiles for iOS 16, has a narrow public surface, and is wired into a non-promoting CI lane. But the phase’s security and durability outcome depends on strict canonical proof admission and recoverable verified replacement. The actual runtime accepts parser-differential/under-specified signed proofs and cannot overwrite a corrupt cache with a new verified proof. Existing green tests do not test those failure paths and even permit the forbidden concurrent ordering outcome.

The three gaps are not deferred: Phases 224–226 cover bridge, host StoreKit integration, and readiness handoff, not core proof-parser or cache-recovery repairs.

---

_Verified: 2026-08-06T16:04:29Z_  
_Verifier: the agent (gsd-verifier)_
