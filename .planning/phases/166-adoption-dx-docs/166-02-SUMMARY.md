---
phase: 166-adoption-dx-docs
plan: 02
subsystem: docs
tags: [readme, docker, adoption-dx, docs-contract]
requires:
  - phase: 166-01
    provides: Docker-aware Phoenix endpoint bind for localhost evaluator path
provides:
  - Docker-first Start Here flow for the host demo
  - Native Phoenix fallback and Accrue.Auth trust-boundary handoffs below the first run path
affects: [examples/accrue_host, public-guides, package-readmes]
tech-stack:
  added: []
  patterns:
    - Docker is the primary evaluator path; native Phoenix remains the contributor path.
key-files:
  created: []
  modified:
    - examples/accrue_host/README.md
    - accrue/README.md
    - accrue_admin/README.md
    - accrue/guides/first_hour.md
key-decisions:
  - "Place Start Here before prerequisites so evaluators can boot and inspect the realistic demo before reading caveats."
  - "Keep Sigra framed as demo infrastructure and production integration framed through host-owned Accrue.Auth."
patterns-established:
  - "Host README first screen is now persona, Docker command, localhost destination, walkthrough, focused proof."
requirements-completed: [DOC-01, DOC-02, DOC-03]
duration: 4 min
completed: 2026-06-02
---

# Phase 166 Plan 02: Host README Start Here Summary

**Docker-first host README flow now leads evaluators from localhost boot to Fake-backed billing inspection**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-02T07:41:00Z
- **Completed:** 2026-06-02T07:45:10Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `## Start Here` near the top of `examples/accrue_host/README.md`, before prerequisites and caveat-heavy support detail.
- Made Docker the primary evaluator path with `docker compose up --build`, `http://localhost:4000`, `/app/billing`, `/billing`, `Accrue.Processor.Fake`, and `mix verify`.
- Preserved the existing `## First run` native Phoenix spine, capsule headings, manifest-backed command order, PGHOST footguns, and non-Sigra `Accrue.Auth` / First Hour / Organization billing handoffs.

## Task Commits

Each task was committed atomically:

1. **Tasks 1-2: Add Start Here and preserve trust-boundary handoffs** - `678baf15` (docs)

**Plan metadata:** committed during closeout.

## Files Created/Modified

- `examples/accrue_host/README.md` - Adds Docker-first Start Here, native fallback, trust boundary, and Docker footguns.
- `accrue/README.md` - Updates the package install pin to match `accrue/mix.exs`.
- `accrue_admin/README.md` - Updates the package install/dependency pins to match `accrue_admin/mix.exs`.
- `accrue/guides/first_hour.md` - Updates package pins so the docs verifier remains aligned with package versions.

## Decisions Made

- Kept `mix verify.full`, Playwright, and CI wrapper detail below the first-run path so the top of the README stays evaluator-focused.
- Treated `docker compose down --volumes` as reset guidance, not normal stop guidance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Package docs version pins lagged package mix versions**
- **Found during:** Task 2 (`bash scripts/ci/verify_package_docs.sh`)
- **Issue:** The docs verifier required `1.4.0` pins from `accrue/mix.exs` and `accrue_admin/mix.exs`, but package docs still showed `1.3.0`.
- **Fix:** Updated only package version pins in `accrue/README.md`, `accrue_admin/README.md`, and `accrue/guides/first_hour.md`.
- **Files modified:** `accrue/README.md`, `accrue_admin/README.md`, `accrue/guides/first_hour.md`
- **Verification:** `bash scripts/ci/verify_package_docs.sh` passed.
- **Committed in:** `678baf15`

---

**Total deviations:** 1 auto-fixed (missing critical)
**Impact on plan:** The fix was required to run the planned docs verifier and did not change runtime behavior.

## Issues Encountered

None beyond the auto-fixed docs-contract drift above.

## Verification

- README Start Here grep checks -> passed
- Start Here before Prerequisites and no CI wrapper before first `mix verify.full` -> passed
- `bash scripts/ci/verify_package_docs.sh` -> passed
- `cd examples/accrue_host && MIX_ENV=test mix test test/demo/command_manifest_test.exs` -> passed
- `cd accrue && MIX_ENV=test mix test test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` -> passed
- `git diff --check -- examples/accrue_host/README.md accrue/README.md accrue_admin/README.md accrue/guides/first_hour.md` -> passed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 3 can reorganize the proof-depth documentation and pin the new Start Here claims in `verify_package_docs.sh`.

## Self-Check: PASSED

---
*Phase: 166-adoption-dx-docs*
*Completed: 2026-06-02*
