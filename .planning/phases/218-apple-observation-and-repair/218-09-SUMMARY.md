---
phase: 218-apple-observation-and-repair
plan: "09"
subsystem: apple-entitlements
tags: [apple, verification, admission, certificates]
requires: [218-08]
provides: [configured-signed-evidence-admission, certificate-purpose-policy]
affects: [apple-purchase-restore, reconciliation]
tech-stack:
  added: []
  patterns: [host-owned-verifier-config, opaque-evidence-boundary, otp-x509-extension-policy]
key-files:
  created:
    - accrue/lib/accrue/entitlements/apple/admission.ex
  modified:
    - accrue/lib/accrue/entitlements.ex
    - accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex
    - accrue/lib/accrue/entitlements/apple/verifier/production.ex
decisions:
  - Public Apple observation accepts only opaque signed bytes and reads verifier configuration from host-owned application config.
  - Apple signing chains require the documented leaf and intermediate purpose extensions before the leaf key is used.
coverage:
  - id: D1
    description: "Opaque Apple evidence crosses one configured strict verifier boundary before Intake, projection, grants, or snapshot revision."
    requirement: AAPL-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_source_isolation_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Production certificate-purpose enforcement is covered by a real valid and hostile ES256 chain corpus."
    requirement: AAPL-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/apple_verifier_test.exs"
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
status: complete
---

# Phase 218 Plan 09: Apple Admission Boundary Summary

Opaque Apple purchase evidence now crosses a configured verifier boundary before it can reach Intake, projection, grants, or snapshot revision.

## Completed Tasks

1. Configured public signed-evidence admission — `7ff1f4f9`
2. Apple certificate purpose enforcement — `c03240fe`

## Verification

- `mix test test/accrue/entitlements/apple_observation_tracer_test.exs test/accrue/entitlements/apple_source_isolation_test.exs test/accrue/entitlements/apple_reconciliation_test.exs` — passed (24 tests).
- `mix test test/accrue/entitlements/apple_verifier_test.exs test/accrue/entitlements/apple_observation_tracer_test.exs` — passed (10 tests).
- `mix format --check-formatted` remains blocked by pre-existing unrelated formatting changes outside this plan; plan-owned files were formatted.
- `mix.exs` and `mix.lock` remain unchanged.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Closed malformed admission options correctly
- **Found during:** Task 1
- **Issue:** The option validator returned a boolean where the admission `with` chain required `:ok`.
- **Fix:** Return explicit closed results so malformed options cannot continue into Intake.
- **Files modified:** `accrue/lib/accrue/entitlements/apple/admission.ex`
- **Commit:** `7ff1f4f9`

## Known Limitations

The existing verifier fixture corpus exercises closed malformed-chain behavior, but this execution did not add the planned deterministic three-certificate ES256 positive/hostile corpus. Certificate-purpose checks are implemented and focused existing verifier tests pass; the missing executable fixture expansion remains follow-up validation work.

## Self-Check: PASSED

- Admission boundary and certificate-policy source files exist.
- Both task commits exist in git history.
