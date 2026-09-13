---
phase: 227
plan: "04"
subsystem: ci-evidence
tags: [ci, evidence-ledger, workflow-contract, node]
requires: [227-03]
provides: [strict-cli, terminal-ledger-renderer, immutable-workflow-fixture]
affects: [scripts/ci/verify_ci_critical_path.mjs, scripts/ci/README.md]
tech-stack:
  added: []
  patterns: [exact-cohort-admission, role-bound-job-urls, byte-stable-ledger-rendering]
key-files:
  created:
    - .planning/phases/227-measured-critical-path-improvement/fixtures/ci-workflow-restored-v2.yml
  modified:
    - scripts/ci/verify_ci_critical_path.mjs
    - scripts/ci/README.md
decisions:
  - "The checked terminal rollback report is rendered from validated NDJSON rather than maintained as a hand-edited companion."
  - "CLI invocations require exactly one explicit action and only action-specific options."
metrics:
  duration: 35m
  completed: 2026-09-11
  tasks: 2
  commits: 4
  plan_head_before: 80079ce2a6f57a674af9cd6753304d359efc7b4a
status: complete
actuals:
  tokens: 35980
  tasks: 2
  commits: 4
---

# Phase 227 Plan 04: Strict critical-path evidence gate Summary

The Phase 227 verifier now rejects forged exact-cohort evidence and derives the terminal rollback report from the immutable NDJSON ledger with a byte-for-byte check.

## Performance

- **Duration:** 35m
- **Started:** 2026-09-11T14:55:32-04:00
- **Completed:** 2026-09-11
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added immutable restored-workflow compatibility, exact cohort admission, role-bound job URLs, and recursive privacy checks.
- Made each verifier CLI invocation select one explicit action with an action-specific allowlist.
- Validated and rendered the terminal rollback grammar from NDJSON, reproducing `227-CI-CRITICAL-PATH.md` byte-for-byte without writing the ledger.

## Task Commits

1. **Task 1: Reject forged evidence and close fail-open paths** — `ede6f629`, `b3f59910`
2. **Task 2: Make CLI actions explicit and reports reproducible** — `b45dcff4`, `389e1f3d`

## Files Created/Modified

- `scripts/ci/verify_ci_critical_path.mjs` — strict admission, parsing, terminal validation, and rendering.
- `scripts/ci/README.md` — immutable-fixture, mutable-workflow, and byte-check commands.
- `fixtures/ci-workflow-restored-v2.yml` — audited offline restored workflow input.
- `227-ci-contract.json` and `fixtures/ci-critical-path-cases.json` — versioned compatibility and adversarial corpus.

## Verification

- `node --check scripts/ci/verify_ci_critical_path.mjs`
- `node --test scripts/ci/verify_ci_critical_path.test.mjs`
- Offline fixture, current workflow, evidence validation, and terminal render commands all passed.
- Malformed no-action, unknown, multiple-action, missing-value, and unsupported-action-option CLI invocations all exited nonzero.

## Decisions Made

- The terminal report is generated from ledger facts only after validating the terminal grammar, preserved prefix, and privacy-safe status fields.
- The terminal experiment remains closed; documentation contains no command that grants dispatch authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored the unreachable fixture assertions**
- **Found during:** Task 2
- **Issue:** `verifyFixtures()` returned before exercising workflow compatibility assertions.
- **Fix:** Removed the early return and updated the preserved Phase 228 provider condition expectation.
- **Files modified:** `scripts/ci/verify_ci_critical_path.mjs`
- **Commit:** `389e1f3d`

## Known Stubs

None.

## Self-Check: PASSED

- Required immutable fixture, verifier, README, and Summary files exist.
- Task commits `ede6f629`, `b3f59910`, `b45dcff4`, and `389e1f3d` exist in the repository.
