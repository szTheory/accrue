---
phase: 219-offline-study-contract
plan: "03"
subsystem: entitlements
tags: [offline, postgres, ecto, p256, proof-of-possession, nonce, security]
requires:
  - phase: "219-01"
    provides: ES256 public-key and offline-proof protocol foundation
  - phase: "219-02"
    provides: four-state offline continuity contract
provides:
  - constrained public P-256 device key, one-time challenge, and issuance metadata persistence
  - host-authorized P-256 proof-of-possession device registration with row-locked nonce consumption
  - executable installer propagation and real PostgreSQL migration evidence
affects: [219-04, offline proof issuance, authenticated reconnect]
tech-stack:
  added: []
  patterns: [PostgreSQL constraints mirror changeset validation, hashed transient request material, row-locked challenge consumption]
key-files:
  created:
    - accrue/priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs
    - accrue/lib/accrue/entitlements/offline/challenge.ex
    - accrue/lib/accrue/entitlements/offline/issuance.ex
    - accrue/lib/accrue/entitlements/offline/registration.ex
  modified:
    - accrue/lib/accrue/entitlements/device.ex
    - accrue/lib/accrue/entitlements/offline.ex
    - accrue/test/accrue/entitlements/offline_registration_test.exs
    - accrue/test/mix/tasks/accrue_install_test.exs
key-decisions:
  - "Public JWK storage is exact EC/P-256 x/y material with a recomputed RFC-7638 thumbprint; private or auxiliary JWK members are rejected."
  - "Challenges retain nonce and idempotency digests only; the transient raw nonce is supplied for signature verification and never persisted."
  - "PostgreSQL row locks and constraints, rather than idempotency alone, serialize registration authority."
patterns-established:
  - "Offline registration signatures use a versioned length-prefixed binding of account, installation, challenge, nonce, and idempotency digest."
  - "Exact idempotent replay returns the existing active-device result only after revalidating the same proof binding."
requirements-completed: [OFF-05, OFF-06]
coverage:
  - id: D1
    description: Constrained durable device-key, nonce, and issuance/high-water state applies to PostgreSQL.
    requirement: OFF-05
    verification:
      - kind: integration
        ref: MIX_ENV=test mix ecto.migrate --quiet; test/accrue/entitlements/offline_registration_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Authenticated one-time P-256 proof-of-possession registration is locked, replay-safe, and installer-propagated.
    requirement: OFF-06
    verification:
      - kind: integration
        ref: test/accrue/entitlements/offline_registration_test.exs; test/mix/tasks/accrue_install_test.exs
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-04
status: complete
---

# Phase 219 Plan 03: Offline Proof-State Persistence Summary

**PostgreSQL-backed public P-256 device registration with hashed one-time challenges, issuance ordering metadata, and row-locked proof-of-possession.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-04T00:24:00Z
- **Completed:** 2026-08-04T00:32:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Applied `20260803040000_create_accrue_offline_proof_state` to the real test PostgreSQL repository, adding bounded public-JWK, nonce, and issuance/high-water constraints.
- Added exact P-256 JWK validation and RFC-7638 SHA-256 thumbprint recomputation without storing a private key, proof, raw nonce, idempotency key, or correlation value.
- Added host-authorized challenge and registration facade APIs that verify canonical proof-of-possession, lock and consume challenges, and coalesce exact idempotent replays.
- Extended installer coverage to require exactly one copied offline proof-state migration with its named constraint.

## Task Commits

1. **Task 1: Add constrained challenge, device-key, and issuance persistence** — `fdc87921` (RED), `54dff053` (GREEN)
2. **Task 2: Apply the Ecto migration gate and register a proof-of-possession device** — `d63ea184` (RED), `f1e483b4` (GREEN)

## Files Created/Modified

- `accrue/priv/repo/migrations/20260803040000_create_accrue_offline_proof_state.exs` — additive device-key column and constrained challenge/issuance tables.
- `accrue/lib/accrue/entitlements/device.ex` — exact public P-256 JWK validation and recomputed thumbprint.
- `accrue/lib/accrue/entitlements/offline/{challenge,issuance,registration}.ex` — durable schemas and locked proof-of-possession registration.
- `accrue/lib/accrue/entitlements/offline.ex` — host-authorized public challenge and registration facade.
- `accrue/test/accrue/entitlements/offline_registration_test.exs` — real-repository persistence, constraint, proof, replay, and privacy tests.
- `accrue/test/mix/tasks/accrue_install_test.exs` — exact installer migration propagation test.

## Decisions Made

- Stored only validated public EC material and fixed-length digests; existing device rows may retain a nil public JWK for backwards-compatible lifecycle history, while new proof registration requires the validated material.
- Used DER ECDSA signatures for the native proof-of-possession boundary; the canonical message remains language-neutral and binds every authority-relevant value.
- Kept authorization host-owned through required `authorize/2` callbacks and emitted no key, nonce, signature, or account-token telemetry fields.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added transient raw nonce to the registration request**
- **Found during:** Task 2
- **Issue:** A nonce digest alone cannot reconstruct the required canonical nonce-bound signature input.
- **Fix:** Added a transient `nonce` request field, hashed it before comparison, and never stored or logged it.
- **Files modified:** `accrue/lib/accrue/entitlements/offline/registration.ex`, `accrue/test/accrue/entitlements/offline_registration_test.exs`
- **Verification:** Focused registration test proves storage contains only the digest and successful registration verifies the nonce-bound signature.
- **Committed in:** `f1e483b4`

**2. [Rule 1 - Bug] Corrected installer migration uniqueness assertion syntax**
- **Found during:** Task 2 verification
- **Issue:** A function call was placed directly in a match pattern, preventing the installer test from compiling.
- **Fix:** Bound the expected migration path before pinning it in the assertion.
- **Files modified:** `accrue/test/mix/tasks/accrue_install_test.exs`
- **Verification:** Focused installer and registration suites pass.
- **Committed in:** `f1e483b4`

**Total deviations:** 2 auto-fixed (1 Rule 2, 1 Rule 1).

## Issues Encountered

- Context7 CLI was unavailable; local installed JOSE source and a short runtime probe verified the supported public-key conversion API used by the proof test.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 219-04 can issue and order device-bound proofs using the persisted `Issuance` records and the active device's public JWK under the same account/device lock.
- The test database is already migrated through the required offline proof-state schema.

## Self-Check: PASSED

- All persisted-state, registration, installer, and summary artifacts exist on disk.
- RED and GREEN commits exist for both TDD tasks.
