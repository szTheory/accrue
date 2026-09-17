---
phase: quick-260916-gda
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/STATE.md
  - .planning/REQUIREMENTS.md
  - .planning/phases/229-repository-truth-recovery-safety/229-UAT.md
  - scripts/ci/collect_window_dispositions.mjs
  - scripts/ci/verify_window_dispositions.mjs
  - scripts/ci/verify_recut_candidate.mjs
  - scripts/ci/phase229_gap_closure.test.mjs
autonomous: true
requirements: [QT-260916-GDA]

estimate:
  tokens: 70000
  raw_tokens: 70000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "`bash scripts/ci/verify_roadmap_hygiene.sh` exits 0 at HEAD (it exits 1 today)."
    - "`bash scripts/ci/verify_v1_17_friction_research_contract.sh` exits 0 at HEAD (it exits 1 today)."
    - "`node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` exits 0 without `--write`."
    - "`node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs` reports `# fail 0` (it reports `# fail 2` today)."
    - "A window-disposition row with `disposition: \"fixed\"` and `state` other than `proved` is rejected by BOTH the collector's row validation and the verifier's strict checks."
    - "`verify_recut_candidate.mjs` exits non-zero when `--expected-repository` names a repository the working tree is not, and still exits 0 for `szTheory/accrue`."
    - "GATE-01/GATE-02 in `.planning/REQUIREMENTS.md` describe proving honest per-lane gate status, not a green/passing aggregate."
  artifacts:
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
    - .planning/phases/229-repository-truth-recovery-safety/229-UAT.md
    - scripts/ci/collect_window_dispositions.mjs
    - scripts/ci/verify_window_dispositions.mjs
    - scripts/ci/verify_recut_candidate.mjs
    - scripts/ci/phase229_gap_closure.test.mjs
  key_links:
    - "scripts/ci/verify_roadmap_hygiene.sh pause_rule needle -> .planning/STATE.md `## Post-v1.48 Pause Rule`"
    - "scripts/ci/verify_roadmap_hygiene.sh `## Deferred Items`/HOST-01..03/READY-01..02 needles -> .planning/STATE.md `## Deferred Items`"
    - "scripts/ci/verify_v1_17_friction_research_contract.sh inventory + north-star needles -> .planning/STATE.md `### Historical Research Assets`"
    - "collect_window_dispositions.mjs validateWindowRow -> verify_window_dispositions.mjs applyStrictFlags (independent re-check)"
    - "verify_recut_candidate.mjs main() --expected-repository -> live `git -C <repo> remote get-url origin` identity"
---

<objective>
Close six independently-verified Phase 231 loose ends: three planning-doc contract restorations and three CI-script hardening fixes.

Purpose: two merge-blocking CI contracts (`verify_roadmap_hygiene.sh`, `verify_v1_17_friction_research_contract.sh`) fail at HEAD because a milestone regen skeletonized `.planning/STATE.md`; the Phase-229 gap-closure suite has a 2-test reporter-format bug; `229-UAT.md` is stale; and the Phase 231 code review found one CRITICAL schema hole (CR-01) plus one vacuous required flag (WR-01) in the new release-gate verifiers.

Output: restored STATE.md standing sections, regenerated 229-UAT.md, reworded GATE-01/GATE-02 requirement text, a TAP-emitting isolated-test helper, and two hardened verifiers each carrying a negative test.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/REQUIREMENTS.md
@.planning/phases/231-exact-sha-release-gate-proof/231-REVIEW.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Restore STATE.md standing sections, regenerate 229-UAT.md, reword GATE-01/GATE-02</name>
  <files>.planning/STATE.md, .planning/phases/229-repository-truth-recovery-safety/229-UAT.md, .planning/REQUIREMENTS.md</files>
  <precondition>Working tree is on branch `gsd/milestone-v1.62-release-integration-hygiene`; commit `f7889d99` is reachable (`git cat-file -e f7889d99:.planning/STATE.md`).</precondition>
  <action>
Confirm the red first: run `bash scripts/ci/verify_roadmap_hygiene.sh` and `bash scripts/ci/verify_v1_17_friction_research_contract.sh` and record that both exit 1.

