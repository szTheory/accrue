---
phase: 215-research-contracts-and-crosswake-feasibility
plan: 05
subsystem: testing
tags: [entitlements, es256, jws, cryptokit, otp-crypto, offline-cache]
requires:
  - phase: 215-03
    provides: canonical DecisionCases and Crosswake client contract
provides:
  - ES256-verified, DecisionCase-bound offline golden-vector contract in Elixir and Swift
  - deterministic atomic cache replacement fault proof
affects: [219-offline-study-contract, crosswake-client]
tech-stack:
  added: []
  patterns: [pinned ES256 fixture verification, verified candidate then atomic replacement]
key-files:
  created: []
  modified:
    - accrue/test/support/entitlements/offline_golden_vector_verifier.ex
    - examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift
    - examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift
key-decisions:
  - "Use OTP :crypto and CryptoKit with the pinned TEST-ONLY P-256 public key; no runtime issuer or new dependency."
  - "Treat candidate durability and rename as the sole cache visibility boundary; failures preserve old state before rename and complete new state after it."
requirements-completed: [RSCH-02, RAIL-05]
coverage:
  - id: D1
    description: DecisionCase-bound JWS corpus verifies ES256 signatures, bindings, and high-water ordering in both runtimes.
    requirement: RSCH-02
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/offline_golden_vectors_test.exs; examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift"
        status: pass
    human_judgment: false
  - id: D2
    description: Atomic cache replacement keeps only old or complete new cache state across deterministic faults.
    requirement: RAIL-05
    verification:
      - kind: unit
        ref: "examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift#cache replacement exposes only the old or complete new verified state"
        status: pass
    human_judgment: false
duration: 1h
completed: 2026-07-31
status: complete
---

# Phase 215 Plan 05: Offline Signed-Vector Contract Summary

**Pinned ES256 offline-entitlement vectors now execute real Elixir and Swift verification, high-water denial handling, and atomic cache-fault assertions.**

## Accomplishments

- Bound deterministic vectors to canonical DecisionCases and kept exporter bytes current.
- Verified compact ES256 JWS signatures before enforcing fixed issuer, audience, type, account, device, thumbprint, revision, iat, and freshness constraints.
- Proved Swift cache replacement exposes only the existing cache before rename or a complete verified replacement after rename.

## Verification

- `cd accrue && mix accrue.entitlements.decision_cases --check` — passed
- `cd accrue && mix test test/accrue/entitlements/decision_cases_test.exs` — passed (9 tests)
- `cd accrue && mix test test/accrue/entitlements/offline_golden_vectors_test.exs` — passed
- `cd examples/crosswake_tracer && swift test --filter GoldenVectorTests` — passed (2 tests)

## Task Commits

1. Task 1: derive and bind vectors — `467192ca`, `099157c3`
2. Task 2: execute signed verification and atomic replacement — `ec2f8efc`, `3ea7de66`, `1b9ba05f`

## Files Modified

- `accrue/lib/accrue/entitlements/decision_cases/markdown.ex` — produces a genuinely changed, fixed-length invalid signature fixture.
- `accrue/test/support/entitlements/offline_golden_vector_verifier.ex` — OTP ES256/JWS and claim/high-water verifier.
- `examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift` — CryptoKit verifier and atomic cache seam.
- `examples/crosswake_tracer/Tests/AccrueOfflineClientTests/GoldenVectorTests.swift` — parity and fault-boundary assertions.

## Decisions Made

- Fixture keys remain explicitly TEST-ONLY and never enter application configuration or runtime issuance.
- The deterministic server/vector lane remains merge-blocking independently of Crosswake physical-device feasibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced structural JWS parsing with cryptographic verification.**
- **Found during:** Task 2
- **Issue:** The recovery implementation accepted labelled fixtures after parsing headers and payloads without verifying ES256 signatures.
- **Fix:** Added OTP/CryptoKit signature verification, pinned-key construction, bounded rejection reasons, and observed-result assertions.
- **Commit:** `1b9ba05f`

**2. [Rule 2 - Missing critical functionality] Added deterministic atomic replacement fault seam.**
- **Found during:** Task 2
- **Issue:** No candidate-write/rename boundary existed to prove cache fault behavior.
- **Fix:** Added synchronized candidate write plus atomic replacement, with before/after rename failure tests.
- **Commit:** `1b9ba05f`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all verifier and Swift cache files exist.
- Confirmed commits `467192ca`, `099157c3`, `ec2f8efc`, `3ea7de66`, and `1b9ba05f` exist.
