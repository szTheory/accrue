---
phase: 232-bounded-hygiene-release-handoff
plan: 06
subsystem: infra
tags: [ci, github-actions, ratchet, ship-window, disposition-honesty]

requires:
  - phase: 232-04
    provides: "the honest window-disposition renderer/verifier machinery (BUCKET_OF_PAIR, waiver-completeness assertion) this plan's waived row must satisfy"
  - phase: 232-05
    provides: "the release-manifest-ssot job structure and CI-editing conventions this plan's ci.yml edits stay consistent with"
provides:
  - "admin-ui-ratchet-selftests -- a new BLOCKING CI job (no continue-on-error at job or step level) carrying the three genuinely-passing ratchet machinery checks (ledger self-test, sign-off self-test, Phase 208 CI contract) plus the Parked-lane expiry trigger (D-26)"
  - "admin-ui-ratchet-guardrails renamed to display name \"Admin UI ratchet guardrails [parked]\", retaining its job-level continue-on-error and carrying only the two steps that fail because the ledger is deliberately unfrozen, with an if:always() status summary that reads real ledger fields instead of printing hardcoded PASS rows"
  - "ship-window row 11 in .planning/WINDOWS.md: kind unmet-truth, phase 232, waived, reason naming owner/rationale/release-impact"
  - "ANNOTATION_SWEEP_EXCLUDE keyed on disposition (advisory,parked) instead of subject (advisory,ratchet)"
affects: [232-10]

