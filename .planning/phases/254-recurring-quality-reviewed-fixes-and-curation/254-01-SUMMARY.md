---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "01"
subsystem: testing
tags: [ci, measurement, playwright, storybook, budget, fingerprint, node-test]

requires:
  - phase: 252-production-backed-subscription-stories
    provides: phase252_lab.mjs lab server, phase252_reporters.mjs parsePlaywrightJson, render lane and results bundles
  - phase: 253-real-groups-and-a-whole-subscription-job
    provides: composition results bundles and manifest lanes measured here
provides:
  - scripts/ci/phase254_measure.mjs fingerprinted measurement harness (fingerprint, cold, warm, focused, ci-collect, provisional-budget, --self-test)
  - per-test duration retention in phase252_reporters.mjs with unchanged skip/retry/flaky/failed rejection
  - accrue_admin/storybook/phase254-budget.json provisional record with informs_only local samples and the open DEV-254-01 D-24 attribution
  - CI fingerprint and machine-evidence upload steps in admin-phase200-guardrails and browser-uat
affects: [254-02, 254-03, 254-09, 254-15, 254-18]

actuals:
  tokens: 25825
  tasks: 3
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Conforming entrypoint idiom: isMainModule assigned inside try/catch, real test() registrations under NODE_TEST_CONTEXT"
    - "Fingerprint built from an explicit env allow-list; process.env is never serialized"
    - "Freeze eligibility is a pure predicate (ubuntu image, clean tree, full protocol); local samples are informs_only"

key-files:
  created:
    - scripts/ci/phase254_measure.mjs
    - scripts/ci/phase254_measure.test.mjs
    - scripts/ci/phase252_reporters.test.mjs
    - accrue_admin/storybook/phase254-budget.json
  modified:
    - scripts/ci/phase252_reporters.mjs
    - .gitignore
    - .github/workflows/ci.yml
    - .github/workflows/accrue_admin_browser.yml

key-decisions:
  - "Missing Playwright durations parse as null instead of being rejected, so committed Phase 252/253 fixtures that predate the field keep parsing; measurement consumers require finite durations themselves."
  - "Cold boot_ms is serve-to-health minus the isolated lab create/drop probe (database_ms), so compile + database + boot partition the cold total."
  - "Warm values_ms records the slowest representative story per iteration (conservative against the 10 s target); per_cell holds the pooled per-navigation median/p90."
  - "ci-collect emits samples only for the two owner jobs that upload a fingerprint; jobs without one yield no sample."
  - "Added a provisional-budget verb so the tracked budget record is reproducible from the three local samples instead of hand-assembled."

patterns-established:
  - "Pinned local and CI sample schemas are asserted by exact key equality in tests"
  - "Cache outcomes are parsed from gh run log steps; an unrecognised cache step is rejected, never counted as a miss"

requirements-completed: [CIQ-04]

coverage:
  - id: D1
    description: "Fingerprinted measurement harness with PROTOCOLS, summarizeSamples, freeze eligibility, lane registry and a --self-test that names the secret-key and protocol-completeness controls"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs (28 tests, 0 fail)"
        status: pass
      - kind: unit
        ref: "node scripts/ci/phase254_measure.mjs --self-test (6 scenarios)"
        status: pass
    human_judgment: false
  - id: D2
    description: "phase252_reporters.mjs keeps per-test durations as a new field while still rejecting skipped, retried, flaky and failed browser results; module-boundary guard added"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase252_reporters.test.mjs scripts/ci/phase252_reporters.mjs (13 + 2 named tests); generate_phase252/253_acceptance, verify_phase252_ci_contract and verify_phase253_compositions suites 89/89"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cold (3), warm-preview (1+10) and focused (1+5) local protocols run at the D-21 counts and recorded in the tracked provisional budget with informs_only samples, frozen null and an open DEV-254-01 attribution"
    requirement: CIQ-04
    verification:
      - kind: other
        ref: "node scripts/ci/phase254_measure.mjs cold|warm|focused --lane phase252-render, then provisional-budget; budget record verification one-liner from 254-01-02 (verify true)"
        status: pass
      - kind: integration
        ref: "wave-boundary: focused --lane phase252-render --runs 1 --warmup 0 wrote a smoke sample with 16 durations, fingerprint.dirty and cpu_model"
        status: pass
    human_judgment: false
  - id: D4
    description: "CI fingerprint and machine-evidence upload steps in both owner jobs plus the ci-collect reader and cache-outcome parser, with fixtures for attempt 2, missing fingerprint, missing image_os and unparsed cache steps"
    requirement: CIQ-04
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/phase254_measure.test.mjs (collectCiSample and parseCacheOutcomes tests)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_ci_efficiency_contract.mjs --repo . ; bash scripts/ci/verify_phase200_ci_contract.sh ; step-name count 1 per workflow"
        status: pass
    human_judgment: false