Read both verifier scripts in full before editing so the restore is driven by their actual needles, not by guesswork. `verify_roadmap_hygiene.sh` requires THREE things of `.planning/STATE.md` that are all missing today, not just the one the script reports first (it stops at the first failure): the verbatim `pause_rule` sentence (line 36 of the script), the literal heading `## Deferred Items`, and the literals `HOST-01..03` and `READY-01..02`. It also forbids the regexes `feature freeze|maintenance only` and `dormant seed alone (creates|opens)|deferred idea alone (creates|opens)` anywhere in STATE.md — do not introduce either. `verify_v1_17_friction_research_contract.sh` requires STATE.md to contain the literals `.planning/research/v1.17-FRICTION-INVENTORY.md` AND `v1.17-north-star.md`.

Recover the authoritative text with `git show f7889d99:.planning/STATE.md`. Restore the full standing sections verbatim, not the minimum needles:
- The `## Deferred Items` table and the `## Post-v1.48 Pause Rule` section (a contiguous block around lines 45-57 there, including the v1.55/v1.58/v1.59 paragraphs that follow the pause-rule sentence).
- The `### Historical Research Assets` bullet list (around lines 548-552 there), whose first two bullets name the friction inventory and the north star.

Place them where they structurally belong in today's STATE.md, whose headings are: Project Reference, Current Position, Performance Metrics, Accumulated Context (Decisions / Pending Todos / Deferred-Dormant / Blockers-Concerns / Quick Tasks Completed), Session Continuity. Put `## Deferred Items` + `## Post-v1.48 Pause Rule` as top-level sections after `## Accumulated Context`'s subsections and before `## Session Continuity`; put `### Historical Research Assets` as a subsection immediately after them. Do not delete, reword, or reorder any existing STATE.md content, and do not touch the YAML front matter.

Then regenerate the stale UAT artifact using the script's own writer — `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229 --write`. Do NOT hand-edit `229-UAT.md`. Re-run without `--write` afterwards and confirm a clean exit; inspect `git diff` on the artifact so the regeneration is understood rather than blindly accepted.

Finally reword only the GATE-01 and GATE-02 checklist lines in `.planning/REQUIREMENTS.md` (lines 22-23). Today they read as if the gates pass ("passes the repository's complete local CI-equivalent gates", "checks for the exact candidate SHA are green"). Phase 231's locked decision D-29 was: no aggregate boolean, reject fabricated proved states, and a green Actions conclusion is not provider proof — the deliverable was honest, re-verifiable, per-lane proof of the real state, which for GATE-02 included a genuine recorded failure. Reword both so they describe producing honest per-lane gate status with recorded argv/exit-code evidence at the exact candidate SHA, under the closed proved/failed/skipped/advisory/non_run lexicon. Wording only: keep the `**GATE-01**:`/`**GATE-02**:` IDs, keep the `- [x]` marks, and leave the `| GATE-01 | Phase 231 | Complete |` coverage-table rows (lines 71-72) and every other requirement untouched. Note `scripts/ci/verify_stable_core_posture.sh` greps this file for the literal `POS-03` only, so the reword is safe — re-run it to prove that.
  </action>
  <verify>
    <automated>bash scripts/ci/verify_roadmap_hygiene.sh && bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_stable_core_posture.sh && node scripts/ci/verify_executable_uat_contract.mjs --self-test && node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in && node scripts/ci/verify_executable_uat_contract.mjs --all-since 229</automated>
  </verify>
  <done>All six commands above exit 0 (the first two exit 1 before this task). `git diff .planning/REQUIREMENTS.md` touches only the GATE-01 and GATE-02 checklist lines. `git diff .planning/STATE.md` is additive only — no existing line removed or reordered.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Enforce the CR-01 invariant — disposition "fixed" requires state "proved"</name>
  <files>scripts/ci/collect_window_dispositions.mjs, scripts/ci/verify_window_dispositions.mjs</files>
  <behavior>
    - A row `{ disposition: "fixed", state: "failed", ... }` is rejected by `validateWindowRow` with a message naming both the disposition and the observed state.
    - The same row is rejected by the verifier's strict layer (independently of collection-time validation, matching the existing `assertWaiverCompleteness` discipline), including when hand-authored and never passed through the collector.
    - `state` values `skipped`, `advisory`, and `non_run` paired with `disposition: "fixed"` are rejected the same way.
    - A `{ disposition: "fixed", state: "proved", exit_code: 0 }` row still passes both layers unchanged.
    - A `{ disposition: "waived", state: "failed" }` row with complete owner/rationale/release_impact still passes both layers unchanged.
  </behavior>
  <action>