actuals:
  tokens: 6786
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Job-level continue-on-error absorbs the whole job's conclusion regardless of any individual step's own setting -- a step meant to fail blockingly cannot live in a job carrying that flag; place it in a sibling blocking job instead (D-26's own documented escape hatch)."
    - "Disposition-keyed annotation-sweep exclusion (job display-name fragment) instead of subject-keyed, landed in the same commit as the display-name change it depends on -- generalizable to any future parked/non-blocking CI lane."

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .planning/WINDOWS.md
    - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh

key-decisions:
  - "Re-derived the machinery-vs-parked step split live by running each npm script locally rather than trusting 232-PATTERNS.md's assertion: ratchet:ledger:self-test, ratchet:signoff:self-test, and ratchet:ci-contract all exit 0 today; ratchet:ledger:verify-frozen and ratchet:signoff (require-accept) both exit 1 today. The three-versus-two split matched the plan's assumption exactly, but was proved rather than assumed."
  - "Placed the Parked-lane expiry trigger (D-26) step in the BLOCKING admin-ui-ratchet-selftests job, not the parked admin-ui-ratchet-guardrails job, per the plan's own documented fallback: GitHub Actions' job-level continue-on-error absorbs the whole job's conclusion regardless of any individual step's own setting -- there is no per-step override that escapes a job-level flag. A step whose entire purpose is to fail blockingly cannot live in a job whose failures are structurally absorbed."
  - "Sequenced the ci.yml edits across the three task commits so the job's [parked] display-name marker and the ANNOTATION_SWEEP_EXCLUDE disposition-key edit landed in the SAME (Task 3) commit as required by D-25, even though the job split (Task 1) and the real-values summary/expiry trigger (Task 2) touch the same YAML block -- built the full target state first, then reverted the not-yet-due pieces back to their prior form for each earlier commit and reapplied them in the correct later commit."
  - "verify_admin_ui_ratchet_ci_contract.sh (not in the plan's declared files_modified) required updating in all three commits: it is the exact meta-contract this plan's own Task 1/2/3 <verify> commands invoke (npm run ratchet:ci-contract), and it hardcoded assertions against the pre-split single-job shape, the fabricated PASS lines, and the old ANNOTATION_SWEEP_EXCLUDE value -- a genuine Rule 3 blocking fix at each step, not scope creep."
  - "Ship-window row 11 uses kind unmet-truth (not unrun-verify, deviation, or any advisory-adjacent kind): the ratchet lane's truth -- a frozen, zero-open-findings ledger -- is asserted by verify-frozen/signoff and is currently false, i.e. an unmet truth, matching D-21's mandate that this lane's honest state is failed, never non_run/skipped/advisory."

requirements-completed: [HYG-02]

coverage:
  - id: D1
    description: "Two jobs exist where one did: admin-ui-ratchet-selftests (blocking, no continue-on-error at job or step level, three genuinely-passing steps) and admin-ui-ratchet-guardrails (job-level continue-on-error retained, only the two parked steps); the sweep's needs list and selector both gain the new blocking job id in the same commit as the split."
    requirement: HYG-02
    verification:
      - kind: other
        ref: "python3 assertion: 'continue-on-error' not in admin-ui-ratchet-selftests (job or any step); admin-ui-ratchet-guardrails.get('continue-on-error') is True -> 'split ok'"
        status: pass
      - kind: other
        ref: "python3 assertion: 'admin-ui-ratchet-selftests' in annotation-sweep.needs and in its run command -> 'sweep wired'"
        status: pass
      - kind: integration
        ref: "cd accrue_admin && npm run ratchet:ledger:self-test && npm run ratchet:signoff:self-test && npm run ratchet:ci-contract -> all exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The fabricated nine-row hardcoded PASS status-summary step is deleted; its replacement is if:always() and prints only values read or computed from accrue_admin/e2e/ratchet/ledger.baseline.json at run time. A new Parked-lane expiry trigger (D-26) step fails non-zero when ledger.frozen is true while ship-window row 11 still exists waived, proved by both negative controls."
    requirement: HYG-02
    verification:
      - kind: other
        ref: "grep -c 'PASS - ' .github/workflows/ci.yml -> 0"
        status: pass
      - kind: other
        ref: "python3 assertion: Ratchet status summary step .get('if')=='always()' -> 'summary ok'"
        status: pass
      - kind: other
        ref: "node -e against a synthetic {frozen:true} ledger + a synthetic waived-row-11 WINDOWS.md fixture -> exit 1; against the real ledger.baseline.json (frozen:false) + real .planning/WINDOWS.md (row 11 waived) -> exit 0 (both negative controls run manually, not committed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Ship-window row 11 is minted via the canonical gsd-tools windows append/waive writer commands (never hand-edited), waived with a reason naming an owner, a rationale, and an explicit release-impact statement; the ledger's four frontmatter counts are internally consistent (waived_count 2->3, total_count 10->11, open_count stays 0) and were recomputed by the writer."
    requirement: HYG-02
    verification:
      - kind: other
        ref: "python3 assertion over WINDOWS.md frontmatter: waived=3 total=11 open=0, exit 0"
        status: pass
      - kind: other
        ref: "python3 assertion over the embedded JSON block: every waived row has a non-empty reason -> 'waivers complete: 3'"
        status: pass
    human_judgment: false
  - id: D4
    description: "The annotation-sweep exclusion is keyed on disposition (advisory,parked) rather than subject (advisory,ratchet), and the job display-name '[parked]' marker driving that exclusion lands in the SAME commit as the WINDOWS.md waiver."
    requirement: HYG-02
    verification:
      - kind: other
        ref: "grep -n ANNOTATION_SWEEP_EXCLUDE .github/workflows/ci.yml -> 'ANNOTATION_SWEEP_EXCLUDE: advisory,parked'"
        status: pass
      - kind: other
        ref: "git show --stat HEAD -- .planning/WINDOWS.md .github/workflows/ci.yml -> both files listed in one commit (81e2c827)"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-16
status: complete
---

# Phase 232 Plan 06: Ratchet lane machinery/parked split with honest status and expiring waiver Summary

**Split the bundled Admin UI ratchet CI job into a blocking `admin-ui-ratchet-selftests` job (no continue-on-error anywhere) and a non-blocking parked job, replaced its unreachable nine-row hardcoded PASS summary with an always-run step reading real ledger fields, added a blockingly-failing expiry trigger, and recorded the parked state as one waived ship-window row keyed by disposition rather than subject.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-16 (session continuation from 232-05)
- **Completed:** 2026-09-16T21:14:08Z
- **Tasks:** 3/3 completed
- **Files modified:** 3

## Accomplishments

- Measured live, not assumed: `ratchet:ledger:self-test`, `ratchet:signoff:self-test`, and `ratchet:ci-contract` all exit 0 today; `ratchet:ledger:verify-frozen` and `ratchet:signoff` (require-accept) both exit 1 today because `ledger.baseline.json` is deliberately `frozen:false`. The three-vs-two split matched 232-PATTERNS.md's assumption exactly, but was re-derived per D-15's no-transcription rule before being trusted.
- Created `admin-ui-ratchet-selftests`: a new job carrying only the genuinely-passing machinery checks, with **no `continue-on-error` at job or step level** -- a real regression in this machinery now blocks CI. `admin-ui-ratchet-guardrails` keeps its job-level `continue-on-error: true` and carries only the two steps that fail because the ledger is deliberately unfrozen.
- `annotation-sweep`'s `needs` list and its command-line job selector both gained `admin-ui-ratchet-selftests` in the same commit as the split, so the new blocking job's annotations are actually swept.
- Deleted the unreachable, unconditional nine-row hardcoded `"PASS - ..."` status-summary step (dead-branch-that-lies pattern per D-24) and replaced it with an `if: always()` step that reads `schema_version`, `frozen`, `epoch`, `ledger_sha256`, `resolved_locked` length, and the per-lens `confirmed_open` counts directly from `ledger.baseline.json` at run time. Zero occurrences of the literal `PASS - ` string remain anywhere in `ci.yml`.
- Added `Parked-lane expiry trigger (D-26)`, placed in the **blocking** `admin-ui-ratchet-selftests` job rather than the parked job -- GitHub Actions' job-level `continue-on-error` absorbs the whole job's conclusion regardless of any step's own setting, so a step meant to fail blockingly cannot live in a job whose failures are structurally absorbed. This is the plan's own documented fallback, exercised because the runner genuinely offers no per-step override for a job-level flag. It fails non-zero when `ledger.baseline.json.frozen` is `true` while ship-window row 11 still exists `waived` in `.planning/WINDOWS.md`.
- Negative controls (run manually, not committed as fixtures): the exact expiry-check logic against a synthetic `{frozen:true}` ledger plus a synthetic waived-row-11 `WINDOWS.md` fixture exits 1; against the real `ledger.baseline.json` (`frozen:false`) and the real `.planning/WINDOWS.md` (row 11 now waived, post-Task-3) exits 0.
- Minted **ship-window row 11** in `.planning/WINDOWS.md` via `gsd-tools windows append`/`waive` (never hand-edited): `kind: unmet-truth`, `phase: 232`, description states the lane is failing on the merits (not un-run, not advisory by design). Waived with a reason naming an **owner** (Accrue maintainer), a **rationale** (v1.56 parked, machinery proven green, only the deliberately-unfrozen steps stay parked), and an explicit **release-impact** statement (none -- does not gate v1.62; un-parking scheduled for v1.57 M3; the expiry trigger prevents silent staleness). The writer recomputed all four frontmatter counts: `waived_count` 2->3, `total_count` 10->11, `open_count` stays 0.
- In the **same commit** as the WINDOWS.md waiver: the job's display name gained the literal `[parked]` marker, and `ANNOTATION_SWEEP_EXCLUDE` flipped from `advisory,ratchet` (subject-keyed) to `advisory,parked` (disposition-keyed). The sweep matches normalized job display-name fragments, so splitting the name change from the exclusion-key change would have left a window in which the parked lane's annotations either fail the sweep or a real failure is silently excluded.
- No ratchet finding was closed, re-frozen, or otherwise resolved.

## Task Commits

Each task was committed atomically:

1. **Task 1: Split the bundled ratchet job into a blocking self-test job and a non-blocking parked job** - `0ae81240` (feat)
2. **Task 2: Replace the fabricated status table with a real one, and make the removal comment executable** - `0066726a` (feat)
3. **Task 3: Record the parked ratchet as one waived row in the existing ship-window ledger** - `81e2c827` (feat)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP update)

