---
phase: 166-adoption-dx-docs
plan: 03
subsystem: docs
tags: [readme, proof-ladder, ci, docs-contract]
requires:
  - phase: 166-02
    provides: Docker-first Start Here host README flow
provides:
  - Compact host README proof ladder
  - Shift-left verifier pins for Start Here Docker claims
affects: [examples/accrue_host, scripts-ci, adoption-proof]
tech-stack:
  added: []
  patterns:
    - README proof depth separates exploration, focused local proof, full local gate, CI wrapper, maintainer contracts, and provider parity.
key-files:
  created: []
  modified:
    - examples/accrue_host/README.md
    - scripts/ci/verify_package_docs.sh
key-decisions:
  - "Keep command names unchanged while explaining which confidence level each command proves."
  - "Pin Start Here claims in the package docs verifier without adding inline support-bundle inventory to the README."
patterns-established:
  - "Host README links deeper docs by intent instead of front-loading CI internals before first run."
requirements-completed: [DOC-01, DOC-02, DOC-03]
duration: 3 min
completed: 2026-06-02
---

# Phase 166 Plan 03: Proof Ladder and Docs Contract Summary

**Host README proof depth now maps each command to its confidence level, with Start Here claims shift-left protected**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-02T07:45:20Z
- **Completed:** 2026-06-02T07:48:30Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Reorganized `## Proof and verification` into a compact ladder: Explore, Focused proof, Full local gate, CI wrapper, Maintainer contracts, and Provider parity.
- Kept existing command names unchanged: `docker compose up --build`, `mix verify`, `mix verify.full`, `bash scripts/ci/accrue_host_uat.sh`, `scripts/ci/README.md`, and live Stripe parity wording.
- Added package-doc verifier pins for `## Start Here`, `docker compose up --build`, `http://localhost:4000`, and `Accrue.Processor.Fake`.

## Task Commits

Each task was committed atomically:

1. **Tasks 1-3: Add proof ladder, pin Start Here contract, run docs bundle** - `e32ccb5f` (docs)

**Plan metadata:** committed during closeout.

## Files Created/Modified

- `examples/accrue_host/README.md` - Moves proof-depth explanation near the happy path and defines each proof lane precisely.
- `scripts/ci/verify_package_docs.sh` - Adds Start Here/Docker/Fake needles for the host README.

## Decisions Made

- Kept full support-contract bundle membership in `scripts/ci/README.md` rather than copying verifier inventory into the host README.
- Left `verify_verify01_readme_contract.sh` unchanged because the existing VERIFY-01 pinned substrings still passed after the README reorganization.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- Proof ladder label grep checks -> passed
- Start Here verifier needle grep checks in `scripts/ci/verify_package_docs.sh` -> passed
- `bash scripts/ci/verify_package_docs.sh` -> passed
- `bash scripts/ci/verify_verify01_readme_contract.sh` -> passed
- `bash scripts/ci/verify_adoption_proof_matrix.sh` -> passed
- `cd examples/accrue_host && MIX_ENV=test mix test test/demo/command_manifest_test.exs` -> passed
- `cd accrue && MIX_ENV=test mix test test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` -> passed
- `git diff --check -- examples/accrue_host/README.md scripts/ci/verify_package_docs.sh` -> passed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All Phase 166 plans now have summaries. Phase 166 is ready for phase-level verification.

## Self-Check: PASSED

---
*Phase: 166-adoption-dx-docs*
*Completed: 2026-06-02*
