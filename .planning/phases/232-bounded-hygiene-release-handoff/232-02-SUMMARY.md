---
phase: 232-bounded-hygiene-release-handoff
plan: 02
subsystem: infra
tags: [node, ci, module-boundary-guard, esm, node-test, tap-reporter]

requires:
  - phase: 232-01
    provides: "scripts/ci/main_module.mjs exporting isMainModule(moduleUrl), the shared realpath-resolved module-boundary guard, and the try/catch call-site pattern"
provides:
  - "22 git-tracked scripts/ci/*.mjs entrypoints (including main_module.mjs itself) migrated to the shared isMainModule guard; both retired guard idioms at zero occurrences across the migrated set"
  - "8 previously-vacuous scripts/ci/*.mjs files now register at least one real prose-named node:test case, each guard-fix + first-test pair landing in the same commit (D-31)"
  - "Every child `node --test` spawn across scripts/ci/*.mjs selects --test-reporter=tap explicitly"
  - "scripts/ci/phase229_gap_closure.test.mjs completes in ~74s wall clock with an explicit 120_000ms timeout on its two heaviest child-spawning cases, no test deleted or skipped"
affects: [232-03, 232-06, 232-08]

actuals:
  tokens: 12944
  tasks: 3
  commits: 10

tech-stack:
  added: []
  patterns:
    - "isMainModule(import.meta.url) guard usage, try/catch around the throw (232-01's established call-site pattern), reused for every migration in this plan"
    - "Wrapping an existing runSelfTest()/--self-test CLI battery in a single node:test case, rather than duplicating fixture logic, for files that already carried rich self-tests"
    - "Writing a new, small, self-contained node:test case against a pure exported helper (instead of the file's own broken or on-the-merits-failing self-test) when reusing existing coverage would either fail or require fixing an out-of-scope pre-existing bug"

key-files:
  created: []
  modified:
    - scripts/ci/main_module.mjs
    - scripts/ci/collect_gate01_cohort.mjs
    - scripts/ci/collect_integration_disposition.mjs
    - scripts/ci/collect_repository_inventory.mjs
    - scripts/ci/collect_window_dispositions.mjs
    - scripts/ci/render_integration_disposition.mjs
    - scripts/ci/render_repository_inventory.mjs
    - scripts/ci/render_gate01_cohort.mjs
    - scripts/ci/render_window_dispositions.mjs
    - scripts/ci/verify_phase230_archive_invariants.mjs
    - scripts/ci/verify_integration_disposition.mjs
    - scripts/ci/verify_gate01_cohort.mjs
    - scripts/ci/verify_window_dispositions.mjs
    - scripts/ci/verify_repository_inventory.mjs
    - scripts/ci/provider_proof.mjs
    - scripts/ci/render_provider_summary.mjs
    - scripts/ci/verify_phase192_scorecard.mjs
    - scripts/ci/verify_phase192_signoff.mjs
    - scripts/ci/verify_ratchet_ledger.mjs
    - scripts/ci/verify_phase200_scorecard.mjs
    - scripts/ci/verify_phase200_signoff.mjs
    - scripts/ci/verify_ui_ratchet_signoff.mjs
    - scripts/ci/verify_phase229_handoff_invariants.mjs
    - scripts/ci/phase229_gap_closure.test.mjs

