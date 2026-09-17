---
phase: 226-ci-baseline-proof-semantics
plan: "13"
subsystem: ci evidence and host diagnostics
tags: [github-actions, baseline, provider-proof, shell, host-integration]
requires:
  - phase: 226-12
    provides: compatible-path baseline records and frozen critical-path report
provides:
  - absent provider state and unresolved dependencies fail closed in baseline collection
  - host wrapper preserves literal lower-level setup facts and uses an honest aggregate fallback
affects: [phase-226-verification, phase-227-critical-path-improvement]
tech-stack:
  added: []
  patterns: [fail-closed proof normalization, fact-file delta wrapper classification]
key-files:
  created: []
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - scripts/ci/ci_setup_diagnostic.sh
    - scripts/ci/accrue_host_uat.sh
    - scripts/ci/verify_ci_setup_diagnostics.sh
    - examples/accrue_host/README.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
key-decisions:
  - "Missing provider evidence normalizes to non_run rather than deriving proof from event success."
  - "A wrapper preserves new valid inner setup facts and falls back to host_gate_failure only when none is emitted."
patterns-established:
  - "Proof inputs fail closed: absence cannot promote a durable provider or timing claim."
  - "Delegating wrappers retain exact exit status and classify only their own aggregate boundary."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: "Baseline collection cannot turn omitted provider evidence or incomplete dependency topology into durable proof."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path"
        status: pass
    human_judgment: false
  - id: D2
    description: "The host verification wrapper retains lower-level diagnostics, returns the delegated status, and emits an aggregate fallback only when appropriate."
    requirement: OWN-01
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_ci_setup_diagnostics.sh"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 13: Fail-Closed Baseline Proof and Literal Host Diagnostics Summary

**Baseline evidence now refuses missing proof/topology input, while the host gate preserves literal setup failures and reports only an honest aggregate fallback.**

## Performance

- **Duration:** 14 min
- **Completed:** 2026-08-11
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Made omitted provider state `non_run` and rejected unresolved prerequisite topology before baseline records are accepted.
- Added deterministic controls for push/pull-request omission, incomplete prerequisites, preserved inner setup facts, aggregate fallback, and successful delegation.
- Added `host_gate_failure` to the stable registry and host documentation, then recorded the full green Phase 226 contract.

## Task Commits

1. **Task 1: Trace absent proof and incomplete topology through the durable collector** — `cd7fd3ac` (test), `56a3fa37` (fix)
2. **Task 2: Preserve literal inner setup facts and classify only an unclassified aggregate host failure** — `e533c8ce` (test), `564fd74f` (fix)

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` — fails closed on absent provider proof and incomplete prerequisites.
- `scripts/ci/verify_ci_baseline.mjs` — pins no-promotion and missing-prerequisite collector controls.
- `scripts/ci/ci_setup_diagnostic.sh` — registers the host-owned aggregate fallback.
- `scripts/ci/accrue_host_uat.sh` — compares valid setup-fact count across one delegated host gate.
- `scripts/ci/verify_ci_setup_diagnostics.sh` — tests inner, aggregate, and success wrapper paths with a local fake `mix`.
- `examples/accrue_host/README.md` — documents the eighth diagnostic row and its reproduction/evidence path.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` — records Task 2 and full Plan 13 green assertions.

## Decisions Made

- Missing provider-state input is explicit `non_run`; a green ordinary CI conclusion is never provider proof.
- The top-level host wrapper does not reinterpret a lower-level fact. If no new valid fact exists, it emits `host_gate_failure` with the host-integration command log.

## Verification

- PASS — `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- PASS — `node scripts/ci/verify_ci_baseline.mjs --fixtures`
- PASS — frozen critical-path record/render verification with `--require-critical-path`
- PASS — provider-proof fixtures, focused formatter test, and Phase 225 required-lane evidence gate.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 226's baseline, provider proof, and setup ownership boundaries are fail-closed and ready for Phase 227's measured critical-path work.

## Self-Check: PASSED

- Verified all seven modified artifacts exist.
- Verified Task 1 and Task 2 commits exist in git history.

---
*Phase: 226-ci-baseline-proof-semantics*
*Completed: 2026-08-11*
