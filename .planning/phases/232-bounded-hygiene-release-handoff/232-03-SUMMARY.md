---
phase: 232-bounded-hygiene-release-handoff
plan: 03
subsystem: infra
tags: [node, ci, module-boundary-guard, meta-verifier, node-test, ci-baseline]

requires:
  - phase: 232-02
    provides: "22 git-tracked scripts/ci/*.mjs entrypoints migrated to the shared isMainModule guard, and the same-commit guard+test discipline for previously-vacuous files"
provides:
  - "scripts/ci/verify_ci_script_contract.mjs -- a meta-verifier enforcing guard-coverage, non-vacuity, and a live cohort floor across every git-tracked scripts/ci/*.mjs file, merge-blocking and self-enforcing going forward"
  - "12 more scripts/ci/*.mjs files (previously guard-less, out of 232-02's declared scope) migrated to the shared isMainModule guard with a same-commit real test each"
  - "the ci_baseline triad (collect/render/verify_ci_baseline.mjs) green under node --test, guard-migrated, and wired into docs-contracts-shift-left for the first time"
  - "two new merge-blocking docs-contracts-shift-left steps: CI baseline triad units and fixture contract (D-34), CI script contract (D-32)"
affects: [232-04, 232-05, 232-06, 232-07, 232-08, 232-09, 232-10, 232-11]

actuals:
  tokens: 18103
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "isMainModule(import.meta.url) guard usage, try/catch around the throw (232-01's established call-site pattern), reused for every migration in this plan"
    - "A guard-migrated file's child spawnSync/dynamic-import() call sites targeting another guard-migrated file must delete (not blank) inherited NODE_TEST_CONTEXT before invoking, or node:test's recursion guard silently skips the nested run"
    - "Meta-verifier over a live git-tracked glob: enumerate via `git ls-files`, compare against a committed non-zero floor re-measured live, never a raw directory read"

key-files:
  created:
    - scripts/ci/verify_ci_script_contract.mjs
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/render_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - scripts/ci/apple_notification_delivery_smoke.mjs
    - scripts/ci/bootstrap_stripe_provider_proof.mjs
    - scripts/ci/generate_phase200_closeout_reports.mjs
    - scripts/ci/phase_evidence_path.mjs
    - scripts/ci/provider_proof_automation.mjs
    - scripts/ci/verify_ci_critical_path.mjs
    - scripts/ci/verify_ci_critical_path.test.mjs
    - scripts/ci/verify_executable_uat_contract.mjs
    - scripts/ci/verify_foundation_contrast.mjs
    - scripts/ci/verify_phase191_ax187_coverage.mjs
    - scripts/ci/verify_phase229_handoff_invariants.mjs
    - scripts/ci/verify_provider_proof.mjs
    - scripts/ci/verify_stripe_webhook_boot_evidence.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
    - .github/workflows/ci.yml
    - scripts/ci/README.md

key-decisions:
  - "Task 1's own <verify> block requires the real-repository invocation (--repo . --require-guard-coverage --require-non-vacuity --require-cohort-floor) to exit 0. The initial run found 15 files still ungated: the 3-file ci_baseline triad (Task 2's declared scope) plus 12 more that plan 232-02 explicitly deferred as out of its own scope. Migrated all 12 within Task 1 (Rule 3 -- own acceptance criteria are the authority) so Task 1's own gate could clear before Task 2 even started; documented as a deviation rather than silently narrowing the acceptance criterion."
  - "Committed cohort floor (COMMITTED_COHORT_FLOOR = 41) was re-measured live via `git ls-files 'scripts/ci/*.mjs' | wc -l` during this plan's execution, per D-00/D-15 -- not copied from RESEARCH.md's stale 42 (which counted two then-untracked Stripe fixture files that remain untracked and out of this plan's scope)."
  - "Rule 1 bug, found via Task 1's own fixture failures and confirmed via a full 382-file cohort `node --test` sweep: any spawnSync/dynamic-import() call targeting a now-guard-migrated module must DELETE (not blank with an empty string) an inherited NODE_TEST_CONTEXT from the child's env. node:test's recursion guard treats mere key presence -- even `\"\"` -- as \"already inside a test run\" and silently skips the nested invocation, which would turn a deliberately-bad CLI negative control's expected non-zero exit into a false 0, or turn an in-process self-test-as-library-load into an unwanted mid-run test() registration. Fixed at every affected site (verify_ci_critical_path.test.mjs's four spawns, phase229_gap_closure.test.mjs's loadHandoffLibrary in-process import, verify_provider_proof.mjs's two nested provider_proof.mjs spawns, verify_ci_baseline.mjs's two nested render_ci_baseline.mjs spawns, collect_ci_baseline.mjs's own nested verify_ci_baseline.mjs spawn) and documented in scripts/ci/README.md's guard-convention section for future migrations."
  - "For verify_foundation_contrast.mjs and verify_phase191_ax187_coverage.mjs, which had NO function wrapper at all (every statement ran unconditionally at module top level, including file reads), wrapped the side-effecting body in an exported main() so importing the module is no longer itself a side effect -- the exact D-29 defect class, just without an entrypoint guard of any kind rather than a broken one."
  - "--require-required-job-set is the only verify_ci_baseline.mjs strict flag wired into the CI baseline triad's --fixtures step: the other three (--require-critical-path, --require-event-class, --require-exit-codes) all require --records, which a --fixtures-only wiring does not supply."

