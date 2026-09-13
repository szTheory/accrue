---
phase: 227-measured-critical-path-improvement
plan: "08"
subsystem: ci-evidence
tags: [github-actions, critical-path, kept-cohort, validation, fail-closed]
requires:
  - phase: 227-07
    provides: exact candidate SHA, preflight evidence, and fail-closed v3 authority
provides:
  - genuine kept exact-three critical-path cohort
  - deterministic kept report and read-only maintainer verification
  - validated Nyquist map and passed additive re-verification
affects: [PATH-01, PATH-02, SAFE-01, SAFE-02, ci-workflow]
tech-stack:
  added: []
  patterns: [reservation-before-dispatch, immediate-run-consumption, kept-only-live-gate, byte-stable-report]
key-files:
  created:
    - .planning/phases/227-measured-critical-path-improvement/227-08-SUMMARY.md
  modified:
    - scripts/ci/README.md
    - scripts/ci/verify_ci_critical_path.test.mjs
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md
    - .planning/phases/227-measured-critical-path-improvement/227-VALIDATION.md
    - .planning/phases/227-measured-critical-path-improvement/227-VERIFICATION.md
key-decisions:
  - "Kept only the exact three qualifying first-attempt candidates; candidate authority is closed and restoration authority closed unspent."
  - "Maintainer guidance exposes only read-only verifier commands and names the literal inverse as a separately authorized future action."
  - "The kept-only regression now constructs a v2 rollback fixture, so it continues proving rejection after the live ledger becomes kept."
requirements-completed: [PATH-01, PATH-02, SAFE-01, SAFE-02]
actuals:
  tokens: 12600
  tasks: 3
  commits: 16
plan_head_before: dc8b0410d65e4599a331a4eb2fe35a7ad59cb36e
metrics:
  duration: 8m
  completed: 2026-09-12
status: complete
coverage:
  - id: D1
    description: "Repository-bound exact-three kept cohort with complete required vectors and closed authority."
    requirement: PATH-02
    verification:
      - kind: integration
        ref: "verify_ci_critical_path.mjs --verify-live-actions --require-kept"
        status: pass
    human_judgment: false
  - id: D2
    description: "Stable required checks, artifacts, controls, and byte-generated evidence report."
    requirement: SAFE-01
    verification:
      - kind: integration
        ref: "verify_ci_critical_path.mjs --render-evidence; --verify-workflow --expected-state candidate"
        status: pass
    human_judgment: false
  - id: D3
    description: "Validated PATH and SAFE requirement closure with historic gaps preserved."
    requirement: SAFE-02
    verification:
      - kind: integration
        ref: "Task 3 prescribed full suite"
        status: pass
    human_judgment: false
---

# Phase 227 Plan 08: Kept Critical-Path Closure Summary

**A live-verified, exact-three critical-path cohort reduced the frozen median to 1125 seconds while retaining every required proof vector, exclusion, and closed authority record.**

## Accomplishments

- Bound and retained three qualifying first-attempt candidate runs: 34665008225 (1179s), 34670140537 (1125s), and 34700972204 (1079s). Their 1125s median is below the 1666s keep threshold and their 1179s maximum is below the 2602s ceiling.
- Generated and byte-verified the kept report from append-only NDJSON, retaining historical exclusions, negative control, literal advisory vectors, `non_run` provider state, and removed temporary-ref accounting.
- Replaced stale rollback-only README instructions with read-only kept, byte-render, and candidate-workflow verification commands.
- Closed the previous three verification gaps with a green Nyquist record and a preserved historical verification report.

## Task Commits

1. **Task 1: Reservation, consumption, live proof, and kept decision** — `8b23ab12`, `709db014`, `981ae876`, `31255838`, `5e8cadec`, `4a3fb3bc`, `47a67332`, `6e3c6b38`, `7b5798df`, `e60781d0`, `db627041`, `660bcddc`, `18912734`, `d96539a5`
2. **Task 2: Kept-only maintainer report guidance** — `9c97353c`
3. **Task 3: Validation and additive re-verification** — `e370e1fe`

## Verification

- `node --test scripts/ci/verify_ci_critical_path.test.mjs` — 7/7 passing.
- Exact-SHA preflight, immutable restored fixture, live `--require-kept`, byte renderer, and candidate workflow gates — passed.
- Frozen baseline, provider and webhook fixtures, setup diagnostics, and Phase 225 lane preservation — passed.
- CI-pinned `mix format --check-formatted` and focused Accrue suite — 10 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Made the kept-only regression independent of the live terminal state**
- **Found during:** Task 3
- **Issue:** The prior regression expected the mutable ledger to remain v2 rollback, so the now-genuine kept result made a fail-closed assertion fail.
- **Fix:** The test builds a temporary v2-only rollback evidence fixture and still asserts that `--require-kept` rejects it.
- **Files modified:** `scripts/ci/verify_ci_critical_path.test.mjs`
- **Verification:** Node verifier suite passed 7/7 and the full prescribed suite passed.
- **Commit:** `e370e1fe`

## Known Stubs

None.

## Self-Check: PASSED

- Kept report, validation, verification, README, test, and this summary exist.
- All 16 plan commits listed above exist in Git history.
- No generated or unrelated untracked file was staged.
