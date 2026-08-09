---
phase: 223-ios-compatible-accrue-offline-client
verified: 2026-08-06T17:43:48Z
status: passed
score: 28/28 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 26/28
  gaps_closed:
    - "A verified cached proof cannot regain fresh authority after the client has observed a later time and the device clock is rolled back."
    - "Malformed untrusted compact proofs are rejected through the bounded four-state result boundary without unbounded allocation or recursive parser exhaustion."
  gaps_remaining: []
  regressions: []
---

# Phase 223: iOS-compatible Accrue offline client Verification Report

**Phase Goal:** Extract the verified Crosswake tracer foundation into an iOS-compatible, reusable SwiftPM offline client while retaining canonical ES256 verification, device binding, high-water and signed-deny ordering, verified atomic cache replacement, and an honest iOS compilation boundary.

**Verified:** 2026-08-06T17:43:48Z
**Status:** passed
**Re-verification:** Yes — after Plan 07 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Standalone SwiftPM client supports canonical ES256 verification, high-water ordering, and allow/deny replacement. | ✓ VERIFIED | `Package.swift` exports the core iOS-16 product; `canonicalCorpusParity` and ordering/process tests pass. |
| 2 | Only verified device-bound ES256 proofs can replace cached state; stale is never a local grant. | ✓ VERIFIED | Private `verify` completes profile/binding/signature checks before `cache.replace`; stale maps only to `staleOffline(revalidationDue, reconnectRequired)`. |
| 3 | Authenticated reconnect feeds compact bytes through the ordinary verification/cache boundary. | ✓ VERIFIED | `OfflineReconnect.swift:13` passes host-returned `Data` directly to `applyServerProof`; reconnect tests pass. |
| 4 | Cache write/recovery failures preserve the complete authenticated prior cache. | ✓ VERIFIED | Prepared HMAC-authenticated transaction/backup recovery is locked; late-fault and fresh-process tests pass. |
| 5 | Public tests cover canonical, malformed, rotation, ordering, recovery, and iOS 16 compilation is merge-gated. | ✓ VERIFIED | 21 Swift tests plus both boundary scripts pass; CI macOS job invokes the iOS script. |
| 6 | StoreKit, host auth/UI, bridge runtime, and device feasibility stay out of scope and are not promoted. | ✓ VERIFIED | Runtime-source gate rejects host/test APIs; capability report/evidence hashes remain unchanged and feasibility-blocked. |
| 7 | Cached loading of absent/tampered cache is read-only and bounded. | ✓ VERIFIED | `recoverProof` authenticates under lock; `cache loads are read-only` test passes. |
| 8 | Untrusted malformed compact proofs remain bounded at the public result boundary. | ✓ VERIFIED | 256-KiB compact, encoded/decoded segment guards precede base64/JSON; depth 32 cap precedes Foundation parsing; public hostile-input regression passes. |
| 9 | The public result boundary is exactly four immutable `Sendable` states. | ✓ VERIFIED | `OfflineEntitlementState` has only `fresh`, `staleOffline`, `denied`, and `invalid`; associated enums are closed `Sendable` values. |
| 10 | Stale continuity is not local grant authority. | ✓ VERIFIED | Expired allow returns only `staleOffline(...reconnectRequired)`; README limits it to study/progress. |
| 11 | Canonical corpus fixtures and signing keys remain test-only. | ✓ VERIFIED | `verify_ios_offline_client.sh` rejects fixture/key references in core sources and passed. |
| 12 | Equal-revision signed deny wins over allow and repeated inputs are idempotent. | ✓ VERIFIED | `ProofHighWater.accepts` and `denyPrecedenceAndIdempotency` pass. |
| 13 | Interrupted or concurrent replacement cannot weaken signed-deny ordering. | ✓ VERIFIED | Process race/recovery suites finish with the authenticated signed denial where applicable. |
| 14 | Repeated verification cannot add authority. | ✓ VERIFIED | Equal proof returns identical; superseded evidence remains invalid as tested. |
| 15 | Time checks prevent a cached proof from regaining fresh authority after clock rollback. | ✓ VERIFIED | HMAC-signed v3 `observed_at` is compared/advanced under cache lock; fresh-client rollback behavior passes. |
| 16 | Every declared late durability fault preserves the exact prior authenticated cache. | ✓ VERIFIED | `lateDurabilityFailureRecoversExactPrior` and fresh-process rollback recovery cover restore and directory-sync faults. |
| 17 | Reconnect remains host-owned and transports compact bytes only. | ✓ VERIFIED | Protocol has one `reconnectProof() -> Data` method; no endpoint/credential API exists. |
| 18 | Reconnect reuses direct verified admission. | ✓ VERIFIED | Direct delegate call at `OfflineReconnect.swift:13`; focused reconnect suite passes. |
| 19 | Concurrent reconnect cannot weaken cached authority. | ✓ VERIFIED | Concurrent allow/deny reconnect regression ends in signed denial. |
| 20 | Apple helper remains explicit ThisDeviceOnly policy without key custody. | ✓ VERIFIED | Helper only maps host descriptors/outcomes; Apple tests pass. |
| 21 | Crosswake tracer consumes the local standalone package. | ✓ VERIFIED | Local SwiftPM dependency and tracer conformance test pass. |
| 22 | iOS 16 core compilation is merge-blocking. | ✓ VERIFIED | CI `ios-offline-client` job on macOS invokes a passing arm64 iPhoneOS 16 core build. |
| 23 | Deterministic checks cannot promote Crosswake feasibility. | ✓ VERIFIED | Gate requires all capability statuses to remain `feasibility_blocked`; hashes were unchanged. |
| 24 | Documentation retains host ownership and stale non-grant semantics. | ✓ VERIFIED | Package and tracer READMEs state both constraints. |
| 25 | Installed core excludes fixtures, keys, and host-product claims. | ✓ VERIFIED | Runtime-surface source scan in iOS gate passes. |
| 26 | Malformed/HMAC-invalid cache can be replaced by a verified direct proof. | ✓ VERIFIED | Private verifier/cache boundary regression passes. |
| 27 | Canonical profile requires bounded claims/benefits and bounded deny reasons. | ✓ VERIFIED | Exact schema/type/string/collection checks and adversarial regression pass. |
| 28 | Process harness reports rejected admission as unsuccessful without leaking proof material. | ✓ VERIFIED | Focused harness process regression passes. |

