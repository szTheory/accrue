---
phase: 175-b-persona-driven-ia-spine
plan: "06"
subsystem: ui
tags: [phoenix_live_view, heex, customer_360, filter_chip_bar, compliance_lens]

requires:
  - phase: 175-03
    provides: ax-tab-more-menu CSS class in committed bundle
  - phase: 175-04
    provides: /payments route, ChargesLive renamed, ScopedPath patterns

provides:
  - Customer-360 tab tiering with 3 primary tabs (Subscriptions/Invoices/Payments) + More ▾ overflow
  - more_tabs_open boolean assign with toggle_more_tabs/close_more_tabs handle_event
  - normalize_tab/1 backward-compat clause: "payments" → "charges"
  - filter_chip_bar optional :href attr for activation-link chip behavior
  - EventsLive "By actor" compliance lens chip (always visible, URL-param synced)

affects:
  - 175-07 (Phase 175 final plan — UI/CSS polish may reference ax-tab-more-menu)
  - 176 (per-screen rubric uplift — inherits Customer-360 tab tiering contract)

tech-stack:
  added: []
  patterns:
    - "Tab tiering via @primary_tabs/@more_tabs module attributes + inline HEEx tab strip"
    - "More ▾ dropdown: aria-haspopup=menu + aria-expanded + phx-window-keydown=close_more_tabs"
    - "filter_chip_bar :href extension: activation link when chip has href but no remove_href"
    - "Compliance saved lens: always-active chip, cobalt+Clear when active / slate+activation href when inactive"

key-files:
  created:
    - accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/live/customer_live.ex
    - accrue_admin/lib/accrue_admin/live/events_live.ex
    - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
    - accrue_admin/test/accrue_admin/live/customer_live_test.exs
    - accrue_admin/test/accrue_admin/live/events_live_test.exs

key-decisions:
  - "Tab strip inlined in customer_live.ex (not via Tabs component) to support More ▾ button variant without touching Tabs public API"
  - "more_tabs exposed as socket assign (not just module attribute) so template @more_tabs check works in HEEx"
  - "Compliance chip activation href built via append_query/2 on table_path (not ScopedPath.build/4) because table_path is already the scoped base; org= param preserved via existing table_path assign"
  - "filter_chip_bar :href extension: when chip has :href and no :remove_href, label renders as <a href>; :remove_href takes precedence when both set"

patterns-established:
  - "Always-active compliance lens chip: active: true so chip renders even when filter is off; tone switches cobalt/slate to signal state"
  - "More ▾ overflow: phx-window-keydown=close_more_tabs + phx-key=Escape for keyboard close"

requirements-completed:
  - IA-05
  - IA-07

duration: 15min
completed: 2026-06-04
---

# Phase 175 Plan 06: Customer-360 Tab Tiering + Compliance Actor-Lens Summary

**Customer-360 gets 3-primary-tab + More ▾ overflow tiering; EventsLive gets always-visible "By actor" compliance lens chip; filter_chip_bar extended with backward-compatible :href activation-link support.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-04T05:02:00Z
- **Completed:** 2026-06-04T05:07:00Z
- **Tasks:** 2 (both TDD: RED → GREEN)
- **Files modified:** 5 files + 1 created

## Accomplishments

- Customer-360 now shows 3 primary tabs (Subscriptions, Invoices, Payments) + a "More ▾" button that reveals 4 recessed tabs (Payment methods, Entitlements, Events, Metadata) as an `ax-tab-more-menu` dropdown
- `more_tabs_open` boolean assign toggled by `toggle_more_tabs`/`close_more_tabs` handle_events; `handle_params` resets it to false on tab navigation; Escape key closes via `phx-window-keydown`
- "charges" tab renders as "Payments" label (internal id unchanged for URL backward compat); `normalize_tab("payments")` → "charges" compat clause added
- `related_items/3` updated to use `/payments` href instead of `/charges`
- `filter_chip_bar` extended with optional `:href` attr: when a chip has `href:` set and no `remove_href:`, its label renders as `<a href>` (activation link); fully backward-compatible
- EventsLive renders "By actor" compliance lens chip above the DataTable; always visible (active: true); cobalt + Clear when `?actor_type=` active, slate + activation href when not set

## Task Commits

1. **Test RED — Customer-360 tab tiering** - `5319840e` (test)
2. **Feat GREEN — Customer-360 primary tabs + More ▾** - `6550257a` (feat)
3. **Test RED — compliance actor-lens chip + filter_chip_bar :href** - `e996f99d` (test)
4. **Feat GREEN — compliance chip + filter_chip_bar extension** - `012d69ff` (feat)

## Files Created/Modified

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — @primary_tabs/@more_tabs attrs, more_tabs_open assign, toggle/close handle_events, inline tab strip with More ▾ dropdown, normalize_tab("payments") compat, /payments related_items href
- `accrue_admin/lib/accrue_admin/live/events_live.ex` — compliance_chips/2, append_query/2, FilterChipBar render in template
- `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` — :href extension, chip_activation_href/1 private fn
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — 7 new assertions for tab tiering
- `accrue_admin/test/accrue_admin/live/events_live_test.exs` — 3 new assertions for compliance chip
- `accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs` — new file with 7 assertions (existing + :href extension)

## Decisions Made

- Inlined tab strip in `customer_live.ex` rather than extending `Tabs` component: the More ▾ button requires different HEEx structure that would have forced a breaking change to the Tabs API
- `@more_tabs` module attribute exposed as socket assign (`:more_tabs`) so HEEx `@more_tabs` template reference works correctly
- Compliance chip activation href uses `append_query/2` on the existing `table_path` assign (already scoped) rather than calling `ScopedPath.build/4` with a separate mount_path — avoids double-scoping

## Deviations from Plan

None — plan executed exactly as written. The `compliance_chips/2` arity is 2 (params + table_path) rather than the 3-arity variant the plan optionally suggested, because `table_path` already incorporates scope; this matches the simpler approach the plan documented as acceptable.

## Issues Encountered

**Pre-existing test failures (out of scope):** 5 tests in `ChargeLiveTest` fail because they navigate to `/billing/charges/:id` and the redirect controller (Plan 175-04) redirects them to `/billing/payments/:id`. These failures predate this plan and are not caused by any changes here. Tracked in `deferred-items.md` per deviation rule scope boundary.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The `?actor_type=` param flows through the existing DataTable filter path already scoped per `OwnerScope` (T-175-06-02 accept disposition confirmed). The More ▾ menu state (`more_tabs_open`) is a boolean UI-only assign with no data access implications (T-175-06-03 accept disposition confirmed).

## Known Stubs

None — all data flows are wired. The compliance chip activation href defaults to `?actor_type=admin` (primary compliance use case per plan spec).

## Self-Check

- [x] customer_live.ex exists and compiles
- [x] events_live.ex exists and compiles
- [x] filter_chip_bar.ex exists and compiles
- [x] 28 tests green (customer_live + events_live + filter_chip_bar test files)
- [x] All task commits exist

---
*Phase: 175-b-persona-driven-ia-spine*
*Completed: 2026-06-04*