## Files Created/Modified

- `.github/workflows/ci.yml` - split ratchet job, real status summary, expiry trigger, disposition-keyed sweep exclusion
- `.planning/WINDOWS.md` - new waived ship-window row 11 (parked ratchet lane)
- `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` - meta-contract updated to assert the new two-job shape (not in the plan's declared `files_modified`; see Deviations)

## Decisions Made

See `key-decisions` in frontmatter for full rationale on: re-deriving (not trusting) the machinery-vs-parked split; placing the D-26 expiry trigger in the blocking job per the plan's own fallback; sequencing the interdependent ci.yml edits across three commits to honor the D-25 same-commit constraint; and using `unmet-truth` as the ship-window row's kind.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` required updating at every task, not just declared files_modified**
- **Found during:** Task 1, running the plan's own `<verify>` command `cd accrue_admin && npm run ratchet:ci-contract`
- **Issue:** This meta-contract script is invoked by the new blocking job's own "Phase 208 CI contract" step and hardcodes assertions against the pre-split single-job shape (all five steps inside `admin-ui-ratchet-guardrails`, the nine literal `PASS - ` strings, the unbracketed job name, `ANNOTATION_SWEEP_EXCLUDE: advisory,ratchet`). Splitting the job, replacing the summary, and re-keying the exclusion each independently broke one or more of its hardcoded assertions -- unavoidable, since the script's whole purpose is to assert the job's exact shape.
- **Fix:** Updated the script's job-body extraction and assertions to match the new two-job shape at each commit: Task 1 added `admin-ui-ratchet-selftests` assertions and split the old single-job needle list; Task 2 replaced the hardcoded-PASS-line assertions with `if: always()` / real-field assertions for both the status summary and the new expiry-trigger step; Task 3 updated the job-name and `ANNOTATION_SWEEP_EXCLUDE` literal-value assertions.
- **Files modified:** `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` (all three commits).
- **Verification:** `cd accrue_admin && npm run ratchet:ci-contract` exits 0 after every commit.
- **Committed in:** `0ae81240`, `0066726a`, `81e2c827` (incremental, one hunk per commit matching the corresponding task).

---

**Total deviations:** 1 auto-fixed (Rule 3 -- a genuine blocking dependency the split necessarily broke, not scope creep; the file is the exact contract this plan's own `<verify>` commands invoke).
**Impact on plan:** Necessary for every task's own `<verify>` command to pass. No behavior change beyond what the plan itself mandates for the ratchet job's shape.

## Issues Encountered

`node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` (the prior-wave sibling-plan contract named in this plan's `<prior_wave_constraints>`) fails today: `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/collect_gate01_cohort.mjs`, `scripts/ci/collect_window_dispositions.mjs`, and `scripts/ci/verify_ci_baseline.mjs` are vacuous or fail under `node --test`. Confirmed **pre-existing and out of scope**: `git diff 6cbe6284 HEAD --stat` shows only `.github/workflows/ci.yml`, `.planning/WINDOWS.md`, and `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` changed by this plan -- none of the four failing files were touched. This matches 232-CONTEXT.md D-34's own description of the `ci_baseline` triad as "a dated landmine... not yet wired into ci.yml, and two of its three files fail `node --test`" -- pre-existing debt this plan does not own or introduce. Per the deviation rules' scope boundary, not auto-fixed; left for whichever plan owns that triad.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ratchet machinery regressions now block CI; the deliberately-parked subject does not. Nothing in the ratchet job's CI output prints an outcome it did not measure. The parked state expires by failing (not by someone remembering to delete a comment), is recorded once in the existing ship-window ledger with a complete owner/rationale/release-impact waiver, and the sweep exclusion that hides its annotations is keyed on disposition rather than subject. Plan 232-10's row-join against `.planning/WINDOWS.md` can now find row 11 with a complete reason. No blockers for later plans in this phase.

## Self-Check: PASSED

- FOUND: `0ae81240`, `0066726a`, `81e2c827` (all three task commits) in `git log --oneline`
- FOUND: `.github/workflows/ci.yml`, `.planning/WINDOWS.md`, `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` all present and modified as described (confirmed via `git show --stat` on each commit)
- Re-ran all plan-level `<verification>` commands: parsed workflow shows `admin-ui-ratchet-selftests` carries no non-blocking flag at job or step level (PASS); `grep -c 'PASS - ' .github/workflows/ci.yml` -> 0; expiry trigger exits 1 against a synthetic frozen ledger and 0 against the real one (both re-confirmed live); `.planning/WINDOWS.md` reports `open=0`, `waived=3`, `total=11` with one new complete waived row; `git show --stat 81e2c827 -- .planning/WINDOWS.md .github/workflows/ci.yml` lists both files in one commit
- `cd accrue_admin && npm run ratchet:ci-contract` -> `verify_admin_ui_ratchet_ci_contract: ok` (confirmed live, final state)

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-16*
