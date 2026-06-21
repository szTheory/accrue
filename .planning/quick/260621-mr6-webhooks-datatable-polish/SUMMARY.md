---
quick_id: 260621-mr6
slug: webhooks-datatable-polish
date: 2026-06-21
status: complete
---

# Summary: Admin webhooks DataTable polish (4 shared fixes)

Four UI fixes surfaced on the `/admin/webhooks?type=in` demo, all rooted in the **shared
`DataTable`** so every list page benefits (`--validate`: plan-check PASS first iteration,
verification PASS independently re-run). 4 atomic commits on `main`, non-worktree.

## What changed

1. **Truthful empty state (DataTable-owned, reusable, non-breaking opt-in).** With a filter that
   matched nothing, the page showed the *truly-empty* hero ("No webhook deliveries for this
   organization yet") even though the org HAS deliveries — a lie. DataTable already knew filters
   were active (`any_filter_active?/1`) but passed a single `empty_title`/`empty_copy`.
   - `copy.ex`: +4 helpers — `webhooks_index_filtered_empty_title/0` ("No webhook deliveries match
     these filters") + `_copy/0`; generic reusable `data_table_filtered_empty_title/0` ("No
     results match these filters") + `_copy/0`. Existing truly-empty webhooks copy unchanged;
     `page_state_copy(:filtered_empty, _)` (arity-2) left alone.
   - `data_table.ex`: `assign_new(:filtered_empty_title, nil)` + `:filtered_empty_copy`; new
     `resolve_empty_state/1` derives `resolved_empty_*` → filtered copy only when filters active
     AND a filtered copy was supplied, else falls back to `empty_*`. **Opt-out pages
     (invoices/subscriptions/customers/…) render byte-identical** (nil → `empty_title`).
   - `webhooks_live.ex`: passes `filtered_empty_title/copy` to `<.data_table>`.
2. **Spacing.** Added base `.ax-data-table { display:flex; flex-direction:column;
   gap: var(--ax-space-lg); }` (none existed) — filters no longer sit flush against the
   results/empty card. All pages benefit.
3. **Filter toolbar → mobile-first responsive grid.** Replaced
   `.ax-data-table-filters` (flex-wrap/align-end) with grid: 1-col mobile;
   `@media (min-width:768px)` → `repeat(auto-fit, minmax(12rem,1fr)) auto` with actions
   `justify-self:end`. Tokens-only, no new color. (Side effect: activates the previously-dormant
   dev-lab toolbar grid rules — an improvement.)
4. **Select buttons → native checkboxes** (`reuse .ax-checkbox`). Per-row (grid + card) and the
   single shared select-all are now `<input type="checkbox">`; `<th>` label is
   `ax-visually-hidden`. Every pinned contract preserved: `data-role`
   (toggle-row/toggle-all/bulk-action/selected-count), `data-phase191-focus`, per-row
   `data-row-id`, and `aria-label` text from `selection_label/5` + `toggle_all_label/1`. Exactly
   **one** `[data-role='toggle-all']` (shared grid+cards). Select-all label reuses
   `.ax-field-inline` → **no new class, zero `component_registry.ex` churn**.

Rebuilt the committed `priv/static/accrue_admin.css` (final commit); **`accrue_admin.js`
byte-identical** (no JS source edits).

## Result

`mix compile --warnings-as-errors` clean; full `mix test` → **348 tests, 0 failures**
(`data_table_test`, `webhooks_live_test`, `webhook_replay_test`, `assets_test` all green).
Spec-gap proven: the new filtered-empty assertions FAIL on the pre-change HEEx, PASS after.

## Commits
- `9aa35ced` — truthful filtered-empty (copy + DataTable opt-in + webhooks wiring + tests)
- `63b3a394` — native checkboxes (grid/card/select-all + hidden `<th>`)
- `231b3316` — base `.ax-data-table` gap + mobile-first filter grid (+ `.ax-field-inline` reuse)
- `bf83caf5` — rebuilt committed asset bundle (css only)

## Notes / decisions
- **Non-breaking by construction**: only `webhooks_live.ex` opts in; the capability is now in the
  design system for any page to adopt (invoices/subscriptions keep their bespoke `queue_empty_*`).
- **Deviation (registry-safe)**: used existing `.ax-field-inline` for the select-all label rather
  than a new `.ax-data-table-toggle-all` class — a new registered class would break the
  `/dev/components` render-coverage guardrail (the selection bar doesn't render there).
- **Host test not re-run (acceptable gap)**: `examples/accrue_host/.../admin_webhook_replay_test.exs`
  needs `mix deps.get`, which would touch the off-limits **stale `examples/accrue_host/mix.lock`**.
  Zero host files changed; its contracts (`bulk-action`, `confirm-retry-selected`,
  `{:data_table_bulk_action,…}`, single unscoped `toggle-all`) are unchanged and independently
  covered by the passing accrue_admin tests.

## Browser-only follow-up (user visual confirm on the demo)
`/admin/webhooks`: (a) `?type=<no-match>` → "No webhook deliveries match these filters" + Clear,
clearing restores the row; (b) tidy aligned filter row on desktop, full-width single column on
mobile; (c) comfortable space above the results/empty card; (d) per-row + select-all are real
checkboxes driving the same Retry-selected flow. Spot-check `/admin/invoices` unregressed.
