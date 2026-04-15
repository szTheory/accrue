---
phase: 07-admin-ui-accrue-admin
plan: 12
subsystem: ui
tags: [phoenix, liveview, coupons, promotion-codes, connect]
requires:
  - phase: 07-admin-ui-accrue-admin
    provides: Shared admin shell, query modules, navigation primitives, display components, and DataTable behavior from plans 07-03, 07-04, 07-09, 07-10, and 07-11
provides:
  - Explicit coupon list/detail and promotion-code list/detail admin surfaces backed by local projections
  - Dedicated Connect account list/detail pages with curated readiness state and local platform-fee override editing
  - Repo-grounded platform-fee preview and persistence flow validated through `Accrue.Connect.platform_fee/2`
affects: []
tech-stack:
  added: []
  patterns: [query-driven admin list pages, local projection detail surfaces, per-account fee override preview via Accrue.Connect.PlatformFee]
key-files:
  created:
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/components/app_shell.ex
key-decisions:
  - "Promotion codes ship as their own list/detail route pair and sidebar entry instead of hiding under coupon detail only."
  - "Connect account override state is stored only in `accrue_connect_accounts.data[\"platform_fee_override\"]`, while the global default remains read-only from `Accrue.Config`."
  - "Override validation and preview both run through `Accrue.Connect.platform_fee/2` so percent and clamp semantics stay aligned with the existing repo primitive."
patterns-established:
  - "Discount-management pattern: list pages stay on `AccrueAdmin.Queries.*` projections while detail pages use local curated sections plus limited payload inspection."
  - "Connect-override pattern: normalize string form input, preview against a sample gross amount, then persist only the local override map when validation passes."
requirements-completed: [ADMIN-15, ADMIN-19, ADMIN-20]
duration: 14m
completed: 2026-04-15
---

# Phase 7 Plan 12: Coupons, Promotion Codes, and Connect Configuration Summary

**Explicit discount-management pages plus Connect account configuration with local platform-fee overrides**

## Performance

- **Duration:** 14m
- **Completed:** 2026-04-15T18:59:13Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Added explicit coupon and promotion-code list/detail LiveViews so ADMIN-15 is covered by separate manager-facing surfaces rather than being implied through one discount page.
- Added Connect account list/detail LiveViews that show readiness state from local projections and expose a per-account platform-fee override editor without inventing new storage columns or settings subsystems.
- Kept the override preview and persistence flow repo-grounded by validating input through `Accrue.Connect.platform_fee/2` and storing only `data["platform_fee_override"]` on the local account row.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build concrete coupon and promotion-code management pages for ADMIN-15** - `6a671e7` (feat)
2. **Task 2: Build Connect account pages and the repo-grounded platform-fee override UI** - `50592a7` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/{coupons_live,coupon_live,promotion_codes_live,promotion_code_live}.ex` - dedicated coupon and promotion-code list/detail pages with local projection summaries and cross-links.
- `accrue_admin/lib/accrue_admin/live/{connect_accounts_live,connect_account_live}.ex` - connected-account list/detail pages plus local platform-fee override preview and save flow.
- `accrue_admin/test/accrue_admin/live/{coupons_live,coupon_live,promotion_codes_live,promotion_code_live,connect_accounts_live,connect_account_live}_test.exs` - focused LiveView coverage for the explicit discount and Connect surfaces.
- `accrue_admin/lib/accrue_admin/router.ex` and `accrue_admin/lib/accrue_admin/components/app_shell.ex` - mounted routes and navigation entries for the new admin slice.

## Decisions Made

- Kept coupon and promotion-code detail pages local-projection-only, using curated sections and links instead of broadening the shared query modules.
- Treated the global Connect fee policy as read-only config and limited writes to the account-local override map inside `data`.
- Recorded Connect override saves as admin events and audits so fee-policy changes remain queryable operator actions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the Connect detail flash payload shape**
- **Found during:** Task 2 verification
- **Issue:** `ConnectAccountLive` assigned flashes as tuples, but the shared `FlashGroup` component expects maps with `:kind` and `:message`, causing the save path to crash after a successful override update.
- **Fix:** Switched the Connect detail page to assign flash entries as maps matching the shared component contract.
- **Files modified:** `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`
- **Verification:** `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs --warnings-as-errors`
- **Committed in:** `50592a7`

---

**Total deviations:** 1 auto-fixed (1 Rule 3)
**Impact on plan:** The fix was required to let the platform-fee override flow render its success state after persistence. No scope creep beyond the planned Connect admin UI.

## Issues Encountered

- The shared flash component contract is map-based, so the Connect detail page could not reuse older tuple-style ad hoc flash data.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later admin work can link directly into coupon, promotion-code, and Connect detail routes instead of rebuilding discount or payout inspection from scratch.
- The Connect detail page now exposes one reusable pattern for local-only policy overrides validated through existing billing primitives.

## Self-Check: PASSED

- Found `.planning/phases/07-admin-ui-accrue-admin/07-12-SUMMARY.md`
- Found task commit `6a671e7` in git history
- Found task commit `50592a7` in git history
