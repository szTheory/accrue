---
phase: 109-support-contract-truth
plan: 03
subsystem: docs
tags: [example-host, ci, support-contract, braintree, stripe]
requires:
  - phase: 109-support-contract-truth
    provides: provider-honest package docs, planning mirrors, and mounted Braintree onboarding contract
provides:
  - example-host proof docs now mirror the shipped checkout and billing-portal support contract
  - shift-left bash gates now pin the provider-honest host and adoption-matrix wording
  - phase 109 closes with docs and verifiers aligned against the same support truth
affects: [phase-110, example-host-proof, docs-contracts-shift-left, supportability]
tech-stack:
  added: []
  patterns: [example-host proof docs mirror package-doc truth, support wording changes require same-PR verifier updates]
key-files:
  created: [.planning/milestones/v1.35-phases/109-support-contract-truth/109-03-SUMMARY.md]
  modified: [examples/accrue_host/README.md, examples/accrue_host/docs/adoption-proof-matrix.md, scripts/ci/README.md, scripts/ci/verify_package_docs.sh, scripts/ci/verify_verify01_readme_contract.sh, scripts/ci/verify_adoption_proof_matrix.sh, .planning/STATE.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md]
key-decisions:
  - "The example host remains proof/reference, while package docs stay the primary install story for Hex consumers."
  - "Provider-honest checkout and billing-portal wording must be enforced by the same bash gates that protect the support matrix and host proof docs."
patterns-established:
  - "Support-contract edits to package docs or example-host mirrors must ship with co-updated verify_package_docs, verify_verify01_readme_contract, and verify_adoption_proof_matrix needles."
requirements-completed: []
duration: 4 min
completed: 2026-05-06
---

# Phase 109 Plan 03: Support Contract Truth Summary

**Example-host proof docs and shift-left gates now close the last Stripe-only wording gap in the Phase 109 support contract**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-06T20:07:44Z
- **Completed:** 2026-05-06T20:11:12Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Rewrote the example-host README and adoption proof matrix so they mirror the shipped provider-honest checkout and billing-portal contract instead of teaching stale Stripe-only semantics.
- Preserved the proof/reference framing of `examples/accrue_host` and kept package docs as the primary install path.
- Updated `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, and `verify_adoption_proof_matrix.sh` to pin the new wording and reject stale `Stripe-only` drift.
- Added a contributor-facing same-PR co-update rule for support-contract mirrors and their bash gates in `scripts/ci/README.md`.
- Advanced planning state to reflect Phase 109 complete and ready for follow-on milestone work.

## Verification

- Task 1 verifier passed: `rg -n "gateway subscription core|mounted local|checkout|billing portal|Braintree" examples/accrue_host/README.md examples/accrue_host/docs/adoption-proof-matrix.md && ! rg -n "Stripe-only|remain Stripe-only" examples/accrue_host/README.md examples/accrue_host/docs/adoption-proof-matrix.md`
- Task 2 verifier passed: `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh`
- Bundle output:
  - `verify_processor_support_matrix: OK`
  - `package docs verified for accrue 1.0.0 and accrue_admin 1.0.0`
  - `verify_verify01_readme_contract: OK`
  - `verify_adoption_proof_matrix: OK`

## Task Commits

Each task was committed atomically:

1. **Task 1: Update example-host mirrors to the shipped support truth** - `0987b9e` (docs)
2. **Task 2: Update shift-left bash gates and contributor-map prose for the new wording** - `adc53d2` (docs)

## Files Created/Modified

- `examples/accrue_host/README.md` - removed stale Stripe-only support wording and clarified Stripe-hosted vs Braintree-mounted local URLs while preserving the proof/reference posture
- `examples/accrue_host/docs/adoption-proof-matrix.md` - aligned the proof taxonomy intro with the provider-honest checkout and portal contract
- `scripts/ci/README.md` - documented the same-PR co-update rule for support-contract mirrors and the four-script verifier bundle
- `scripts/ci/verify_package_docs.sh` - pinned the updated host README wording and rejects stale Stripe-only literals in the host docs
- `scripts/ci/verify_verify01_readme_contract.sh` - pins the provider-honest host README language and rejects stale Stripe-only wording
- `scripts/ci/verify_adoption_proof_matrix.sh` - pins the updated adoption-matrix provider wording and rejects stale Stripe-only wording
- `.planning/STATE.md` - advanced the active position from Plan 03 pending to Phase 109 complete / next-phase ready
- `.planning/ROADMAP.md` - marked Phase 109 complete in the active v1.35 phase table
- `.planning/REQUIREMENTS.md` - refreshed the milestone requirements timestamp after Phase 109 closeout

## Decisions Made

- Kept `examples/accrue_host` explicitly subordinate to package docs by describing it as proof/reference instead of turning it into the primary Braintree install guide.
- Treated the bash scripts as part of the product contract, not just CI glue, so wording changes in the host docs now require same-PR verifier changes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `gsd-sdk query` was not available in this environment, so `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` were updated directly to reflect plan completion.

## Known Stubs

None.

## Next Phase Readiness

- Phase 109 is complete; the active milestone can move to lifecycle semantics and operator-closure work in Phases 110 and 111.
- The support-contract wording is now aligned across package docs, host proof docs, and merge-blocking bash gates.

## Self-Check: PASSED

- Found `.planning/milestones/v1.35-phases/109-support-contract-truth/109-03-SUMMARY.md` on disk.
- Verified task commits `0987b9e` and `adc53d2` exist in git history.
