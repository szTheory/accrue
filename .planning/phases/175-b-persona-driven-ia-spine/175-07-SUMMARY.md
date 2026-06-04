---
phase: 175
plan: "07"
subsystem: accrue_admin
tags:
  - related-resources
  - ia-spine
  - detail-screens
  - href-fix
dependency_graph:
  requires:
    - "175-05"
    - "175-06"
  provides:
    - "All 8 detail screens have RelatedResources cards"
    - "No detail screen dead ends for persona navigation"
    - "All /charges hrefs updated to /payments in live/ layer"
  affects:
    - "subscription_live"
    - "coupon_live"
    - "promotion_code_live"
    - "connect_account_live"
    - "invoice_live"
    - "charge_live"
    - "events_live"
tech_stack:
  added: []
  patterns:
    - "RelatedResources.related_resources component on 4 previously-missing screens"
    - "TDD RED/GREEN cycle per task"
    - "related_items/3 private function pattern consistent across all detail screens"
key_files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/charge_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
    - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
    - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
    - accrue_admin/test/accrue_admin/live/charge_live_test.exs
decisions:
  - "Used ScopedPath.build/3,4 exclusively for all cross-entity links; no string concatenation"
  - "subject_type for ConnectAccount events is 'ConnectAccount' (derived from connect_account_live.ex Events.record call)"
  - "coupon_live: promotion codes link goes to bare /promotion-codes (no coupon_id filter — list does not support that param)"
  - "subscription_live: inline related billing card /charges href also updated to /payments"
metrics:
  duration: "8 minutes"
  completed: "2026-06-04"
  tasks: 2
  files: 13
---

# Phase 175 Plan 07: Related Resources Card Completion & /charges→/payments Fix Summary

Wave 4 closed all bidirectional Related card gaps: RelatedResources added to the 4 detail screens that previously had none (subscription, coupon, promotion code, connect account), all /charges hrefs updated to /payments across the live/ layer, and the 5 pre-existing ChargeLiveTest failures from Plan 175-04's route rename fully resolved.

## What Was Built

### Task 1: RelatedResources on subscription_live and coupon_live; invoice/charge href fixes

**subscription_live.ex**: Added `RelatedResources` alias and a `related_items/3` private function that produces three items: customer link (with customer name/email as value), invoices filtered by `subscription_id`, and events filtered by `subject_type=Subscription&subject_id=<id>`. The assign is built in the mount success branch. The render places `<RelatedResources.related_resources items={@related_items} />` before the flash group. The existing inline related billing card's `/charges` href was also updated to `/payments`.

**coupon_live.ex**: Added `RelatedResources` + `ScopedPath` aliases. `related_items/3` produces promotion codes (bare `/promotion-codes`) and events (subject_type=Coupon).

**invoice_live.ex**: `related_items/3` "Charges for this customer" updated to "Payments for this customer" pointing at `/payments`.

**charge_live.ex**: `related_items/4` "Other charges for this customer" updated to "Other payments for this customer" pointing at `/payments`.

**charge_live_test.exs**: All 5 `live(conn, "/billing/charges/...")` calls updated to `"/billing/payments/..."` — this resolves the 5 pre-existing failures introduced by Plan 175-04's redirect route.

### Task 2: RelatedResources on promotion_code_live and connect_account_live; final suite gate

**promotion_code_live.ex**: Added RelatedResources + ScopedPath aliases. `related_items/3` builds source coupon link (with coupon name/processor_id as value when preloaded) and events link filtered by `subject_type=PromotionCode`.

**connect_account_live.ex**: Added RelatedResources + ScopedPath aliases. `related_items/3` produces a single events link filtered by `subject_type=ConnectAccount`.

**Additional /charges cleanup (Rule 1 - Bug fix inline)**:
- `charge_live.ex` breadcrumb: "Charges" label and `/charges` href updated to "Payments" / `/payments`
- `charge_live.ex` `current_path`: updated from `/charges` to `/payments` (nav highlight correctness)
- `events_live.ex` `subject_href/3` for `"Charge"`: updated from `/charges/:id` to `/payments/:id`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Additional /charges hrefs in charge_live breadcrumb and events_live subject_href**
- **Found during:** Post-implementation verification check (`grep -rn "/charges" accrue_admin/lib/accrue_admin/live/ | grep -v redirect | grep -v "router.ex"`)
- **Issue:** Three additional `/charges` references remained: the breadcrumb link in charge_live.ex, the `current_path` assign in charge_live.ex `assign_shell/2`, and `events_live.ex`'s `subject_href/3` clause for Charge entities.
- **Fix:** Updated all three to use `/payments` path.
- **Files modified:** `charge_live.ex`, `events_live.ex`
- **Commit:** 8254a502

## Known Stubs

None. All RelatedResources items are wired to real entity IDs from server-side assigns.

## Threat Flags

No new security-relevant surface introduced. All cross-entity hrefs are server-constructed from entity IDs already loaded within owner scope. Event filter params (subject_type, subject_id) are hardcoded strings and server-derived IDs, not user-controlled input.

## Self-Check: PASSED

Files confirmed present:
- subscription_live.ex: RelatedResources alias and related_items/3 function present
- coupon_live.ex: RelatedResources alias and related_items/3 function present
- promotion_code_live.ex: RelatedResources alias and related_items/3 function present
- connect_account_live.ex: RelatedResources alias and related_items/3 function present

Commits confirmed:
- eef3a8ec (Task 1)
- 625c6ab3 (Task 2)
- 8254a502 (additional /charges cleanup)

Final verification:
- `grep -rn "related_resources" accrue_admin/lib/accrue_admin/live/ | wc -l` → 9 (8 detail screens + component definition call, satisfies 8+ target)
- `grep -rn "/charges" accrue_admin/lib/accrue_admin/live/ | grep -v redirect | grep -v "router.ex"` → 0
- Full suite: 227 tests, 0 failures