patterns-established:
  - "Meta-verifier assertions are pure functions (assertGuardCoverage, assertNonVacuity, assertCohortFloor) taking file descriptors rather than paths, so --fixtures exercises them against a scratch temp directory with no git dependency at all -- only the live liveCohort() enumeration touches git."

requirements-completed: []

coverage:
  - id: D1
    description: "scripts/ci/verify_ci_script_contract.mjs enforces guard-coverage, non-vacuity, and a live cohort floor over the real git-tracked scripts/ci/*.mjs cohort, and cannot pass on a zero-match or short glob"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/verify_ci_script_contract.mjs (6 tests, 0 fail)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_script_contract.mjs --fixtures --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor -> PASS, 5 negative controls exercised"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor -> PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_script_contract.mjs --expected-repository szTheory/accrue -> PASS (schema-only: no strict flags supplied, ...)"
        status: pass
    human_judgment: false
  - id: D2
    description: "12 previously guard-less scripts/ci/*.mjs files migrated to the shared isMainModule guard with a same-commit real named node:test each; no behavior change to any CLI invocation"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap over all 12 files -- 0 fail each, at least one non-file-path TAP entry"
        status: pass
      - kind: integration
        ref: "CLI behavior re-verified unchanged: node scripts/ci/phase_evidence_path.mjs, verify_foundation_contrast.mjs, verify_phase191_ax187_coverage.mjs, verify_ci_critical_path.mjs --fixtures, verify_provider_proof.mjs --fixtures, verify_stripe_webhook_boot_evidence.mjs --fixtures, verify_phase229_handoff_invariants.mjs --self-test, bootstrap_stripe_provider_proof.mjs self-test, provider_proof_automation.mjs self-test, verify_executable_uat_contract.mjs self-test"
        status: pass
    human_judgment: false
  - id: D3
    description: "The ci_baseline triad (collect/render/verify_ci_baseline.mjs) is green under node --test with no assertion deleted, skipped, or weakened, and appears in the meta-verifier's cohort with no allowlist exemption"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap over collect_ci_baseline.mjs, render_ci_baseline.mjs, verify_ci_baseline.mjs together -- 33/33 pass, 0 fail"
        status: pass
      - kind: other
        ref: "Pre-fix isolated re-measurement (git stash of just these 3 files): collect_ci_baseline.mjs exit 0 (21/21); render_ci_baseline.mjs exit 1 (main() ran unconditionally, no CLI args, threw usage error); verify_ci_baseline.mjs exit 1 (no guard at all, await main() ran unconditionally) -- matches D-27's claim of 2/3 failing, re-verified rather than transcribed"
        status: pass
    human_judgment: false
  - id: D4
    description: "Two new merge-blocking docs-contracts-shift-left steps (CI baseline triad units and fixture contract D-34, CI script contract D-32) run both a --fixtures self-test and a real invocation against the actual repository, neither carries continue-on-error, and the workflow parses"
    requirement: HYG-02
    verification:
      - kind: other
        ref: "python3 yaml.safe_load(.github/workflows/ci.yml) -> parsed; step-name + continue-on-error + --repo . assertion script -> ok"
        status: pass
      - kind: integration
        ref: "Both new steps' exact run: command chains executed locally end to end -> exit 0"
        status: pass
    human_judgment: false

duration: ~80min
completed: 2026-09-16
status: complete
---

# Phase 232 Plan 03: CI script contract meta-verifier + ci_baseline triad wiring Summary

