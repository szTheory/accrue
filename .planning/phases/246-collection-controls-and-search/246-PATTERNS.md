# Phase 246: Collection Controls and Search - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 20 likely modified/created source and validation files (the final plan may narrow page consumers)  
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | component | request-response/render | same file `filter_toolbar/1`, table/card renderers | exact |
| `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | component | request-response/render | same file `filter_chip_bar/1`, `chip/1` | exact |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | component | request-response + async | same file | exact |
| `accrue_admin/assets/js/hooks/command_palette.js` | hook | event-driven | same hook | exact |
| `accrue_admin/assets/css/app.css` | config/style | render | same stylesheet, palette + table/card rules | exact |
| `accrue_admin/lib/accrue_admin/live/{charges,invoices,subscriptions,coupons,promotion_codes,events,connect_accounts,customers}_live.ex` | controller/live view | request-response/URL state | invoices and subscriptions LiveViews | role-match |
| `accrue_admin/lib/accrue_admin/queries/{charges,invoices,subscriptions,coupons,promotion_codes,events,connect_accounts,customers}.ex` | service/query | transform/CRUD read | invoices and subscriptions query modules | role-match |
| `accrue_admin/test/accrue_admin/components/{data_table,filter_chip_bar,global_search}_test.exs` | test | request-response | matching component tests | exact |
| `accrue_admin/test/js/command_palette_test.mjs` | test | event-driven | matching hook test | exact |
| `accrue_admin/test/accrue_admin/live/{charges,invoices,subscriptions,coupons,promotion_codes,events,connect_accounts,customers}_live_test.exs` | test | request-response/URL state | invoices/subscriptions LiveView tests | role-match |
| `examples/accrue_host/e2e/phase246-collection-controls.spec.js` (likely new) | test | browser interaction | `phase245-admin-baseline.spec.js` and phase234/237 collection specs | role-match |

The tracked-source gate was checked for all named source and test analogs with `git ls-files`; no `.gsd/capabilities` runtime mirror paths are used.

## Pattern Assignments

### Shared filter controls and applied chips

**Analogs:** `accrue_admin/lib/accrue_admin/components/data_table.ex:580-639`; `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex:20-105`.

`DataTable.filter_toolbar/1` owns the shared form and sends `phx-change="data_table_filter"`; labels currently use `ax-visually-hidden`, and undeclared filter params are carried as hidden fields. `FilterChipBar` owns applied constraints, count, reset, and removal links. Preserve explicit active-constraint modeling: `chip_active?/1` defaults missing `:active` to true, while `chip_activation_href/1` renders `:href` only when no `:remove_href` exists. Navigation/view choices therefore need explicit exclusion from chips.

```elixir
<form phx-change="data_table_filter" phx-submit="data_table_filter" class="ax-data-table-filters">
  <div :for={field <- @filter_fields} class={["ax-data-table-filter", filter_field_class(field)]}>
    <label for={field_id(@id, field)} class="ax-visually-hidden"><%= field_label(field) %></label>
    <.filter_input id={field_id(@id, field)} field={field}
      value={Map.get(@filter_params, field_param(field))} focus_key={field_param(field)} />
  </div>
</form>
```

Use `accrue_admin/test/accrue_admin/components/data_table_test.exs` and `filter_chip_bar_test.exs` for component fixtures/assertion style. `global_search_test.exs` shows async component testing and grouped failure/retry cases.

### URL, scope, and predicate ownership

**Analogs:** `accrue_admin/lib/accrue_admin/data_table_nav.ex:24-64`; `accrue_admin/lib/accrue_admin/live/invoices_live.ex:55-83,327-343`; `accrue_admin/lib/accrue_admin/queries/invoices.ex:109-160`.

Page LiveViews own canonical params, defaults, chip constructors, and row/column ordering. Query modules own actual matching predicates. Route filter changes through `DataTableNav.patch_with_filters/3`; its merge keeps existing `org` and unrelated query values while deleting blank values. Invoice/subscription status strings are comma-delimited: queries OR the selected statuses and reduce other criteria successively (AND). Preserve defaults `open,uncollectible` and `past_due,canceling`, and exact relationship predicates. General-search copy must reflect each query's actual clauses; do not broaden `q` to absorb `customer_id`, coupon, or source-webhook exact filters.

```elixir
def handle_event("data_table_filter", params, socket) do
  {:noreply, AccrueAdmin.DataTableNav.patch_with_filters(
    socket, socket.assigns.table_path, Map.drop(params, ["_target", "_csrf_token"]))}
