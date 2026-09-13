---
phase: 226-ci-baseline-proof-semantics
plan: "15"
subsystem: ci-evidence
tags: [github-actions, ci-baseline, dag-timing, proof-semantics]
requires:
  - phase: 226-ci-baseline-proof-semantics
    provides: live Actions baseline collector and deterministic verification fixtures
provides:
  - Exact workflow-display-name mapping for the docs prerequisite in live CI collection
  - Workflow-coupled live-path regression fixture with fail-closed negative controls
  - Twenty-two-row Phase 226 validation ledger with full preservation evidence
affects: [BASE-01, BASE-02, OWN-01]
tech-stack:
  added: []
  patterns: [normalized display identities, injected GitHub Actions fixtures, fail-closed DAG timing]
key-files:
  created: []
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
decisions:
  - The exact Docs and bash contracts (shift-left) workflow display name maps to docs-and-bash-contracts-shift-left.
  - YAML job IDs remain restricted to the verifier's bounded workflow-contract assertion; live collection matches observed display identities.
metrics:
  duration: 9m
  completed: 2026-08-12
status: complete
---

# Phase 226 Plan 15: Exact Docs Display Identity Summary

The live collector now maps the exact CI workflow display name `Docs and bash contracts (shift-left)` to the normalized prerequisite identity consumed by host timing, with the frozen privacy-safe baseline preserved byte-for-byte.

## Completed Tasks

1. Added RED/GREEN coverage that binds the injected live fixture to the `docs-contracts-shift-left` workflow block and verifies absent, spelling-drift, and temporal prerequisite failures.
2. Centralized the display identity mapping for host integration and Docker prerequisites, then recorded the successful full Phase 226 regression in the validation ledger.

## Verification

- `node --check scripts/ci/collect_ci_baseline.mjs`
- `node --check scripts/ci/render_ci_baseline.mjs`
- `node --check scripts/ci/verify_ci_baseline.mjs`
- `node --check scripts/ci/verify_provider_proof.mjs`
- `node scripts/ci/verify_ci_baseline.mjs --fixtures`
- `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path`
- `node scripts/ci/verify_provider_proof.mjs --fixtures`
- `(cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors)`
- `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- `bash scripts/ci/verify_phase225_required_lane_evidence.sh`

All passed. The frozen NDJSON and Markdown baseline artifacts were unchanged.

## Commits

- `aff15fb1` — `test(226-15): add failing exact docs identity regression`
- `3f6f4754` — `fix(226-15): map docs prerequisite by workflow display identity`
- `de5bf0e9` — `docs(226-15): record exact-name closure validation`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve the locked parenthetical display identity**
- **Found during:** Task 1
- **Issue:** Generic normalization discarded parenthetical text, so the literal workflow name could not resolve to `docs-and-bash-contracts-shift-left`.
- **Fix:** Added a narrow exact-display-name identity mapping before generic normalization.
- **Files modified:** `scripts/ci/collect_ci_baseline.mjs`
- **Verification:** The production `liveRuns()` → `collectBaseline()` fixture now emits finite host DAG wait and all negative controls fail closed.
- **Commit:** `3f6f4754`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Restores production collection without changing the general identity, cohort, privacy, or timing semantics.

## Known Stubs

None.

## Self-Check: PASSED

- Required modified files exist and the three task commits are present in Git history.
