---
phase: 231-exact-sha-release-gate-proof
plan: 04
subsystem: infra
tags: [ci-evidence, node, release-gate, github-actions, gh-cli]

requires:
  - phase: 231-exact-sha-release-gate-proof
    provides: "integration/v1.62-candidate re-cut to f524f2a6b16d3576829632ab6fa77d24b718e6f7 (Plan 01), 231-ROLLBACK-POINT.json"
provides:
  - "declaredRequiredJobSet/liveRequiredJobSet/requiredJobSetDrift in collect_ci_baseline.mjs — the required-check set is derived from the in-repo ci.yml declaration and cross-checked against the live annotation-sweep needs: array, never from branch protection or rulesets (both empty on this repository)"
  - "verify_ci_baseline.mjs --require-required-job-set / --require-event-class (+ --expect-event-class) / --require-exit-codes"
  - "integration/v1.62-candidate pushed to origin (szTheory/accrue) at f524f2a6b16d3576829632ab6fa77d24b718e6f7 — the one authorized, one-way publication"
  - ".planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.{ndjson,md} — honest workflow_dispatch-class GATE-02 proof recording a genuine CI FAILURE at the candidate SHA"
affects: [232-bounded-hygiene-release-handoff]

actuals:
  tokens: 21000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "liveRequiredJobSet derives the required-check set from the live job graph's terminal annotation-sweep gate's needs: array (+ itself), the same live-graph anchor Plan 03's collect_gate01_cohort.mjs uses for GATE-01 — never from branches/main/protection or rulesets, both of which are empty on this repository and would pass every completeness check vacuously (D-18)"
    - "render_ci_baseline.mjs extended with data-driven, backward-compatible notes gated on the actual record data (single-event-class run set; provider_state: skipped on workflow_dispatch) — both gates are empty arrays against Phase 226's mixed-cohort dataset, so its archived 226-CI-BASELINE.md still regenerates byte-identical"
    - "collect_ci_baseline.mjs's existing prerequisite-closure invariant (every job's needs: must be present as a job record in the same run) is a hard boundary GATE-02 respects rather than weakens: a job whose own prerequisites were skipped (annotation-sweep here) cannot be forced into a job record without first including its skipped prerequisites, which the module structurally forbids (skipped jobs are excluded from timing eligibility by design). The run-level `conclusion` field plus its immutable run_url is the correct place to surface that failure instead."

key-files:
  created:
    - .planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.ndjson
    - .planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.md
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - scripts/ci/render_ci_baseline.mjs

key-decisions:
  - "declaredRequiredJobSet re-exports Plan 03's declaredMergeBlockingJobs rather than writing a second ci.yml header parser (D-19); liveRequiredJobSet reuses Plan 03's annotationSweepNeeds the same way."
  - "provider_state: proved is rejected in normalizeRun whenever the run's conclusion is the unknown/no-data placeholder — this schema has no separate exit_code field for a run, so a genuinely recorded conclusion IS the recorded proof (D-21, D-29)."
  - "render_ci_baseline.mjs extended in place (undeclared in this plan's files_modified, added as a Rule 3 blocking-issue fix) because verify_ci_baseline.mjs's --rendered flag requires byte-for-byte reproducibility against renderBaseline(), so Task 3's acceptance criteria (event class in the first section, Phase 232 mention, live-stripe skip reason) could not be satisfied by hand-editing the .md file — it had to come out of the shared renderer, verified non-regressive against the archived Phase 226 artifact."
  - "GATE-02 is recorded honestly as a FAILURE, not forced to proved/success. The maintainer's Task 2 go authorized publishing and dispatching, not a particular outcome; the closed provider_state enum and D-20/D-29 explicitly require recording the real result, not absence-of-failure-as-success."

requirements-completed: [GATE-02]

