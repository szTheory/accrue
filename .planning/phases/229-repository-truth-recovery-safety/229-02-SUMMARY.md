---
phase: 229-repository-truth-recovery-safety
plan: 02
subsystem: ci
tags: [github-actions, monitoring, node, bash, read-only]
requires: [REPO-01, REPO-02]
provides:
  - Repository-bound exact-SHA CI run listing, inspection, and bounded watching
  - A legacy watcher wrapper that delegates to the single monitor implementation
affects: [231-exact-sha-release-gate-proof]
tech-stack:
  added: [Node.js CommonJS, Node test runner]
  patterns: [injected read adapter, allowlisted failure summaries, bounded polling]
key-files:
  created:
    - scripts/ci/ci_monitor.cjs
  modified:
    - scripts/ci/watch_ci.sh
key-decisions:
  - "The monitor accepts only list, inspect, and watch, and every GitHub invocation is an explicit read against szTheory/accrue."
  - "Legacy branch selection resolves a run to its full SHA before polling; explicit SHA input bypasses branch selection."
  - "A successful Actions result retains provider_proof: non_run unless separate proof explicitly marks it proved."
actuals:
  tokens: 3744
  tasks: 2
  commits: 5
coverage:
  - id: D1
    description: "Read-only repository-bound CI monitor lists, inspects an exact SHA, and watches within hard timeout and polling bounds, with distinct no-match, ambiguity, unavailable, and timeout failures."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "The legacy watcher is a thin wrapper that performs one monitor exec, preserves the optional branch argument, lets --sha take precedence, and supplies bounded defaults."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md"
        status: pass
      - kind: integration
        ref: "node --test scripts/ci/phase229_gap_closure.test.mjs#WR-02 CI inspection rejects selected-viewed run ID and workflow switching"
        status: pass
    human_judgment: false
plan_head_before: c0873687fca510c81c3682a57369955d47499b7b
duration: 15min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 02: Exact-SHA CI Monitor Summary

**Delivered one read-only, repository-bound CI monitor that lists runs, inspects an exact SHA with sanitised failure detail, and watches within hard timeout and polling bounds.**

## Accomplishments

- Added `ci_monitor.cjs` with `list`, `inspect`, and `watch` as its only command surface, fixed `szTheory/accrue` attribution, lowercase full-SHA validation, deterministic ordering, and distinct no-match, ambiguity, unavailable-response, and timeout failures.
- Added injected-adapter self-tests that audit every GitHub argv as a repository-bound read and cover success, failure, cancellation, queued/in-progress completion, malformed input, empty/null responses, forbidden commands, and provider-proof vocabulary.
- Replaced the legacy watcher loop with a strict executable Bash wrapper that performs one monitor `exec`, preserves the optional branch argument, lets `--sha` take precedence, and supplies bounded defaults.

## Verification

- `node --check scripts/ci/ci_monitor.cjs` — passed.
- `node scripts/ci/ci_monitor.cjs --self-test` — passed.
- `bash -n scripts/ci/watch_ci.sh` — passed.
- `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh` — passed.
- `node --test scripts/ci/ci_monitor.cjs` — passed (1 test).

## Task Commits

1. **Task 1 RED: Add the failing monitor contract test** — `8ba7b9e3` (test)
2. **Task 1 GREEN: Implement exact-SHA read-only monitor** — `41785411` (feat)
3. **Task 2: Delegate legacy watcher to monitor** — `38ff72ba` (feat)
4. **Task 2 correction: Preserve executable wrapper mode** — `1b270608` (fix)
5. **Task 1 coverage correction: Exercise completion transitions** — `1299128e` (fix)

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Prevented the CLI entry point from running inside Node's test runner.**
   - **Found during:** Task 1 GREEN verification.
   - **Fix:** Gate CLI execution on the Node test-runner context so the embedded adapter suite can run without a subcommand.
   - **Files modified:** `scripts/ci/ci_monitor.cjs`
   - **Commit:** `41785411`

2. **[Rule 1 - Bug] Restored the compatibility wrapper's executable mode.**
   - **Found during:** Task 2 post-commit check.
   - **Fix:** Restored mode `100755` after the file replacement changed it to non-executable.
   - **Files modified:** `scripts/ci/watch_ci.sh`
   - **Commit:** `1b270608`

3. **[Rule 2 - Missing critical verification] Added queued/in-progress-to-completed watch coverage.**
   - **Found during:** Final acceptance review.
   - **Fix:** Added a deterministic adapter fixture proving a bounded watch reaches a completed result after queued and in-progress states.
   - **Files modified:** `scripts/ci/ci_monitor.cjs`
   - **Commit:** `1299128e`

## Self-Check: PASSED

- Both scoped implementation files exist and all five plan commits are present in Git history.
- The complete syntax, wrapper, self-test, and Node test verification suite passed after the final corrective commit.
