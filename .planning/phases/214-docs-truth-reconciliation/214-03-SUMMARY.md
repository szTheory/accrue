---
phase: 214-docs-truth-reconciliation
plan: "03"
subsystem: docs
tags: [release-please, semver, changelog, contract-tests, release-notes]
requires:
  - phase: 214-docs-truth-reconciliation
    provides: current release-note truth and linked 1.5.0 release story
provides:
  - state-aware release-note verification for checked-in and aligned Release Please candidate states
  - negative regression coverage for malformed, mismatched, incomplete, and ownership-inverted release states
  - restored Stripe-first gateway-strategy compatibility invariant
affects: [release-notes, package-docs, changelog, release-please, phase-214]
tech-stack:
  added: []
  patterns:
    - ROOT_DIR-backed isolated release-state contract fixtures
    - stable SemVer validation before changelog-section selection
key-files:
  created:
    - .planning/phases/214-docs-truth-reconciliation/214-03-SUMMARY.md
  modified:
    - scripts/ci/verify_release_notes_contract.sh
    - accrue/test/accrue/docs/release_notes_contract_test.exs
    - .planning/STRATEGY.md
    - .planning/PROJECT.md
key-decisions:
  - "A linked Release Please 1.5.0 candidate is valid only after all package versions are stable SemVer, equal, and backed by matching package-local numbered sections."
  - "Verification and UAT default to executable evidence; credentials and irreversible publishing remain authorization gates."
  - "PROC-08 remains a bounded Stripe-first gateway foundation while v1.59 rail work stays separate."
patterns-established:
  - "Release candidate negatives mutate one isolated ROOT_DIR fixture invariant at a time and assert stable verifier diagnostics."
requirements-completed: [DOCS-03]
coverage:
  - id: D1
    description: "The release-note contract accepts both the checked-in 1.4.0 pre-release state and an aligned Release Please 1.5.0 candidate."
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs"
        status: pass
      - kind: integration
        ref: "bash scripts/ci/verify_release_notes_contract.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Malformed, mismatched, incomplete, prematurely numbered, and ownership-inverted release fixtures fail through the production verifier with bounded diagnostics."
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "accrue/test/accrue/docs/release_notes_contract_test.exs#negative candidate fixtures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Package documentation, support matrix, and entitlement-isolation compatibility gates remain green after the release-contract correction."
    requirement: DOCS-03
    verification:
      - kind: integration
        ref: "bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_entitlement_sync_isolation.sh"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-07-31
status: complete
---

# Phase 214 Plan 03: Release-State Contract Hardening Summary

**The release gate now accepts the checked-in 1.4.0 pre-release and a fully aligned Release Please 1.5.0 candidate while rejecting unsafe version, section, and ownership drift.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-07-31T14:18:07Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Proved the shared verifier accepts both intended linked release states without changing the live package versions or changelogs.
- Added isolated negative fixtures for version divergence, malformed SemVer, missing candidate sections, and core/companion ownership inversions; existing fixtures retain premature-numbering and spaced-`ROOT_DIR` coverage.
- Restored the `Stripe-first` PROC-08 compatibility statement required by the package-doc contract and recorded an executable-first verification posture.

## Task Commits

1. **Task 1 RED: Release Please candidate fixture** - `96ba55e0` (test)
2. **Task 1 GREEN: State-aware release verifier** - `93293c96` (feat)
3. **Task 2: Invalid release-state regressions** - `cdaefc85` (test)
4. **Integration fix: Gateway strategy compatibility invariant** - `ec81907b` (fix)

## Files Created/Modified

- `scripts/ci/verify_release_notes_contract.sh` - validates stable aligned versions, selects pre-release versus candidate changelog sections, and retains Release Please ownership rules.
- `accrue/test/accrue/docs/release_notes_contract_test.exs` - runs the valid candidate and isolated unsafe-state fixture family through the production script.
- `.planning/STRATEGY.md` - restores the accurate Stripe-first PROC-08 gateway-foundation statement.
- `.planning/PROJECT.md` - records default executable verification/UAT and authorization-gate boundaries.

## Decisions Made

- Candidate release validation uses only quoted fixed paths below `ROOT_DIR`; version text must be stable SemVer before it selects a changelog section.
- No workflow auto-advance was enabled, and no Phase 215 work was started.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Integration drift] Restored the required Stripe-first strategy compatibility statement**
- **Found during:** Post-Task 2 integration verification
- **Issue:** `verify_package_docs.sh` correctly rejected `.planning/STRATEGY.md` after a prior edit removed its required `Stripe-first` invariant.
- **Fix:** Restored the accurate statement at the PROC-08 bounded gateway-foundation outcome and recorded the durable zero-human verification preference in project context.
- **Files modified:** `.planning/STRATEGY.md`, `.planning/PROJECT.md`
- **Verification:** `bash scripts/ci/verify_package_docs.sh` passed, followed by the complete five-gate bundle.
- **Committed in:** `ec81907b`

---

**Total deviations:** 1 auto-fixed integration issue
**Impact on plan:** The fix restored an existing contract without weakening its guard or expanding product scope.

## Verification

- `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs` - pass, 12 tests, 0 failures.
- `bash scripts/ci/verify_release_notes_contract.sh` - pass.
- `bash scripts/ci/verify_package_docs.sh` - pass.
- `bash scripts/ci/verify_processor_support_matrix.sh` - pass.
- `bash scripts/ci/verify_entitlement_sync_isolation.sh` - pass.

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

DOCS-03 is verifier-backed for current and generated candidate release states. Phase 214 is ready for its closeout workflow; Phase 215 remains queued.

## Self-Check: PASSED

- Summary path exists and task commits `96ba55e0`, `93293c96`, `cdaefc85`, and `ec81907b` exist in git history.
- The Phase 213 review modification remains unstaged and excluded from this plan's commits.

---
*Phase: 214-docs-truth-reconciliation*
*Completed: 2026-07-31*
