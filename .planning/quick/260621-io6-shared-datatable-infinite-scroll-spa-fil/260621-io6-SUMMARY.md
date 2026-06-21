---
phase: quick-260621-io6
plan: 01
subsystem: accrue_admin
tags: [admin-ui, data-table, infinite-scroll, spa-filters, clipboard, customers]
status: complete
requires:
  - accrue_admin DataTable LiveComponent + 9 list LiveViews
  - registered Clipboard LiveView hook (assets/js)
provides:
  - AccrueAdmin.DataTableNav.patch_with_filters/3 (merge-into-existing-query push_patch)
  - AccrueAdmin.Components.IdBadge (click-to-copy id chip)
  - Queries.Customers.distinct_owner_types/1 (owner-scoped dropdown source)
  - infinite-scroll viewport sentinel + SPA filter contract for all 9 admin list pages
affects:
  - all 9 admin list pages (customers, subscriptions, invoices, charges, coupons,
    promotion_codes, connect_accounts, events, webhooks)
  - committed priv/static/accrue_admin.{css,js} bundle
tech-stack:
  added: []
  patterns:
    - "Parent-targeted LiveComponent filter form (phx-change/phx-submit, no phx-target) -> shared nav helper push_patch"
    - "Per-element registered LiveView hook (Clipboard) survives infinite-scroll/filter re-render"
    - "URI.parse/decode_query/encode_query merge to preserve ?org= and avoid double-?"
key-files:
  created:
    - accrue_admin/lib/accrue_admin/data_table_nav.ex
    - accrue_admin/lib/accrue_admin/components/id_badge.ex
    - accrue_admin/test/accrue_admin/data_table_nav_test.exs
    - accrue_admin/test/accrue_admin/components/id_badge_test.exs
  modified:
    - accrue_admin/lib/accrue_admin/components/data_table.ex
    - accrue_admin/lib/accrue_admin/live/customers_live.ex
    - accrue_admin/lib/accrue_admin/queries/customers.ex
    - accrue_admin/lib/accrue_admin/copy.ex
    - accrue_admin/lib/accrue_admin/components/icon.ex
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
    - accrue_admin/assets/js/hooks/clipboard.js
    - accrue_admin/assets/js/app.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/accrue_admin.js
    - the 9 list LiveViews (handle_event "data_table_filter")
decisions:
  - "patch_with_filters merges into the path's existing query (URI decode/merge/encode) to preserve ?org= and never emit a double-?"
  - "Clipboard is a REAL registered per-element LiveView hook (mounted/2) so copy binds on infinite-scroll-appended + filter-re-rendered rows; initClipboardControls() kept for json_viewer"
  - "Customers redesigned to a lean find-and-open surface: Customer (name+email) / Payment method (On file|Missing) / copy-id chip; dropped Billing-signals (always-Off) and Owner-types KPI"
  - "owner_type filter is a select sourced from distinct_owner_types(owner_scope), mirroring webhooks distinct_types"
metrics:
  duration_min: ~7 (this session; Tasks 1-2 landed in a prior session)
  completed: 2026-06-21
  tasks: 5
  files: 23
---

# Phase quick-260621-io6 Plan 01: Shared DataTable infinite scroll + SPA filters + IdBadge + customers redesign Summary

Part B of the ethereal-harbor plan: upgraded the shared admin DataTable (infinite-scroll
viewport sentinel + SPA `push_patch` filters + grouped filter-toolbar spacing) so all 9 admin
list pages benefit, added a reusable click-to-copy `IdBadge` driven by a registered Clipboard
LiveView hook, and redesigned `/admin/customers` from a raw-DB dump into a lean operator
find-and-open surface. accrue_admin-only; no core, host, seed, or ROADMAP changes.

## Execution Note — Continuation

