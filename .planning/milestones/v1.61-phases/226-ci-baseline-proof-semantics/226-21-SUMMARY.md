---
phase: 226-ci-baseline-proof-semantics
plan: "21"
subsystem: ci-evidence
tags: [github-actions, provenance, ndjson, validation, markdown]
requires:
  - phase: 226-20
    provides: semantic baseline rendering and frozen canonical evidence
provides:
  - caller-supplied repository trust context for CI evidence
  - fail-closed renderer handling for foreign Actions URLs
affects: [227-critical-path-optimization]
tech-stack:
  added: []
  patterns: [branded-validation-context, fail-closed-cli-output]
key-files:
  created: []
  modified: [scripts/ci/collect_ci_baseline.mjs, scripts/ci/render_ci_baseline.mjs, scripts/ci/verify_ci_baseline.mjs, scripts/ci/README.md, .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md, .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md]
key-decisions:
  - "Repository trust is constructed only from an explicit owner/repository CLI input."
  - "The renderer validates provenance before opening its output path."
requirements-completed: [BASE-01, BASE-02, OWN-01]
coverage:
  - id: D1
    description: "Baseline run and job evidence accepts only the independently expected repository."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue"
        status: pass
    human_judgment: false
  - id: D2
    description: "Canonical baseline remains byte-reproducible with explicit repository provenance."
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-12
status: complete
---

# Phase 226 Plan 21: Repository-Bound CI Evidence Summary

**CI baseline evidence now requires an independently supplied repository context, preventing foreign Actions links from becoming Markdown evidence.**

## Accomplishments

- Added immutable branded repository validation context throughout collector, renderer, and verifier boundaries.
- Made collector, renderer, and verifier CLIs require explicit repository trust input before output writes.
- Added production renderer foreign-repository rejection coverage and regenerated canonical reproduction commands.

## Task Commits

1. **Task 1: Reject cross-repository evidence through the production renderer** — `20aa7fc4` (fix)

## Files Created/Modified

- `scripts/ci/collect_ci_baseline.mjs` — validates repository-bound raw and persisted evidence.
- `scripts/ci/render_ci_baseline.mjs` — requires expected repository before rendering or writing.
- `scripts/ci/verify_ci_baseline.mjs` — verifies same-repository success and foreign-evidence rejection.
- `scripts/ci/README.md` and Phase 226 baseline documents — carry explicit repository arguments.

## Decisions Made

- Repository provenance is a caller-owned trust input and is never inferred from the persisted snapshot.
- Foreign repository URLs fail before renderer output creation.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

The production regression was added and verified within the task commit; no separate RED commit was created.

## Verification

- `node --check` for all three baseline scripts — passed.
- Fixture verifier with `acme/accrue` — passed.
- Fixture verifier with `attacker/forged` — rejected nonzero.
- Canonical critical-path verification with `szTheory/accrue` — passed.
- Provider fixture verifier and setup diagnostics — passed.

## Next Phase Readiness

Phase 227 can rely on repository-bound, byte-reproducible canonical CI evidence.

## Self-Check: PASSED

- All six modified task files exist and task commit `20aa7fc4` is present.
