---
quick_id: 260621-mr6
slug: webhooks-datatable-polish
date: 2026-06-21
---

# Webhooks DataTable polish (4 shared-component fixes + webhooks copy)

## Problem

On `/admin/webhooks?type=in` (a filter matching nothing), the page shows the *truly-empty* hero even though the org HAS deliveries — they just don't match the filter. Three more shared-`DataTable` issues compound it: filters sit flush against the results/empty card (no inter-child gap), the filter toolbar is `flex-wrap` ragged rather than mobile-first grid, and selection uses "Select"/"Selected" `<button>` text instead of native checkboxes. All four are rooted in the shared component `accrue_admin/lib/accrue_admin/components/data_table.ex` + `accrue_admin/assets/css/app.css`, so fixing once pays off across all 10 list pages. This is a `--validate` (spec-driven) quick task on `main`, non-worktree. `accrue_admin` serves the **committed** `priv/static/accrue_admin.{css,js}`, so any CSS change requires a bundle rebuild + commit (`assets_test.exs` asserts md5).

Every existing pinned contract MUST survive: `data-role="toggle-row|toggle-all|bulk-action|selected-count|clear-filters|empty-state"`, `data-phase191-focus="toggle-all|toggle-row|filter-*|clear-filters"`, per-row `data-row-id`, the `aria-label` text from `selection_label/5` (data_table.ex:491) and `toggle_all_label/1` (data_table.ex:484), and exactly ONE `[data-role='toggle-all']` instance in the DOM (host `admin_webhook_replay_test.exs` clicks it unscoped via `element/2` — two instances would raise). Pages that do NOT opt in to the new filtered-empty copy (invoices/subscriptions) must render **byte-identical** to today.

---

## Tasks

### Task 1 — Truthful empty state: copy + DataTable opt-in switch + webhooks wiring + tests (Commit 1)

**1a. `accrue_admin/lib/accrue_admin/copy.ex`** — ADD four arity-0 functions. Place the two webhook-specific functions immediately after the existing truly-empty `webhooks_index_empty_copy` (currently ends ~line 670–671); leave `webhooks_index_empty_title/0` (line 666) and `webhooks_index_empty_copy/0` (line 668) **UNCHANGED**. Place the two generic functions near the other `data_table_*` defaults (around lines 480–491, e.g. right after `data_table_default_empty_copy/0`).

- `webhooks_index_filtered_empty_title/0` → `"No webhook deliveries match these filters"`
- `webhooks_index_filtered_empty_copy/0` → `"Adjust or clear the status, type, or live-mode filters above to see matching deliveries."`
- `data_table_filtered_empty_title/0` → `"No results match these filters"`
- `data_table_filtered_empty_copy/0` → `"Clear or adjust the filters above to see results."`

DECISION (planner): the generic `data_table_filtered_empty_*` are **standalone arity-0 string helpers**, NOT delegations to `page_state_copy(:filtered_empty, opts)` (copy.ex:407). Standalone avoids the opts/`%{heading,body}` map shape and matches the existing `data_table_default_empty_title/copy` pattern. Do NOT remove or alter `page_state_copy/2` — it is a separate map-returning API used elsewhere.

**1b. `accrue_admin/lib/accrue_admin/components/data_table.ex`** — opt-in derived assigns (non-breaking).

In `update/2` (lines 14–66), in the `assign_new` chain (after line 33 `:empty_copy`), add:
```
|> assign_new(:filtered_empty_title, fn -> nil end)
|> assign_new(:filtered_empty_copy, fn -> nil end)
```
(`nil` = opt-out; default fallback to `empty_title`/`empty_copy`.)

Then compute **derived assigns** so the HEEx stays clean and the resolution is testable. The empty-state resolution depends on `@filter_params`, which is set inside `reload/2` (line 449), so derive after the `cond` block (after line 63, before `maybe_schedule_poll` on line 65). Add a derived-assign step that reads `socket.assigns.filter_params`, `socket.assigns.filtered_empty_title/copy`, and `socket.assigns.empty_title/copy`, e.g.:

