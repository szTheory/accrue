---
phase: 220-first-adopter-proof-and-release-gates
plan: 17
subsystem: entitlements
tags: [elixir, ecto, offline-entitlements, device-replacement, jwks, key-retention]
requires:
  - phase: 220-13
    provides: closed reference command families and production-backed family executors
provides:
  - Device replacement family dispatch through the public Offline.replace_device/3 facade
  - Fresh durable replacement observations and replay-adversarial coverage
  - Issuance-derived JWKS retention and wrong-adapter rejection for device/key actions
affects: [220-18, 220-19, 220-20, proof-02, offline-entitlements]
tech-stack:
  added: []
  patterns: [family-owned runtime secrets, fresh persistence collection, issued-proof key retirement]
key-files:
  created:
    - accrue/test/support/entitlements/reference_scenario_executor/device_keys.ex
    - accrue/test/accrue/entitlements/reference_scenario_device_keys_test.exs
  modified:
    - accrue/test/support/entitlements/reference_scenario_executor.ex
key-decisions:
  - "Replacement runtime secrets remain inside the family executor; its shared observed tuple contains only bounded public and persisted facts."
  - "Key retention is derived from persisted finite Issuance rows and rendered by Offline.verification_keys_with_issued_retention/1, not fixture key lists."
requirements-completed: [PROOF-02]
coverage:
  - id: D1
    description: "The device replacement scenario executes Offline.replace_device/3 and independently observes the prior/replacement devices, consumed challenge, audit delta, snapshot revision, and replay outcomes."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/reference_scenario_device_keys_test.exs test/accrue/entitlements/offline_registration_test.exs:238 --seed 458442 --max-failures 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "A finite issued proof retains its old public kid until the required margin, then permits retirement while wrong production adapters fail device/key matchers."
    requirement: PROOF-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/reference_scenario_device_keys_test.exs test/accrue/entitlements/offline_reconnect_test.exs:780 --seed 458442 --max-failures 1"
        status: pass
    human_judgment: false
metrics:
  duration: 6m
  completed: 2026-08-04
  tasks: 2
  files: 3
status: complete
---

# Phase 220 Plan 17: Device Replacement and Key Retention Summary

**Device replacement now runs through the shipped public facade with fresh durable evidence, while key rotation proves finite issuance-backed JWKS retention without exposing proof or private-key material.**

## Accomplishments

- Extracted the real replacement setup, PoP dispatch, and persisted collector into the device/key executor family.
- Added exact replay and divergent replay coverage with bounded observations only.
- Added issued-proof retention proof for retained and retired public kids, plus real generic, no-effect, registration, and snapshot substitute rejection.

## Task Commits

1. **Task 1: Route device replacement through the shipped API and fresh collector** — `98059ed7` (`test`), `9b526a63` (`feat`)
2. **Task 2: Execute issued-proof key retention and defeat registration/snapshot substitutes** — `fb225b43` (`test`), `78ecbbdc` (`feat`)

## Verification

- `cd accrue && mix format --check-formatted test/support/entitlements/reference_scenario_executor.ex test/support/entitlements/reference_scenario_executor/device_keys.ex test/accrue/entitlements/reference_scenario_device_keys_test.exs` — passed.
- `cd accrue && mix test test/accrue/entitlements/reference_scenario_device_keys_test.exs test/accrue/entitlements/offline_registration_test.exs:238 --seed 458442 --max-failures 1` — 4 tests, 0 failures.
- `cd accrue && mix test test/accrue/entitlements/reference_scenario_device_keys_test.exs test/accrue/entitlements/offline_reconnect_test.exs:780 --seed 458442 --max-failures 1` — 4 tests, 0 failures.
- Combined focused verification — 5 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Next Phase Readiness

The dedicated device/key family provides production-backed replacement and issued-retention evidence for downstream PROOF-02 aggregation.

## Self-Check: PASSED

- Device/key executor and focused family test exist.
- Task commits `98059ed7`, `9b526a63`, `fb225b43`, and `78ecbbdc` exist in git history.
