---
phase: 12-first-user-dx-stabilization
plan: 10
subsystem: docs
tags: [docs, verification, ci, exunit, guides, shell]
requires:
  - phase: 12-first-user-dx-stabilization
    provides: "Host-first guide contracts and strict package-doc verification baseline from plans 12-06 and 12-07"
provides:
  - "Published First Hour and troubleshooting guides now document :webhook_signing_secrets with the runtime map shape"
  - "Guide contract tests lock the webhook signing config wording to the plural runtime key"
  - "verify_package_docs.sh rejects singular webhook secret drift in both published guides"
affects: [phase-12, phase-13, docs, package-verification]
tech-stack:
  added: []
  patterns: ["Guide contracts assert exact runtime config snippets", "Shell verifier checks both presence of required docs text and absence of forbidden drift"]
key-files:
  created: []
  modified:
    - accrue/guides/first_hour.md
    - accrue/guides/troubleshooting.md
    - accrue/test/accrue/docs/first_hour_guide_test.exs
    - accrue/test/accrue/docs/troubleshooting_guide_test.exs
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
key-decisions:
  - "Keep the webhook docs contract executable by asserting the exact plural runtime key and Stripe example in both guide tests."
  - "Extend the shell verifier with explicit plural-key presence and singular-key absence checks for both published guides."
  - "Add a ROOT_DIR override to the shell verifier so ExUnit can exercise drift failures against a temporary copied docs tree."
patterns-established:
  - "Docs drift checks should fail on forbidden stale config keys, not just verify expected prose exists."
  - "Verifier wrappers can prove shell-script failure modes by running the script against isolated temp fixtures."
requirements-completed: [DX-03, DX-04, DX-06]
duration: 17 min
completed: 2026-04-16
---

# Phase 12 Plan 10: Gap-closure Summary

**Webhook setup docs now teach `:webhook_signing_secrets`, and the package-doc verifier blocks singular-key regressions in published guides**

## Performance

- **Duration:** 17 min
- **Started:** 2026-04-16T22:33:00Z
- **Completed:** 2026-04-16T22:49:41Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Corrected the First Hour and troubleshooting guides to use the real runtime key `:webhook_signing_secrets` with the documented Stripe example.
- Tightened the guide contract tests so they assert the plural-key snippet and reject standalone singular-key drift.
- Extended `scripts/ci/verify_package_docs.sh` so CI now checks both published guides for the required plural snippet and fails when the singular key reappears.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix the published guide snippets to use `:webhook_signing_secrets`** - `4e3e8ec` (test), `e40cc9e` (fix)
2. **Task 2: Extend the strict docs verifier to fail on singular webhook secret drift** - `f12c72d` (test), `bbf3e1f` (fix)

## Files Created/Modified
- `accrue/guides/first_hour.md` - Replaced the stale singular webhook config with the plural runtime map example.
- `accrue/guides/troubleshooting.md` - Updated the `ACCRUE-DX-WEBHOOK-SECRET-MISSING` remediation text and added a concrete plural-key fix block.
- `accrue/test/accrue/docs/first_hour_guide_test.exs` - Added executable assertions for the plural webhook config snippet and singular-key rejection.
- `accrue/test/accrue/docs/troubleshooting_guide_test.exs` - Locked the troubleshooting remediation text to the plural webhook config contract.
- `scripts/ci/verify_package_docs.sh` - Added explicit guide checks for plural-key presence and singular-key absence, with `ROOT_DIR` override support for isolated verification.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Added regression coverage proving the verifier fails against a copied guide tree that drifts back to the singular key.

## Decisions Made
- Used exact-string guide assertions for the runtime config snippet so the published setup path cannot drift away from the code contract silently.
- Kept the docs verifier grep-based and strict, matching the plan requirement to make the guard shell-visible and CI-friendly.
- Added a `ROOT_DIR` environment override instead of hardcoding repo paths in the test, so the verifier can be exercised against temporary fixtures without weakening production behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Tightened singular-key rejection to avoid false failures on the plural key**
- **Found during:** Task 1 (Fix the published guide snippets to use `:webhook_signing_secrets`)
- **Issue:** The first negative test used a plain substring check, which also matched the valid plural key `webhook_signing_secrets`.
- **Fix:** Replaced the substring check with a regex that rejects only the standalone singular key.
- **Files modified:** `accrue/test/accrue/docs/first_hour_guide_test.exs`, `accrue/test/accrue/docs/troubleshooting_guide_test.exs`
- **Verification:** `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs`
- **Committed in:** `e40cc9e`

**2. [Rule 3 - Blocking] Added verifier root override so the shell script could be regression-tested against copied docs**
- **Found during:** Task 2 (Extend the strict docs verifier to fail on singular webhook secret drift)
- **Issue:** The ExUnit regression test needed to run the verifier against a temporary copied docs tree, but the script hardcoded the repo root from its own path.
- **Fix:** Added `ROOT_DIR` override support while preserving the existing repo-root default behavior.
- **Files modified:** `scripts/ci/verify_package_docs.sh`
- **Verification:** `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs`
- **Committed in:** `bbf3e1f`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were required to make the new regression coverage reliable. No scope creep beyond the requested docs-verification hardening.

## Issues Encountered
- The initial standalone-singular rejection used a naive substring match, which also matched the valid plural key.
- The shell verifier exited early under `set -e` until the absence check was rewritten with an explicit `if grep ...; then fail; fi` form.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness
- Phase 12 now closes the remaining docs/runtime drift flagged by verification and review.
- Phase 13 can build adoption assets on top of a host-first setup path that matches the runtime contract and is guarded by CI.

## Self-Check: PASSED

- Found `.planning/phases/12-first-user-dx-stabilization/12-10-SUMMARY.md`
- Found commit `4e3e8ec`
- Found commit `e40cc9e`
- Found commit `f12c72d`
- Found commit `bbf3e1f`