This run resumed an in-flight execution. **Tasks 1 and 2 were already committed by a prior
session** (`4077965e`, `daaa0db5`) and verified complete here against their `<verify>`/`<done>`
criteria (phx-viewport-bottom present, `patch_with_filters` present, 9 `data_table_filter`
handlers, registered `export const Clipboard`, app.js wiring, `:copy` icon, id-badge registry +
explicit kitchen clause). This session executed **Tasks 3, 4, and 5** from the partially-staged
working tree and committed each atomically.

## What Was Built (per task)

- **Task 1 (prior commit 4077965e):** `AccrueAdmin.DataTableNav.patch_with_filters/3` (merge into
  existing query, exposes `merge_query/2` for unit testing); DataTable viewport sentinel (gated on
  `next_cursor && length(rows) < dom_limit`, Load-more button kept), SPA filter form (parent-targeted
  `data_table_filter`, debounced text), patch Clear links to `table_path` as-is, grouped actions
  container; 9 per-page `handle_event("data_table_filter", …)`; CSS toolbar spacing.
- **Task 2 (prior commit daaa0db5):** registered per-element `Clipboard` hook + app.js wiring;
  `IdBadge` component (unique DOM id, `phx-hook="Clipboard"`, `data-clipboard-text`, mono truncated
  id + `:copy` icon); `:copy` icon path; `.ax-id-badge*` CSS; id-badge registry entry + explicit
  `do_render_specimen("id-badge", …)` kitchen clause; `initClipboardControls()` kept for json_viewer.
- **Task 3 (b3c44395):** `Queries.Customers.distinct_owner_types/1` (owner-scoped SQL distinct);
  Customers page heading "Customers" + plain Copy-sourced description; dropped Owner-types KPI and
  `owner_type_count`; lean columns Customer (name+email) / Payment method (softened to "On file" /
  "Missing", no raw pm id) / copy-id chip via `IdBadge`; dropped owner_id/processor_id/Billing-signals
  columns; removed dead `billing_signals_cell/1` and the `BillingPresentation` alias; owner_type filter
  → `:select` from derived options.
- **Task 4 (65bc67f3):** rebuilt + committed `priv/static/accrue_admin.{css,js}` (`.ax-id-badge` +
  filter spacing in CSS, registered Clipboard hook in JS). Idempotent — a second build leaves the
  committed bundle clean.
- **Task 5 (12e64d57):** new `data_table_nav_test` (merge guard), new `id_badge_test`; rewrote
  `data_table_test` GET-form/anchor-Clear assertions to the SPA contract + sentinel coverage; updated
  `customers_live_test` to the new copy/columns/dropdown/IdBadge; added a `subscriptions_live_test`
  shared-filter `push_patch` smoke (second page).

## Critical-Fact Compliance (baked-in plan-check fixes)

1. **Clipboard is a real registered hook** — `export const Clipboard = { mounted() {…} }` in
   `hooks/clipboard.js`, registered in app.js `hooks` map; `IdBadge` renders `phx-hook="Clipboard"`
   with a unique per-row DOM id (`ax-id-badge-<customer.id>`); `initClipboardControls()` retained for
   json_viewer. JS bundle changed intentionally and is committed (assets md5 covers JS). Verified:
   `grep -c Clipboard priv/static/accrue_admin.js` ≥ 1.
2. **`patch_with_filters` MERGES, never appends** — `URI.parse → decode_query → Map.merge → drop
   blank/nil → encode_query → single re-attached query (nil when empty)`. The unit test asserts:
   one `?`, `org=acme` survives, `q=foo` present, blank/nil dropped, only-blank → org-only path,
   query-less path → single `?query`, filter-wins-over-stale.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `assert_patch/2` does not accept a regex**
- **Found during:** Task 5 (subscriptions smoke test)
- **Issue:** `assert_patch(view, ~r/…/)` raised `FunctionClauseError` — the arity-2 form only
  takes a binary `to` or an integer timeout.
- **Fix:** Capture the patched path with `to = assert_patch(view)` and assert substrings
  (`=~ "/billing/subscriptions"` and `=~ "q=acme"`).
