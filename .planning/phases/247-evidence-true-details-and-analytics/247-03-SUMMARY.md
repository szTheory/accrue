---
phase: 247-evidence-true-details-and-analytics
plan: "03"
subsystem: ui
tags: [phoenix, liveview, timestamps, intl, clipboard]
requires:
  - phase: 247-01
    provides: UTC-first timestamp component and browser formatting hook
  - phase: 247-02
    provides: Shared Local/UTC preference and truthful clipboard feedback
provides:
  - Shared timestamp controls across dashboard, Connect, commerce, customer, invoice, event, promotion code, and subscription detail consumers
  - Timeline rendering for raw DateTime values with exact ISO copy payloads
affects: [phase-247, timestamp-display, admin-activity]
actuals:
  tokens: 5512
  tasks: 3
  commits: 3
  plan_head_before: 0c8c0e8f68597015ec488b76c736fa4ff74481ce
  plan_head_after: 0d066da2585e9b249ada5a72fc4611ba7e985b1a
commits: 3
plan_head_before: 0c8c0e8f68597015ec488b76c736fa4ff74481ce
plan_head_after: 0d066da2585e9b249ada5a72fc4611ba7e985b1a
tech-stack:
  added: []
  patterns:
    - Keep raw DateTime values through timeline and list rendering, using Timestamp.timestamp at the HTML boundary
    - Distinguish DOM IDs for the same record rendered in table, card, header, and summary surfaces
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/components/timeline.ex
    - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
    - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/lib/accrue_admin/live/coupons_live.ex
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/invoice_live.ex
    - accrue_admin/lib/accrue_admin/live/invoices_live.ex
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
    - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
    - accrue_admin/lib/accrue_admin/live/subscription_live.ex
    - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs
key-decisions:
  - "Use the existing shared timestamp component for each visible DateTime while retaining Date values and UTC query behavior."
  - "Keep existing event audit sentence wording and expose its exact timestamp in the adjacent timestamp control."
requirements-completed: []
coverage:
  - id: D1
    description: "Dashboard, Connect, commerce, customer, and invoice consumers display source instants through the shared Local/UTC and exact-copy control."
    requirement: TIME-01
    verification:
      - kind: unit
        ref: "mix test test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/connect_account_live_test.exs"
        status: pass
      - kind: unit
        ref: "mix test test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/invoices_live_test.exs"
        status: pass
    human_judgment: true
    rationale: "Full consumer inventory and representative mounted visual proof are owned by later Phase 247 plans."
  - id: D2
    description: "Event and promotion code instants use the shared timestamp control in detail and list surfaces."
    requirement: TIME-01
    verification:
      - kind: unit
        ref: "mix test test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/subscription_live_test.exs"
        status: pass
      - kind: unit
        ref: "mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs"
        status: pass
    human_judgment: true
    rationale: "The phase verifier owns complete consumer inventory and mounted visual proof."
  - id: D3
    description: "Subscription detail instants use the shared timestamp control while preserving current owner and action behavior."
    requirement: TIME-01
    verification:
      - kind: unit
        ref: "mix test test/accrue_admin/live/subscription_live_test.exs"
        status: pass
    human_judgment: true
    rationale: "Authorization and representative browser presentation are covered by the phase-wide verifier."
duration: 14min
completed: 2026-10-11
status: complete
---

# Phase 247 Plan 03: Timestamp Consumer Summary

**Dashboard, Connect, commerce, customer, invoice, event, promotion code, and subscription surfaces now render exact instants with the shared Local/UTC preference and copy control.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-10-11T21:26:00Z
- **Completed:** 2026-10-11T21:39:36Z
- **Tasks:** 3
- **Files modified:** 16

## Accomplishments

- Converted visible DateTime values to the shared timestamp control across the named detail and list consumers, including timelines and responsive cards.
- Kept raw DateTime values until rendering and retained the exact source ISO payload for copy. Date-only fields and analytics/query boundaries were left unchanged.
- Made rendered IDs distinct when the same row or record appears in table, card, header, and summary surfaces.

## Task Commits