Read `scripts/ci/collect_window_dispositions.mjs` (`validateWindowRow`, roughly lines 54-95) and `scripts/ci/verify_window_dispositions.mjs` (`applyStrictFlags` around line 121, the `assertRowJoin`/`assertEvidenceFreshness`/`assertWaiverCompleteness` cluster around lines 45-82, and `verifyFixtures` around line 134) before editing.

Add the missing cross-field invariant at BOTH layers, per CR-01 in `.planning/phases/231-exact-sha-release-gate-proof/231-REVIEW.md`:

1. In `validateWindowRow`, next to the existing `disposition === "waived"` completeness block, reject any row whose `disposition` is `fixed` while `state` is anything other than `proved`. The failure message must name the label, the disposition, and the actual state.
2. In `verify_window_dispositions.mjs`, add a sibling strict assertion (e.g. a `assertFixedRowsProved` helper) invoked from the same place `assertWaiverCompleteness` is invoked in `applyStrictFlags`, so a hand-edited committed record that never went through the collector is still caught. Reuse the existing `fail` helper and the established comment style citing D-22/GATE-03.

Write the negative controls FIRST, before the production edits, so you see them fail. Both files already carry their own self-tests: the collector registers `node:test` cases under `NODE_TEST_CONTEXT` (bottom of the file, around line 224) and the verifier's `verifyFixtures()` is a numbered sequence of assertions ending at case 13. Extend each in place following the surrounding numbering and style — add the fabricated `fixed`-but-not-`proved` rejection plus the still-passing `fixed`/`proved` and `waived`/`failed` controls.

This is a schema floor for FUTURE rows: the committed `231-WINDOW-DISPOSITIONS.json` is already internally consistent (every `fixed` row has `state: proved`). Do NOT change any committed disposition data, any row's `disposition` or `state` value, `.planning/WINDOWS.md`, or the rendered `231-WINDOW-DISPOSITIONS.md`. The real-artifact verification in the verify block must pass with the JSON exactly as committed; if it does not, the new invariant is wrong, not the data.
  </action>
  <verify>
    <automated>node --test scripts/ci/collect_window_dispositions.mjs && node --test scripts/ci/verify_window_dispositions.mjs && node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism && node scripts/ci/verify_window_dispositions.mjs --repo . --records .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json --rendered .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism</automated>
  </verify>
  <done>All four commands exit 0. A negative test exists in the collector's `node:test` block AND in the verifier's `verifyFixtures()` proving a fabricated `disposition: "fixed"` / `state: "failed"` row is rejected by that layer. `git diff` shows zero changes to `231-WINDOW-DISPOSITIONS.json`, `231-WINDOW-DISPOSITIONS.md`, and `.planning/WINDOWS.md`.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Fix the isolated-test TAP reporter and make --expected-repository non-vacuous</name>
  <files>scripts/ci/phase229_gap_closure.test.mjs, scripts/ci/verify_recut_candidate.mjs</files>
  <behavior>
    - The two `runIsolatedNodeTest` callers see `ok 1 - ...` TAP lines from the spawned child and their existing assertions pass unchanged.
    - `verify_recut_candidate.mjs --repo . --expected-repository szTheory/accrue ...` still exits 0 against the real repository.
    - `verify_recut_candidate.mjs --repo . --expected-repository someone-else/not-accrue ...` exits non-zero with a message naming the observed and expected repository.
    - `--fixtures` behavior is unchanged (it returns before the identity check, as CI invokes it that way).
  </behavior>
  <action>
Part A (item 2 — TAP harness). `runIsolatedNodeTest` at `scripts/ci/phase229_gap_closure.test.mjs:171` spawns `node --test --test-name-pattern=... <file>`. Node 22+ defaults to the `spec` reporter, so the child emits `✔ name (1.2ms)` while its only two callers (around lines 758-772) assert `/ok 1 - .../` TAP output; both currently fail with ERR_ASSERTION. Add `--test-reporter=tap` to the spawned child argv so the child emits TAP. Keep both assertions exactly as written — their intent is correct. Those two callers (confirmed by `grep -n runIsolatedNodeTest`) are the only users of the helper, so no spec-format consumer regresses; re-run that grep to reconfirm before editing.

