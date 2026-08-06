---
phase: 223-ios-compatible-accrue-offline-client
reviewed: 2026-08-06T17:11:38Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - packages/accrue-offline-client/Package.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientAppleTests/KeychainCacheKeyTests.swift
  - packages/accrue-offline-client/README.md
  - examples/crosswake_tracer/Package.swift
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/README.md
  - scripts/ci/verify_ios_offline_client.sh
  - scripts/ci/verify_reference_scenario_contract.sh
  - .github/workflows/ci.yml
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 223: Code Review Report

**Reviewed:** 2026-08-06T17:11:38Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

The package facade, verifier/cache call path, reconnect seam, Apple policy helper, test harnesses, documentation, and CI integration were reviewed. Package tests and the iOS compatibility gate pass, but those checks do not exercise a persistent clock rollback and do not bound attacker-controlled JSON parser depth/size. Both defects can violate the offline authority boundary.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The public API cannot maintain its required clock high-water mark

**Classification:** BLOCKER

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:20-22, 84`

**Issue:** Rollback detection only compares `now` with the optional, construction-time `Configuration.clockHighWater`; the client never records a successful observation, exposes no updated high-water value for the host to persist, and the authenticated cache stores no wall-clock high-water. With the README's normal configuration (the default is `nil`), a user can first load an otherwise-valid proof near its `fresh_until`, then set the device clock back to any time after `nbf` and before `fresh_until`. `loadCachedState(now:)` verifies the same cached proof as fresh again, extending fresh access after it should have become stale. The existing test supplies a static high-water only for a rejection case and therefore does not test this transition.

**Fix:** Make last-seen wall-clock time a durable authenticated cache invariant (updated only monotonically under the same lock) or add a required host-owned persistent clock store with an atomic read/update API. Reject any operation where `now` is below the persisted value, and add a test that advances beyond `fresh_until`, rolls back to an earlier post-`nbf` time, and expects `.clockRollback` rather than `.fresh`.

### CR-02: Unbounded pre-verification JSON parsing permits a malicious proof to crash the host

**Classification:** BLOCKER

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:62-64`

**Issue:** The facade invokes the internal duplicate-member scanner before signature verification, but it applies no compact-proof/decoded-segment size limit or nesting limit. The scanner recursively descends every attacker-controlled array/object. A reconnect response containing a base64url payload with sufficiently deep nesting can overflow the Swift stack before the signature is checked; a huge segment also forces unbounded allocation. This is reachable through the public host transport without a signing key and terminates the host instead of returning the required bounded invalid outcome.

**Fix:** Before decoding, cap compact-proof and header/payload byte lengths. Make the duplicate-member scanner iterative or enforce a small maximum nesting depth, returning `.malformed` for either limit. Add unsigned oversized and deeply nested compact-JWS cases that verify `applyServerProof` returns `.invalid(.malformed, .reconnectRequired)` without crashing.

## Warnings

### WR-01: Valid signed JSON containing escaped supplementary Unicode is rejected

**Classification:** WARNING

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:63`

**Issue:** The duplicate-member admission dependency used at this line treats each `\\uXXXX` escape as an independent Unicode scalar. JSON represents non-BMP characters as a high/low-surrogate pair, so a valid signed claim such as `"\\uD83D\\uDE00"` is rejected before Foundation decodes it. This unnecessarily refuses valid proofs whose bounded string values contain escaped supplementary Unicode; no scoped test covers that interoperability case.

**Fix:** Update the admission scanner to combine valid JSON surrogate pairs and reject only lone/mismatched surrogates. Add signed fixtures for a valid pair and for invalid lone-surrogate input.

---

_Reviewed: 2026-08-06T17:11:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
