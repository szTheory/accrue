---
phase: 226-ci-baseline-proof-semantics
plan: "12"
subsystem: ci
tags: [github-actions, critical-path, fingerprint-strata, deterministic-evidence, privacy]
requires:
  - phase: 226-07
    provides: Per-run staged-path derivation and fail-closed critical-path verification
provides:
  - Latest-20 compatible complete CI path selection with visible fingerprint sensitivity
  - Recollected privacy-safe 90-day Actions evidence and byte-reproducible report
  - Green validation ledger for baseline, provider, formatter, setup, and required-lane contracts
affects: [phase-227-critical-path-improvement, ci-baseline, release-evidence]
tech-stack:
  added: []
  patterns: [compatible-path stratification, latest-shard completion, atomic evidence refresh, byte-exact rendering]
key-files:
  created: [.planning/phases/226-ci-baseline-proof-semantics/226-12-SUMMARY.md]
  modified: [scripts/ci/render_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md, .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md]
key-decisions:
  - "Use the latest 20 compatible complete paths across fingerprints while reporting every fingerprint as a sensitivity stratum."
  - "Treat matrix-named playwright-e2e-shard-* jobs as one parallel Playwright stage and measure only its latest completion."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: Compatible complete staged paths are selected across evolving workflow fingerprints with deterministic sensitivity disclosure.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --fixtures
        status: pass
      - kind: integration
        ref: node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path
        status: pass
    human_judgment: false
  - id: D2
    description: The frozen 90-day Actions snapshot is privacy-safe, byte reproducible, and preserves provider and setup ownership boundaries.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: node scripts/ci/verify_provider_proof.mjs --fixtures
        status: pass
      - kind: integration
        ref: cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors
        status: pass
      - kind: integration
        ref: bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-08-11
status: complete
---

# Phase 226 Plan 12: Compatible CI Baseline Closure Summary

**A privacy-safe 90-day Actions snapshot now measures 20 compatible release-to-Playwright paths at p50 2083s and p95 2602s, while exposing eight workflow-fingerprint strata instead of hiding topology evolution.**

## Performance

- **Duration:** 20 min
- **Completed:** 2026-08-11
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Replaced exact-fingerprint availability with latest-20 compatible complete-path selection and deterministic fingerprint sensitivity.
- Recollected the canonical `szTheory/accrue` `ci.yml` 90-day snapshot only after read-only authentication, Actions access, schema, critical-path, and dual-render gates passed.
- Revalidated provider proof, formatter, setup diagnostics, and Phase 225 required-lane evidence without changing their implementation contracts.

## Task Commits

1. **Task 1: Compatible staged-path selection and sensitivity** — `8fd2a902` (test), `77d01ddd` (feat)
2. **Task 1 deviation: Recognize current Playwright shard labels** — `9c936fa7` (fix)
3. **Task 2: Recollect, freeze, byte-compare, and complete the Phase 226 contract** — `f8e8792d` (docs)

## Files Created/Modified

- `scripts/ci/render_ci_baseline.mjs` — selects compatible staged paths, calculates one unsummed span per run, and renders strata sensitivity.
- `scripts/ci/verify_ci_baseline.mjs` — verifies rendered sample disclosure and current compatibility controls.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` — canonical 90-day privacy-safe frozen Actions records.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — byte-reproducible measured baseline report.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md` — final Plan 06/07/12 proof ledger and sign-off.

## Decisions Made

- Keep topology fingerprints visible as strata: comparable evidence is sufficient across evolution, but variation remains measurable.
- Accept matrix shard labels as the Playwright stage and use only their latest completion so parallel work is never double-counted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Recognized GitHub matrix Playwright shard labels**
- **Found during:** Task 2 temporary live evidence gate
- **Issue:** Live jobs normalize to `playwright-e2e-shard-1/3` rather than the fixture-only exact `playwright-e2e`, causing a false missing-stage failure despite 28 structurally complete paths.
- **Fix:** Matched the stable Playwright stage prefix and updated the verifier's rendered sample assertion.
- **Files modified:** `scripts/ci/render_ci_baseline.mjs`, `scripts/ci/verify_ci_baseline.mjs`
- **Verification:** Fixture suite and frozen `--require-critical-path` gate pass with 20 selected paths.
- **Committed in:** `9c936fa7`

**Total deviations:** 1 auto-fixed (Rule 1).

## Issues Encountered

The first temporary gate reported a missing Playwright stage. Read-only inspection confirmed 28 eligible first-attempt runs and 28 structurally complete paths; the mismatch was solely the current shard-label spelling and was corrected before evidence publication.

## User Setup Required

None.

## Next Phase Readiness

Phase 227 can use the measured compatible-path baseline and its explicit topology sensitivity to choose one verified critical-path improvement without changing required checks or proof ownership.

## Self-Check: PASSED

- Confirmed task commits `8fd2a902`, `77d01ddd`, `9c936fa7`, and `f8e8792d` exist.
- Confirmed frozen NDJSON, Markdown, and validation ledger exist and pass the required critical-path verifier.

---
*Phase: 226-ci-baseline-proof-semantics*
*Completed: 2026-08-11*
