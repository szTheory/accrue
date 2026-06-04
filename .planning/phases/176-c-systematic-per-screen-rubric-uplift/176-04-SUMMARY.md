---
phase: 176-c-systematic-per-screen-rubric-uplift
plan: "04"
subsystem: accrue_admin
tags: [rubric-uplift, detail-components, promotion-code, connect-account, webhook, flash-pipeline]
dependency_graph:
  requires: [176-01, 176-02, 176-03]
  provides: [promotion_code_live_detail_components, connect_account_ax_measure, webhook_forensic_dry, flash_pipeline_fix]
  affects: [accrue_admin_browser_pipeline, all_live_detail_screens_with_put_flash]
tech_stack:
  added: []
  patterns:
    - Detail.summary_card hero replacing hand-rolled ax-page-header (promotion_code_live)
    - Detail.detail_section replacing hand-rolled ax-card sections (promotion_code_live, webhook_live)
    - Detail.detail_field_list for structured field pairs (webhook_live forensic section)
    - ax-measure on prose <p> elements (connect_account_live, webhook_live)
    - fetch_live_flash in accrue_admin_browser pipeline for LiveView redirect flash support
    - put_flash(:error) before nil redirect for dim ④ state coverage
key_files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/webhook_live.ex
    - accrue_admin/lib/accrue_admin/router.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
    - .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md
decisions:
  - fetch_live_flash added to accrue_admin_browser pipeline (not fetch_flash) — LiveView-native flash plug; must be imported inside the quote block with `import Phoenix.LiveView.Router, only: [fetch_live_flash: 2]`
  - promotion_code_live dim ④ fixed with put_flash(:error, promotion_code_not_found()) before redirect; new Copy key added
  - WebhookLive forensic section DRY'd to Detail.detail_section + Detail.detail_field_list; ⑩ now 3
  - connect_account_live ax-measure added to platform-fee prose only; form/submit unchanged
metrics:
  duration: 15m
  completed: "2026-06-04"
  tasks: 2
  files: 10
---

# Phase 176 Plan 04: Wave 2b Catalog/Specialist DRY Uplift Summary

Detail component uplift for promotion_code_live, connect_account_live, and webhook_live, plus a cross-cutting flash-pipeline fix that enables not-found redirects to carry error messages across all admin LiveViews.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | promotion_code_live Detail alias + summary_card + detail_section + not-found flash + pipeline fix | 19526952 | promotion_code_live.ex, router.ex, copy.ex, copy/promotion_code.ex, promotion_code_live_test.exs |
| 2 | connect_account ax-measure + webhook forensic DRY + SCORECARD update | 12b1e84e | connect_account_live.ex, webhook_live.ex, connect_account_live_test.exs, webhook_live_test.exs, 176-SCORECARD.md |

## Changes Made

### promotion_code_live.ex

- Added `Detail` to the alias list (was missing — identical gap to coupon_live before Plan 03)
- Replaced hand-rolled `<header class="ax-page-header">` hero with `Detail.summary_card` (eyebrow + title + facts: status + redemption)
- Replaced hand-rolled `<section class="ax-card">` parent-coupon section with `Detail.detail_section`
- Added `put_flash(:error, AccrueAdmin.Copy.promotion_code_not_found())` before the nil-case redirect

### accrue_admin/router.ex (cross-cutting pipeline fix)

