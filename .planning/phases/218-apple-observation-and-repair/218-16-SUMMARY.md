---
phase: 218-apple-observation-and-repair
plan: 16
subsystem: entitlements
tags: [apple, reconciliation, postgres, ecto, provider-boundary]
requires:
  - phase: 218-13
    provides: "Bound Apple lineage, idempotent admission, and reconciliation checkpoint semantics"
provides:
  - "Locked environment-qualified lineage lookup before Apple provider I/O"
  - "Explicit separation between local checkpoint identity and Apple's original transaction identifier"
affects: [apple-reconciliation, scheduled-repair, provider-isolation]
tech-stack:
  added: []
  patterns: ["Lock local persistence identity before crossing a provider boundary"]
key-files:
  created: []
  modified:
    - accrue/lib/accrue/entitlements/apple/reconciliation.ex
    - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
key-decisions:
  - "Use lineage.id for checkpoints, admissions, retry jobs, and continuations; send lineage.original_transaction_id only to Apple client calls."
patterns-established:
  - "Provider path parameters come from locked provider identity, never local durable UUIDs."
requirements-completed: [AAPL-04]
coverage:
  - id: D1
    description: "Reconciliation locks the local, environment-qualified lineage and uses its stored Apple original transaction identifier for both Production status and history paths."
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_reconciliation_test.exs#reconciliation keeps its local checkpoint identity while Production uses Apple's original transaction identifier"
        status: pass
      - kind: integration
        ref: "cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Missing or environment-mismatched local lineages fail before provider transport and cannot create an alternate checkpoint identity."
    requirement: AAPL-04
    verification:
      - kind: integration
        ref: "accrue/test/accrue/entitlements/apple_reconciliation_test.exs#a missing or environment-mismatched lineage fails before Apple transport"
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 16: Reconciliation Provider Identity Repair Summary

**Scheduled Apple repair now locks a local lineage for durable work while using only its stored original transaction identifier in Apple status and history URLs.**

## Performance

- **Duration:** 24 min
- **Tasks:** 1/1
- **Files modified:** 2
- **Human judgment:** false — executable coverage only

## Accomplishments

- Locked the environment-qualified local lineage before checkpoint creation or provider calls.
- Kept local `lineage.id` for checkpoints, admission, continuation, retry, and job identity.
- Sent only URI-encoded `lineage.original_transaction_id` to both Production Apple endpoints, with regressions excluding the local UUID.
- Failed closed for missing or environment-mismatched lineage before Apple transport.

## Task Commits

1. **Task 1 RED: Provider identity tracer** — `f8912246` (`test`)
2. **Task 1 GREEN: Locked identity separation** — `1636c712` (`fix`)

## Files Created/Modified

- `accrue/lib/accrue/entitlements/apple/reconciliation.ex` — separates locked local and provider identifiers at the reconciliation boundary.
- `accrue/test/accrue/entitlements/apple_reconciliation_test.exs` — captures Production URLs and proves local checkpoint retention plus fail-closed lookup.

## Decisions Made

- Local UUIDs remain the sole durable orchestration identity; the Apple original transaction ID crosses only the private client boundary.
- Missing, mismatched, or unusable provider lineage fails closed before any provider transport.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `cd accrue && mix test test/accrue/entitlements/apple_reconciliation_test.exs` — pass (19 tests)
- `cd accrue && mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — pass (56 tests, 1 property)
- `mix format --check-formatted` and `mix compile --warnings-as-errors` — pass
- `git diff --quiet -- mix.exs mix.lock` — pass

## Known Stubs

None.

## Self-Check: PASSED

- Both implementation and regression files exist.
- Task commits `f8912246` and `1636c712` exist.

## Next Phase Readiness

Apple reconciliation can now obtain authoritative status and history without changing local checkpoint, cursor, admission, or lifecycle ownership semantics.
