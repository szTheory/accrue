---
phase: 174-a-design-system-gap-closure-token-completeness
plan: "06"
subsystem: testing
tags: [elixir, exunit, ci, verify_package_docs, package-docs-verifier, adoption-proof-matrix]

requires:
  - phase: 174-05
    provides: verify_package_docs.sh require_absent_regex guard for adoption-proof-matrix.md (line 304)

provides:
  - seed_tmp_dir! now copies examples/accrue_host/docs/adoption-proof-matrix.md into every negative test's tmp directory
  - Negative test that enforces the Stripe-only regex guard is caught by CI — not just by manual script execution

affects:
  - PackageDocsVerifierTest — test count is now 10 (was 9)
  - CI: the require_absent_regex guard for adoption-proof-matrix.md is now regression-tested

tech-stack:
  added: []
  patterns:
    - "Coupling invariant: when a new doc-file needle is added to verify_package_docs.sh, seed_tmp_dir! must also be updated — gap DSY-01 now closed"

key-files:
  created: []
  modified:
    - accrue/test/accrue/docs/package_docs_verifier_test.exs

key-decisions:
  - "Add both mkdir_p! for examples/accrue_host/docs and copy_fixture! for adoption-proof-matrix.md per DSY-01 gap spec, even though copy_fixture! already calls mkdir_p! internally"
  - "Inject Stripe-only (not remain Stripe-only) — simpler string that still matches the regex guard"

patterns-established:
  - "Every require_absent_regex guard in verify_package_docs.sh must have a corresponding negative test that seeds the guarded file and injects the forbidden pattern"

requirements-completed:
  - DSY-01

duration: 5min
completed: 2026-06-04
---

# Phase 174 Plan 06: Design-System Gap Closure — Package Docs Verifier (DSY-01) Summary

**PackageDocsVerifierTest now seeds adoption-proof-matrix.md in every tmp dir, and a dedicated negative test confirms the require_absent_regex guard fires on Stripe-only injection — closing the silent-pass bug in CI.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-04T21:55:00Z
- **Completed:** 2026-06-04T22:00:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `File.mkdir_p!` for `examples/accrue_host/docs` in `seed_tmp_dir!`
- Added `copy_fixture!("examples/accrue_host/docs/adoption-proof-matrix.md", tmp_dir)` to ensure the file is present in every seeded tmp directory
- Added 10th negative test: "package docs verifier rejects Stripe-only language in adoption-proof-matrix.md" — seeds the file, appends "This is Stripe-only content.", asserts the verifier exits non-zero and output references "adoption-proof-matrix.md"
- All 10 tests pass; real-repo `bash scripts/ci/verify_package_docs.sh` still exits 0

## Task Commits

1. **Task 1: Add adoption-proof-matrix.md to seed_tmp_dir! and add Stripe-only negative test** - `d179c305` (fix)

## Files Created/Modified

- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — +28 lines: mkdir_p! for docs subdir, copy_fixture! for adoption-proof-matrix.md, new Stripe-only negative test

## Decisions Made

- Add explicit `mkdir_p!` for `examples/accrue_host/docs` as specified by the gap, even though `copy_fixture!` already calls it internally — harmless redundancy that matches the gap contract exactly.
- Inject "Stripe-only" (not "remain Stripe-only") — simpler, still triggers the `'Stripe-only|remain Stripe-only'` regex.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- DSY-01 fully closed: the silent-pass where grep exits code 2 (file not found) would cause the guard to silently pass is now prevented by seeding the file.
- Phase 174 all plans complete; proceed to phase-level verification.

---
*Phase: 174-a-design-system-gap-closure-token-completeness*
*Completed: 2026-06-04*
