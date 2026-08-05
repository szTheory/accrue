---
phase: 217-canonical-projection-and-compatibility
plan: 01
subsystem: entitlements
tags: [elixir, ecto, postgresql, oban, telemetry, integration-testing]
requires:
  - phase: 216-additive-rail-and-persistence-foundation
    provides: account, observation, and grant persistence contracts
provides:
  - real PostgreSQL projection proof from qualified observations to public snapshots
  - atomic revision, audit, and unique Oban follow-up behavior
  - reusable zero-human backend-plan automation contract
affects: [217-02, entitlement projection, automated validation]
tech-stack:
  added: []
  patterns: [row-locked projector transaction, transactional audit and Oban handoff, zero-human backend ratchet]
key-files:
  created: [accrue/test/accrue/backend_automation_contract_test.exs]
  modified: [accrue/lib/accrue/entitlements/projector.ex, accrue/test/accrue/entitlements/projector_test.exs, .planning/phases/217-canonical-projection-and-compatibility/217-01-PLAN.md, .planning/phases/217-canonical-projection-and-compatibility/217-VALIDATION.md]
key-decisions:
  - "Phase 217 backend verification is zero-human and rejects tracer or human-verify tasks when opted in."
  - "Projector no-ops are legal transaction results and material changes atomically include audit and Oban work."
requirements-completed: [ACCT-01, ACCT-02]
coverage:
  - id: D1
    description: Qualified Stripe and Apple observations project to a revisioned canonical snapshot with atomic audit and unique follow-up work.
    requirement: ACCT-01
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/accrue/backend_automation_contract_test.exs --exclude live_stripe"
        status: pass
    human_judgment: false
  - id: D2
    description: Stale, duplicate, and source-local retraction observations preserve survivor grants and return stable no-op results when authorization does not change.
    requirement: ACCT-02
    verification:
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/projector_test.exs --exclude live_stripe"
        status: pass
    human_judgment: false
metrics:
  duration: "~10m"
  completed_date: "2026-08-02"
status: complete
---

# Phase 217 Plan 01: Canonical Projection Tracer Summary

Qualified Stripe and Apple observations now have database-backed evidence for canonical snapshot projection, source-local retraction, material revisions, bounded audit data, Oban handoff, and telemetry metadata.

## Completed Work

- Replaced the export-only projector proof with `Accrue.RepoCase`, SQL Sandbox, host-owned manual Oban, audit, public snapshot, and telemetry integration tests.
- Made transaction no-op outcomes valid and retained their tagged public result.
- Added source-local retraction and stale-safe unique follow-up job configuration.
- Added a fixture-tested ExUnit automation contract; Phase 217 is opted into zero-human verification and its plan is now `type="auto"`.

## Verification

- `mix test test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/accrue/backend_automation_contract_test.exs` — 10 tests, 0 failures.
- `mix test test/accrue/entitlements --exclude live_stripe` — 159 tests, 0 failures.
- `mix format --check-formatted ...` — exit 0.
- `mix compile --warnings-as-errors` — exit 0.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the projector transaction contract and Oban uniqueness options.
   - **Found during:** Task 1 integration RED/GREEN cycle.
   - **Fix:** Returned tagged no-op results through the Repo transaction success envelope and used atom keys with worker-plus-args uniqueness.
   - **Commit:** 2017292e

2. [Rule 2 - Critical verification] Replaced the human tracer checkpoint with the reusable zero-human backend automation ratchet.
   - **Found during:** Task 1 checkpoint rejection.
   - **Fix:** Phase opt-in plus fixture-tested ExUnit policy reject tracer/human-verify tasks and missing automated verification.
   - **Commit:** 2017292e

## Known Stubs

None.

## Self-Check: PASSED

- Production and integration-test commit `2017292e` exists.
- `accrue/lib/accrue/entitlements/projector.ex`, `accrue/test/accrue/entitlements/projector_test.exs`, and `accrue/test/accrue/backend_automation_contract_test.exs` exist.