end
```

`merge_query/2` decodes the existing URI query, merges stringified params, rejects blank values, then encodes one query string (`data_table_nav.ex:45-59`). `Queries.Invoices.filter_query/2` illustrates `q`, status, exact `customer_id`, and `collection_method` as separate predicates. For status UI, retain these query contracts and use `in`/OR semantics for multiple values.

Representative behavioral tests: `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`, `subscriptions_live_test.exs`, and `coupons_live_test.exs`; URL merge tests live in `data_table_nav_test.exs`. Extend the corresponding page-owner test for direct URL, selected controls, chips, result rows, and scope-preserving remove/reset behavior.

### Global search and browser active result

**Analogs:** `accrue_admin/lib/accrue_admin/components/global_search.ex:278-314`; `accrue_admin/assets/js/hooks/command_palette.js:1-130`; `accrue_admin/assets/css/app.css:4312-4350`.

GlobalSearch owns the trigger/dialog, async groups and owner/query generation checks. Keep partial successful groups and retries. The hook owns one `activeIndex`, input focus, pointer movement, keyboard activation, ARIA announcement, focus trap/return. CSS currently styles `:hover` and `.ax-active` independently; make hover subordinate to the same active state. Spinner markup has `hidden`, but base `.ax-spinner` sets `display:inline-block`; inspect served CSS and ensure `[hidden]` wins while adding an existing size modifier and preserving reduced-motion styling.

```js
handlePointerMove(e) {
  const item = e.target.closest?.(".ax-command-palette-item[data-path], .ax-command-palette-item[data-action]");
  const index = item ? this.items?.indexOf(item) : -1;
  if (index >= 0 && index !== this.activeIndex) {
    this.activeIndex = index;
    this.updateActiveItem();
  }
}
```

Copy test patterns from `accrue_admin/test/js/command_palette_test.mjs` and `accrue_admin/test/accrue_admin/components/global_search_test.exs`. For mounted browser coverage, use the ordinary host harness and auth helpers in `examples/accrue_host/e2e/phase245-admin-baseline.spec.js`; keep Phase 245 artifacts immutable and put new evidence/spec coverage under Phase 246.

### Shared table identity and responsive layout

**Analogs:** `accrue_admin/lib/accrue_admin/components/data_table.ex:484-547`; `accrue_admin/assets/css/app.css:3413-3589,3778-3810`; consumer row helpers in `customers_live.ex`, `promotion_codes_live.ex`, `invoices_live.ex`, and `subscriptions_live.ex`.

`DataTable` renders semantic desktop rows and responsive cards. Keep name/code and exact ID in separate identity lines; apply `min-width: 0` and wrapping to the identity child rather than widening the whole column. Preserve full ID and existing `InlineId` copy behavior. Consumers own data order and `card_fields`; order recognizable identity, meaningful state, money, then relevant timing, keeping ownership/technical detail lower priority. Shared `EmptyState` grouping and shared CSS are the analog for empty-state spacing fixes.

## Shared Patterns

| Concern | Source | Apply to |
|---|---|---|
| Owner/query scope preserved through filter changes | `accrue_admin/lib/accrue_admin/data_table_nav.ex:45-59` | All list LiveViews and chip reset/removal paths |
| Exact search predicate truth | `accrue_admin/lib/accrue_admin/queries/*.ex` (`filter_query/2`) | Search labels and secondary relationship controls |
| Async request freshness and result groups | `accrue_admin/lib/accrue_admin/components/global_search.ex` | Global search edits |
| Accessible focus and single active result | `accrue_admin/assets/js/hooks/command_palette.js` | Palette interaction/CSS |
| Responsive table/card identity | `DataTable` plus shared rules in `app.css` | All collection consumers |
| Existing host auth and mounted browser setup | `examples/accrue_host/e2e/phase245-admin-baseline.spec.js` | New Phase 246 Playwright evidence |

## No Analog Found

No file role/data-flow gap found. Phase 246's exact mounted collection interaction scenario is new; use the tracked Phase 245/234/237 Playwright harness as its closest role-match analog, and write new Phase 246 evidence separately.

## Metadata

**Analog search scope:** `accrue_admin/lib/accrue_admin/{components,live,queries}`, `accrue_admin/assets/{css,js/hooks}`, `accrue_admin/test`, `examples/accrue_host/e2e`  
**Pattern extraction date:** 2026-10-11