duration: 26min
completed: 2026-10-28
status: complete
commits: 6
plan_head_before: dec29e27436ee031165c3572047bc7746c809a6a
plan_head_after: a90b557a2f1f7ead62fff7dab644c3a6572f7d1a
---

# Phase 254 Plan 01: Measure (W1) Summary

**Fingerprinted CIQ-04 harness (cold, warm-preview, focused, ci-collect) over the existing Phase 252/253 lanes, per-test durations kept in the reporter, and a provisional budget record attributing the ~7 min local cost mostly to compile (262 s of 415 s).**

## Performance

- **Duration:** 26 min
- **Started:** 2026-10-28T14:35:06Z
- **Completed:** 2026-10-28T15:01:30Z
- **Tasks:** 3
- **Files modified:** 8 (4 created, 4 modified)

## Accomplishments

- `scripts/ci/phase254_measure.mjs`: one command per mode (`fingerprint`, `cold`, `warm`, `focused --lane`, `ci-collect`, `provisional-budget`, `--self-test`) with the sixteen pinned `FINGERPRINT_KEYS` built from an env allow-list, the exported `PROTOCOLS`, nearest-rank `summarizeSamples`, `isProtocolComplete`, `freezeBlockers`/`isFreezeEligible`, a four-lane `LANES` registry (unknown lane fails), `attributeLaneCost`, `parseCacheOutcomes` and `collectCiSample`. It uses the conforming module-boundary idiom (PATTERNS S1) with real `test()` registrations.
- `phase252_reporters.mjs`: `parsePlaywrightJson` is exported and returns a new `durations` array of `{identity, duration_ms}`; every skipped/retried/flaky/failed rejection and the `browserBindings` literal `15` are untouched. The file also gained the shared guard and non-vacuous self-tests, so it no longer appears in the module-boundary offender list.
- Local protocols run at full D-21 counts and recorded as `informs_only` in `accrue_admin/storybook/phase254-budget.json` (`frozen`/`allowances`/`warn_at`/`ceiling` null, `selection.total` 166 = 15 Phase 252 + 151 Phase 253 rendered cases read from the latest passed bundles).
- CI: both owner jobs run `Phase 254 machine fingerprint` and upload `phase254-machine-evidence-guardrails` / `phase254-machine-evidence-browser-uat` through new steps; the existing upload path lists are unchanged.

## Measured numbers (local, informs only)

Machine: darwin 25.6.0, arm64, Apple M5 Pro, 18 cores, 64 GiB RAM, OTP 28, Elixir 1.19.5, Node 22.14.0, Playwright 1.59.1, workers 1, no `ImageOS`/`ImageVersion`/`RUNNER_OS`. Revision 428511d06, working tree dirty (uncommitted harness edits plus the orchestrator's `.planning/STATE.md` and the user's `.planning/config.json`). Several unrelated BEAM processes were running on the machine, so these are noisy by construction; they inform and never freeze (D-21).

| Mode | Lane | n / warmup | median | p90 | Notes |
|---|---|---|---|---|---|
| cold | cold-start | 3 / 0 | 110 033 ms | 131 031 ms | phases (medians): compile 107 258, database 542, boot 2 233 ms |
| warm | warm-preview | 10 / 1 per story | 31.6 ms (slowest of 3 stories per iteration) | 36.4 ms | per navigation median 24.9 ms, p90 32.0 ms over 30 navigations; target 10 s |
| focused | phase252-render | 5 / 1 | 11 309 ms | 11 488 ms | 16 cells, per-cell median 488.5 / p90 645 ms, overhead 2 595 ms; target 60 s |

DEV-254-01 (open, closes in 254-09-03): the latest passed Phase 252+253 bundles (revision 285918126) total 415.3 s locally against the 300 s provisional incremental target. Buckets: compile 262.1 s (`production-packages` 132.6 s, `phase253-manifest-contract` 65.4 s, `manifest-current` 64.1 s), database 86.5 s (`heldout-cleanup` 58.7 s, `isolation-reset` 11.5 s), boot-to-health 4.5 s, per-cell 49.6 s over 168 tests (`phase253-compositions-browser` 43.2 s), other 12.8 s. The repeated `mix run --no-start` manifest lanes and the isolated production compile are confirmed as the dominant suspects.

## Task Commits

1. **Task 1: Fingerprinted sample with per-test durations kept** (TDD)
   - RED `30b042eff` test(254-01): reporter duration test (7 failing; classified `RED_EVIDENCE_OK`)
   - GREEN `ad04af090` feat(254-01): durations field plus module-boundary guard
   - RED `ad9f82ae3` test(254-01): harness tests against a stub module (10 failing; `RED_EVIDENCE_OK`)
   - GREEN `428511d06` feat(254-01): harness, fingerprint, lanes, focused samples, `.gitignore`
2. **Task 2: Cold, warm-preview and focused protocols with D-24 attribution** - `6ee60bed2` (feat)
3. **Task 3: CI fingerprint/evidence steps and ci-collect** - `a90b557a2` (feat)