1. **247-03-01 Convert dashboard, payment and Connect instants** — `de3d2698` (`feat`)
2. **247-03-02 Convert commerce and customer instants** — `16a20e13` (`feat`)
3. **247-03-03 Convert events, codes and subscription-detail instants** — `0d066da2` (`feat`)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/components/timeline.ex` — renders source DateTime values through the shared timestamp control.
- Fourteen named LiveView consumers — dashboard, payment/Connect, commerce/customer/invoice, event, promotion code, and subscription displays.
- `accrue_admin/test/accrue_admin/live/invoices_live_test.exs` and `events_live_test.exs` — presentation assertions account for timestamp precision and the added timestamp copy control.

## Decisions Made

- Reused `Timestamp.timestamp/1` at each render boundary and kept component IDs unique across concurrently rendered surfaces.
- Kept existing human-readable audit sentence wording while making exact instants available through adjacent copyable timestamp controls.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added raw DateTime support to the shared timeline seam**
- **Found during:** Task 1
- **Issue:** Timeline consumers formatted timestamps to strings before HTML rendering, preventing the shared component from using the original instant.
- **Fix:** Timeline items now retain source DateTime values and the shared timeline renders them through `Timestamp.timestamp/1`; existing string-only timeline items remain supported.
- **Files modified:** `accrue_admin/lib/accrue_admin/components/timeline.ex`, `accrue_admin/lib/accrue_admin/live/dashboard_live.ex`, `accrue_admin/lib/accrue_admin/live/connect_account_live.ex`, `accrue_admin/lib/accrue_admin/live/customer_live.ex`, `accrue_admin/lib/accrue_admin/live/invoice_live.ex`, `accrue_admin/lib/accrue_admin/live/subscription_live.ex`
- **Verification:** Focused owning LiveView suites passed.
- **Committed in:** `de3d2698` (timeline seam and first consumers); subsequent consumer changes are in `16a20e13` and `0d066da2`.

**2. [Rule 1 - Bug] Prevented duplicate timestamp IDs across concurrent render surfaces**
- **Found during:** Tasks 2 and 3
- **Issue:** LiveView rendered the same record in summary/table and responsive card surfaces, which initially gave each timestamp control the same DOM ID.
- **Fix:** IDs now include the record and presentation surface; presentation assertions were updated for seconds precision and the additional timestamp copy action.
- **Files modified:** Invoice, coupon, promotion code, event, and subscription LiveViews plus the two owning list test files.
- **Verification:** All focused suites passed, including repeat runs after fixing the duplicate IDs.
- **Committed in:** `16a20e13`, `0d066da2`.

**3. [Rule 3 - Scope] Left the charge list unchanged after confirming it has no visible timestamp field**
- **Found during:** Task 1
- **Issue:** `charges_live.ex` does not render a DateTime value in its list view.
- **Fix:** No consumer change was necessary; the required charge owner suite still ran with the Connect checks.
- **Verification:** 23 tests passed across the focused payment and Connect suites.
- **Committed in:** `de3d2698` (other task changes only).

**Total deviations:** 3 (two correctness fixes, one no-op consumer confirmed by source inspection)
**Impact on plan:** The work remains presentation-only. No authorization, owner scoping, business behavior, query bounds, or dependencies changed.

## Verification

- `mix test test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` — 23 tests passed.
- `mix test test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/invoices_live_test.exs` — 82 tests passed.
- `mix test test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/subscription_live_test.exs` — 66 tests passed.
- `mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs` — 23 tests passed.
- `mix format --check-formatted` on the task 3 implementation and test files passed; `git diff --check` passed before each task commit.

## Next Phase Readiness

The five remaining timestamp owners are explicitly assigned to Plan 247-08: subscriptions list, webhooks list, campaign detail, at-risk table, and campaign timeline. Plan 247-08 also owns the complete timestamp inventory; Plan 247-07 owns phase-wide mounted proof. Phase requirements remain open for the final verifier.

---
*Phase: 247-evidence-true-details-and-analytics*
*Completed: 2026-10-11*

## Self-Check: PASSED

- Summary file exists at the planned output path.
- Task commits `de3d2698`, `16a20e13`, and `0d066da2` are ancestors of the current plan head.
- All focused test owners passed; source changes were checked with `git diff --check`.
