---
phase: 219-offline-study-contract
plan: 04
subsystem: entitlements
tags: [offline, jws, jwks, reconnect, postgresql]
requires:
  - phase: 219-03
    provides: durable device, challenge, and issuance persistence
provides:
  - Locked canonical self-verified allow and deny proof issuance
  - Durable per-kid retirement requirements and JWKS validation
  - Authenticated reconnect source coordination with fail-closed pending outcomes
affects: [offline clients, host source adapters, key rotation]
tech-stack:
  added: []
  patterns: [locked terminal issuance, one-time reconnect PoP, due-only coordination]
key-files:
  created:
    - accrue/lib/accrue/entitlements/offline/issuer.ex
    - accrue/lib/accrue/entitlements/offline/reconnect.ex
    - accrue/lib/accrue/entitlements/offline/source_coordinator.ex
  modified:
    - accrue/lib/accrue/entitlements/offline.ex
    - accrue/lib/accrue/entitlements/offline/issuance.ex
    - accrue/lib/accrue/entitlements/offline/key_provider.ex
    - accrue/lib/accrue/entitlements/offline/proof.ex
    - accrue/test/accrue/entitlements/offline_reconnect_test.exs
key-decisions:
  - "Issue only from account/device rows locked in stable order and the committed Snapshot."
  - "Keep keys with unbounded issuances indefinitely; require actual expiry plus 86,400 seconds for finite retirement."
  - "Consume authenticated reconnect PoP before due-source inspection; unresolved due work returns no replacement proof."
metrics:
  duration: 0h 6m
  completed_date: 2026-08-04
status: complete
---

# Phase 219 Plan 04: Locked offline issuance and reconnect Summary

Locked canonical snapshot issuance now produces a self-verified compact allow or deny proof, persists its privacy-safe metadata atomically, and coordinates authenticated due-source reconnects without partial positive results.

## Tasks Completed

1. Issued locked, self-verified canonical proofs with persistent high-water updates and durable key retirement requirements.
2. Added authenticated reconnect PoP consumption, due-only source refresh, repair enqueueing, and typed no-proof pending/needs-repair outcomes.

## Verification

- `mix test test/accrue/entitlements/offline_reconnect_test.exs --only issuance` — PASS (2 tests)
- `mix test test/accrue/entitlements/offline_reconnect_test.exs test/accrue/entitlements/offline_registration_test.exs test/accrue/entitlements/projector_test.exs` — PASS (13 tests)
- `mix compile` and `mix format` on modified modules — PASS

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected issuance time-order validation
- **Found during:** Task 1 GREEN verification
- **Issue:** Structural comparison of DateTime values rejected valid persisted issuance rows, returning `:persistence_failed`.
- **Fix:** Compare timestamps with `DateTime.compare/2` and retain the database time-order constraint.
- **Commit:** `590c9cfc`

2. [Rule 1 - Bug] Made the projector fixture effective at the test clock
- **Found during:** Task 1 GREEN verification
- **Issue:** The fixture grant was future-effective, so canonical projection correctly returned `:no_material_change`.
- **Fix:** Made the fixture effective before the database test clock while retaining the intended issuance timestamp.
- **Commit:** `590c9cfc`

## Self-Check: PASSED

- Required implementation files exist.
- RED (`987ed614`) and GREEN task commits (`590c9cfc`, `f1e530e6`) exist.