**Plan metadata:** committed with this SUMMARY (docs: complete plan).

## Files Created/Modified

- `scripts/ci/phase254_measure.mjs` - harness (1 059 lines)
- `scripts/ci/phase254_measure.test.mjs` - 28 named tests including freeze eligibility, warm lane refusal, ci-collect and cache parsing
- `scripts/ci/phase252_reporters.mjs` / `.test.mjs` - durations field, guard, 13 named tests
- `accrue_admin/storybook/phase254-budget.json` - provisional budget record
- `.gitignore` - `accrue_admin/tmp/phase254/`
- `.github/workflows/ci.yml`, `.github/workflows/accrue_admin_browser.yml` - fingerprint and upload steps

## Decisions Made

See `key-decisions` above. Notably the budget builder refuses a smoke sample, a missing mode and any non-`informs_only` local sample, so a below-protocol or Mac number cannot reach the record.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reporter duration validation broke existing consumers**
- **Found during:** Task 1 (GREEN)
- **Issue:** The first draft rejected any Playwright result without a finite duration; the committed `generate_phase252_acceptance` fixtures predate the field, so 13 existing tests failed.
- **Fix:** Missing durations are kept as `null`; only the pass/skip/retry/flaky rules reject. The harness's own `readReport` requires finite durations.
- **Files modified:** scripts/ci/phase252_reporters.mjs, scripts/ci/phase252_reporters.test.mjs
- **Verification:** reporters tests 13/13; acceptance, CI-contract and composition suites 89/89 (baseline 71/71 before the change).
- **Committed in:** ad04af090

**2. [Rule 1 - Bug] Warm collection story was not directly renderable**
- **Found during:** Task 2 (first warm run timed out waiting for `.psb-sandbox h1`)
- **Issue:** The non-iframe collection story page wraps the story in an iframe; the Phase 253 specs navigate the `iframe/` path.
- **Fix:** The collection representative uses `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row`.
- **Files modified:** scripts/ci/phase254_measure.mjs
- **Verification:** 1-run probe, then the full 10+1 warm protocol (n=10).
- **Committed in:** 6ee60bed2

### Process notes (not code deviations)

- The Task 1 harness RED used a minimal stub module so the target tests fail on assertions rather than on a missing import.
- Task 3 tests were written before the implementation but their RED run was not committed separately (the code was split into the Task 2 and Task 3 commits afterwards). Running the final test file against the Task 2 module gave 13 of 28 failing, including the target `parseCacheOutcomes` test on its planned assertion. The machine classifier rejected that capture as `INVALID_RED / invalid_record` (malformed-TAP report, "Non-TAP data"), so it is not claimed as `RED_EVIDENCE_OK`.
- Added beyond the plan text: the `provisional-budget` verb and `buildProvisionalBudget` (with tests) so the tracked record is reproducible.

---

**Total deviations:** 2 auto-fixed (2 bugs). **Impact on plan:** both fixes were needed for correctness; no scope creep.

## Issues Encountered

- Focused protocol at full counts was run for `phase252-render` only. `phase253-aggregate`, `phase253-manifest` and `phase252-aggregate` are registered and runnable but cost roughly 2, 1 and 5 minutes per run, so 6 runs each were not spent here; their cost enters the record through the latest passed results bundles (D-24 attribution).
- Local numbers were taken on a busy developer machine with a dirty tree; they are explicitly informs-only. Real runner observations are 254-03's job.

## Deferred Issues

- Seven `scripts/ci/*.mjs` files still fail the merge-blocking `verify_ci_script_contract --require-guard-coverage` (generate_phase252_acceptance, generate_phase253_acceptance, phase252_paths, verify_phase252_production_boundary, verify_phase252_stories, verify_phase252_transparency, verify_phase253_compositions). This is the pre-existing PATTERNS P1 finding; `phase252_reporters.mjs` (touched here) and `phase254_measure.mjs` are no longer on the list. Fixing the rest is outside this plan.

## Known Stubs

None.

## Threat Flags

None. The workflow edits add no triggers, permissions or `pull_request_target`; the fingerprint test injects secret-looking variables and asserts they never appear (T-254-01); no dependency was added (D-01).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 254-02 onward can read `metrics.local` and `deviations` from `accrue_admin/storybook/phase254-budget.json` using only the pinned key names; `manifest_sha256` is the sha256 of `storybook/phase252-manifest.json`.
- 254-03 can collect the first runner observations with `node scripts/ci/phase254_measure.mjs ci-collect --run <run_id> --repo szTheory/accrue` once a PR run of both owner jobs exists (attempt 1 only). Nothing was pushed in this plan.

## Self-Check: PASSED

All eight changed paths exist, all six task commits are ancestors of HEAD, and the plan-level verification (three task verify commands plus the wave-boundary lane run) passed.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-28*
