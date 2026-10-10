---
phase: 242-investigations-and-remaining-admin-surfaces
plan: 03
subsystem: ui
tags: [phoenix-liveview, coupons, promotion-codes, scoped-path, catalog-copy]
requires:
  - phase: 242-01
    provides: ScopedPath return validation and family filter normalization
provides:
  - Coupon and promotion-code details retain validated list context and exact relationship identity
  - Catalog copy describes missing limits and restrictions as unrecorded rather than unlimited
affects: [242-06, 242-07, coupon-operations, promotion-code-operations]
actuals:
  tokens: 6579
  tasks: 3
  commits: 3
commits: 3
plan_head_before: 803c808b20e2b7113aa0bee6fb7481df4f69576c
plan_head_after: 72aa63c54dc67ac2e8884c4d8a0af5661d93dea5
tech-stack:
  added: []
  patterns:
    - Rebuild validated catalog return destinations with the current admin route context
    - Require exact foreign-key identity before showing parent catalog navigation
    - Preserve zero values while representing nullable limits as not recorded
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/lib/accrue_admin/copy/coupon.ex
    - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
    - accrue_admin/lib/accrue_admin/scoped_path.ex
    - accrue_admin/test/accrue_admin/scoped_path_test.exs
key-decisions:
  - "Keep the incumbent global catalog data model; these schemas have no owner fields, so describe route/session context only where supported and make no tenant-filtered membership claim."
  - "Keep Copy.Locked and provider/API diagnostics unchanged; nullable catalog limits and restrictions are unknown unless explicit values are present."
requirements-completed: [JRN-06, UXC-01]
coverage:
  - id: D1
    description: "Coupon list context survives detail navigation and returns through validated query/lens filters; child promotion-code links filter by the exact coupon ID."
    requirement: JRN-06
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs — 35 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Promotion-code returns preserve validated list filters; only the exact loaded parent identity is linked, and an unlinked code has no substitute parent link."
    requirement: JRN-06
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs — 18 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Coupon and promotion-code surfaces preserve explicit zero counts/limits and label missing limits and unsupported restriction facts as unrecorded."
    requirement: UXC-01
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs — 55 tests, 0 failures"
        status: pass
    human_judgment: false
metrics:
  duration: 14min
  completed: 2026-10-10
status: complete
human_judgment: false
---

# Phase 242 Plan 03: Coupon and Promotion-Code Catalog Summary

**Coupon and promotion-code navigation now preserves validated filter context and exact parent identity, while nullable limits and restrictions read as unknown instead of unlimited.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-10T12:59:13Z
- **Completed:** 2026-10-10T13:12:54Z
- **Tasks:** 3/3
- **Files modified:** 12, including the authorized shared ScopedPath helper and regression test.

## Accomplishments

- Coupon details return to the validated coupon list context. Related code links carry the exact coupon ID filter, and code rows from another coupon are not shown.
- Promotion-code details return to validated list filters and expose a coupon destination only when the loaded coupon ID exactly equals the promotion code's `coupon_id`. A code with no parent ID remains explicitly unlinked.
- Nullable maximum redemptions and unrepresented restriction facts now say “not recorded.” Explicit zero counts and zero limits remain zero. Unknown activity state is not rendered as inactive.
- The existing global catalog model has no coupon or promotion-code owner fields. Route/session scope is described only where supported; these changes do not claim tenant-filtered catalog membership or expand the schema.

## Task Commits

1. **Task 1: Carry coupon context into definition and child-code views** — `ff2b7a68` (`feat`)
2. **Task 2: Preserve promotion-code identity and exact parent return** — `6919558d` (`feat`)
3. **Task 3: Reconcile catalog words at existing Copy owners** — `72aa63c5` (`fix`)

## Verification Results

- Task 1 plus ScopedPath regression: `MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs` — **35 tests, 0 failures**.
- Task 2: `MIX_ENV=test mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` — **18 tests, 0 failures**.
- Final combined focused run: `MIX_ENV=test mix test test/accrue_admin/scoped_path_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` — **55 tests, 0 failures**.
- Coupon and promotion-code return tests compare decoded query maps, so equivalent query parameter ordering is accepted while each filter value remains checked.
- No screenshot or browser visual pass was performed; Plan 242-07 owns the phase-wide visual budget. The automated tests establish rendered route and copy behavior, not tenant-filtered catalog membership.

## Decisions Made

- Kept the existing global Coupon and PromotionCode schemas and exact FK identity checks. Neither schema has an owner field; no tenant/schema expansion was introduced.
- Preserved explicit provider/API diagnostics and the locked copy owner. No provider restriction is inferred from arbitrary raw data.
- Kept direct entry on the family list fallback and built contextual returns through the shared validated ScopedPath contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalize ScopedPath encoder keys before filter comparison**
- **Found during:** Task 1 (coupon context return)
- **Issue:** The helper compared string query keys against atom keys returned by the filter encoder, so parameterized catalog return paths fell back to the base list and lost filters.
- **Fix:** Normalize encoded keys and values before validating destination filters; added focused coupon and promotion-code regression cases, including booleans and the all lens.
- **Files modified:** `accrue_admin/lib/accrue_admin/scoped_path.ex`, `accrue_admin/test/accrue_admin/scoped_path_test.exs`
- **Verification:** Focused ScopedPath and catalog suites passed; included in the 55-test final run.
- **Committed in:** `ff2b7a68`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The shared helper fix was necessary to complete the approved contextual return behavior. No dependencies, data model, or product capability were added.

## Issues Encountered

- Initial return assertions depended on query parameter ordering. They were corrected to compare decoded query maps and then passed.
- The database enforces non-null constraints for promotion-code activity and redemption counts and coupon redemption counts. Tests therefore verify persisted zero separately from nullable/unknown limits; they do not claim those non-null fields can be absent in the current schema.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 06 can add catalog Copy unit assertions in the owned `copy_test.exs`. Plan 07 retains the visual inspection budget. The current catalog model remains global and does not expose owner fields for tenant membership enforcement.

---
*Phase: 242-investigations-and-remaining-admin-surfaces*
*Completed: 2026-10-10*

## Self-Check: PASSED

- The three task commits are present on the branch and no commit deleted tracked files.
- All 12 modified files are listed above; the 55-test focused final run passed with nonzero coverage.
- `Copy.Locked` and the later-plan-owned `copy_test.exs` were not modified.