key-decisions:
  - "Re-derived the census live rather than trusting 232-PATTERNS.md/232-CONTEXT.md's transcribed file lists (D-15): idiom-1 (pathname comparison) = 10 real guard sites (not 11 -- one grep hit was main_module.mjs's own explanatory comment), idiom-2 (file-URL template) = 8 files (not 9 -- one of the 9 named in RESEARCH.md, stripe_test_fixtures.mjs, is untracked and excluded per this plan's own prohibition), and 4 files (verify_gate01_cohort.mjs, verify_window_dispositions.mjs, verify_repository_inventory.mjs, verify_integration_disposition.mjs) had NO guard at all (231-REVIEW IN-01 shape) -- 3 more than CONTEXT.md/PATTERNS.md named."
  - "The re-derived census also found that ALL 8 idiom-2 files are vacuous under node --test (zero real named TAP entries), not just the 3 the plan's Task 2 <files> declared (verify_phase200_scorecard.mjs, verify_phase200_signoff.mjs, verify_ui_ratchet_signoff.mjs). Per Task 1's own instruction ('files whose count is zero are the vacuous set and belong to Task 2, not this task') and Task 2's own read_first ('the census is what binds'), the other 5 (provider_proof.mjs, render_provider_summary.mjs, verify_phase192_scorecard.mjs, verify_phase192_signoff.mjs, verify_ratchet_ledger.mjs) were also given a same-commit guard+test pair under Task 2, not migrated bare under Task 1. All 5 are already named in the plan's frontmatter files_modified list -- this is a re-derivation within declared scope, not scope creep."
  - "For files that already carry a rich runSelfTest()/--self-test CLI battery (verify_phase192_scorecard.mjs, verify_phase192_signoff.mjs, verify_ratchet_ledger.mjs, verify_phase200_signoff.mjs), wrapped that existing battery in a single node:test case rather than writing new fixtures -- cheapest genuinely meaningful assertion available, per the task's own instruction."
  - "For verify_phase200_scorecard.mjs, did NOT wrap its existing runSelfTest(): that self-test's fixtures write evidence under a PHASE200_DIR-prefixed ref, which the file's own shouldRequireDiskArtifact resolves against the REAL repo root -- a pre-existing bug making the self-test (and the file's default real-evidence CLI run) fail on the merits today, unrelated to and unchanged by this guard migration (re-verified identical exit=1 before and after). Wrote a new, self-contained test against the exported verifyPhase200Scorecard using an accrue_admin/test-results/-prefixed evidence ref outside the disk-required phase200/ subpath instead."
  - "For verify_ui_ratchet_signoff.mjs, did NOT exercise the end-to-end verifyUiRatchetSignoff()/verifyFrozenRatchetLedger() path at all: per CONTEXT.md D-21/D-27 the ratchet ledger is not frozen today, so that path fails on the merits. Wrote two tests against small pure helpers (validEvidenceRef, parseDecisionLine) instead, so this plan does not depend on un-parking the ratchet (owned by plan 232-06)."
  - "Task 3's grep-zero acceptance criterion ('a child argv containing the bare test flag without a reporter flag returns 0 lines') is repo-wide by its own wording, so fixed 3 reporter-implicit child `node --test` spawns in scripts/ci/verify_phase229_handoff_invariants.mjs even though that file is not in this plan's declared files_modified -- same re-derivation discipline Task 1 already established for its own grep-zero criterion. These spawns only check exit status (never parse TAP output), so this is a forward-looking safety pin with zero behavior change."
  - "Rule 1 bug found and fixed during Task 3's full-file re-run: Task 1's isMainModule import addition to verify_repository_inventory.mjs broke phase229_gap_closure.test.mjs's documentedStrictFixture(), which copies that file into an isolated scratch scripts/ci/ directory without main_module.mjs, causing ERR_MODULE_NOT_FOUND. Added main_module.mjs to the fixture's copy set."
  - "15 further guard-less scripts/ci/*.mjs files are out of this plan's declared scope (never named in 232-02-PLAN.md's files_modified, and never matched either retired idiom) and were left untouched: apple_notification_delivery_smoke.mjs, bootstrap_stripe_provider_proof.mjs, collect_ci_baseline.mjs, generate_phase200_closeout_reports.mjs, phase_evidence_path.mjs (library module, no CLI entrypoint), provider_proof_automation.mjs, render_ci_baseline.mjs, verify_ci_baseline.mjs, verify_ci_critical_path.mjs, verify_executable_uat_contract.mjs, verify_foundation_contrast.mjs, verify_phase191_ax187_coverage.mjs, verify_phase229_handoff_invariants.mjs (guard-migration only, out of scope; its reporter flags WERE fixed under Task 3), verify_provider_proof.mjs, verify_stripe_webhook_boot_evidence.mjs."