**Score:** 28/28 truths verified (0 present but behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `Package.swift` | iOS 16 SwiftPM core/Apple products | ✓ VERIFIED | Separate core/Apple libraries; crash harness is not a product dependency. |
| `OfflineEntitlementClient.swift` | Strict verifier and narrow facade | ✓ VERIFIED | Bounds, canonical verification, device binding, four-state mapping, and durable observed-time admission are implemented and exercised. |
| `AtomicOfflineCache.swift` | Recoverable authenticated atomic persistence | ✓ VERIFIED | v2 compatibility, v3 authenticated `observed_at`, prepared transactions, backup recovery, and locking are substantive and tested. |
| `CanonicalJSONAdmission.swift` | Duplicate-aware bounded JSON admission | ✓ VERIFIED | Unique member checking and maximum nesting depth 32 run before Foundation parsing. |
| `OfflineReconnect.swift` | Host-owned byte-only reconnect | ✓ VERIFIED | Calls normal admission once; no host transport ownership. |
| Core/process/reconnect tests | Behavioral proof of authority/cache invariants | ✓ VERIFIED | 21 tests in 4 suites pass. |
| iOS CI gate/tracer consumer | Compilation and non-promotion boundary | ✓ VERIFIED | Both scripts and tracer conformance pass. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `verify(_:now:)` | `CanonicalJSONAdmission.validate` | bound then duplicate-safe JSON admission | ✓ WIRED | Segment bounds at lines 72–81; scanner calls at line 82 occur before `JSONSerialization`. |
| `applyServerProof` | `AtomicOfflineCache.replace` | opaque verified proof plus observation | ✓ WIRED | Line 41 verifies first; line 42 performs locked durable admission. |
| `loadCachedState` | authenticated cache + observed-time commit | recovery, re-verification, then locked observe | ✓ WIRED | Lines 54–57 recover opaque bytes, verify them, then call `cache.observe`. |
| `AtomicOfflineCache.replace` | transaction recovery | locked recovery before prior-state inspection | ✓ WIRED | `recoverPendingTransaction()` is first inside `withLock` at line 30. |
| rollback faults | actual restoration operations | overwrite and parent sync | ✓ WIRED | Fault hooks surround restore/sync; direct and fresh-process tests pass. |
| reconnect | direct admission | host bytes to private verifier/cache | ✓ WIRED | Exact delegation at `OfflineReconnect.swift:13`. |
| tracer/CI | standalone core and iOS gate | local package dependency + macOS workflow step | ✓ WIRED | `verify_ios_offline_client.sh` and CI workflow pass. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Offline client | Compact proof | Host direct/reconnect bytes or authenticated cache | Strict verification precedes any state/persistence | ✓ FLOWING |
| Atomic cache | Verified opaque proof + `observed_at` | Private verifier result and supplied current time | HMAC-authenticated v3 envelope/transaction with recovery | ✓ FLOWING |
| Crosswake tracer | Core facade | Local SwiftPM path dependency | Tracer conformance test imports actual package | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Durable observed-time rollback | `swift test --filter OfflineEntitlementClientTests.durableObservedTimeRejectsRollbackAcrossFreshClientsAndRecovery` | 1 test passed | ✓ PASS |
| Bounded hostile admission | `swift test --filter OfflineEntitlementClientTests.boundedMalformedProofAdmissionDoesNotMutateCache` | 1 test passed | ✓ PASS |
| Signed-deny/idempotency | `swift test --filter OfflineEntitlementClientTests.denyPrecedenceAndIdempotency` | 1 test passed | ✓ PASS |
| Reconnect boundary/order | `swift test --filter OfflineReconnectTests` | 2 tests passed | ✓ PASS |
| Public package | `swift test --package-path packages/accrue-offline-client` | 21 tests in 4 suites passed | ✓ PASS |
| iOS/package/tracer boundary | `bash scripts/ci/verify_ios_offline_client.sh` | `OK` | ✓ PASS |
| Reference contract/non-promotion | `bash scripts/ci/verify_reference_scenario_contract.sh` | `OK` | ✓ PASS |
| Evidence immutability | `git diff --exit-code -- examples/crosswake_tracer/capability-report.json examples/crosswake_tracer/physical-device-evidence.md` | exit 0 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 223 probe script is declared or present.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| IOS-01 | 01–07 | Importable iOS SwiftPM client with canonical proof/high-water/allow-deny behavior. | ✓ SATISFIED | Core product, corpus, signed deny ordering, durable observed time, and iOS build all pass. |
| IOS-02 | 01–07 | ES256-only/device-bound proofs with stale-study-only continuity. | ✓ SATISFIED | Strict ES256/profile/binding checks, bounded malformed input, and stale non-grant mapping pass. |
| IOS-03 | 02–06 | Authenticated reconnect admits only verified newer allow/signed deny. | ✓ SATISFIED | Byte-only transport delegates to direct admission; reconnect ordering/concurrency tests pass. |

All Phase 223 requirement IDs are declared by its plans; none is orphaned. Later phases cover host integration and device evidence, not a missing Phase 223 deliverable, so no items are deferred.

### Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, hardcoded empty-output, or console-only implementation markers were found in Phase 223 package sources/tests. The generic `verify.key-links` helper reports older symbol-based links as unparseable because its `from` field requires a file path; each was manually traced above.

### Gaps Summary

None. Plan 07 closes both prior blockers with executable evidence: `observed_at` is authenticated in the v3 envelope and monotonically committed under the cache lock, while compact segment and nesting bounds execute before untrusted decode/recursive admission. The full package and iOS/non-promotion boundaries remain green.

---

_Verified: 2026-08-06T17:43:48Z_
_Verifier: the agent (gsd-verifier)_
