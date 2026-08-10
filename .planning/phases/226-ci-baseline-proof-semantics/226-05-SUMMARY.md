---
phase: 226-ci-baseline-proof-semantics
plan: "05"
subsystem: ci-evidence
tags: [bash, jq, github-actions, schema-validation, pagination]
requires:
  - phase: 226-04
    provides: Canonical cohort and CI ownership contracts
provides:
  - Exact allowlisted collector-record validation
  - Status-aware, pagination-complete metadata collection
  - Separate initial-queue, staged-chain, proof, and signature facts
affects: [226-06, ci-baseline]
tech-stack:
  added: []
  patterns: [versioned evidence discriminator, fixture HTTP envelopes, independent jq derivations]
key-files:
  created: []
  modified:
    - scripts/ci/ci_baseline_workflow_policy.json
    - scripts/ci/capture_ci_baseline.sh
    - scripts/ci/verify_ci_baseline_contract.sh
key-decisions:
  - "Collector records use schema version 2 and an explicit document_type discriminator."
  - "Confirmed classic HTTP 404 is the only provider-absence outcome."
requirements-completed: [BASE-01, BASE-02, OWN-01]
duration: 24min
completed: 2026-08-10
status: complete
---

# Phase 226 Plan 05: CI Baseline Proof Semantics Summary

**Versioned, metadata-only CI collection now validates one-run records through a closed schema while separating provider absence, initial queue, staged chain, and eligible proof facts.**

## Accomplishments

- Added a public collector-record contract with exact object-key allowlists and privacy-safe fixture coverage.
- Made classic protection absence depend exclusively on an explicit HTTP 404 and made paginated evidence fail closed.
- Declared initial queue roots separately from staged-chain ordering and verified proof/signature mutations independently.

## Task Commits

1. Task 1 — `fd530ea1`, `f4aa40af`
2. Task 2 — `ad55ae3c`
3. Task 3 — `0720de88`

## Verification

- `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` — passed.
- `bash scripts/ci/verify_ci_baseline_contract.sh` — passed.
- `bash scripts/ci/verify_phase192_ci_contract.sh` — passed.
- `git diff --check` — passed.

## Decisions Made

- Keep the v1 canonical cohort validator distinct until Plan 06 regenerates canonical evidence as v2.
- Use fixture status/page envelopes so non-200 and incomplete pagination paths are deterministic without credentials.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

- `scripts/ci/verify_ci_baseline_contract.sh`: legacy canonical v1 validation is intentionally transitional; Plan 06 regenerates and validates the canonical artifact with the corrected v2 facts.

## Next Phase Readiness

Plan 06 can collect the three canonical runs and render corrected baseline JSON/Markdown using the completed v2 collector contract.

## Self-Check: PASSED

- Confirmed all three modified CI artifacts exist.
- Confirmed commits `fd530ea1`, `f4aa40af`, `ad55ae3c`, and `0720de88` exist.
