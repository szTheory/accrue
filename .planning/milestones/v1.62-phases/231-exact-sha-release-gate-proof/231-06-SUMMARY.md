---
phase: 231-exact-sha-release-gate-proof
plan: 06
subsystem: infra
tags: [ci-evidence, ci-wiring, release-gate, repository-inventory, contributor-docs]

requires:
  - phase: 231-exact-sha-release-gate-proof
    provides: "plan 231-01's verify_recut_candidate.mjs; plan 231-02's window-dispositions triad; plan 231-03's collect/render/verify_gate01_cohort.mjs and 231-GATE-01-EVIDENCE; plan 231-04's collect_ci_baseline.mjs required-job-set-drift extension and 231-GATE-02-EVIDENCE; plan 231-05's WINDOWS.md open_count: 0 and 231-WINDOW-DISPOSITIONS"
provides:
  - "Three new merge-blocking .github/workflows/ci.yml steps inside docs-contracts-shift-left: recut-candidate shape/ancestry, GATE-01 cohort triad, window-dispositions triad -- each running its unit suite then its --fixtures self-test, with the required-job-set drift triple still empty"
  - "scripts/ci/README.md `## Phase 231 exact-SHA release gate proof` section: one evidence-table row per artifact (ROLLBACK-POINT, GATE-01, GATE-02, WINDOW-DISPOSITIONS), each command re-run against the real committed artifacts before being written; two splice-marker notes (phase231-window-dispositions, phase231-gate01-cohort)"
  - ".planning/phases/231-exact-sha-release-gate-proof/231-REPOSITORY-INVENTORY.json -- a fresh Phase 231 repository-inventory capsule minted last, after all window-status edits and this plan's own STATE.md/ROADMAP.md/REQUIREMENTS.md updates settled, via a real (non-fixture) run of preserve_repository_state.sh + collect_repository_inventory.mjs against the live repository"
affects: [232-bounded-hygiene-release-handoff]

actuals:
  tokens: 34000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "The one-capsule-per-phase mint (D-28) is ordered strictly after this plan's own STATE.md/ROADMAP.md/REQUIREMENTS.md updates land, not merely after prior plans' -- the recovery manifest is frozen first via preserve_repository_state.sh, then state.advance-plan/roadmap/requirements settle the two untracked workflow-metadata paths (.planning/milestone.lock, .planning/state.json), then the final-capture attestation is built from the resulting drift, and only then does collect_repository_inventory.mjs run for real."
    - "collect_repository_inventory.mjs's --artifact-authorization/--final-capture-attestation schema literals are spelled 'phase229_workflow_metadata_refresh'/'phase229_final_capture' in code regardless of which phase is minting -- these are the module's own closed-vocabulary constants, not phase-specific naming, and are used verbatim for the Phase 231 mint exactly as Phase 229's own fixture suite does."

key-files:
  created:
    - .planning/phases/231-exact-sha-release-gate-proof/231-REPOSITORY-INVENTORY.json
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/README.md
    - scripts/ci/collect_repository_inventory.mjs

key-decisions:
  - "Task 3's recovery manifest/bundle were minted via a real (non-self-test) invocation of scripts/ci/preserve_repository_state.sh with --preservation-phase 231, freezing all 119 non-preservation refs into a new refs/accrue-preserve/phase-231/* namespace -- not reused from Phase 229's or Phase 230's own manifests, which stay untouched (D-28's 'do not touch or re-diff the frozen 229/230 capsules')."
  - "The final-capture attestation and workflow-metadata authorization were hand-built (no dedicated CLI helper exists outside the Phase-229-specific --run-final-chain wrapper, which is hard-pinned to 229's own canonical output path and could not be reused for a 231 artifact) rather than skipped -- collect_repository_inventory.mjs requires both inputs unconditionally, and skipping them was not an option."
  - "collect_repository_inventory.mjs was run WITHOUT --observe-remote: `mode: local_only` is a legitimate, schema-valid inventory mode, and omitting it avoids a live GitHub API dependency in a mint that this plan's own <verify> block never binds against `--records`/`--rendered` anyway (D-27: strict verification of a published capsule stays out of routine CI)."
  - "No .md sibling was rendered for 231-REPOSITORY-INVENTORY.json -- the plan's frontmatter `files_modified` and Task 3's own acceptance criteria name only the .json, and rendering an unplanned second artifact was judged out of scope rather than an automatic Rule 2 addition."