coverage:
  - id: D1
    description: "Pushed integration/v1.62-candidate (and only that ref) to origin at the exact authorized SHA, dispatched ci.yml, polled to real completion via ci_monitor.cjs watch, and committed a workflow_dispatch-class GATE-02 evidence NDJSON + rendered Markdown that passes strict verification (required-job-set drift, event-class, exit-code/conclusion gates) and contains no absolute paths, home references, or secrets"
    requirement: GATE-02
    verification:
      - kind: other
        ref: "git ls-remote --heads origin integration/v1.62-candidate == f524f2a6b16d3576829632ab6fa77d24b718e6f7; origin/main and origin's tag list unchanged"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_ci_baseline.mjs --records .../231-GATE-02-EVIDENCE.ndjson --rendered .../231-GATE-02-EVIDENCE.md --expected-repository szTheory/accrue --expect-event-class workflow_dispatch --require-required-job-set --require-event-class --require-exit-codes"
        status: pass
      - kind: other
        ref: "grep -nE '/Users/|/home/|\\$HOME' 231-GATE-02-EVIDENCE.{ndjson,md} (exit 1 — no match)"
        status: pass
    human_judgment: false
  - id: D2
    description: "collect_ci_baseline.mjs extended with declaredRequiredJobSet/liveRequiredJobSet/requiredJobSetDrift and a provider_state: proved-requires-conclusion gate, via a full RED-GREEN TDD cycle, with no Phase 226 fixture regression"
    requirement: GATE-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_ci_baseline.mjs (16/16 pass)"
        status: pass
      - kind: other
        ref: "gsd_run check tdd-red-evidence — RED_EVIDENCE_OK (8 intentional failures) before GREEN"
        status: pass
      - kind: other
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository szTheory/accrue"
        status: pass
    human_judgment: false