patterns-established:
  - "Same-commit guard+test discipline (D-31): every previously-vacuous file's isMainModule migration and its first real node:test case land in exactly one commit, never split."
  - "When a file already carries a positive/negative fixture battery wired to --self-test, prefer wrapping it in one node:test case over hand-rolling new fixtures -- unless that battery itself fails on the merits, in which case write an independent, correctly-scoped test rather than propagating a pre-existing bug into the merge-blocking gate."

requirements-completed: [HYG-02]

coverage:
  - id: D1
    description: "10 already-tested scripts/ci/*.mjs entrypoints (idiom-1) plus 4 previously guard-less entrypoints (verify_gate01_cohort.mjs, verify_window_dispositions.mjs, verify_repository_inventory.mjs, verify_integration_disposition.mjs, IN-01 shape) migrated to the shared isMainModule guard with no other behavior change"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap over all 13 files -- 0 fail each"
        status: pass
      - kind: other
        ref: "git ls-files 'scripts/ci/*.mjs' | xargs grep -l 'new URL(import.meta.url).pathname' | wc -l -> idiom1_remaining=0"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_gate01_cohort.mjs --fixtures / verify_window_dispositions.mjs --fixtures / verify_repository_inventory.mjs --fixtures -> PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "8 vacuous scripts/ci/*.mjs files (all of idiom-2's bucket) each gained a same-commit isMainModule guard + first real named node:test case"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap over all 8 files -- 0 fail each, at least one non-file-path TAP entry"
        status: pass
      - kind: other
        ref: "git show --stat <sha> per file contains both the guard hunk and the new test( hunk (8 SHAs recorded below)"
        status: pass
      - kind: integration
        ref: "CLI --self-test / default-run behavior re-verified unchanged for provider_proof.mjs, render_provider_summary.mjs, verify_phase192_scorecard.mjs, verify_phase192_signoff.mjs, verify_ratchet_ledger.mjs, verify_phase200_scorecard.mjs, verify_phase200_signoff.mjs, verify_ui_ratchet_signoff.mjs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every child node --test spawn across git-tracked scripts/ci/*.mjs selects --test-reporter=tap explicitly; phase229_gap_closure.test.mjs completes within a declared 120s bound with no test deleted or skipped"
    requirement: HYG-02
    verification:
      - kind: other
        ref: "git ls-files 'scripts/ci/*.mjs' | xargs grep -n -- '--test\"' | grep -v test-reporter | wc -l -> 0"
        status: pass
      - kind: integration
        ref: "node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs -> exit 0, 26/26 pass, duration_ms=73656, no timeout line"
        status: pass
    human_judgment: false

duration: 95min
completed: 2026-09-16
status: complete
---

# Phase 232 Plan 02: Module-boundary guard migration + non-vacuity + reporter-explicit child tests Summary

**Retired both broken `isMainModule` guard idioms across 22 git-tracked `scripts/ci/*.mjs` entrypoints, closed the entire vacuous-test class the re-derived census actually found (8 files, not the 3 the plan pre-declared), and pinned `--test-reporter=tap` on every child `node --test` spawn including the one Task 3's own re-run surfaced outside the declared file list.**

## Performance

- **Duration:** ~95 min
- **Started:** 2026-09-16 (session continuation from 232-01)
- **Completed:** 2026-09-16
- **Tasks:** 3/3 completed
- **Files modified:** 24 (0 created, 24 modified)

## Accomplishments