Added `plug(:fetch_live_flash)` to the `accrue_admin_browser` pipeline. This required `import Phoenix.LiveView.Router, only: [fetch_live_flash: 2]` inside the quote block (the function lives in `Phoenix.LiveView.Router`, not in the host router's scope). Without this plug, `put_flash/3` on the socket during the HTTP initial render phase fails with ArgumentError.

### connect_account_live.ex

- Added `ax-measure` to the `<p class="ax-body">` platform-fee description paragraph (line 144)
- All other code unchanged: phx-submit="save_override", data-role="save-override", form inputs, event handlers all preserved

### webhook_live.ex

- Replaced the last hand-rolled `<section class="ax-card">` forensic payload section with `Detail.detail_section :if={@webhook}` + `Detail.detail_field_list` for Endpoint/Processed fields
- Kept the Activity-feed paragraph as `<p class="ax-body ax-measure">` (prose link sentence; ax-measure applied)
- The full activity-feed href using `scoped_mount_path` is preserved verbatim

## Test Coverage

| Test | File | Assertion |
|------|------|-----------|
| renders Detail.summary_card hero | promotion_code_live_test.exs | html =~ "ax-summary-card" |
| renders parent coupon section in Detail.detail_section | promotion_code_live_test.exs | html =~ "ax-detail-section" |
| redirects with flash when not found | promotion_code_live_test.exs | flash["error"] != nil |
| applies ax-measure to platform-fee description prose | connect_account_live_test.exs | html =~ ~s(class="ax-body ax-measure") |
| preserves save_override form phx-submit and data-role | connect_account_live_test.exs | html =~ phx-submit="save_override" AND data-role="save-override" |
| forensic payload section uses Detail.detail_section | webhook_live_test.exs | html =~ "ax-detail-section" |
| applies ax-measure to Activity-feed prose | webhook_live_test.exs | html =~ ~s(class="ax-body ax-measure") |

## SCORECARD After-Scores (Wave 2b)

| Screen | ① | ② | ③ | ④ | ⑤ | ⑥ | ⑦ | ⑧ | ⑨ | ⑩ | Min | Pass? | Delta |
|--------|---|---|---|---|---|---|---|---|---|---|-----|-------|-------|
| PromotionCodeLive | 3 | 2 | 3 | 2 | 3 | 2 | 2 | 2 | 2 | 2 | 2 | YES | ②④⑦⑩ all 1→2 |
| ConnectAccountLive | 3 | 2 | 3 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | YES | ③ 2→3 (ax-measure) |
| WebhookLive | 3 | 3 | 3 | 3 | 2 | 2 | 2 | 3 | 2 | 3 | 2 | YES | ⑩ 2→3 (forensic DRY) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] flash pipeline gate missing from accrue_admin_browser**
- **Found during:** Task 1 (implementing put_flash for dim ④)
- **Issue:** The `accrue_admin_browser` pipeline lacked `fetch_live_flash`, causing `put_flash/3` calls on the socket to 500 during the HTTP initial render phase. This was the root cause of the known "EventLive not-found redirect omits put_flash (fetch_flash missing from accrue_admin_browser pipeline)" note in STATE.md decisions.
- **Fix:** Added `import Phoenix.LiveView.Router, only: [fetch_live_flash: 2]` and `plug(:fetch_live_flash)` inside the `accrue_admin_browser` pipeline generated by the `accrue_admin/2` macro.
- **Files modified:** `accrue_admin/lib/accrue_admin/router.ex`
- **Commit:** 19526952
- **Note:** CouponLive and EventLive still have dim ④ = 1 because they use bare `redirect` without `put_flash`. They are out of scope for this plan but can now be fixed without pipeline blockers.

**2. [Rule 2 - Missing Copy Key] promotion_code_not_found/0 Copy key did not exist**
- **Found during:** Task 1
- **Issue:** `put_flash(:error, AccrueAdmin.Copy.promotion_code_not_found())` required a new Copy key that was missing from `AccrueAdmin.Copy.PromotionCode` and its delegate in `AccrueAdmin.Copy`.
- **Fix:** Added `def promotion_code_not_found` to `copy/promotion_code.ex` and `defdelegate` to `copy.ex`.
- **Files modified:** `accrue_admin/lib/accrue_admin/copy/promotion_code.ex`, `accrue_admin/lib/accrue_admin/copy.ex`
- **Commit:** 19526952

## Known Stubs

None. All sections are wired to real data. No placeholder values.

## Threat Flags

None. Changes are limited to CSS class additions (`ax-measure`) and component substitutions (Detail.* for hand-rolled markup). No new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- [x] `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` exists and contains `Detail,`
- [x] `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` contains `ax-summary-card` (via Detail.summary_card)
- [x] `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` contains `ax-detail-section` (via Detail.detail_section)
- [x] `accrue_admin/lib/accrue_admin/live/connect_account_live.ex` contains `ax-body ax-measure`
- [x] `accrue_admin/lib/accrue_admin/live/webhook_live.ex` contains `ax-detail-section` (via Detail.detail_section)
- [x] `accrue_admin/lib/accrue_admin/live/webhook_live.ex` contains `ax-body ax-measure`
- [x] `accrue_admin/lib/accrue_admin/router.ex` contains `fetch_live_flash`
- [x] Commits 19526952 and 12b1e84e exist
- [x] Full suite: 239 tests, 0 failures (was 232 before this plan)