duration: ~70min active work (excludes the checkpoint hold awaiting the maintainer's go/no-go)
completed: 2026-09-16
status: complete
---

# Phase 231 Plan 4: Exact-SHA Release Gate Proof — GATE-02 Summary

Extended `collect_ci_baseline.mjs`/`verify_ci_baseline.mjs` with a required-job-set drift check anchored to the in-repo `ci.yml` declaration (never branch protection/rulesets, both empty on this repository), pushed the re-cut candidate to `origin` under maintainer authorization, dispatched `ci.yml` against it, and committed an honest `workflow_dispatch`-class GATE-02 proof — which records a genuine CI **failure** at the candidate SHA, not a fabricated pass.

## Performance

- **Duration:** ~70 min active work across three tasks (Task 1 TDD extension, Task 2 checkpoint authorization, Task 3 push/dispatch/poll/evidence), excluding the real-time hold between Task 1's completion and the maintainer's go decision on Task 2.
- **Tasks:** 3/3 completed
- **Files modified:** 5 (3 scripts extended, 2 evidence artifacts created)

## Accomplishments

- `declaredRequiredJobSet`/`liveRequiredJobSet`/`requiredJobSetDrift` in `collect_ci_baseline.mjs`, re-exporting/reusing Plan 03's `declaredMergeBlockingJobs`/`annotationSweepNeeds` rather than duplicating a parser; verified zero drift against the live `.github/workflows/ci.yml`.
- `event_class`/`required_job_set_declared`/`required_job_set_observed` accepted as descriptive `RUN_INPUT_FIELDS`, and `normalizeRun` now rejects `provider_state: proved` with no recorded conclusion.
- `verify_ci_baseline.mjs` gained `--require-required-job-set`, `--require-event-class` (+ `--expect-event-class`), and `--require-exit-codes`, plus a fix decoupling `--fixtures` from the CLI's production `--expected-repository` (a pre-existing bug, unrelated to this plan's new work, that blocked Task 1's own literal verify command).
- Pushed exactly `integration/v1.62-candidate` at `f524f2a6b16d3576829632ab6fa77d24b718e6f7` to `origin` (`szTheory/accrue`) under the maintainer's Task 2 go-decision; `origin/main` and the tag list are unchanged, and no pull request was opened.
- Dispatched `gh workflow run ci.yml --ref integration/v1.62-candidate -f run_live_stripe=false` and polled to real completion (`ci_monitor.cjs watch`, exit 69 — genuine unsuccessful completion, not a deadline breach).
- Committed `231-GATE-02-EVIDENCE.ndjson`/`.md`: one `run` record (`event_class: workflow_dispatch`, `conclusion: failure`, `provider_state: skipped` with an explicit `run_live_stripe=false` reason in the rendered doc) plus 13 `job` records for every job whose own prerequisites reached a definite outcome.
- `render_ci_baseline.mjs` gained two small, data-conditioned extensions — a first-section event-class + Phase 232 note, and a live-stripe skip-reason sentence — both verified to leave the archived Phase 226 `226-CI-BASELINE.md` byte-identical on regeneration.

## Task Commits

1. **Task 1 RED:** `b859113c` (test) — 8 intentional failures; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
2. **Task 1 GREEN:** `9bb6b5fa` (feat) — `declaredRequiredJobSet`/`liveRequiredJobSet`/`requiredJobSetDrift`, the `proved`-requires-conclusion gate, the three new `verify_ci_baseline.mjs` flags, and the `--fixtures` repository-decoupling fix; all 16 tests pass.
3. **Task 2:** no commit — a `checkpoint:decision` authorization gate (see below), recorded here rather than in a task commit.
4. **Task 3:** `8c87baae` (feat) — push, dispatch, poll, `render_ci_baseline.mjs` extension, and the committed GATE-02 evidence.

**Plan metadata:** this commit (SUMMARY + STATE + ROADMAP).

## Checkpoint: Task 2 Authorization (irreversible external operation, not an acceptance gate)

- **SHA authorized:** `f524f2a6b16d3576829632ab6fa77d24b718e6f7` — re-verified equal to the live `git rev-parse integration/v1.62-candidate` immediately before the push in Task 3 (per the coordinator's explicit re-verification instruction). Match confirmed.
- **Scope:** exactly one ref (`integration/v1.62-candidate`) to `origin` (`https://github.com/szTheory/accrue.git`); `main` was never pushed, no tag was moved or created, and no pull request was opened. All three were re-verified after the push (`git ls-remote --heads origin main` unchanged from its pre-task value; `git ls-remote --tags origin` count unchanged; `gh pr list --repo szTheory/accrue --head integration/v1.62-candidate` returned empty).
- **Decision maker:** the coordinator relayed the maintainer's explicit "Option A — go" for this exact SHA, naming the authorization scope verbatim (push only this branch at this SHA; never `main`/tags/PR; halt and report if the live SHA didn't match before pushing).
- This checkpoint authorized an **irreversible external operation** (publishing a commit to a public repository) — CLAUDE.md's post-218 policy explicitly permits human interaction for exactly this class of action. It accepted no *behavior* and is not a UAT substitute; `behavior_unverified` stays `0` for this plan (D-33 posture unaffected).

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` — required-job-set drift derivation, provider-proof conclusion gate.
- `scripts/ci/verify_ci_baseline.mjs` — three new strict-verification flags; `--fixtures` repository decoupling.
- `scripts/ci/render_ci_baseline.mjs` — event-class-aware first section note; live-stripe skip-reason note.
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.ndjson` — committed evidence (mode `0600`).
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.md` — rendered diagnostic (byte-reproducible from the NDJSON via `verify_ci_baseline.mjs`).

## Decisions Made

- Reused Plan 03's `declaredMergeBlockingJobs`/`annotationSweepNeeds` for GATE-02's required-set derivation rather than writing a second `ci.yml` parser (D-19); confirmed zero drift live.
- Recorded `provider_state: skipped` (not `non_run`) for the candidate run, since the dispatch deliberately and explicitly declined to run `live-stripe` via `run_live_stripe=false` — a positive, known fact, not an absence of observation.
- Did **not** attempt to force `annotation-sweep` into a job record. Its own declared prerequisites (`host-integration`, `playwright-e2e`, `host-docker-smoke`) never reached `success` (they were themselves skipped by GitHub because their own upstream jobs failed), and `collect_ci_baseline.mjs`'s `unresolvedPrerequisites`/`workflowNeeds` machinery correctly, fail-closed, refuses to normalize a job whose declared prerequisites are absent from the same run's job set. Weakening that invariant to shoehorn in one job record for this one artifact would have been a much larger, out-of-scope change to a load-bearing correctness guarantee. The run-level `conclusion: failure` field plus its immutable `run_url` (`https://github.com/szTheory/accrue/actions/runs/35100620086`) is where a maintainer sees `annotation-sweep`'s actual failure.
- Extended `render_ci_baseline.mjs` even though it is not in this plan's declared `files_modified` — necessary because `verify_ci_baseline.mjs --rendered` enforces byte-for-byte reproducibility against `renderBaseline()`, so the plan's own acceptance criteria (event class visible in the first section; Phase 232 mention; live-stripe skip reason) were unreachable without it. Verified non-regressive: `node scripts/ci/render_ci_baseline.mjs --input .../226-CI-BASELINE.ndjson ...` still reproduces the archived `226-CI-BASELINE.md` byte-for-byte.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `verify_ci_baseline.mjs --fixtures --expected-repository szTheory/accrue` failed on pre-existing, unmodified code**
- **Found during:** Task 1's own second literal `<verify>` command.
- **Issue:** `verifyFixtures` hard-required its caller-supplied `validationContext.expectedRepository` to equal the fixture dataset's own fixed `acme/accrue`; confirmed via `git show HEAD~1:scripts/ci/verify_ci_baseline.mjs` that this predates this plan entirely.
- **Fix:** `main()` now always invokes `verifyFixtures` with a fixed internal `acme/accrue` context, independent of the CLI's `--expected-repository` (which still governs `--records`/`--rendered`/the new flags).
- **Files modified:** `scripts/ci/verify_ci_baseline.mjs`.
- **Verification:** `node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository szTheory/accrue` now prints `ci baseline fixtures: PASS`.
- **Committed in:** `9bb6b5fa`.

**2. [Rule 1 - Bug] Pre-existing `collect_ci_baseline.mjs` CLI guard missing the `NODE_TEST_CONTEXT` check**
- **Found during:** Task 1's own first literal `<verify>` command.
- **Issue:** Every sibling `scripts/ci/*.mjs` module guards its CLI `main()` invocation with `!process.env.NODE_TEST_CONTEXT`; `collect_ci_baseline.mjs` lacked it, so `node --test scripts/ci/collect_ci_baseline.mjs` spuriously ran the CLI's `main()` (which then failed on `--repo is required`) even before any test block existed in this file.
- **Fix:** Added the missing guard, matching the established pattern.
- **Files modified:** `scripts/ci/collect_ci_baseline.mjs`.
- **Verification:** `node --test scripts/ci/collect_ci_baseline.mjs` now runs only the intended test suite.
- **Committed in:** `b859113c`.

**3. [Rule 3 - Blocking] `render_ci_baseline.mjs` extension required to satisfy Task 3's acceptance criteria**
- See "Decisions Made" above for the full rationale. **Files modified:** `scripts/ci/render_ci_baseline.mjs`. **Verification:** byte-identical regeneration of the archived `226-CI-BASELINE.md`; Task 3's literal `--records`/`--rendered` verify command passes. **Committed in:** `8c87baae`.

**4. [Rule 1 - Bug, plan-text only] Two of the plan's own literal `<verify>` snippets do not run as written on this environment/data shape**
- Task 1's third `<verify>` command (`node --input-type=module -e "... require('node:fs') ..."`) throws `ReferenceError: require is not defined` on Node v24.19.0 — ESM eval via `--input-type=module` has no `require`. The identical drift-check logic passes via `node -e "..."` (default CJS eval), confirmed with matching output (`OK no drift`). No production code was affected.
- Task 3's third `<verify>` command compares each record's 12-hex `sha` field against a live 40-hex `git rev-parse` value (`r.sha !== sha`), which is a permanent false positive by construction — the schema intentionally truncates `run.sha` to 12 hex characters (`sha: run.head_sha.slice(0, 12)`, enforced by `validateRecord`'s `/^[a-f0-9]{12}$/` check). The corrected comparison (`r.sha !== sha.slice(0, 12)`) passes cleanly against the committed evidence.
- **No files were changed for this deviation** — both are plan-text-only bugs unrelated to any code in this plan. Flagging for the plan/verify text to be corrected in a future pass.

---

**Total deviations:** 4 (2 Rule 3 blocking fixes, 1 Rule 1 bug fix, 1 Rule 1 plan-text-only note with no code change). **Impact:** all in-scope and necessary to satisfy this plan's own literal acceptance criteria; no scope creep beyond the minimum needed. None weakened any existing correctness invariant.

## Issues Encountered

**The candidate SHA's dispatched CI run genuinely FAILED — this is the plan's most consequential finding, not a deviation to auto-fix.**

Run [35100620086](https://github.com/szTheory/accrue/actions/runs/35100620086) at `f524f2a6b16d3576829632ab6fa77d24b718e6f7` concluded `failure`. Of the 13 declared merge-blocking jobs:

- **Failed (real failures, present as job records):** `docs-contracts-shift-left` (`verify_v1_17_friction_research_contract: STATE.md must reference canonical inventory path`), `release-gate` × 3 non-advisory matrix cells + 1 advisory cell (`Accrue.Entitlements.ReferenceScenariosTest`/`Accrue.Docs.V159ReleaseContractTest` assertion failures — `missing docs-contracts-shift-left invocation` / `generated matrix drift`), `phase18-tax-gate`, `admin-ui-ratchet-guardrails`.
- **Failed as a downstream consequence, not present as a job record (see Decisions Made):** `annotation-sweep` — visible via the run's `conclusion: failure` and immutable `run_url`.
- **Never ran, correctly excluded (GitHub itself marked them `skipped`):** `admin-drift-docs`, `host-integration`, `playwright-e2e`, `host-docker-smoke` — all downstream of the `docs-contracts-shift-left` failure.
- **Succeeded:** `release-manifest-ssot`, `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails`.

I did **not** attempt to fix these failures. That would be a substantial, unbounded engineering effort (real test-content and docs-contract regressions across at least two independent subsystems) far outside this plan's charter — Task 3 authorized push/dispatch/poll/record, not "make the candidate branch pass CI." The maintainer's Task 2 go-decision authorized publishing this exact SHA and observing its real outcome, not any particular outcome.

**This is exactly what GATE-02 exists to prove, and it proved it honestly:** the closed `PROVIDER_STATES`/`conclusion` enums, the `event_class` field, and the required-job-set drift check all did their job — nobody reading `231-GATE-02-EVIDENCE.md` can mistake this `failure`-conclusion `workflow_dispatch` run for a green light.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**GATE-02 is proved — and the proof is FAIL.** `integration/v1.62-candidate` at `f524f2a6b16d3576829632ab6fa77d24b718e6f7` does not currently pass its own required CI job set. Phase 232 (Bounded Hygiene & Release Handoff) cannot proceed to open a pull request or any release action against this candidate SHA until the real regressions above (docs-contracts-shift-left, the release-gate matrix, Phase 18 Stripe Tax gate, and Admin UI ratchet guardrails) are fixed and a fresh GATE-02 dispatch proves green. This is a blocker for release, not a blocker for this plan, which completed its own charter (prove, honestly, whatever the outcome is).

`roadmap update-plan-progress` for phase 231 is expected to fail with `missing_phase_details` — a known, pre-existing `</details>` placement defect in ROADMAP.md already surfaced to the maintainer, unrelated to this plan. Not fixed here per explicit instruction.

## Self-Check: PASSED

- `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs`, `scripts/ci/render_ci_baseline.mjs` exist on disk with the described changes.
- `.planning/phases/231-exact-sha-release-gate-proof/231-GATE-02-EVIDENCE.ndjson` and `.md` exist on disk.
- Commits `b859113c`, `9bb6b5fa`, `8c87baae` found in `git log --oneline --all`.
- Re-ran the plan-level `<verification>` block: `node --check`/`node --test` pass for all three scripts; the live required-job-set drift triple is empty; `git ls-remote` confirms exactly the one new remote branch and unmoved `origin/main`/tags; the strict baseline verification (event-class, required-job-set, exit-code flags) passes; no absolute path or home-directory reference in either committed evidence file.

---
*Phase: 231-exact-sha-release-gate-proof*
*Completed: 2026-09-16*