- Both retired guard idioms (`argv[1] === new URL(import.meta.url).pathname` and `` import.meta.url === `file://${argv[1]}` ``) are now at zero occurrences across every git-tracked `scripts/ci/*.mjs` file, confirmed by a literal grep sweep.
- Live census re-derivation (D-15 no-transcription rule) found the plan's own pre-declared file lists were stale in two directions: `main_module.mjs`'s own explanatory comment tripped the idiom-1 grep (mirroring 232-01's Deviation 1), and 4 files carried no guard at all (231-REVIEW IN-01 shape) rather than the single file CONTEXT.md named.
- All 8 idiom-2 files (not just the 3 the plan's Task 2 `<files>` declared) are the true vacuous set; each received a same-commit `isMainModule` guard + first real `node:test` case, per D-31.
- Every child `node --test` spawn across `scripts/ci/*.mjs` now selects `--test-reporter=tap` explicitly, including 3 spawns in `verify_phase229_handoff_invariants.mjs` discovered by this task's own re-derivation (outside the plan's declared files, fixed under the same grep-zero discipline Task 1 established).
- `scripts/ci/phase229_gap_closure.test.mjs` completes in ~74s wall clock (26/26 tests pass) with an explicit 120s bound on its two heaviest child-spawning cases; a real regression this task's re-run surfaced (Task 1's `isMainModule` import broke a scratch-fixture copy set) was found and fixed before commit.

## Task Commits

Each task was committed atomically (10 commits total for this plan):

1. **Task 1: Re-measure the census, then migrate every already-tested entrypoint to the shared guard** - `fc2f0a0c` (feat) -- 13 files (9 idiom-1 swaps + 4 IN-01 full-guard additions) + `main_module.mjs`'s own comment reword
2. **Task 2 (file 1/8): provider_proof.mjs** - `f55ae243` (feat)
3. **Task 2 (file 2/8): render_provider_summary.mjs** - `50f8bdcf` (feat)
4. **Task 2 (file 3/8): verify_phase192_scorecard.mjs** - `a321a9cf` (feat)
5. **Task 2 (file 4/8): verify_phase192_signoff.mjs** - `6386547d` (feat)
6. **Task 2 (file 5/8): verify_ratchet_ledger.mjs** - `e1b1062c` (feat)
7. **Task 2 (file 6/8): verify_phase200_scorecard.mjs** - `08e95252` (feat)
8. **Task 2 (file 7/8): verify_phase200_signoff.mjs** - `db23e775` (feat)
9. **Task 2 (file 8/8): verify_ui_ratchet_signoff.mjs** - `97ee1b29` (feat)
10. **Task 3: Reporter-explicit child node --test spawns + bounded gap-closure runtime** - `15f6dc69` (feat)

## Files Created/Modified

- `scripts/ci/main_module.mjs` - explanatory comment reworded to stop tripping the idiom-1 literal grep (Rule 1 fix, mirrors 232-01 Deviation 1)
- `scripts/ci/collect_gate01_cohort.mjs` - guard swap + `fileURLToPath` fix for a non-guard idiom-1-literal usage (own-file-path derivation for reading `ci.yml`)
- `scripts/ci/collect_integration_disposition.mjs`, `collect_repository_inventory.mjs`, `collect_window_dispositions.mjs`, `render_integration_disposition.mjs`, `render_repository_inventory.mjs`, `render_gate01_cohort.mjs`, `render_window_dispositions.mjs`, `verify_phase230_archive_invariants.mjs` - guard swap only
- `scripts/ci/verify_integration_disposition.mjs` - full guard added (IN-01 shape) + `fileURLToPath` fix for a non-guard idiom-1-literal usage (spawning itself as a child process)
- `scripts/ci/verify_gate01_cohort.mjs`, `verify_window_dispositions.mjs`, `verify_repository_inventory.mjs` - full guard added (IN-01 shape)
- `scripts/ci/provider_proof.mjs` - guard + new test (classifyProviderProof positive/negative)
- `scripts/ci/render_provider_summary.mjs` - guard + new test (renderProviderSummary Markdown escaping/freshness)
- `scripts/ci/verify_phase192_scorecard.mjs`, `verify_phase192_signoff.mjs`, `verify_ratchet_ledger.mjs`, `verify_phase200_signoff.mjs` - guard + existing runSelfTest() wrapped in a node:test case
- `scripts/ci/verify_phase200_scorecard.mjs` - guard + new independent test against verifyPhase200Scorecard (existing self-test fails on the merits, out of scope to fix)
- `scripts/ci/verify_ui_ratchet_signoff.mjs` - guard + new tests against validEvidenceRef/parseDecisionLine helpers only (end-to-end path fails on the merits, D-21, out of scope)
- `scripts/ci/verify_phase229_handoff_invariants.mjs` - 3 child `node --test` spawns made reporter-explicit (`--test-reporter=tap`)
- `scripts/ci/phase229_gap_closure.test.mjs` - explicit `{ timeout: 120_000 }` on its 2 heaviest tests + fixed a real regression (missing `main_module.mjs` in a scratch-fixture copy set)