Part B (item 5 — WR-01). `main()` in `scripts/ci/verify_recut_candidate.mjs` (around lines 537-548) requires `--expected-repository` but never reads the value again — a decorative required argument implying a safety property it does not provide. Its three siblings all do real work with the same flag; read `scripts/ci/verify_ci_baseline.mjs`'s `createRepositoryValidationContext` usage (or `verify_window_dispositions.mjs:278`, the simplest form) and match the established failure-message style.

`RECUT_RECORD_FIELDS` has no `repository` field, so there is nothing in the record to compare against; do not add one (that would change the committed `231-ROLLBACK-POINT.json` schema). Instead assert the flag against observed live repository identity: derive `owner/name` from `git -C <repo> remote get-url origin` (today `https://github.com/szTheory/accrue.git`), normalizing both the `https://github.com/OWNER/NAME.git` and `git@github.com:OWNER/NAME.git` forms and stripping a trailing `.git`, then fail if it differs from `--expected-repository`. Handle a missing/unresolvable origin as an explicit failure naming the repo path, never a silent pass. Place the check in `main()` after the `--fixtures` early return and after `repo` is resolved, so the CI step `node scripts/ci/verify_recut_candidate.mjs --fixtures --expected-repository szTheory/accrue` (`.github/workflows/ci.yml:212`) is unaffected.

Add the negative control to `verifyFixtures()` in the same file (around line 280): its `fixtureRepo()` helper builds a scratch git repo — give it a known origin URL via `git remote add origin`, then assert the identity check rejects a mismatched expected value and accepts the matching one. Write that negative test before the production change so you observe it fail first.
  </action>
  <verify>
    <automated>node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs && node --test scripts/ci/verify_recut_candidate.mjs && node scripts/ci/verify_recut_candidate.mjs --fixtures --expected-repository szTheory/accrue && node scripts/ci/verify_recut_candidate.mjs --repo . --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain && ! node scripts/ci/verify_recut_candidate.mjs --repo . --expected-repository someone-else/not-accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain</automated>
  </verify>
  <done>The gap-closure suite reports `# fail 0` (it reports `# fail 2` before this task; the run takes roughly 90 seconds). The recut verifier exits 0 for `szTheory/accrue` and non-zero for a mismatched repository, and a negative control proving the mismatch rejection exists inside `verifyFixtures()`.</done>
</task>

</tasks>

<verification>
Run the full set from the repository root on branch `gsd/milestone-v1.62-release-integration-hygiene`:

1. `bash scripts/ci/verify_roadmap_hygiene.sh`
2. `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
3. `bash scripts/ci/verify_stable_core_posture.sh`
4. `node scripts/ci/verify_executable_uat_contract.mjs --self-test`
5. `node scripts/ci/verify_executable_uat_contract.mjs --all-opted-in`
6. `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229`
7. `node --test scripts/ci/collect_window_dispositions.mjs`
8. `node --test scripts/ci/verify_window_dispositions.mjs`
9. `node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`
10. `node --test --test-reporter=tap scripts/ci/phase229_gap_closure.test.mjs` → `# fail 0`
11. `node --test scripts/ci/verify_recut_candidate.mjs`
12. `node scripts/ci/verify_recut_candidate.mjs --repo . --expected-repository szTheory/accrue --require-shape --require-ancestry --require-revert-proof --require-toolchain`

Out of scope, do not attempt: the `Admin UI ratchet guardrails` CI job, the `Annotation sweep` CI job, re-cutting the integration candidate SHA, opening any PR, and anything touching `main`, tags, or remote refs.
</verification>

<success_criteria>
- Two previously-red merge-blocking planning-doc contracts are green, restored verbatim from `f7889d99` rather than minimally patched to the needle.
- `229-UAT.md` matches executable SUMMARY coverage and was regenerated by the script, not hand-edited.
- GATE-01/GATE-02 describe honest per-lane proof (D-29) with no requirement IDs, completion marks, or coverage rows changed.
- The Phase-229 gap-closure suite is `# fail 0`.
- CR-01 and WR-01 are each closed at both the schema and verifier layer, each with a negative test proving a bad input is rejected, and with zero changes to committed evidence data.
</success_criteria>

<output>
Create `.planning/quick/260916-gda-close-phase-231-loose-ends-state-md-stan/260916-gda-SUMMARY.md` when done.
</output>
