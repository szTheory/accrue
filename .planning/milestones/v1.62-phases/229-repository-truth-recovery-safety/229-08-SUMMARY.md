---
phase: 229-repository-truth-recovery-safety
plan: 08
subsystem: ci
tags: [github-actions, monitoring, node, bash, exact-sha, read-only]
requires:
  - phase: 229-02
    provides: Repository-bound exact-SHA CI monitor and thin compatibility wrapper
provides:
  - Executable no-argument main/CI compatibility watcher contract
  - Stable non-zero exits for completed unsuccessful CI runs
  - Contributor-facing command, selection, bounds, and failure semantics
affects: [231-exact-sha-release-gate-proof, release-handoff]
actuals:
  tokens: 6213
  tasks: 2
  commits: 4
plan_head_before: 72fad3fa8b27dc607bfcee63f922e5ac6128e3e8
tech-stack:
  added: []
  patterns: [executable fake-GitHub adapter fixture, exact-SHA precedence, stable CLI exit taxonomy]
key-files:
  created: []
  modified:
    - scripts/ci/ci_monitor.cjs
    - scripts/ci/watch_ci.sh
    - scripts/ci/README.md
key-decisions:
  - "The compatibility watcher defaults to repository szTheory/accrue, branch main, workflow CI, timeout 900 seconds, and poll interval 10 seconds."
  - "An explicit full SHA takes precedence over branch selection, while explicit workflow and bound overrides replace only their matching defaults."
  - "Completed success exits 0; every completed non-success conclusion renders repository/SHA evidence and exits 69."
patterns-established:
  - "Wrapper behavior is tested by executing watch_ci.sh against a controlled gh executable, exercising the real monitor and process exit path."
  - "GitHub run lists are filtered locally by requested workflow before exact-SHA selection, even when an adapter returns unrelated workflows."
requirements-completed: [REPO-03]
coverage:
  - id: D1
    description: "The no-argument wrapper deterministically resolves main/CI, supports compatible overrides, and gives explicit SHA precedence."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "scripts/ci/ci_monitor.cjs#compatibility wrapper defaults to main and CI and propagates unsuccessful completions"
        status: pass
      - kind: other
        ref: "bash -n scripts/ci/watch_ci.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Completed unsuccessful CI conclusions retain exact repository/SHA output and return stable exit 69."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "node --test scripts/ci/ci_monitor.cjs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The contributor map documents the tested direct and compatibility commands, bounds, exit taxonomy, read-only scope, and provider-proof boundary."
    requirement: REPO-03
    verification:
      - kind: other
        ref: "node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-09-13
status: complete
---

# Phase 229 Plan 08: Compatibility CI Watcher Gap Closure Summary

**A process-tested `main`/`CI` compatibility watcher now resolves one exact SHA, remains bounded and read-only, and makes every completed non-success observable through exit 69.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-13T14:50:52Z
- **Completed:** 2026-09-13T15:00:06Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Executed `watch_ci.sh` in fixtures through the real monitor and a controlled `gh` adapter, covering no arguments, positional branch, exact SHA, workflow override, multi-workflow responses, successful completion, and every documented unsuccessful conclusion.
- Restored deterministic `main`/`CI` defaults, explicit-SHA precedence, bounded reads/polling, local workflow filtering, and stable exit codes without adding any GitHub mutation operation.
- Added one contributor-facing Phase 229 evidence row plus compact direct/wrapper command matrices that preserve the Actions-versus-provider-proof boundary.

## Task Commits

1. **Task 1 RED: Add failing executable watcher contract** — `ee8bf797` (test)
2. **Task 1 GREEN: Restore deterministic CI watcher behavior** — `8b879dcc` (feat)
3. **Task 1: Retain exact observation diagnostics** — `d69400a3` (fix)
4. **Task 2: Align supported CI watcher contract** — `7975d66e` (docs)

## Files Created/Modified

- `scripts/ci/ci_monitor.cjs` — executable wrapper fixture, workflow-safe selection, bounded GitHub reads, exact observation diagnostics, and completion exit mapping.
- `scripts/ci/watch_ci.sh` — thin one-exec wrapper with `main`/`CI` and bounded defaults plus exact-SHA precedence.
- `scripts/ci/README.md` — supported Phase 229 command matrix, compatibility defaults, exit taxonomy, provider attribution, and scope exclusions.

## Decisions Made

- Used a temporary controlled `gh` executable instead of source-text-only wrapper assertions, so tests exercise Bash argument handling, the real monitor, repository binding, rendered output, and process status together.
- Reserved exit `69` for completed non-success conclusions while retaining `64` usage, `65` no-match, `66` ambiguity, `67` unavailable/malformed response, and `68` polling timeout.
- Applied explicit SHA before branch resolution in the monitor as well as the wrapper, making precedence deterministic even when both selectors are supplied.

## TDD Gate Compliance

- **RED:** `ee8bf797` added the named executable wrapper test; `node --test scripts/ci/ci_monitor.cjs` failed because the no-argument wrapper returned 64 instead of 0.
- **RED evidence:** `gsd_run check tdd-red-evidence /tmp/phase229-08-red.json --raw` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** `8b879dcc` made the executable fixture pass; `d69400a3` retained the exact-SHA diagnostic and distinct-error requirements with the suite still green.
- **REFACTOR:** No separate refactor was necessary.

## Verification

- `bash -n scripts/ci/watch_ci.sh` — passed.
- `node --check scripts/ci/ci_monitor.cjs` — passed.
- `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` — passed.
- `node --test scripts/ci/ci_monitor.cjs` — passed (2 tests).
- Adapter registry assertion — passed; only `listRuns` and `viewRun` operations are exposed, and `dispatch` is rejected with usage exit 64.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first RED fixture inherited Node's test-runner context into the wrapper subprocess, so the child loaded tests instead of the CLI. The fixture now clears that inherited test-only variable; the intentional RED was then recorded against the actual no-argument exit-64 assertion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CR-05 is closed and REPO-03 now has an executable supported-command/failure-semantics probe.
- Phase 231 can consume one deterministic, repository-bound exact-SHA observation path; CI execution and release-gate proof remain outside Phase 229.

## Self-Check: PASSED

- All three modified files exist.
- All four task commits are present in Git history.
- Syntax, wrapper subprocess fixtures, Node tests, docs verification, and the read-only adapter registry assertion passed after the final task commit.
- No skipped tests, known stubs, unrun verification, or out-of-scope threat surface remain.

---
*Phase: 229-repository-truth-recovery-safety*
*Completed: 2026-09-13*