## Decisions Made

See `key-decisions` in frontmatter above for the full rationale on: the re-derived census correcting the plan's pre-declared file lists in both directions; expanding Task 2's guard+test work to all 8 vacuous idiom-2 files (within declared scope); choosing wrap-existing-self-test vs. write-new-independent-test per file based on whether the existing self-test already passes; and fixing 3 out-of-declared-file reporter flags under Task 3's own grep-zero acceptance criterion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `main_module.mjs`'s own explanatory comment tripped the idiom-1 literal grep**
- **Found during:** Task 1, first census re-derivation
- **Issue:** The file's comment named the retired idiom in prose (`new URL(import.meta.url).pathname`), which a literal-text grep gate (Task 1's own acceptance criterion) has no comment carve-out for -- exactly the same class of bug 232-01's Deviation 1 hit for `import.meta.main`.
- **Fix:** Reworded the comment to describe the same fact without spelling the literal token.
- **Files modified:** `scripts/ci/main_module.mjs`
- **Verification:** `grep -c` for both idiom literals against the file → 0; full self-test suite still 5/5 pass.
- **Committed in:** `fc2f0a0c` (Task 1 commit)

**2. [Rule 1 - Bug] Two literal idiom-1 occurrences were not guard usages and would have tripped the grep-zero acceptance criterion**
- **Found during:** Task 1, acceptance-criteria verification
- **Issue:** `collect_gate01_cohort.mjs` used `new URL(import.meta.url).pathname` to derive its own file path for reading `ci.yml` (not a guard comparison); `verify_integration_disposition.mjs` used the same expression to spawn itself as a child process for a determinism test. Both would have left the literal idiom text in the tree, failing the plan's own strict grep-zero criterion.
- **Fix:** Replaced both with `fileURLToPath(import.meta.url)`, functionally identical, no behavior change.
- **Files modified:** `scripts/ci/collect_gate01_cohort.mjs`, `scripts/ci/verify_integration_disposition.mjs`
- **Verification:** Post-fix grep returns 0 for both files; both files' `node --test` and CLI behavior re-verified unchanged.
- **Committed in:** `fc2f0a0c` (Task 1 commit)

**3. [Rule 2 - Missing Critical] 3 reporter-implicit child `node --test` spawns discovered outside this plan's declared files**
- **Found during:** Task 3, census re-derivation
- **Issue:** Task 3's own acceptance criterion is a repo-wide grep for the bare `--test` flag without `--test-reporter=tap`. Three such spawns exist in `scripts/ci/verify_phase229_handoff_invariants.mjs`, which is not in this plan's declared `files_modified`. Leaving them would fail this task's own stated acceptance criterion, and they carry the exact D-33 footgun (Node 22+ defaults to the `spec` reporter).
- **Fix:** Added `--test-reporter=tap` to all 3 spawns. These spawns only check exit status today (never parse TAP output), so this is a forward-looking safety pin with zero observable behavior change.
- **Files modified:** `scripts/ci/verify_phase229_handoff_invariants.mjs`
- **Verification:** Repo-wide grep for the bare flag returns 0; file re-checked with `node --check`.
- **Committed in:** `15f6dc69` (Task 3 commit)