- **Files modified:** `test/accrue_admin/live/subscriptions_live_test.exs`
- **Commit:** 12e64d57

**2. [Rule 3 - Blocking] `live_isolated` cannot route `handle_params`/`push_patch`**
- **Found during:** Task 5 (data_table_test parent-contract test)
- **Issue:** Adding `handle_params/3` to the isolated `TableLive` fixture made `live_isolated`
  raise ("not mounted nor accessed through the router live/3 macro"); a `push_patch` there also
  raises since there is no route.
- **Fix:** The fixture's `data_table_filter` handler now `send`s `{:data_table_filter_received, params}`
  to the test pid; the data_table_test asserts the event reaches the PARENT (no `phx-target`).
  The real URL-merge behavior is covered deterministically by `data_table_nav_test` (unit) and the
  routed `subscriptions_live_test` (integration push_patch), so coverage is not weakened.
- **Files modified:** `test/accrue_admin/components/data_table_test.exs`
- **Commit:** 12e64d57

All other tasks executed as written.

## Threat Model

Honored: T-io6-04 (CSP unchanged — first-party in-repo Clipboard hook, no inline/eval, no new
directives; JS md5 guards the committed bundle); T-io6-01/02/03/SC accept/mitigate dispositions
unchanged (filter params flow through existing `decode_filter` + owner-scoped queries; copied IDs
already rendered; no new deps). No new security surface introduced.

## Verification Results (exact)

- `cd accrue_admin && mix compile --warnings-as-errors` — **clean** (no dead-function/unused-alias warnings).
- `cd accrue_admin && mix accrue_admin.assets.build` — rebuilt; second run left the committed bundle clean (idempotent).
- `cd accrue_admin && mix test test/accrue_admin/assets_test.exs` — **3 tests, 0 failures** (committed bundle md5 matches fresh build for CSS and JS).
- `cd accrue_admin && mix test --seed 0` (full suite) — **347 tests, 0 failures**.
- Task 5 named files together — **42 tests, 0 failures**.
- `grep -c ax-id-badge priv/static/accrue_admin.css` → **1**.
- `grep -c Clipboard priv/static/accrue_admin.js` → **1** (registered hook present).
- No changes under `examples/accrue_host`, no `mix.lock` change committed, no ROADMAP.md change, no `.planning/research/.cache/` change, StatusBadge untouched. (Pre-existing dirty `examples/accrue_host/mix.lock` was left untouched, never staged.)

## Commits (5 atomic task commits)

| Task | Hash | Message |
|------|------|---------|
| 1 | `4077965e` | feat(260621-io6): shared DataTable infinite scroll + SPA push_patch filters + toolbar spacing *(prior session)* |
| 2 | `daaa0db5` | feat(260621-io6): click-to-copy IdBadge with registered Clipboard hook + :copy icon + lab *(prior session)* |
| 3 | `b3c44395` | feat(260621-io6): customers find-and-open redesign — lean columns, owner-type dropdown, copy-id chip |
| 4 | `65bc67f3` | build(260621-io6): rebuild committed static bundle (ax-id-badge CSS + Clipboard JS hook) |
| 5 | `12e64d57` | test(260621-io6): SPA-filter/infinite-scroll contract, IdBadge, customers redesign, nav merge guard |

## Known Stubs

None. No placeholder/empty-data stubs introduced; all rendered surfaces are wired to real queries.

## Self-Check: PASSED

- FOUND: accrue_admin/lib/accrue_admin/data_table_nav.ex
- FOUND: accrue_admin/lib/accrue_admin/components/id_badge.ex
- FOUND: accrue_admin/test/accrue_admin/data_table_nav_test.exs
- FOUND: accrue_admin/test/accrue_admin/components/id_badge_test.exs
- FOUND commit: b3c44395, 65bc67f3, 12e64d57 (this session); 4077965e, daaa0db5 (prior)
