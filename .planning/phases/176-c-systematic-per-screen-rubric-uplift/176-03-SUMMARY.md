---
phase: 176-c-systematic-per-screen-rubric-uplift
plan: "03"
subsystem: accrue_admin/live
tags:
  - rubric-uplift
  - detail-components
  - semantic-html
  - dry
dependency_graph:
  requires:
    - 176-01
    - 176-02
  provides:
    - event_live semantic dl/dt/dd facts + detail_section body
    - coupon_live Detail.summary_card hero + Detail.detail_section DRY sections
  affects:
    - 176-SCORECARD.md (Wave 2a after-scores updated)
tech_stack:
  added: []
  patterns:
    - Detail.summary_card replacing hand-rolled ax-page-header hero
    - Detail.detail_section replacing hand-rolled ax-card sections
    - Detail.detail_field_list replacing hand-rolled ax-page key/value paragraphs
    - dl/dt/dd semantic structure inside summary_card :facts slot
key_files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/live/event_live.ex
    - accrue_admin/test/accrue_admin/live/event_live_test.exs
    - accrue_admin/lib/accrue_admin/live/coupon_live.ex
    - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
    - .planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md
decisions:
  - "event_live: used string literals ('Event detail', 'Event details') rather than adding new Copy keys — Copy keys don't exist and the plan says to use fallback strings when Copy keys are missing"
  - "event_live: FlashGroup/KpiCard/Copy aliases not added since they were not used in the implementation (detail_section body + dl/dt/dd covers all rubric targets without them)"
  - "Dim ④ (not-found state) stays at 1 for both screens — the silent redirect is a known pipeline constraint (fetch_flash missing from accrue_admin_browser pipeline, documented in STATE.md). The STATE.md note 'EventLive not-found redirect omits put_flash' confirms this is a pre-existing constraint, not a new gap."
  - "coupon_live: :facts slot uses bare <span> items (not dl/dt/dd) since coupon facts are processor_id / discount / status — short labels already embedded in the text. The dim ⑦ uplift for coupon comes from the detail_field_list in the projection section."
metrics:
  duration: "~8m"
  completed: "2026-06-04"
  tasks_completed: 2
  files_changed: 5
---

# Phase 176 Plan 03: Wave 2a — event_live + coupon_live DRY Uplift Summary

**One-liner:** Lifted the two thinnest tail detail screens to full Detail-component structure — event_live gains dl/dt/dd semantic facts and a detail_section body, coupon_live gains Detail alias, summary_card hero, and detail_section + detail_field_list projection section.

## What Was Built

### Task 1: event_live.ex uplift

**File:** `accrue_admin/lib/accrue_admin/live/event_live.ex`

1. Replaced bare `<span>Actor: @event.actor_type</span>` facts in the summary_card `:facts` slot with a `<dl class="ax-summary-facts-dl"><dt class="ax-label">/<dd class="ax-body">` semantic structure for Actor, Subject, and Recorded fields.

2. Added a `Detail.detail_section` body section titled "Event details" containing a `Detail.detail_field_list` with six fields: Type, Actor type, Actor ID, Subject type, Subject ID, Recorded.

3. Added 2 new test assertions: `renders semantic dl/dt/dd facts inside summary_card` and `renders a detail_section body with event type, actor, subject, recorded fields`.

**Rubric scores (before → after):**
- ② 1→2: detail_section body with heading hierarchy added
- ⑦ 1→2: dl/dt/dd in :facts slot
- ⑩ 1→2: Detail.detail_section + Detail.detail_field_list now used
- ④ remains 1: silent redirect (pipeline constraint — `fetch_flash` missing from accrue_admin_browser pipeline; documented in STATE.md)

### Task 2: coupon_live.ex uplift + SCORECARD

**File:** `accrue_admin/lib/accrue_admin/live/coupon_live.ex`

1. Added `Detail` to the alias list (was missing, causing all rubric misses).

2. Replaced hand-rolled `<header class="ax-page-header">` hero section (lines 46–61) with `Detail.summary_card` (eyebrow from `Copy.coupon_detail_eyebrow()`, title from `coupon_label(@coupon)`, facts slot with processor_id / discount / status).

