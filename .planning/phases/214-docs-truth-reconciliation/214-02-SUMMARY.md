---
phase: 214-docs-truth-reconciliation
plan: "02"
subsystem: docs
tags: [release-notes, changelog, exdoc, lattice_stripe, entitlements]
requires:
  - phase: 214-docs-truth-reconciliation
    provides: Plan 01 current-truth documentation and advisory sync boundary contract
  - phase: 213-stripe-native-advisory-entitlements-sync-observational-only
    provides: optional default-off advisory Stripe-native entitlement refresh with isolation proof
provides:
  - package-owned Unreleased truth across accrue, accrue_admin, and accrue_portal
  - linked plain-language next-release 1.5.0 story with three package changelog discovery
  - exact @doc since metadata for the four supported Phase 213 public contract surfaces
  - release-note and package-doc verifier regressions for ownership, discoverability, stale metadata, and internal over-badging
affects: [release-notes, package-docs, changelog, exdoc, entitlements, phase-214]
tech-stack:
  added: []
  patterns:
    - ROOT_DIR-backed negative docs fixtures for package release truth
    - shell verifier line-aware metadata placement checks
key-files:
  created:
    - .planning/phases/214-docs-truth-reconciliation/214-02-SUMMARY.md
  modified:
    - accrue/CHANGELOG.md
    - accrue_admin/CHANGELOG.md
    - accrue_portal/CHANGELOG.md
    - accrue/guides/release-notes.md
    - scripts/ci/verify_release_notes_contract.sh
    - accrue/test/accrue/docs/release_notes_contract_test.exs
    - accrue/lib/accrue/entitlements/stripe_sync.ex
    - accrue/lib/accrue/processor.ex
    - accrue/lib/accrue/processor/fake.ex
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
key-decisions:
  - "Release Please remains the only writer for numbered package changelog sections and package @version values; main carries only Unreleased and hand-authored next-release prose."
  - "Admin and portal changelog entries are compatibility-only; substantive advisory sync capability belongs to the core accrue changelog."
  - "Exactly StripeSync.refresh/2, Processor.list_active_entitlements/2 callback, Processor.list_active_entitlements/2 facade, and Processor.Fake.put_entitlements/2 carry since 1.5.0 metadata."
patterns-established:
  - "Release-note verifier checks current package changelog ownership and next-release discovery without deriving the next story from current @version."
  - "Package-doc verifier enforces supported @doc since metadata with immediate-predecessor checks and separate internal-surface exclusions."
requirements-completed: [DOCS-03]
coverage:
  - id: D1
    description: "Core, admin, and portal changelogs have scoped Unreleased entries while package versions and numbered release sections remain Release Please-owned."
    requirement: DOCS-03
    verification:
      - kind: other
        ref: "cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_release_notes_contract.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Plain-language release notes link all three package changelogs and describe the next linked 1.5.0 release as core capability plus admin/portal compatibility."
    requirement: DOCS-03
    verification:
      - kind: other
        ref: "bash scripts/ci/verify_release_notes_contract.sh"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exactly the four supported Phase 213 public contract surfaces carry @doc since: \"1.5.0\" while internal plumbing remains unbadged."
    requirement: DOCS-03
    verification:
      - kind: other
        ref: "cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_package_docs.sh"
        status: pass
      - kind: other
        ref: "cd accrue && mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-07-31
status: complete
---

# Phase 214 Plan 02: Release Truth and ExDoc Metadata Summary

**Linked package release truth now describes the next 1.5.0 advisory sync release without changing package versions, and ExDoc availability metadata is exact on the four supported public surfaces.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-31T03:47:39Z
- **Completed:** 2026-07-31T03:58:55Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added scoped `## Unreleased` entries to all three package changelogs: core owns the substantive `lattice_stripe ~> 2.0` and advisory-sync story; admin and portal are compatibility-only.
- Added the portal changelog link and hand-authored next-release `1.5.0` story to `accrue/guides/release-notes.md`.
- Updated `@doc since: "1.5.0"` on exactly `StripeSync.refresh/2`, both `Processor.list_active_entitlements/2` rendered surfaces, and `Processor.Fake.put_entitlements/2`.
- Extended the release-note and package-doc verifier suites with failing fixtures for missing/misplaced Unreleased sections, package ownership inversions, manual numbered changelog sections, missing portal discovery, missing next-release truth, stale/missing supported metadata, and internal over-badging.

## Task Commits

1. **Task 1 RED: changelog ownership fixtures** - `32e69040` (test)
2. **Task 1 GREEN: package-owned Unreleased truth** - `9957d3ae` (feat)
3. **Task 2 RED: next-release discoverability fixtures** - `fda441a6` (test)
4. **Task 2 GREEN: linked next-release story** - `4bed566d` (feat)
5. **Task 3 RED: ExDoc metadata fixtures** - `302e7fdd` (test)
6. **Task 3 GREEN: supported since metadata** - `b33c0924` (feat)