requirements-completed: [GATE-01, GATE-02, GATE-03]

coverage:
  - id: D1
    description: "Three new ci.yml steps make the Phase 231 verifier suites merge-blocking inside docs-contracts-shift-left, with no dependency on any local-only ref and no drift in the declared required-job-set"
    requirement: GATE-01
    verification:
      - kind: other
        ref: "node -e checks: all three step titles present, no non-comment line references integration/v1.62-candidate or review/v1.62-candidate-code-only, required-job-set drift triple empty"
        status: pass
      - kind: unit
        ref: "node --test scripts/ci/verify_recut_candidate.mjs scripts/ci/collect_gate01_cohort.mjs scripts/ci/render_gate01_cohort.mjs scripts/ci/verify_gate01_cohort.mjs scripts/ci/collect_window_dispositions.mjs scripts/ci/render_window_dispositions.mjs scripts/ci/verify_window_dispositions.mjs (54/54 pass)"
        status: pass
    human_judgment: false
  - id: D2
    description: "scripts/ci/README.md carries a Phase 231 evidence-table row per artifact, each with a verify command re-run against the real committed files before being written, plus both splice-marker notes"
    requirement: GATE-02
    verification:
      - kind: other
        ref: "node -e README needle/absolute-path checks; node -e README-referenced-artifact-existence check; each of the four real verify commands (verify_recut_candidate.mjs, verify_gate01_cohort.mjs, verify_ci_baseline.mjs, verify_window_dispositions.mjs) re-run against the real committed 231-* artifacts, all exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "A fresh 231-REPOSITORY-INVENTORY.json capsule is minted last -- after all window-status edits (plan 231-05) and this plan's own STATE.md/ROADMAP.md/REQUIREMENTS.md settle -- with its bundle mode 600, the frozen 229/230 capsules byte-unchanged, and no absolute path or home-directory reference in the record"
    requirement: GATE-03
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_repository_inventory.mjs scripts/ci/verify_repository_inventory.mjs"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-edge-cases --require-all-ref-recovery --require-typed-artifacts --require-privacy-controls --require-determinism --require-command-provenance"
        status: pass
      - kind: other
        ref: "test -f 231-REPOSITORY-INVENTORY.json; explicit-range git diff --quiet against the frozen 229/230 artifacts; grep -nE for absolute/home paths (exit 1, no match); git worktree list row count unchanged"
        status: pass
    human_judgment: false

duration: ~100min
completed: 2026-09-16
status: complete
---

# Phase 231 Plan 6: Exact-SHA Release Gate Proof — CI Wiring, README, and Final Capsule Summary

Wired all three Phase 231 verifier triads permanently merge-blocking into `docs-contracts-shift-left`, documented every Phase 231 evidence artifact in `scripts/ci/README.md` with re-run-verified commands, and minted the phase's `231-REPOSITORY-INVENTORY.json` capsule last — via a real `preserve_repository_state.sh` freeze of 119 refs and a hand-built final-capture attestation proving only `.planning/milestone.lock`/`.planning/state.json` moved between freeze and collection — closing Phase 231 with GATE-01, GATE-02, and GATE-03 all complete.

## Performance

- **Duration:** ~100 min
- **Tasks:** 3
- **Files created:** 1
- **Files modified:** 3

## Accomplishments