3. Replaced hand-rolled `<section class="ax-card">` promotion codes list with `Detail.detail_section title={Copy.coupon_detail_section_codes_heading()}` — inner content (link list + empty state) unchanged.

4. Replaced hand-rolled `<section class="ax-card">/<div class="ax-page">/<p class="ax-body">Key Value</p>` projection section with `Detail.detail_section title={Copy.coupon_detail_section_projection_heading()}` containing `Detail.detail_field_list` with duration, currency, and processor fields.

5. Added 3 new test assertions: `renders Detail.summary_card hero not a hand-rolled page header`, `renders projection section as Detail.detail_section with semantic dl field list`, `promotion codes section rendered in Detail.detail_section wrapper`.

**Rubric scores (before → after):**
- ② 1→2: summary_card hero replaces ad-hoc page-header
- ③ 1→2: `<div class="ax-page">` semantic mismatch replaced with detail_section
- ⑦ 1→2: detail_field_list provides dl/dt/dd semantics in projection section
- ⑩ 1→2: Detail alias added; Detail primitives used throughout
- ④ remains 1: same silent redirect constraint

**File:** `.planning/phases/176-c-systematic-per-screen-rubric-uplift/176-SCORECARD.md`

Added Wave 2a after-scores section with per-dimension rationale for both screens.

## Deviations from Plan

### Auto-resolved Issues

**1. [Rule 2 — Missing functionality] Copy keys `event_detail_eyebrow()` and `event_detail_section_heading()` do not exist in the Copy module**
- **Found during:** Task 1 implementation
- **Issue:** Plan referenced `Copy.event_detail_eyebrow()` and `Copy.event_detail_section_heading()` but these functions don't exist in `AccrueAdmin.Copy`.
- **Fix:** Used string literals `"Event detail"` and `"Event details"` per plan instructions ("use a string fallback if no Copy key exists — do not add new Copy keys").
- **Files modified:** `accrue_admin/lib/accrue_admin/live/event_live.ex`
- **Commit:** d4a057d3

**2. [Plan adjustment] Dim ④ (not-found state) not lifted for either screen**
- **Found during:** Task 1 read-first
- **Issue:** STATE.md explicitly notes "EventLive not-found redirect omits put_flash (fetch_flash missing from accrue_admin_browser pipeline)". Adding `put_flash` would silently fail at runtime.
- **Decision:** Left ④ at score 1. The plan's `<threat_model>` has no mitigation for this and the pipeline constraint is a pre-existing architectural decision. Documented in SCORECARD Wave 2a rationale.

**3. [Plan adjustment] FlashGroup/KpiCard/Copy aliases not added to event_live**
- **Found during:** Task 1 implementation
- **Issue:** Plan suggested adding these from webhook_live's imports. However, none of them are used in the final event_live template (no flash emit, no KPI cards added, no Copy keys).
- **Decision:** Followed Elixir convention of not importing unused modules. Anti-churn.

## Known Stubs

None — all section data is wired from live assigns.

## Threat Flags

None — presentation-only changes. No new routes, data access patterns, or form handlers introduced. All existing phx-* event names in coupon_live are preserved (coupon_live.ex has no form submissions; coupons are read-only in admin).

## Self-Check

### Created files exist:
- No new files created (only modifications).

### Commits exist:
- d4a057d3 — feat(176-c-03): uplift event_live — dl/dt/dd facts, detail_section body, semantic structure
- ca482009 — feat(176-c-03): uplift coupon_live — Detail alias, summary_card hero, detail_section DRY + SCORECARD Wave 2a

### Verification results:
- `mix test --seed 0` (full suite): 232 tests, 0 failures
- `grep "detail_section" accrue_admin/lib/accrue_admin/live/event_live.ex`: 2 matches (Detail.detail_section open + close)
- `grep "detail_section" accrue_admin/lib/accrue_admin/live/coupon_live.ex`: 4 matches (2 detail_section calls for codes + projection)
- `grep "Detail," accrue_admin/lib/accrue_admin/live/coupon_live.ex`: 1 match (alias confirmed)

## Self-Check: PASSED
