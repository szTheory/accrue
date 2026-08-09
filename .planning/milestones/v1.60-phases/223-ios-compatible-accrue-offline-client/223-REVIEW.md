---
phase: 223-ios-compatible-accrue-offline-client
reviewed: 2026-08-06T17:47:45Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/ci.yml
  - examples/crosswake_tracer/Package.swift
  - examples/crosswake_tracer/README.md
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTracerTests/PackageConformanceTests.swift
  - packages/accrue-offline-client/Package.swift
  - packages/accrue-offline-client/README.md
  - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/CanonicalJSONAdmission.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineReconnect.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientAppleTests/KeychainCacheKeyTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientCoreTests/OfflineReconnectTests.swift
  - packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift
  - scripts/ci/verify_ios_offline_client.sh
  - scripts/ci/verify_reference_scenario_contract.sh
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---

# Phase 223: Code Review Report

**Reviewed:** 2026-08-06T17:47:45Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

All scoped package, consumer, test, and CI files were reviewed against Phase 223 plans and history. The package suite and `verify_ios_offline_client.sh` pass, but a cached-read/replacement race can return a superseded allow after a signed denial is installed. Cache reuse across security contexts is also not safely namespaced.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Cached reads can return an allow after a concurrent signed denial wins

**Classification:** BLOCKER

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:54-57`; `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift:101-103,105-114`

**Issue:** `loadCachedState` reads proof A under the cache lock, releases that lock, verifies A, then calls `observe`. A concurrent `applyServerProof` can install a newer (or equal-revision) signed-denial proof B in that gap. `observe` calls `replace(A, ...)`, but discards its `.superseded` result; `loadCachedState` then derives and returns A's `.fresh` state. This directly violates the phase requirement that cached recovery, proof order, and observation remain one locked operation and lets a host act on stale allow authority after denial is durable.

**Fix:** Add a single locked cache operation that authenticates/retrieves the envelope, verifies it, compares/commits observed time, and returns the proof that is still current. Alternatively, make `observe` return `Admission` and retry recovery when it is `.superseded`; never derive a public result from a proof that was not current at the final lock boundary. Add a deterministic race test: pause a cached load after recovery, admit a same-revision denial, resume, and assert the load returns `.denied` (or a bounded non-grant), never `.fresh`.

## Warnings

### WR-01: Cache high-water is not bound to the configured account/device context

**Classification:** WARNING

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift:154-176`; `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:41-45`

**Issue:** Authenticated envelopes bind their HMAC to the cache path but contain no issuer, audience, account subject, device thumbprint, or JWKS-context fingerprint. If a host reuses one cache URL/key while switching accounts or device registrations, a valid higher-revision proof from the old context remains trusted for ordering. A newly verified proof for the current context can consequently be reported `.superseded` and never cached, even though `loadCachedState` later rejects the old proof's bindings. This creates a persistent denial/reconnect loop after a normal identity transition.

**Fix:** Include a stable fingerprint of the verification context (at least issuer, audience, subject, device thumbprint, and key-set version/hash) in the authenticated envelope and transaction records. On mismatch, treat the prior cache as non-authoritative for ordering and replace/quarantine it only after the current proof verifies. Add a regression using the same URL/key with two account configurations.

## Info

### IN-01: Coordinator high-water state is dead and misleading

**Classification:** INFO

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift:282-285`

**Issue:** `CacheCoordinator.highWater` is written by `record` but never read; authoritative ordering always reparses the persisted envelope. The unused mutable state makes it appear that ordering has an in-memory component when it does not.

**Fix:** Remove `highWater` and `record`, or use it deliberately with an invariant-preserving read path and tests.

---

_Reviewed: 2026-08-06T17:47:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