**4. [Rule 1 - Bug] `phase229_gap_closure.test.mjs`'s "WR-01 documented strict command..." case failed after Task 1's own guard migration**
- **Found during:** Task 3, full-file re-run (measuring the wall-clock duration this task's acceptance criteria require)
- **Issue:** Task 1 added `import { isMainModule } from "./main_module.mjs"` to `verify_repository_inventory.mjs`. `documentedStrictFixture()` in `phase229_gap_closure.test.mjs` copies that file into an isolated scratch `scripts/ci/` directory (to run it against a fixture repo) without copying `main_module.mjs` alongside it, so the import failed with `ERR_MODULE_NOT_FOUND` under a full run -- a real regression this plan's own earlier commit introduced, caught by this task's mandated full-file re-verification before it could reach a merge-blocking gate.
- **Fix:** Added `main_module.mjs` to the fixture's copy set (one line).
- **Files modified:** `scripts/ci/phase229_gap_closure.test.mjs`
- **Verification:** Full file re-run: 26/26 pass, exit 0 (previously 25/26, 1 failure with the exact `ERR_MODULE_NOT_FOUND` trace).
- **Committed in:** `15f6dc69` (Task 3 commit)

---

**Total deviations:** 4 auto-fixed (2 Rule 1 grep-tripping literal fixes, 1 Rule 2 out-of-file-scope safety pin required by this task's own acceptance criterion, 1 Rule 1 real regression from this plan's own earlier commit).
**Impact on plan:** All four were necessary for this plan's own stated acceptance criteria and `<verify>` blocks to pass, or to keep a merge-blocking test suite green. None expanded functional scope beyond guard-migration, non-vacuity, and reporter-explicitness. Deviation 4 in particular is exactly the kind of self-inflicted breakage D-31's same-commit discipline and this task's own mandated full-file re-run exist to catch before it reaches CI.

## Issues Encountered

None beyond the four auto-fixed deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`scripts/ci/verify_ci_script_contract.mjs` (232-03) can now assert, over this plan's 22-file migrated set, that every file imports `isMainModule` from `./main_module.mjs` and registers at least one real named test -- both invariants this plan established and verified. The 15 remaining guard-less `scripts/ci/*.mjs` files (listed in key-decisions above) are explicitly out of this plan's scope and available for 232-03's own census to size, if in scope there. `scripts/ci/verify_ui_ratchet_signoff.mjs`'s on-the-merits failure (ratchet ledger not frozen, D-21) is unchanged and remains plan 232-06's to un-park. `scripts/ci/verify_phase200_scorecard.mjs`'s pre-existing self-test/CLI bug (disk-required artifact refs resolved against the real repo root instead of its own fixture root) is unchanged, recorded here, and available as a numbered finding for a future cleanup plan (232-08's `232-CLEANUP-FINDINGS.json`) if in scope there. No blockers for 232-03.

## Self-Check: PASSED

- FOUND: `scripts/ci/main_module.mjs` (verified via `node --check`)
- FOUND: `fc2f0a0c` (Task 1 commit) in `git log --oneline`
- FOUND: `f55ae243`, `50f8bdcf`, `a321a9cf`, `6386547d`, `e1b1062c`, `08e95252`, `db23e775`, `97ee1b29` (Task 2, 8 commits) in `git log --oneline`
- FOUND: `15f6dc69` (Task 3 commit) in `git log --oneline`
- Idiom-1 grep: `idiom1_remaining=0` (confirmed live)
- Idiom-2 grep: 0 matches (confirmed live)
- Reporter-implicit child `--test` spawn grep: 0 matches (confirmed live)
- `node --test --test-reporter=tap` over all 22 declared-scope files: 0 fail each (confirmed live)
- `node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs`: exit 0, 26/26 pass, no timeout line (confirmed live)

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-16*
