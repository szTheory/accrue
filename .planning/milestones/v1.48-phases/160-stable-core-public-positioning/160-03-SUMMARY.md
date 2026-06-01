---
phase: 160-stable-core-public-positioning
plan: "03"
subsystem: testing
tags: [stable-core, docs-contracts, ci, release-notes]
requires:
  - phase: 160-02
    provides: stable-core mirror surfaces and release-notes posture section
provides:
  - Dedicated stable-core posture verifier script
  - Release-notes posture token and canonical-guide pointer contract
  - Merge-blocking CI step and gate ownership/triage docs for POS-01..03
affects: [POS-03, docs-contracts-shift-left, scripts/ci]
tech-stack:
  added: []
  patterns: [bash-docs-contract, thin-mirror-posture-gate, ci-shift-left-verifier]
key-files:
  created:
    - scripts/ci/verify_stable_core_posture.sh
  modified:
    - scripts/ci/verify_release_notes_contract.sh
    - scripts/ci/README.md
    - .github/workflows/ci.yml
key-decisions:
  - "Kept stable-core posture verification in a dedicated script instead of overloading verify_package_docs.sh."
  - "Extended release-notes verification lightly (posture token + canonical guide pointer) to avoid turning release notes into static support SSOT."
  - "Used narrow literal/regex needles and explicit banned phrases for low-churn, explainable drift detection."
patterns-established:
  - "Dedicated posture gate pattern: one script with explicit prefix and helper trio (require_fixed/require_regex/require_absent_regex)."
  - "Gate registry mapping pattern: requirement IDs map directly to owning scripts and triage guidance."
requirements-completed: [POS-03]
duration: 18min
completed: 2026-05-31
---

# Phase 160 Plan 03: Stable-Core CI Contract Summary

**Shipped a dedicated stable-core posture drift gate and wired it into merge-blocking docs CI with explicit POS-01/POS-02/POS-03 ownership and triage.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-31T22:15:00Z
- **Completed:** 2026-05-31T22:33:00Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added [`scripts/ci/verify_stable_core_posture.sh`](/Users/jon/projects/accrue/scripts/ci/verify_stable_core_posture.sh) as the dedicated stable-core posture contract with narrow positive anchors and negative retired-term guards.
- Extended [`scripts/ci/verify_release_notes_contract.sh`](/Users/jon/projects/accrue/scripts/ci/verify_release_notes_contract.sh) with posture-token and canonical-guide pointer checks.
- Added a standalone `Stable-core posture contract` step in [`ci.yml`](/Users/jon/projects/accrue/.github/workflows/ci.yml) under `docs-contracts-shift-left`.
- Documented POS gate mapping and triage in [`scripts/ci/README.md`](/Users/jon/projects/accrue/scripts/ci/README.md).

## Task Commits

1. **Task 1: Create dedicated stable-core verifier and lightly extend release-notes contract** - `82adc2c4` (feat)
2. **Task 2: Wire verifier into CI and document gate ownership/triage** - `6cd5f631` (docs)

## Verification Evidence

- `bash -n scripts/ci/verify_stable_core_posture.sh` (pass)
- `bash -n scripts/ci/verify_release_notes_contract.sh` (pass)
- `bash scripts/ci/verify_stable_core_posture.sh` (pass)
- `bash scripts/ci/verify_release_notes_contract.sh` (pass)
- `bash scripts/ci/verify_package_docs.sh` (pass)
- `bash scripts/ci/verify_processor_support_matrix.sh` (pass)
- `bash scripts/ci/verify_adoption_proof_matrix.sh` (pass)
- `actionlint .github/workflows/ci.yml` (pass)
- `rg -n 'POS-01|POS-02|POS-03|verify_stable_core_posture|Stable-core posture contract' scripts/ci/README.md .github/workflows/ci.yml` (pass)

## Files Created/Modified

- `scripts/ci/verify_stable_core_posture.sh` - New dedicated stable-core posture verifier with narrow anchor checks and retired-phrase guards.
- `scripts/ci/verify_release_notes_contract.sh` - Added posture token and canonical-guide pointer checks.
- `scripts/ci/README.md` - Added POS-01..03 gate mapping, stable-core triage section, and support-contract bundle update.
- `.github/workflows/ci.yml` - Added standalone `Stable-core posture contract` step; quoted one existing step name to satisfy YAML linting.

## Decisions Made

- Kept posture checks in a dedicated script to preserve ownership clarity and avoid contract sprawl in `verify_package_docs.sh`.
- Kept release-notes posture checks lightweight and pointer-based, preserving release notes as change narrative instead of support contract SSOT.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed workflow YAML lint blocker**
- **Found during:** Task 2 verification
- **Issue:** `actionlint` failed on an existing unquoted step name containing `:`.
- **Fix:** Quoted step name `Verify ExDoc @doc since: badges` in `.github/workflows/ci.yml`.
- **Files modified:** `.github/workflows/ci.yml`
- **Verification:** `actionlint .github/workflows/ci.yml` passed.
- **Committed in:** `6cd5f631` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking)
**Impact on plan:** No scope change; fix was required to satisfy mandatory workflow verification.

## Issues Encountered

- Initial strict fixed-string check for `stable-core posture` in release notes failed because existing canonical text uses `stable-core / demand-driven expansion posture`; verifier updated to narrow regex while preserving intent.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- POS-03 executable drift contract is now merge-blocking in docs CI.
- Stable-core posture surfaces now have explicit script ownership and triage guidance.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/160-stable-core-public-positioning/160-03-SUMMARY.md`.
- Referenced commits exist in git history: `82adc2c4`, `6cd5f631`.