- `filtered? = any_filter_active?(socket.assigns[:filter_params] || %{})` (reuse `any_filter_active?/1`, data_table.ex:586)
- `resolved_empty_title = if filtered? and socket.assigns.filtered_empty_title, do: socket.assigns.filtered_empty_title, else: socket.assigns.empty_title`
- `resolved_empty_copy` analogous.
- `assign(socket, resolved_empty_title: ..., resolved_empty_copy: ...)`

Guard for the `:poll` branch / first render where `filter_params` may be unset — default to `%{}` so `any_filter_active?/1` returns `false` and it falls back to `empty_title`. (Note `reload/2` always runs on a params-signature change, which is the only path that renders rows/empty; the poll branch keeps prior `filter_params`. Defaulting to `%{}` is safe.)

In the empty-state block (lines 195–208): change line 197 from `<%= @empty_title %>` to `<%= @resolved_empty_title %>` and line 198 from `<%= @empty_copy %>` to `<%= @resolved_empty_copy %>`. Leave the `<.link :if={any_filter_active?(@filter_params)} ... data-role="clear-filters">` (lines 199–207) UNCHANGED. CRITICAL: when `filtered_empty_title` is `nil` (invoices/subscriptions), `resolved_empty_title == empty_title` exactly → byte-identical output.

**1c. `accrue_admin/lib/accrue_admin/live/webhooks_live.ex`** — at the `<.data_table>` call, after `empty_copy={Copy.webhooks_index_empty_copy()}` (line 245), ADD:
```
filtered_empty_title={Copy.webhooks_index_filtered_empty_title()}
filtered_empty_copy={Copy.webhooks_index_filtered_empty_copy()}
```

**1d. Tests — `accrue_admin/test/accrue_admin/components/data_table_test.exs`:**
- Extend the `TableLive` fixture (lines 125–175) `<.live_component>` call (after `table_caption={@table_caption}`, line 172) to pass:
  `filtered_empty_title="No fixtures match these filters"` and `filtered_empty_copy="Adjust the filters above."` (literal fixture strings — the upgraded test asserts these exact strings).
- Upgrade the test "distinguishes true-empty from filtered-empty recovery actions" (lines 399–414):
  - Truly-empty case (`params %{}`, lines 402–406): still `assert html =~ "Nothing in this list yet"` and `refute html =~ ~s(data-role="clear-filters")`. ADD `refute html =~ "No fixtures match these filters"`.
  - Filtered case (`params %{"status" => "closed"}`, lines 408–413): CHANGE `assert html =~ "Nothing in this list yet"` → `refute html =~ "Nothing in this list yet"` and ADD `assert html =~ "No fixtures match these filters"`. Keep `assert html =~ ~s(data-role="clear-filters")` and `assert html =~ "Clear filters"`.

**1e. Tests — `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs`:** ADD a test following the file's convention (`conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")` then `live(conn, "/billing/webhooks?...")`). Mount with a `type` filter that matches nothing (e.g. `live(conn, "/billing/webhooks?type=does-not-exist-zzz")`). Assert `html =~ "No webhook deliveries match these filters"` and `refute html =~ "No webhook deliveries for this organization yet"` (the truly-empty title from copy.ex:666). Confirm the org genuinely has deliveries so the truly-empty path is not the reason for zero rows (match the seed/setup pattern other tests in this file use).

**Spec-gap sanity (--validate):** before applying 1a–1c, run the new 1d filtered assertion and the 1e test — they MUST FAIL (old code shows "Nothing in this list yet" / the truly-empty webhooks title). After 1a–1c they MUST PASS.

---

### Task 2 — Select buttons → native checkboxes (grid + card + select-all + th) (Commit 2)

**`accrue_admin/lib/accrue_admin/components/data_table.ex`** — convert three selection controls from `<button>` to native `<input type="checkbox" class="ax-checkbox">` (reuse `.ax-checkbox`, app.css:2219). Preserve every pinned attr.