- Added three steps to `.github/workflows/ci.yml`'s `docs-contracts-shift-left` job — `Recut candidate shape and ancestry contract (D-01, D-04, D-07)`, `GATE-01 cohort triad units and fixture contract (D-09, D-10, D-18)`, `Window dispositions triad units and fixture contract (D-22, D-26, D-30, D-31)` — each running `node --test` for its module(s) then its `--fixtures` self-test, preceded by a comment explaining why they deliberately avoid depending on `integration/v1.62-candidate` or `review/v1.62-candidate-code-only`. Confirmed the required-job-set drift triple (`missing=[]`, `extra=[]`) is unchanged and the header merge-blocking declaration / `annotation-sweep`'s `needs:` array are untouched (28 lines added, nothing removed).
- Added a `## Phase 231 exact-SHA release gate proof` section to `scripts/ci/README.md`, cloning the Phase 230 three-part shape: a prose paragraph stating the re-cut cause and that GATE-02 is `workflow_dispatch`-class (distinct from Phase 232's `pull_request`-class proof), an evidence table with one row per artifact and its exact reproducing command, and both `phase231-window-dispositions`/`phase231-gate01-cohort` splice-marker notes. All four table commands were executed against the real committed artifacts before being written into the doc — all four passed.
- Minted `.planning/phases/231-exact-sha-release-gate-proof/231-REPOSITORY-INVENTORY.json`: ran `scripts/ci/preserve_repository_state.sh --preservation-phase 231` for real against the live repository (froze 119 non-preservation refs into `refs/accrue-preserve/phase-231/*`, bundle mode `0600`), then advanced this plan's own `state.advance-plan`/`state.update-progress`/`state.record-metric`/`state.add-decision`/`state.record-session`/`roadmap.update-plan-progress`/`requirements.mark-complete` so `.planning/milestone.lock` and `.planning/state.json` genuinely drifted, built a final-capture attestation + workflow-metadata authorization reflecting exactly that drift (and only that drift — the other three untracked artifacts, `.planning/v1.61-v1.61-MILESTONE-AUDIT.md` and the two `scripts/ci/*stripe_test_fixtures.mjs` files, unchanged), found and fixed a real phase-encoding bug in `collect_repository_inventory.mjs` (see Deviations), then ran `collect_repository_inventory.mjs` for real (`mode: local_only`, no `--observe-remote`) to produce the capsule.

## Task Commits

1. **Task 1: Wire the Phase 231 verifiers into docs-contracts-shift-left** — `27a27b08` (feat)
2. **Task 2: Add scripts/ci/README.md evidence rows for every Phase 231 artifact** — `57a0c5f5` (docs)
3. **Task 3: Mint 231-REPOSITORY-INVENTORY.json last** — see commit hash in the git log for this plan (feat)

**Plan metadata:** this commit (SUMMARY + STATE + ROADMAP + REQUIREMENTS).

## Files Created/Modified

- `.github/workflows/ci.yml` — three new merge-blocking steps in `docs-contracts-shift-left`.
- `scripts/ci/README.md` — new `## Phase 231 exact-SHA release gate proof` section.
- `scripts/ci/collect_repository_inventory.mjs` — `validateInventory` now accepts and forwards `preservationPhase` to `validateRecovery` (Rule 1 bug fix, see Deviations).
- `.planning/phases/231-exact-sha-release-gate-proof/231-REPOSITORY-INVENTORY.json` (mode `0600`) — fresh Phase 231 capsule, minted last.

## Decisions Made

- Minted a genuinely new `refs/accrue-preserve/phase-231/*` recovery manifest/bundle rather than reusing Phase 229's — the frozen 229/230 capsules stay untouched per D-28, and each phase's own capsule needs its own preservation namespace.
- Hand-built the final-capture attestation and workflow-metadata authorization JSON (no reusable CLI helper exists outside the Phase-229-pinned `--run-final-chain` wrapper) rather than attempting to force that wrapper onto a 231 output path it structurally refuses (`options.records !== CANONICAL_RECORDS` hard fail).
- Ran the collector without `--observe-remote` (`mode: local_only`) since this plan's own `<verify>` block never strictly binds the live capsule against a remote-observed record, and a network dependency in a one-shot mint added risk with no offsetting requirement.
- Skipped rendering a `.md` sibling for the capsule — out of this plan's declared `files_modified` and not required by any acceptance criterion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `validateInventory` never forwarded `preservationPhase` to `validateRecovery`, hard-defaulting every capsule's ref-encoding check to phase "229" regardless of which phase minted it**
- **Found during:** Task 3, first real (non-fixture) invocation of `collect_repository_inventory.mjs` against the freshly minted phase-231 manifest.
- **Issue:** `collectRepositoryInventory({ ..., preservationPhase: "231" })` correctly threaded `preservationPhase` into `readTrustedRecoveryManifest`'s own `validateRecovery` call, but its own closing call to `validateInventory(...)` (which independently re-validates `recovery.refs[].encoded_ref` via a second `validateRecovery` call) passed no phase argument at all, so that second check silently used `DEFAULT_PRESERVATION_PHASE = "229"`. Every `encoded_ref` in a genuinely phase-231-preserved manifest (`refs/accrue-preserve/phase-231/...`) therefore failed `recovery ref encoded_ref must preserve original name` against the phase-229 encoding it was actually compared to — a real, previously-untested bug that made the documented "one-capsule-per-phase" pattern (D-28) structurally impossible for any phase other than 229.
- **Fix:** `validateInventory(inventory, context, { preservationPhase = DEFAULT_PRESERVATION_PHASE } = {})` now accepts and forwards the phase; `collectRepositoryInventory`'s own call site passes `{ preservationPhase }` (the same value already threaded to `readTrustedRecoveryManifest`). Every other call site (existing Phase-229 tests, `verify_repository_inventory.mjs`) is unaffected — it omits the new third argument and gets the unchanged default of `"229"`.
- **Files modified:** `scripts/ci/collect_repository_inventory.mjs`.
- **Verification:** `node --test scripts/ci/collect_repository_inventory.mjs scripts/ci/verify_repository_inventory.mjs` — 15/15 pass, no regression; the real phase-231 mint then succeeded end-to-end.
- **Committed in:** Task 3's commit (see Task Commits above).

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug fix, scoped to the exact line the phase-parameterized mint needed). **Impact:** Necessary to make D-28's one-capsule-per-phase pattern usable for any phase after 229; zero behavior change for existing Phase-229 callers.

