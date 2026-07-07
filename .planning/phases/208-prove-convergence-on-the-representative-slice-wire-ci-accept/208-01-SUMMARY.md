---
phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept
plan: 01
subsystem: testing
tags: [admin-ui-ratchet, verifier, baseline, ci, node]
requires:
  - phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
    provides: committed finding ledger and independent verifier pattern
  - phase: 207-orchestration-digest-one-command-round-fix-loop
    provides: round sealing, slice scope, and ratchet orchestration artifacts
provides:
  - Score-floor-aware dry-round convergence predicate for the representative slice
  - Read-only frozen ratchet ledger verifier with deterministic red-path fixtures
  - Synthetic count-increase and cross-persona regression proofs
affects: [phase-208, admin-ui-ratchet, ci-guardrails, signoff]
tech-stack:
  added: []
  patterns:
    - Node-only deterministic verifier fixtures using fs.mkdtempSync scratch roots
    - Read-only frozen-baseline acceptance gate separate from the mutating reducer
key-files:
  created: []
  modified:
    - accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
    - scripts/ci/verify_ratchet_ledger.mjs
key-decisions:
  - "SLICES.foundation expands through the manifest-owned foundation slice, with component-kitchen mapped to component and component-group score-floor rows rather than an exact nonexistent surface."
  - "The frozen verifier rejects matching raw-ledger/baseline evidence when independently folded open findings are nonzero; matching hashes alone are not acceptance."
patterns-established:
  - "Frozen ratchet verification is read-only: it checks committed artifacts and scratch fixtures without invoking --freeze or the reducer write path."
  - "Per-lens count increases are surfaced explicitly so one improving lens cannot mask another regressed lens."
requirements-completed: [CONV-01, CONV-02, CONV-03, CONV-04]
duration: 35 min
completed: 2026-07-07
status: complete
---

# Phase 208 Plan 01: Deterministic Frozen Ratchet Verifier Summary

**Score-floor-aware convergence and read-only frozen-baseline verification for the admin UI ratchet**

## Performance

- **Duration:** 35 min
- **Started:** 2026-07-07T20:05:00Z
- **Completed:** 2026-07-07T20:40:11Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Tightened `phase-ratchet-ledger.mjs` so dry-round convergence fails closed when no scoped rows are examined and now requires `coverage_status == "covered"` plus numeric `score >= 2`.
- Added `verify_ratchet_ledger.mjs --verify-frozen`, a read-only Phase 208 verifier for frozen/material baseline evidence, two dry foundation rounds, zero folded open findings, empty regression files, and foundation score-floor coverage.
- Added scratch fixtures proving synthetic count-increase and cross-persona/lens regression failures, including the case where one lens improves while another rises.

## Task Commits

Each task was committed atomically:

1. **Task 1: Enforce score floor in round sealing** - `fbf6d754` (feat)
2. **Tasks 2-3: Add read-only frozen evidence verifier and prove red paths** - `26b9a0af` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` - Adds score-floor helpers, `SLICES.foundation` expansion, component-kitchen mapping, and score-floor self-tests.
- `scripts/ci/verify_ratchet_ledger.mjs` - Adds `--verify-frozen`, frozen evidence checks, Phase 200 regression and score-floor checks, and D-65 red-path fixtures.

## Decisions Made

- `component-kitchen` maps to component and component-group score-floor rows because the capture name is not a Phase 200 census surface.
- The frozen verifier checks folded open findings directly instead of trusting matching `ledger_sha256` or baseline equality.
- Count-increase proofs are represented in a dedicated `countIncrease` failure bucket so per-lens increases are visible even when aggregate totals improve.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The real pre-freeze `--verify-frozen` run correctly fails today because the committed baseline is still unfrozen/placeholder, `rounds.ndjson` has no two dry foundation rows, and component-kitchen score-floor evidence is not yet covered. This is expected before Plan 04's live convergence/freeze work.

## Verification

- `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` - passed.
- `cd accrue_admin && node ../scripts/ci/verify_ratchet_ledger.mjs --self-test` - passed.
- `cd accrue_admin && node ../scripts/ci/verify_ratchet_ledger.mjs --verify-frozen` - failed as expected pre-freeze with artifact-specific errors and did not mutate real ratchet artifacts.

## User Setup Required

None - no external service configuration required for this deterministic verifier foundation.

## Next Phase Readiness

Plan 02 can build the maintainer sign-off verifier on top of the frozen-evidence contract. Plan 04 remains responsible for generating the real foundation dry-round evidence and frozen material baseline.

---
*Phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept*
*Completed: 2026-07-07*