**2a. Per-row, GRID `<td>` (lines 256–271):** replace the `<button>…</button>` (lines 257–270) with:
```
<input
  type="checkbox"
  class="ax-checkbox"
  phx-click="toggle-row"
  phx-value-id={row_identity(row, @row_id)}
  phx-target={@myself}
  checked={selected?(@selected_ids, row_identity(row, @row_id))}
  data-role="toggle-row"
  data-row-id={row_identity(row, @row_id)}
  data-phase191-focus="toggle-row"
  aria-label={selection_label(@selected_ids, row, @row_id, @card_title, @columns)}
/>
```
Drop the `aria-pressed` attr and the inner `"Selected"/"Select"` text node (grep-confirmed: no test asserts visible button text; only `aria-label`).

**2b. Per-row, CARD view (lines 285–300):** same replacement of the `<button :if={@selectable}>…</button>` (lines 285–299) with the identical `<input type="checkbox" …>` from 2a, adding back `:if={@selectable}` on the input.

**2c. Select-all — the SINGLE shared control in the selection bar (lines 218–228):** convert `<button>` → checkbox + visible label. It MUST remain the ONLY `[data-role='toggle-all']` in the DOM (shared by grid+cards; host `admin_webhook_replay_test.exs` clicks it unscoped). Replace lines 218–228 with a `<label>` wrapping the checkbox and a visible `<span>`:
```
<label class="ax-data-table-toggle-all">
  <input
    type="checkbox"
    class="ax-checkbox"
    phx-click="toggle-all"
    phx-target={@myself}
    checked={all_visible_selected?(assigns)}
    data-role="toggle-all"
    data-phase191-focus="toggle-all"
    aria-label={toggle_all_label(assigns)}
  />
  <span><%= if all_visible_selected?(assigns), do: "Clear visible", else: "Select visible" %></span>
</label>
```
Keep `toggle_all_label/1` (line 484) and its aria text unchanged. Keep the `data-role="selected-count"` status `<p>` (lines 211–217) and the `data-role="bulk-action"` button (lines 229–238) UNCHANGED.

**2d. Grid header `<th>Select</th>` (line 250):** change to an accessible-but-hidden header label. `ax-sr-only` does NOT exist in this codebase — use the existing `ax-visually-hidden` utility (app.css:2851):
```
<th :if={@selectable} scope="col" class="ax-label"><span class="ax-visually-hidden">Select</span></th>
```

**2e. Tests stay green:** `data_table_test.exs` selection block (lines 416–460+) asserts `data-role`/`data-phase191-focus`/`aria-label`/`data-row-id` and clicks `toggle-all`/`toggle-row`/`bulk-action` via `render_click(element(...))` — `render_click/1` fires `phx-click` on the checkbox, so these flows are preserved. No edits expected here; if any assertion references visible button text (`"Select"`/`"Selected"` as a node, not in `aria-label`), update it — grep first to confirm none do. Verify `webhooks_live_test.exs` (lines 82,103), `webhook_replay_test.exs`, and host `admin_webhook_replay_test.exs` still pass.

---

### Task 3 — CSS: spacing base rule + mobile-first filter grid + minimal selection tidy (Commit 3)

**`accrue_admin/assets/css/app.css`** — tokens only, NO new color tokens.

**3a. Spacing base rule.** There is currently NO base `.ax-data-table` rule giving vertical gap (only the `min-width:0` group at lines 2255–2265). ADD a standalone base rule (e.g. just before the `min-width:0` group at line 2255):
```
.ax-data-table {
  display: flex;
  flex-direction: column;
  gap: var(--ax-space-lg);
}
```
(`.ax-data-table` stays in the `min-width:0` group too — no conflict.) Executor must visually sanity-check `/admin/webhooks` and `/admin/invoices` for NO double-stacking with existing child margins.