**Shipped `scripts/ci/verify_ci_script_contract.mjs` as a self-enforcing meta-verifier for the D-29 module-boundary guard and non-vacuity contract, migrated the 12 remaining guard-less `scripts/ci/*.mjs` files it exposed as gaps, brought the previously-unwired `ci_baseline` triad green (2 of 3 files failed `node --test` before this plan), and wired both into `docs-contracts-shift-left` as new merge-blocking checks.**

## Performance

- **Duration:** ~80 min
- **Started:** 2026-09-16 (session continuation from 232-02)
- **Completed:** 2026-09-16
- **Tasks:** 3/3 completed
- **Files modified:** 19 (1 created, 18 modified)

## Accomplishments

- `scripts/ci/verify_ci_script_contract.mjs` enforces, for the git-tracked `scripts/ci/*.mjs` cohort (enumerated via `git ls-files`, never a raw directory read): every file imports `isMainModule` from the shared helper (or is `*.test.mjs`, or carries an explicit reasoned allowlist entry -- empty today); every file registers at least one real named test under `node --test --test-reporter=tap` (spawned with `NODE_TEST_CONTEXT` deleted from the child env, not blanked); and the live cohort size never drops below a committed floor (41, re-measured live on 2026-09-16 via `git ls-files 'scripts/ci/*.mjs' | wc -l`). Prints which strict flags actually ran (`PASS (verified: ...)` vs `PASS (schema-only: ...)`).
- Task 1's own real-repository acceptance criterion forced discovering and closing a real gap: 15 files were still guard-less. The 3-file `ci_baseline` triad was Task 2's declared scope; the other 12 (`apple_notification_delivery_smoke.mjs`, `bootstrap_stripe_provider_proof.mjs`, `generate_phase200_closeout_reports.mjs`, `phase_evidence_path.mjs`, `provider_proof_automation.mjs`, `verify_ci_critical_path.mjs`, `verify_executable_uat_contract.mjs`, `verify_foundation_contrast.mjs`, `verify_phase191_ax187_coverage.mjs`, `verify_phase229_handoff_invariants.mjs`, `verify_provider_proof.mjs`, `verify_stripe_webhook_boot_evidence.mjs`) were explicitly out of 232-02's own scope. Migrated all 12 within Task 1 so its own gate could clear.
- Discovered and fixed a real, previously-latent class of bug: when a guard-migrated file's own test spawns or dynamically imports ANOTHER guard-migrated file, an inherited `NODE_TEST_CONTEXT` makes node:test's recursion guard silently skip the nested invocation -- turning an expected non-zero exit (a deliberately-bad CLI negative control) into a false pass, or an in-process self-test-as-library-load into an unwanted mid-run `test()` registration. Fixed at every site this plan's own migrations exposed (`verify_ci_critical_path.test.mjs`, `phase229_gap_closure.test.mjs`, `verify_provider_proof.mjs`, `verify_ci_baseline.mjs`, `collect_ci_baseline.mjs`); confirmed clean via a full 382-test cohort sweep (`node --test --test-reporter=tap $(git ls-files 'scripts/ci/*.mjs')`).
- The `ci_baseline` triad (`collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, `verify_ci_baseline.mjs`) is now green under `node --test` -- `collect_ci_baseline.mjs` already passed (21/21), `render_ci_baseline.mjs` and `verify_ci_baseline.mjs` failed (both had `main()` running unconditionally with no CLI args, throwing the usage error), matching D-27's "two of the three fail" claim, re-measured rather than transcribed. No assertion deleted, skipped, or weakened.
- Two new merge-blocking `docs-contracts-shift-left` steps: `CI baseline triad units and fixture contract (D-34)` and `CI script contract (D-32)`, both after `Window dispositions triad units and fixture contract`, neither with `continue-on-error`. The D-32 step runs the meta-verifier's `--fixtures` self-test AND a real `--repo .` invocation against the actual cohort -- the real invocation is the point, closing the D-16 class of "documented but never executed" verification.

## Task Commits

Each task was committed atomically (4 commits total for this plan):

1. **Task 1: Build the CI script contract meta-verifier with a floor it cannot glob past** - `25e6cfae` (feat) -- verify_ci_script_contract.mjs + 12-file guard migration deviation
2. **Task 1 fix: add the fourth non-vacuity negative control** - `c0e1e20d` (fix)
3. **Task 2: Bring the ci_baseline triad green before anything wires it** - `cf4d9dc2` (feat)
4. **Task 3: Wire the meta-verifier and ci_baseline triad into the shift-left job** - `66210017` (feat)

## Files Created/Modified

- `scripts/ci/verify_ci_script_contract.mjs` - new meta-verifier (D-32)
- `scripts/ci/collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, `verify_ci_baseline.mjs` - guard-migrated, green, NODE_TEST_CONTEXT inheritance bugs fixed
- `scripts/ci/apple_notification_delivery_smoke.mjs` - guard + test exercising `base64url`/`endpoint` pure helpers
- `scripts/ci/bootstrap_stripe_provider_proof.mjs` - guard + existing `selfTest()` wrapped in a `node:test` case
- `scripts/ci/generate_phase200_closeout_reports.mjs` - guard + test exercising exported `parseArgs`
- `scripts/ci/phase_evidence_path.mjs` - guard + test exercising `resolvePhaseEvidencePath`/`repositoryRelativePhaseEvidencePath`
- `scripts/ci/provider_proof_automation.mjs` - guard + existing `selfTest()` wrapped
- `scripts/ci/verify_ci_critical_path.mjs` - guard + test wrapping exported `verifyFixtures()`
- `scripts/ci/verify_ci_critical_path.test.mjs` - NODE_TEST_CONTEXT-inheritance fix on 4 spawn sites (Rule 1)
- `scripts/ci/verify_executable_uat_contract.mjs` - guard + existing `selfTest()` wrapped
- `scripts/ci/verify_foundation_contrast.mjs` - had no function wrapper at all; wrapped body in `main()`, guard + test on exported `contrastRatio`
- `scripts/ci/verify_phase191_ax187_coverage.mjs` - same as above; guard + test on exported `normalizeTag`
- `scripts/ci/verify_phase229_handoff_invariants.mjs` - guard + existing `runSelfTest()` wrapped
- `scripts/ci/verify_provider_proof.mjs` - guard + existing `runFixtures()` wrapped; fixed 2 nested spawns
- `scripts/ci/verify_stripe_webhook_boot_evidence.mjs` - guard + existing `runFixtures()` wrapped
- `scripts/ci/phase229_gap_closure.test.mjs` - `loadHandoffLibrary()`'s in-process import now clears NODE_TEST_CONTEXT for the duration (Rule 1)
- `.github/workflows/ci.yml` - two new merge-blocking `docs-contracts-shift-left` steps
- `scripts/ci/README.md` - `## Module-boundary guard convention` updated (landed, not "arriving") + NODE_TEST_CONTEXT-inheritance footgun note + new `## Phase 232` section

## Decisions Made

See `key-decisions` in frontmatter for full rationale on: expanding Task 1's scope to migrate 12 more files so its own acceptance criteria could clear; re-measuring the committed cohort floor live (41); the NODE_TEST_CONTEXT-deletion-not-blanking fix pattern found and applied across five call sites; wrapping two previously-unwrapped files' entire bodies in `main()`; and which single strict flag is safe to pair with `verify_ci_baseline.mjs --fixtures`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 1's own acceptance criteria required migrating 12 files outside its declared `<files>`**
- **Found during:** Task 1, first real-repository invocation of the newly-built meta-verifier
- **Issue:** Task 1's `<files>` declares only `scripts/ci/verify_ci_script_contract.mjs`, but its own `<verify>` block requires `node scripts/ci/verify_ci_script_contract.mjs --repo . ... --require-guard-coverage --require-non-vacuity --require-cohort-floor` to exit 0. The real-repo run found 15 ungated files -- 3 in Task 2's declared scope, 12 that plan 232-02 explicitly deferred as out of its own scope, and not named anywhere in 232-03's `<files>` either.
- **Fix:** Migrated all 12 within Task 1, using the established guard pattern and, where present, wrapping existing `selfTest()`/`runFixtures()` batteries; otherwise a small pure-helper test. Two files (`verify_foundation_contrast.mjs`, `verify_phase191_ax187_coverage.mjs`) had no function wrapper at all and needed their bodies moved into an exported `main()`.
- **Files modified:** listed above.
- **Verification:** Task 1's own real-repository `<verify>` command now exits 0.
- **Committed in:** `25e6cfae` (Task 1 commit)

**2. [Rule 1 - Bug] NODE_TEST_CONTEXT inheritance silently skips nested `node --test` invocations**
- **Found during:** Task 1's own fixture verification (conforming-file scenario failed as "vacuous" when it was not)
- **Issue:** `assertNonVacuity` spawns `node --test --test-reporter=tap <file>` per cohort file. When this verifier itself runs under an active `node --test` (its own self-test), the spawned child inherits `NODE_TEST_CONTEXT`; node:test's recursion guard treats mere key presence -- even an empty string -- as "already inside a test run" and silently skips running the nested file, printing a warning and reporting zero tests. Setting the child env var to `""` (mirroring `main_module.mjs`'s pattern for a DIFFERENT scenario -- a plain, non-`--test` child) did not fix it; the key must be deleted. The same defect then surfaced independently in `verify_provider_proof.mjs` (nested `provider_proof.mjs --finalize` spawns), `verify_ci_baseline.mjs` (nested `render_ci_baseline.mjs` spawns), `collect_ci_baseline.mjs` (nested `verify_ci_baseline.mjs` spawn), `verify_ci_critical_path.test.mjs` (4 spawns of the now-migrated `verify_ci_critical_path.mjs`), and `phase229_gap_closure.test.mjs`'s `loadHandoffLibrary()` in-process dynamic import of the now-migrated `verify_phase229_handoff_invariants.mjs`.
- **Fix:** At every site, `delete childEnv.NODE_TEST_CONTEXT` (or `delete process.env.NODE_TEST_CONTEXT` for the in-process import case) before spawning/importing, restoring afterward where the site already restores other faked state (argv).
- **Files modified:** `scripts/ci/verify_ci_script_contract.mjs`, `scripts/ci/verify_provider_proof.mjs`, `scripts/ci/verify_ci_baseline.mjs`, `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/verify_ci_critical_path.test.mjs`, `scripts/ci/phase229_gap_closure.test.mjs`.
- **Verification:** Full cohort sweep `node --test --test-reporter=tap $(git ls-files 'scripts/ci/*.mjs')` -> 382/382 pass, 0 fail. `phase229_gap_closure.test.mjs` alone -> 26/26 pass, ~78s (within its established 120s bound).
- **Committed in:** `25e6cfae`, `cf4d9dc2` (Task 1 and Task 2 commits)

---

**Total deviations:** 2 auto-fixed (1 Rule 3 -- own-acceptance-criteria scope expansion, 1 Rule 1 -- a real, previously-latent bug class found and fixed at 6 call sites across 2 tasks).
**Impact on plan:** Both were necessary for this plan's own stated acceptance criteria to pass and for existing merge-blocking test suites to stay green. Deviation 2 in particular is exactly the class of self-inflicted breakage the plan's own D-31/D-33 discipline exists to catch before it reaches a merge-blocking gate -- caught here via mandated fixture verification and a full-cohort re-run, not by CI.

## Issues Encountered

None beyond the two auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The guard-and-non-vacuity contract is now merge-blocking and self-enforcing: `scripts/ci/verify_ci_script_contract.mjs --repo . --require-guard-coverage --require-non-vacuity --require-cohort-floor`, wired into `docs-contracts-shift-left`, will fail CI the moment a future `scripts/ci/*.mjs` file omits the shared guard or registers no real test -- no second invariant test is needed (per the plan's `assumption_delta_decision`). The `ci_baseline` triad is green and wired in the same plan (fix-before-wire, D-34). 15 previously guard-less files across the whole cohort have shrunk to 0; the only remaining `*.mjs` files in `scripts/ci/` without the shared guard are legitimate `*.test.mjs` files. No blockers for 232-04 or later plans; `HYG-02` remains `Pending` in REQUIREMENTS.md because it is a shared ID declared by 6 more not-yet-executed plans in this phase (232-04..232-11) and only flips complete when every declaring plan finishes (per the shared-ID gate).

## Self-Check: PASSED

- FOUND: `scripts/ci/verify_ci_script_contract.mjs` (verified via `node --check`)
- FOUND: `25e6cfae` (Task 1 commit) in `git log --oneline`
- FOUND: `c0e1e20d` (Task 1 fix commit) in `git log --oneline`
- FOUND: `cf4d9dc2` (Task 2 commit) in `git log --oneline`
- FOUND: `66210017` (Task 3 commit) in `git log --oneline`
- Real-repository invocation: `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` -> exit 0, `PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)` (confirmed live)
- Full cohort sweep: `node --test --test-reporter=tap $(git ls-files 'scripts/ci/*.mjs')` -> 382/382 pass (confirmed live)
- `.github/workflows/ci.yml` parses via `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` -> `parsed` (confirmed live)

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-16*
