---
phase: 249-local-gate-parity-planning-truth
plan: "04"
subsystem: ci-gates
status: complete
completed: 2026-10-24
requirements-completed: [GREEN-01]
tags: [d-16, window-dispositions, ledger-through-id, replay-tool]
key-files:
  created:
    - .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py
  modified:
    - scripts/ci/verify_window_dispositions.mjs
    - .github/workflows/ci.yml
    - scripts/ci/verify_executable_uat_contract.mjs
key-decisions:
  - "--ledger-through-id bounds only the frozen-record join; the open-row check stays global"
  - "Unbounded mode keeps the strict whole-ledger join"
commits: 3
plan_head_before: 51fe4393a0af3a8e8d20e13c925adc92002b8835
plan_head_after: 6f5b12c8a0d11bc4e8a10e3cd7a72978009778d4
actuals:
  tokens: 45000
  tasks: 3
  commits: 3
coverage:
  - id: C1
    description: Scoped record join with six negative controls; unbounded mode still strict
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node --test scripts/ci/verify_window_dispositions.mjs"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism"
        status: pass
    human_judgment: false
  - id: C2
    description: ci.yml D-16 step carries --ledger-through-id 14; real run fails only on the 12 open rows, not on missing-from-record
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "node scripts/ci/verify_window_dispositions.mjs --repo . --ledger-through-id 14 --require-row-join (see plan Task 2 command)"
        status: pass
      - kind: command
        ref: "node scripts/ci/verify_phase230_archive_invariants.mjs --repo ."
        status: pass
    human_judgment: false
  - id: C3
    description: Replay tool extracts every run step and reports the known SL-A red as FAIL and roadmap hygiene as PASS
    requirement: GREEN-01
    verification:
      - kind: command
        ref: "python3 .planning/phases/249-local-gate-parity-planning-truth/249-replay-ci-job.py --job docs-contracts-shift-left --out $(mktemp -d) --run --only 'roadmap hygiene'"
        status: pass
      - kind: command
        ref: "bash scripts/ci/verify_no_home_paths.sh --repo"
        status: pass
    human_judgment: false
---

# Phase 249 Plan 04: D-16 scoped join and CI replay tool Summary

`verify_window_dispositions.mjs` now accepts `--ledger-through-id <N>`, bounding only the frozen-record join (open-row check stays global), wired as `--ledger-through-id 14` in the ci.yml D-16 step, plus a committed local `ci.yml` job replay tool.

## Outcomes

1. **Scoped join (671a2e72).** RED: new fixtures failed with `missing=[15, ...]`. GREEN after implementation. Six scenarios: later non-open rows ignored, later open row still fails, missing in-scope partner fails, record id beyond bound fails, invalid bounds (0, -3, abc, 14.5, empty, 1e2) rejected, unbounded still strict. PASS suffix prints `scoped to ledger ids <= N`. Evidence freshness and waiver checks iterate record rows only, so they are naturally in scope.
2. **ci.yml wiring (98c5a612).** Real D-16 run (positive control) fails with exactly `ship-window ledger still has 12 open row(s) with no disposition partner: ids=[15, 16, 17, 18, 19, 20, 28, 29, 30, 36, 37, 38]`, no `missing from record`. 249-10 makes it pass.
3. **Replay tool (6f5b12c8).** 48 run steps of `docs-contracts-shift-left` extract. `--only 'SL-A'` reports `FAIL 04` (claim C1 `open_count: 0` measured 0); `--only 'roadmap hygiene'` reports `PASS 25`. Unresolvable `${{ }}` env (GITHUB_TOKEN, RELEASE_PLEASE_PR) are listed as UNRESOLVED.

## Deviations from Plan

**1. [Rule 3 - Blocking] Archive sweep red from plan 03.** The sweep flagged `verify_executable_uat_contract.mjs:670` (a synthetic negative-control path from 249-03). Added the sanctioned same-line `archive-sweep-exempt:` marker (commit 98c5a612); sweep and self-test pass.

## Known Stubs

None.

## Self-Check: PASSED

Commits 671a2e72, 98c5a612, 6f5b12c8 present; no archived record edited.
