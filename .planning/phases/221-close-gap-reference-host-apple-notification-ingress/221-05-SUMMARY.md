---
phase: 221-close-gap-reference-host-apple-notification-ingress
plan: 05
subsystem: documentation-and-testing
tags: [apple, phoenix, webhook, mix-verify, source-contract, operations]
requires:
  - phase: 221-03
    provides: Host-owned Apple rate-policy and ingress edge proofs
  - phase: 221-04
    provides: Apple reconciliation queue, sweeper, and recovery wiring
provides:
  - Production-only Apple notification adoption and operator guidance
  - Merge-blocking Fake-backed Apple host proof registration in `mix verify`
  - Exact source assertions for the Apple route and runtime identity
affects: [reference-host, operator-runbooks, apple-notification-ingress, ci]
tech-stack:
  added: []
  patterns: [privacy-safe operational correlation, source-contract checks, bounded verifier registration]
key-files:
  created: []
  modified:
    - examples/accrue_host/README.md
    - examples/accrue_host/docs/adoption-proof-matrix.md
    - accrue/guides/operator-runbooks.md
    - examples/accrue_host/test/install_boundary_test.exs
    - scripts/ci/accrue_host_verify_test_bounded.sh
key-decisions:
  - "Fake-backed host-router proof and mix verify are merge authority; App Store delivery remains advisory."
  - "Apple source checks pin the dedicated 262,144-byte route and shared production verifier identity without asserting values."
requirements-completed: [D-01, D-02, D-04, D-05, D-06, D-07, D-08, D-09, D-10, D-11, D-12, D-13]
coverage:
  - id: D1
    description: "Production-only Apple ingress adoption and privacy-safe operator response contract"
    requirement: D-13
    verification:
      - kind: integration
        ref: "rg documentation contract check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dedicated Apple route, runtime identity, and bounded Wave 0 verifier contract"
    requirement: D-11
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test install_boundary_test.exs apple_notification_ingest_test.exs apple_rate_policy_test.exs recovery_wiring_test.exs --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix verify"
        status: pass
    human_judgment: false
duration: 2min
completed: 2026-08-05
status: complete
---

# Phase 221 Plan 05: Adoption Contract and Bounded Verifier Summary

**Production-only Apple notification ingress guidance and a merge-blocking Fake-backed host verifier contract.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-08-05T17:42:22Z
- **Completed:** 2026-08-05T17:44:09Z
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Published the precise `/webhooks/apple` setup, status response meanings, production runtime inputs, and safe triage path.
- Marked deterministic Fake-backed host evidence merge-blocking while keeping App Store delivery and Crosswake/Alpha evidence advisory and separately owned.
- Added source-contract checks and registered all Apple Wave 0 proofs in bounded `mix verify` with database setup and warnings-as-errors preserved.

## Task Commits

1. **Task 1: Publish the adoption and operator contract** — `116780d4` (docs)
2. **Task 2: Bind the source contract and Wave 0 tests into `mix verify`** — `a2f3441f` (test), `d5a0375a` (feat), `0646f4d6` (refactor)

## Files Created/Modified

- `examples/accrue_host/README.md` — Apple ingress recipe, response classes, and literal verification command.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — Blocking Fake-backed evidence and advisory deployment lane.
- `accrue/guides/operator-runbooks.md` — Safe ingress-triage sequence with job-and-next-action language.
- `examples/accrue_host/test/install_boundary_test.exs` — Exactly-once route, runtime-identity, and bounded-script assertions.
- `scripts/ci/accrue_host_verify_test_bounded.sh` — Registers every Wave 0 Apple proof.

## Decisions Made

- The public reference contract names runtime input identifiers but never their values.
- PostgreSQL remains the duplicate/concurrency authority; the local limiter is documented as a single-node backstop.

## Verification

- PASS — focused Apple suite: 22 tests, 0 failures.
- PASS — `mix verify`: 56 tests, 0 failures.
- PASS — documentation contract grep and targeted source formatter check.
- BLOCKED (pre-existing, out of scope) — full `mix format --check-formatted` still reports `priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs`, `priv/repo/migrations/20260803013000_create_accrue_entitlement_compatibility_evidence.exs`, and `lib/accrue_host_web/components/layouts.ex`. This was already recorded in `deferred-items.md`; none was changed here.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Formatted the newly added source-contract test**
- **Found during:** Task 2
- **Issue:** The initial test formatting did not satisfy the project formatter.
- **Fix:** Applied the project formatter to the plan-owned test only.
- **Files modified:** `examples/accrue_host/test/install_boundary_test.exs`
- **Verification:** Focused source-contract test passed after formatting.
- **Committed in:** `0646f4d6`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** No scope expansion; the formatter repair keeps the plan-owned test compliant.

## Issues Encountered

- Existing compiler warnings in `accrue/lib/accrue/entitlements/reference_scenarios.ex` were emitted during test runs but did not fail the focused suite or `mix verify`.
- The existing unrelated formatter violations above prevent a repository-wide format-clean claim.

## Known Stubs

None.

## User Setup Required

None — the runtime identifiers are documented for production adopters; no external action was required to validate this credential-free plan.

## Next Phase Readiness

The Phase 221 reference-host Apple ingress is documented and included in merge-blocking bounded verification. The unrelated formatter violations remain deferred for their owning work.

## Self-Check: PASSED

- All five plan-owned files exist and all four task commits are present in git history.