## Files Created/Modified

- `accrue/CHANGELOG.md` - substantive core Unreleased entry for the 2.x bump, advisory refresh, supported contracts, isolation proof, and closed `fetch_entitled/2` decision.
- `accrue_admin/CHANGELOG.md` - compatibility-only linked-release Unreleased note.
- `accrue_portal/CHANGELOG.md` - compatibility-only linked-release Unreleased note.
- `accrue/guides/release-notes.md` - portal changelog link and next-release `1.5.0` story.
- `scripts/ci/verify_release_notes_contract.sh` - changelog ownership, Release Please boundary, portal-link, and next-release verifier checks.
- `accrue/test/accrue/docs/release_notes_contract_test.exs` - ROOT_DIR-backed negative release-note fixtures.
- `accrue/lib/accrue/entitlements/stripe_sync.ex` - `refresh/2` since metadata corrected to `1.5.0`.
- `accrue/lib/accrue/processor.ex` - since metadata on the optional callback and public facade.
- `accrue/lib/accrue/processor/fake.ex` - since metadata on the deterministic entitlement seeding test helper.
- `scripts/ci/verify_package_docs.sh` - exact supported metadata and internal exclusion checks.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - stale/missing/over-badged metadata fixtures and expanded fixture seed.
- `.planning/phases/214-docs-truth-reconciliation/214-02-SUMMARY.md` - execution summary.

## Decisions Made

- Release Please remains the sole writer of numbered package changelog sections and package `@version` values.
- `accrue_admin` and `accrue_portal` release prose stays compatibility-only for this slice.
- The package-doc verifier checks `since` placement adjacent to specs/callbacks instead of relying only on broad grep counts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed shell verifier Markdown backtick command substitution**
- **Found during:** Task 1
- **Issue:** Backticks inside double-quoted verifier needles were interpreted by bash.
- **Fix:** Split those checks into plain fixed tokens with no command substitution hazard.
- **Files modified:** `scripts/ci/verify_release_notes_contract.sh`
- **Verification:** `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs` passed.
- **Committed in:** `9957d3ae`

**2. [Rule 1 - Bug] Routed missing changelog headings through the stable failure prefix**
- **Found during:** Task 1
- **Issue:** `grep` under `set -euo pipefail` exited before the verifier's `fail()` helper on missing headings.
- **Fix:** Made the line-number helper return an empty value and let the explicit assertion fail.
- **Files modified:** `scripts/ci/verify_release_notes_contract.sh`
- **Verification:** `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs` passed.
- **Committed in:** `9957d3ae`

**3. [Rule 1 - Bug] Made metadata verifier failures surface-specific**
- **Found during:** Task 3
- **Issue:** Stale metadata failed a generic count check before the labelled public-surface check.
- **Fix:** Reordered the verifier checks and added a line-aware no-since helper for internal specs.
- **Files modified:** `scripts/ci/verify_package_docs.sh`
- **Verification:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` passed.
- **Committed in:** `b33c0924`

---

**Total deviations:** 3 auto-fixed (Rule 1 bugs)
**Impact on plan:** All fixes tightened the planned verifier behavior; no scope expansion or runtime behavior change.

## Issues Encountered

- The repository had a pre-existing dirty change in `.planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-REVIEW.md`; it was preserved and excluded from all commits.
- The package-doc focused suite takes about 30 seconds because its ROOT_DIR-backed verifier fixtures exercise many existing documentation guards.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs` - pass, 7 tests, 0 failures.
- `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` - pass, 42 tests, 0 failures.
- `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs test/accrue/docs/package_docs_verifier_test.exs` - pass, 49 tests, 0 failures.
- `cd accrue && mix compile --warnings-as-errors` - pass.
- `bash scripts/ci/verify_release_notes_contract.sh` - pass.
- `bash scripts/ci/verify_package_docs.sh` - pass.
- `bash scripts/ci/verify_processor_support_matrix.sh` - pass.
- `bash scripts/ci/verify_entitlement_sync_isolation.sh` - pass.
- `git diff --check -- [plan files]` - pass.
- Scoped cold-read grep over current docs/changelogs/metadata surfaces - pass; the only `1.5.0` heading hit is the intended hand-authored release-note story, and exactly four supported surfaces carry `@doc since: "1.5.0"`.

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

DOCS-03 is complete. Phase 214 has both plans summarized and the current release/docs truth contract is verifier-backed across package changelogs, release notes, public metadata, support/adoption mirrors, and active planning state.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/214-docs-truth-reconciliation/214-02-SUMMARY.md`.
- Task commits exist: `32e69040`, `9957d3ae`, `fda441a6`, `4bed566d`, `302e7fdd`, `b33c0924`.
- Key files exist and the out-of-scope Phase 213 review edit remains unstaged.

---
*Phase: 214-docs-truth-reconciliation*
*Completed: 2026-07-31*