## Issues Encountered

None blocking.

## User Setup Required

None — no external service configuration required.

## Known Extra Refs (documented reason, not fixed here)

`231-REPOSITORY-INVENTORY.json`'s `refs.all` schema is a fixed `{name, object, role}` shape with no per-ref reason field (D-25's "do not widen a pinned schema" discipline applies equally here), so the reasons for its known "extra" refs relative to the frozen Phase 229/230 baselines are recorded here rather than inside the capsule itself:

- `refs/heads/fix/adopter-app-1.5.1` and `refs/remotes/origin/fix/adopter-app-1.5.1` — maintainer-authorized fail-forward carryovers from Phase 230 (embed a downstream adopter's product name, predate this work, already public; renaming would invalidate the frozen 229 manifest). See `.planning/STATE.md`'s "Adopter-named refs: fail forward" section.
- `refs/heads/integration/v1.62-candidate` and `refs/remotes/origin/integration/v1.62-candidate` — the re-cut candidate branch, pushed to `origin` under this phase's own Plan 04 maintainer authorization (D-14) for the GATE-02 `workflow_dispatch` proof.

## Next Phase Readiness

All three Phase 231 gates are proven and merge-blocking or documented: GATE-01 (local cohort proof), GATE-02 (real, honest `workflow_dispatch` GitHub proof — recorded FAILURE at the candidate SHA, per plan 231-04), GATE-03 (all ten `.planning/WINDOWS.md` rows fixed-or-waived, per plan 231-05). Phase 231's own verifiers are now permanently merge-blocking and documented for contributors. **Phase 232 cannot open the integration pull request or proceed to release action against `integration/v1.62-candidate` at `f524f2a6b16d3576829632ab6fa77d24b718e6f7` until the real GATE-02 regressions (`docs-contracts-shift-left`, the `release-gate` matrix, `phase18-tax-gate`, `admin-ui-ratchet-guardrails`) are fixed and a fresh dispatch proves green** — this is a release blocker recorded honestly by plan 231-04, not a blocker introduced by this plan. `roadmap update-plan-progress` for phase 231 is expected to fail with the known, pre-existing `missing_phase_details` `</details>`-placement defect in `ROADMAP.md` (already surfaced to the maintainer) — not fixed here, per explicit instruction.

## Self-Check: PASSED

- `.planning/phases/231-exact-sha-release-gate-proof/231-REPOSITORY-INVENTORY.json` exists on disk, mode `0600`.
- Commits `27a27b08`, `57a0c5f5`, and Task 3's commit found in `git log --oneline --all`.
- Re-ran the plan-level `<verification>` block: all three `ci.yml` step titles present with no local-only-ref non-comment reference; required-job-set drift triple empty; every module named in a new CI step passes its own `node --test` suite; every README-referenced Phase 231 artifact path exists on disk; the new capsule exists, its bundle is mode 600, and the frozen 229/230 predecessors are byte-unchanged.

---
*Phase: 231-exact-sha-release-gate-proof*
*Completed: 2026-09-16*
