---
phase: 223-ios-compatible-accrue-offline-client
reviewed: 2026-08-06T16:01:50Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/ci.yml
  - examples/crosswake_tracer/Package.swift
  - examples/crosswake_tracer/README.md
  - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
  - examples/crosswake_tracer/Tests/AccrueOfflineClientTracerTests/PackageConformanceTests.swift
  - packages/accrue-offline-client/.gitignore
  - packages/accrue-offline-client/Package.swift
  - packages/accrue-offline-client/README.md
  - packages/accrue-offline-client/Sources/AccrueOfflineCacheCrashHarness/main.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientApple/KeychainCacheKey.swift
  - packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift
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
  critical: 3
  warning: 2
  info: 0
  total: 5
status: issues_found
---

# Phase 223: Code Review Report

**Reviewed:** 2026-08-06T16:01:50Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The new SwiftPM package, conformance consumer, documentation, and CI gate were reviewed at standard depth. The package tests and `verify_ios_offline_client.sh` pass, but the runtime verifier no longer enforces the canonical proof profile promised by the phase, and cache-file tampering can make the facade permanently unable to admit a valid new proof. The test suite also leaves the claimed ordering and durability guarantees materially under-asserted.

## Critical Issues

### CR-01: Verifier admits signed proofs that violate the required claim schema

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:72-78`
**Issue:** `verify` only checks the top-level payload key set and a handful of scalar fields. It does not require a non-empty `jti`, an exact `cnf` object containing only `jkt`, normalized/non-empty allow `plans`/`features`/`quantities`, or a permitted `denial_reason` for deny proofs. Consequently, a correctly ES256-signed but semantically malformed proof can be persisted and returned as `.fresh` or `.denied`, violating the phase's exact-profile admission boundary.
**Fix:** Decode into strict typed claim structures after rejecting duplicate keys. Validate every required field and its bounds, require `cnf` keys to equal `["jkt"]`, require canonical sorted/unique non-empty allow benefits and positive quantities, and allow only the canonical denial reasons before constructing `VerifiedOfflineProof`.

### CR-02: Duplicate JSON members are silently accepted in signed JWS input

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:63-66`
**Issue:** `JSONSerialization` collapses duplicate object keys rather than rejecting them. The header and payload are signed bytes, so an issuer can produce a JWS whose duplicate members are interpreted differently by another component (for example, first-wins versus last-wins parsing), while this client admits the collapsed value. This violates the explicitly required strict/canonical JWS profile and recreates a parser-differential authorization risk.
**Fix:** Run an object-aware duplicate-key rejection pass on `headerData` and `payloadData` before `JSONSerialization`, then retain the existing exact-key checks.

### CR-03: A corrupted cache permanently blocks authenticated recovery

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/AtomicOfflineCache.swift:25-28`
**Issue:** `replace` calls `loadVerifiedEnvelope()` before writing a verified replacement. Any malformed or HMAC-invalid existing cache throws, so `applyServerProof` returns `cache_write_failed` and cannot persist a fresh valid server proof. There is no public recovery/clear operation, allowing an attacker or interrupted write that corrupts the cache file to create a persistent offline-client denial of service.
**Fix:** Under the same file lock, distinguish an absent/invalid envelope from a valid prior envelope. Quarantine or remove only the invalid cache file, then atomically persist the newly verified proof; preserve normal high-water ordering only for an authenticated prior envelope.

## Warnings

### WR-01: JWKS selection does not enforce a signing key or unique `kid`

**File:** `packages/accrue-offline-client/Sources/AccrueOfflineClientCore/OfflineEntitlementClient.swift:81-85`
**Issue:** The verifier accepts the first matching JWK regardless of `use`, and duplicate matching `kid` entries make acceptance dependent on JWKS array order. That is inconsistent with the phase's strict key/profile and deterministic rotation requirements.
**Fix:** Require exactly one matching JWK with `kty=EC`, `crv=P-256`, `alg=ES256`, and `use=sig`; reject duplicate `kid` values and add shuffled/duplicate JWKS tests.

### WR-02: Process concurrency test permits the ordering violation it claims to prevent

**File:** `packages/accrue-offline-client/Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift:29-36`
**Issue:** The concurrent allow/deny test accepts either `.fresh` or `.denied`. It therefore passes if the allow wins, despite the phase requirement that equal-revision signed denial wins independent of concurrent writer order. The harness also discards `applyServerProof`'s result, so an unsuccessful child can still exit successfully.
**Fix:** Use deliberately equal-revision signed allow/deny fixtures, require the final state to be `.denied`, and have the harness exit nonzero when `applyServerProof` does not produce the expected successful admission.

---

_Reviewed: 2026-08-06T16:01:50Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
