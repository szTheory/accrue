---
phase: 230-reviewable-history-integration
plan: 03
subsystem: infra
tags: [git, integration, evidence, ci, hazard-classification]

requires:
  - phase: 230-reviewable-history-integration
    plan: 02
    provides: refs/heads/integration/v1.62-candidate (a single --no-ff merge, never pushed), the collect/render/verify disposition triad with empty hazards/post_merge_commits, and an executed rollback proof
provides:
  - The disposition's hazards section recomputed live from the candidate's two merge parents -- never transcribed from CONTEXT.md -- classifying all six co-touched files from a closed nine-value enumeration, with convergent-identity proved by 40-hex blob-id equality (not asserted).
  - "--require-hazard-universe on verify_integration_disposition.mjs: exact-map completeness (missing=[]/extra=[]/changed=[]) between the live co-touched file set and the committed hazard rows, plus a closed D-21 lane-enumeration completeness check."
  - The closed D-21 lane enumeration (13 lanes explicitly out of Phase 230's scope) recorded as explicit non_run rows owned by Phase 231, encoding the D-20 230/231 boundary as an assertion.
  - A maintainer-legible rendered diagnostic leading with decisions adopted silently, then per-hazard-class sections (zero-row classes rendered explicitly, never omitted), then the 231-owned lanes, then convergent-identical rows collapsed last; fenced with a phase230-integration-disposition splice marker pair for Phase 232.
affects: [230-04, 230-05, 230-06, 230-07, 231-exact-sha-release-gate-proof, 232-bounded-hygiene-release-handoff]

actuals:
  tokens: 18700
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Hazard-class dispatch by filename shape (dependency-lock-drift for accrue/mix.exs, disjoint-hunk marker check for accrue/lib/accrue/config.ex, doc-rewrite for any co-touched .md) with a hard fail on anything unrecognized -- unknown class is never a silent pass-through."
    - "One hazard row per co-touched file, keyed by repository-relative path; co_touched_file_count is asserted equal to hazards.length in both the collector's validator and the verifier's exact-map completeness check."
    - "A second closed enumeration (the 13 D-21 lanes) recorded as explicit non_run rows owned by Phase 231, encoding the D-20 230/231 scope boundary as a schema-level assertion (owner === '231' implies state === 'non_run') rather than prose."
    - "Per-hazard-class rendering with an explicit zero-count section for classes with no rows, sorted deterministically by a path (and blob-id) tiebreak so shuffled input re-renders byte-identically."

key-files:
  created: []
  modified:
    - scripts/ci/collect_integration_disposition.mjs
    - scripts/ci/render_integration_disposition.mjs
    - scripts/ci/verify_integration_disposition.mjs
    - scripts/ci/README.md
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json
    - .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md

key-decisions:
  - "mix.exs's hazard row absorbs both the release-train version bump (1.4.0->1.5.1) and the dependency-lock drift (Decimal 3/ex_money 6/Ecto 3.14) under a single dependency-lock-drift classification, rather than splitting into two rows -- required by the plan's own acceptance criterion that co_touched_file_count equal hazards.length (strict 1:1 path-to-row mapping)."
  - "The D-21 excluded-lane rows live in a new top-level `lanes`/`lane_count` array, separate from `hazards` -- lanes are not co-touched files, so folding them into the file-keyed hazards array would have broken the co_touched_file_count === hazards.length invariant."
  - "Every hazard row's evidence.command is an argv array (never a joined shell string), consistent with the plan's explicit D-20 requirement that a 'proved' row carry a command argv array plus an integer exit_code -- a departure from Plan 230-02's ancestry rows, which use a plain descriptive string for evidence (that precedent predates this requirement and was left unchanged)."
  - "disjoint-hunk proof for config.ex uses a static marker-presence check against the candidate's own blob (both survivor lines present) rather than running any test -- consistent with D-20's 230/231 boundary: this plan proves the merge changed nothing it did not declare, not that the result is releasable."

requirements-completed: [INTG-02, INTG-03]

coverage:
  - id: T1
    description: "The hazard universe (co-touched file set) is recomputed live inside the collector from two merge-parent diffs against a recomputed merge-base, never transcribed; every co-touched file is classified from a closed nine-value enumeration; an unclassifiable file is a hard failure naming it; convergent-identity is proved by two equal 40-hex blob ids, never asserted."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/collect_integration_disposition.mjs (9/9 pass, incl. hazard-classification and unclassifiable-file fixtures)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/collect_integration_disposition.mjs --repo . --expected-repository szTheory/accrue --candidate-ref refs/heads/integration/v1.62-candidate --out ... (real repository: 6 co-touched files recomputed, matching CONTEXT.md's D-16 expectation exactly)"
        status: pass
      - kind: unit
        ref: "grep -n 'dialyzer_ignore|ingest_test|entitlements_live_test' scripts/ci/collect_integration_disposition.mjs returns nothing"
        status: pass
    human_judgment: false
  - id: T2
    description: "--require-hazard-universe asserts exact-set completeness (missing/extra) between the live recomputed co-touched files and the committed hazard rows, refuses on a stale binding before any comparison, and asserts the closed D-21 lane enumeration is exactly and exclusively represented as non_run rows owned by Phase 231."
    requirement: "INTG-03"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_integration_disposition.mjs (1/1 suite pass, incl. missing/extra/stale-binding/bad-lane fixtures)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --fixtures --expected-repository szTheory/accrue --require-hazard-universe"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_integration_disposition.mjs --records ... --rendered ... --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-ancestry --require-scope --require-hazard-universe --require-post-merge-scope --require-determinism (real repository)"
        status: pass
      - kind: unit
        ref: "grep -nE '\\.length *> *0|\\.length *!== *0|Boolean\\(' scripts/ci/verify_integration_disposition.mjs returns nothing"
        status: pass
    human_judgment: false
  - id: T3
    description: "The rendered Markdown leads with decisions adopted silently, sections a hazard class explicitly even with zero rows, collapses convergent-identical rows last, carries a phase230 splice marker pair, and re-renders byte-identically from the committed JSON regardless of input row order."
    requirement: "INTG-02"
    verification:
      - kind: unit
        ref: "node --test scripts/ci/render_integration_disposition.mjs (6/6 pass, incl. shuffle-determinism and zero-count-heading fixtures)"
        status: pass
      - kind: unit
        ref: "grep -n 'Date.now()' scripts/ci/render_integration_disposition.mjs returns nothing"
        status: pass
      - kind: integration
        ref: "--require-determinism against the committed 230-INTEGRATION-DISPOSITION.{json,md} on the real repository"
        status: pass
    human_judgment: false

duration: ~95 min
completed: 2026-09-15
status: complete
commits: 3
plan_head_before: bbcb34de6383e6dc65df905d50119f9088f3143c
---

# Phase 230 Plan 3: Hazard Universe & Disjoint-Conflict Disposition Summary

**Recomputes the v1.62 candidate's full integration hazard universe from live merge-parent SHAs, proves the three convergent-identical co-touched files by blob-id equality, classifies the config.ex/mix.exs/entitlements.md hazards from a closed nine-value enumeration, encodes the 230/231 scope boundary as 13 explicit non_run lane rows owned by Phase 231, and renders a maintainer-legible, byte-deterministic diagnostic that leads with what the merge decided silently.**

## Performance

- **Duration:** ~95 min
- **Started:** 2026-09-15
- **Completed:** 2026-09-15
- **Tasks:** 3
- **Files modified:** 6 (4 scripts/docs, 2 regenerated evidence artifacts)

## Accomplishments

- `scripts/ci/collect_integration_disposition.mjs` recomputes the co-touched file set live from two `git diff --name-only <merge-base> <parent>` calls (never transcribed from CONTEXT.md), classifies every file against a closed hazard-class enumeration (`convergent-identical`, `disjoint-hunk`, `version-release-train-drift`, `version-keyed-contract-script`, `dependency-lock-drift`, `schema-relaxation`, `doc-rewrite`, `archive-path-regression`, `generated-artifact-staleness`), and hard-fails naming the file when a co-touched file matches none of them. On the real repository this recomputes exactly the six files CONTEXT.md's D-16 expected: three convergent-identical (`.dialyzer_ignore.exs`, `ingest_test.exs`, `entitlements_live_test.exs`, each proved by two equal 40-hex blob ids), `accrue/lib/accrue/config.ex` as disjoint-hunk (proved by a static check that both survivor markers — the milestone's `Accrue.Env.mix_env()` and origin/main's optional `:branding` relaxation — are present in the candidate blob), `accrue/mix.exs` as dependency-lock-drift (`non_run`, owned by Plan 230-05 per D-17), and `accrue/guides/entitlements.md` as doc-rewrite (`advisory`).
- Also added the closed D-21 lane enumeration (13 CI/release lanes explicitly out of Phase 230's scope — full `mix test`, Dialyzer/PLT, Playwright E2E, the admin visual pixel-diff gate, storybook specs, host-integration, host-docker-smoke, asset rebuild, `copy_strings.json` regeneration, any provider/live-Stripe lane, `mix hex.publish --dry-run`, any fresh-clone run, any GitHub Actions dispatch) as explicit `non_run` rows owned by Phase 231, with a schema-level assertion that any row owned by Phase 231 must carry `state: "non_run"` (D-20).
- `scripts/ci/verify_integration_disposition.mjs` gained `--require-hazard-universe`: recomputes the live co-touched file set and asserts exact-map equality against the committed hazard rows (`missing=[]`/`extra=[]`/`changed=[]`, reusing the `exactMap`/`assertSameMap` primitive verbatim from `verify_repository_inventory.mjs`), reuses the `STALE_BINDING` refusal before any comparison, and asserts the D-21 lane enumeration is exactly and exclusively represented. Independently provable with no other `--require-*` flag present.
- `scripts/ci/render_integration_disposition.mjs` now renders decisions-adopted-silently first, one section per hazard class (zero-row classes render an explicit "0 rows" heading rather than being omitted), the 231-owned lanes, then convergent-identical rows collapsed last in a `## Convergent-identical (owe nothing)` section as the final `## ` heading — fenced with a `<!-- phase230-integration-disposition:start/end -->` splice marker pair for Phase 232 to lift into the integration PR body (D-39). Rows sort deterministically by a path/blob-id tiebreak so shuffled input row order re-renders byte-identically.
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.{json,md}` regenerated and committed; `--require-hazard-universe` and `--require-determinism` both PASS against the real repository alongside the previously-passing `--require-ancestry`/`--require-scope`/`--require-post-merge-scope`.
- Added a `scripts/ci/README.md` evidence-table row for the Phase 230 triad, matching the Phase 229 precedent's format.

## Task Commits

1. **Task 1: Recompute the hazard universe and prove convergent-identity by blob id** - `3614e7a3` (feat)
2. **Task 2: Exact-set completeness and fail-closed hazard verification** - `32d103c3` (feat)
3. **Task 3: Deterministic maintainer-legible rendering** - `04e18145` (feat)

**Plan metadata:** (this commit) - `docs(230-03): complete plan`

## Files Created/Modified

- `scripts/ci/collect_integration_disposition.mjs` - hazard-class enumeration, `collectCoTouchedFiles`/`collectHazards`/`collectLanes`/`assertHazardUniverse` exports, full `hazards`/`lanes` row validation
- `scripts/ci/verify_integration_disposition.mjs` - `--require-hazard-universe` flag, `assertHazardUniverseLive`, exact-map completeness helpers, new fixture scenarios
- `scripts/ci/render_integration_disposition.mjs` - per-hazard-class sections, D-21 lane section, convergent-identical-last section, splice markers, sort-key tiebreak
- `scripts/ci/README.md` - Phase 230 evidence-table row
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json` - regenerated with the full hazards/lanes payload
- `.planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md` - regenerated, byte-deterministic re-render

## Decisions Made

See `key-decisions` in frontmatter. Summarized: (1) `mix.exs`'s single hazard row absorbs both the version bump and the dependency-lock drift to preserve the plan's `co_touched_file_count === hazards.length` invariant; (2) the D-21 lanes live in a new, separate `lanes`/`lane_count` array rather than being folded into `hazards`; (3) every hazard row's `evidence.command` is an argv array per the plan's explicit D-20 requirement, a departure from Plan 230-02's ancestry-row evidence strings (left unchanged, out of this plan's scope); (4) `config.ex`'s disjoint-hunk proof is a static marker-presence check, not a test run, consistent with the 230/231 boundary.

## Deviations from Plan

None — plan executed exactly as written. The task-boundary choices above (mix.exs's dual-hazard absorption, the separate `lanes` array, argv-array evidence) were made during Task 1/Task 2 implementation to satisfy the plan's own explicit acceptance criteria (`co_touched_file_count === hazards.length`, "every row with state: 'proved' must carry a command argv array") and are not scope changes.

## Issues Encountered

- Early hazard-classification test fixtures used single-line edits to the same file, which caused genuine `ADD/ADD` or same-line merge conflicts in `git merge-tree` — not a code bug, but a fixture-construction lesson: a disjoint-hunk hazard can only be exercised in a fixture when the target file exists, identically, at the actual computed merge-base, with each side then editing non-overlapping lines. Fixed by pre-seeding the shared file at the fixture's base commit before diverging.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The disposition's hazard universe is complete and evidence-backed for Plans 230-04/230-05/230-06/230-07 to build on: Plan 230-05 has a named, non_run `dependency-lock-drift` row on `accrue/mix.exs` to discharge (re-resolve sibling `mix.lock` files and run the money-math/property suites per D-19), and Plan 230-04 (the excluded-commit ledger) can proceed independently.
- INTG-02 and INTG-03 requirements are satisfied by this plan's work but remain `In Progress` in REQUIREMENTS.md pending Plans 230-04/230-06/230-07, which also declare them (shared-ID gate, #2388) — they will flip to `Complete` automatically once the last declaring plan finishes.
- The `--require-hazard-universe` and `--require-determinism` flags are ready for Phase 231/232 CI wiring once those phases are ready to make this triad merge-blocking.

---
*Phase: 230-reviewable-history-integration*
*Completed: 2026-09-15*

## Self-Check: PASSED

- FOUND: scripts/ci/collect_integration_disposition.mjs (modified)
- FOUND: scripts/ci/render_integration_disposition.mjs (modified)
- FOUND: scripts/ci/verify_integration_disposition.mjs (modified)
- FOUND: scripts/ci/README.md (modified)
- FOUND: .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.json (regenerated)
- FOUND: .planning/phases/230-reviewable-history-integration/230-INTEGRATION-DISPOSITION.md (regenerated)
- FOUND commit: 3614e7a3 (Task 1)
- FOUND commit: 32d103c3 (Task 2)
- FOUND commit: 04e18145 (Task 3)
- Re-ran the plan-level `<verification>` items 1-5: all PASS (16/16 unit tests across the three scripts; `--require-hazard-universe`/`--require-determinism` PASS on the real repository; all six convergent-identical/D-21-lane counts match their literal recorded integers).