**3b. Filter toolbar → mobile-first grid.** REPLACE the existing `.ax-data-table-filters` flex rule (lines 2269–2274) with a grid mirroring the proven dev-lab pattern (app.css:461–478):
```
.ax-data-table-filters {
  display: grid;
  gap: var(--ax-space-md);
  grid-template-columns: 1fr;
}

.ax-data-table-filter-actions {
  display: flex;
  gap: var(--ax-space-sm);
  align-items: center;
  width: 100%;
}

@media (min-width: 768px) { /* --ax-bp-md ↑ */
  .ax-data-table-filters {
    grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr)) auto;
    align-items: end;
  }

  .ax-data-table-filter-actions {
    width: auto;
    justify-self: end;
  }
}
```
This merges the old `.ax-data-table-filter-actions` rule (lines 2276–2280) into the base above — delete the old standalone `.ax-data-table-filter-actions` block to avoid duplication. Reuse existing classes only; introduce NO new class here, so `dev/component_registry.ex` needs no churn.

**3c. Selection tidy (only if needed).** If the new `<label class="ax-data-table-toggle-all">` checkbox+span needs alignment, add a tiny rule (tokens only):
```
.ax-data-table-toggle-all {
  display: inline-flex;
  align-items: center;
  gap: var(--ax-space-sm);
}
```
If introduced, register `ax-data-table-toggle-all` in `accrue_admin/lib/accrue_admin/dev/component_registry.ex` with the two-token `ax_class` "base variant" form (render-coverage guardrail). Prefer reusing the existing `.ax-field-inline` pattern (app.css:2235) if it fits — if so, no registry churn.

---

### Task 4 — Rebuild + commit the committed bundle (Commit 4, MUST be last) (Commit 4)

After ALL CSS (Task 3) is settled, from `accrue_admin/`:
```
mix accrue_admin.assets.build
```
Commit `priv/static/accrue_admin.css` AND `priv/static/accrue_admin.js` (`assets_test.exs` asserts both md5s). NO JS source edits in `assets/js/*` — but if the deterministic rebuild changes the JS md5 anyway, commit the rebuilt JS. This is a standalone final commit.

(Executor MAY merge Commits 1+2 if cleaner. The bundle rebuild MUST be its own final step after all CSS is committed. Executor commits CODE only — do NOT write STATE.md.)

---

## Guardrails (hard)

- Do NOT touch: `StatusBadge`, the CSP, `examples/accrue_host/mix.lock`, `.planning/research/.cache/`, `ROADMAP.md`.
- Do NOT remove or alter `page_state_copy/2` (copy.ex:407) or the existing `webhooks_index_empty_title/copy` (copy.ex:666,668).
- Keep EXACTLY ONE `[data-role='toggle-all']` in the DOM.
- Pages not passing `filtered_empty_*` (invoices/subscriptions) must render byte-identical to today.
- Preserve all `data-role`, `data-phase191-focus`, `data-row-id`, and `aria-label` text from `selection_label/5` and `toggle_all_label/1`.
- Use `ax-visually-hidden` (NOT `ax-sr-only`, which does not exist).
- No new color tokens; spacing/border/radius tokens only.
- NO JS source edits.
- Updating STATE.md "Quick Tasks Completed" is the ORCHESTRATOR's job — not the executor.

---

## Verification

From `accrue_admin/`:
```
mix compile --warnings-as-errors
mix accrue_admin.assets.build
mix test
```
Report `N tests / M failures`. Pay special attention to:
- `test/accrue_admin/components/data_table_test.exs`
- `test/accrue_admin/live/webhooks_live_test.exs`
- `test/accrue_admin/live/webhook_replay_test.exs`
- `test/accrue_admin/assets_test.exs`

From `examples/accrue_host/`:
```
mix test test/accrue_host_web/admin_webhook_replay_test.exs
```

Bundle grep (confirm CSS shipped in the committed bundle):
```
grep -n '\.ax-data-table{' accrue_admin/priv/static/accrue_admin.css      # base gap rule (minified: brace adjacent)
grep -n 'ax-data-table-filters' accrue_admin/priv/static/accrue_admin.css # grid rule present
```
(Bundle is minified — match on the minified token form, e.g. `.ax-data-table{display:flex` and `.ax-data-table-filters{display:grid`.)

Spec-gap sanity (--validate): the new filtered-empty assertions in `data_table_test.exs` (Task 1d filtered case) and `webhooks_live_test.exs` (Task 1e) MUST FAIL before the Task 1a–1c copy/DataTable change and PASS after.
