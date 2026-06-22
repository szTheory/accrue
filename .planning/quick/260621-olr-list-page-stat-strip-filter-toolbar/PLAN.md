---
quick_id: 260621-olr
slug: list-page-stat-strip-filter-toolbar
date: 2026-06-21
validate: true
approved_plan: /Users/jon/.claude/plans/i-just-got-an-ethereal-harbor.md
---

# Admin list pages: compact metrics (stat strip) + condensed filter toolbar

Research-backed redesign of every admin **list/index** page: the oversized KPI card band + the
tall label-stacked filter form push the table below the fold. Tighten both within brand,
systematically. Direction (two design sweeps + brand/JTBD mining): list-page metrics → a quiet
inline **stat strip** (v1.51 "demoted KPIs"); filters → a condensed **instant-apply self-labeling
toolbar** with segmented toggles for 2–3-value choices. Full detail in the approved plan.

## Part A — List-page metrics → compact inline "stat strip"

- NEW `lib/accrue_admin/components/stat_strip.ex`: `<dl class="ax-stat-strip" aria-label={@label}
  data-component-group={...}>` + `:stat` slot (`label`, `value`, optional `tone` ∈
  moss|cobalt|amber, optional `href`). Pair = `<div class="ax-stat"><dt class="ax-stat-label">
  …</dt><dd class={["ax-stat-value", tone]}>…</dd></div>`; href wraps dt+dd in `<a class=
  "ax-stat-link">`. Mirror KpiCard's `data-component-group` passthrough.
- CSS (app.css, mirror `.ax-kpi-*`, tokens only): `.ax-stat-strip` flex/wrap/baseline, gap
  `sm lg`, padding `sm 0`; `.ax-stat` flex baseline gap `sm`; hairline `.ax-stat + .ax-stat::before`
  (1px `--ax-border`, margin-right `md`); `.ax-stat-label` `font:var(--ax-type-label-font);
  color:--ax-muted`; `.ax-stat-value` `font-size:--ax-type-lg;600;tabular-nums;color:--ax-primary`;
  tone modifiers color VALUE ONLY (moss→success-readable, cobalt→accent-readable,
  amber→warning-readable); `.ax-stat-link` inline-flex + hover underline + focus ring; `@media
  (max-width:30rem)` stack + drop dividers.
- DEV LAB (render-coverage guardrail — plan-check exact shape): add a `stat-strip` entry to
  `ComponentRegistry.entries/0` mirroring the existing `segmented` entry (~972-1013) — it MUST carry
  `family`, `variant`, `ax_class` (TWO tokens; the **second token is the variant class the
  guardrail asserts must appear in the rendered specimen** — use e.g. `"ax-stat-strip ax-stat-value"`),
  `tokens:` (every token also defined in theme/app.css + rendered), `applicable_states: ["default"]`,
  `na_states:` (cover the rest of the taxonomy with reasons), `specimens:`. AND add a dedicated
  `do_render_specimen("stat-strip", _state, _specimen, _theme)` clause in `component_kitchen_live.ex`
  that renders a real `<dl class="ax-stat-strip">…<dd class="ax-stat-value">` — do NOT rely on the
  `:1632` fallback stub (it won't contain `ax-stat-value` → test a fails).
- MIGRATE list pages (customers, subscriptions, invoices, charges, webhooks, events, coupons,
  promotion_codes, connect_accounts `_live.ex`): `<section class="ax-kpi-grid">…KpiCard…</section>`
  → `<StatStrip.stat_strip>` + `<:stat>` per metric; DROP `<:meta>` captions + list-page
  sparklines; keep metrics/values/tones (e.g. Canceling/Paused → `tone="amber"`). LEAVE KpiCard
  UNTOUCHED (dashboard + detail summary cards).
- TESTS: add StatStrip block in `display_components_test.exs` (`<dl`, `ax-stat-strip`, a value, a
  tone class, `data-component-group`); update list-page `ax-kpi-grid` pins → `ax-stat-strip` (known:
  `webhook_live_test.exs:82`). KpiCard tests stay green.
- DEFAULT: chromeless strip (no ask).

## Part B — Filters → condensed, self-labeling, instant toolbar

- `data_table.ex` header (~171–199): keep the `data_table_filter` form + anchors; render filters in
  ONE flex toolbar (search grows; categorical controls intrinsic; wraps <768px). Self-label: field
  `<label>` → `ax-visually-hidden`; search `:text` gets a placeholder + grows. **Naming the select's
  default option ("All statuses" vs bare "All") is a PRIMITIVE edit, not per-field:** the
  `<option value="">All</option>` is hardcoded in `filter_input/1`'s `:select` clause
  (`data_table.ex:369`). Add an optional `all_label` key to the field map and have the `:select`
  primitive render `all_label || "All"`; then set `all_label` per field at the call sites. Re-check
  any existing test asserting the literal `>All<` option (update knowingly). DROP visible Apply button (instant `phx-change`;
  text debounced 300ms) but KEEP a visually-hidden `<button type="submit"
  data-phase191-focus="filter-submit" tabindex="-1">`. Replace `.ax-data-table-filter-actions` with
  a context-only Clear `<.link patch={@path} data-role="clear-filters"
  data-phase191-focus="clear-filters">` shown only when `any_filter_active?/1`.
- CSS (app.css ~2237, rework `.ax-data-table-filters`; keep the `/* --ax-bp-md ↑ */` comment):
  mobile flex-column gap `sm`; `@media (min-width:768px)` flex-row wrap center gap `md`; search-grow
  (`flex:1 1 16rem;min-width:12rem`); Clear `margin-inline-start:auto`. Reuse `.ax-input`/`.ax-select`/
  `.ax-segmented`/`.ax-visually-hidden`; register any new `.ax-filter-toolbar*` class in dev lab.
- CONTROL-TYPE RULES: ≤3 stable → `:segmented` (PREPEND `{"", "All"}`); 4–7 → `:select`;
  many/dynamic → `:datalist`; text/ids → `:text`; dynamic cardinality → render branch
  (`length(options) <= 3 → :segmented, else :select`). Per-section: customers q→text /
  owner_type→seg-or-select(dynamic) / has_default_payment_method→seg{All,On file,Missing};
  subscriptions status(6)→select; invoices collection_method(2)→seg{All,Automatic,Send invoice};
  charges fees_settled(2)→seg{All,Settled,Pending}, status→select-if-enumerable; webhooks KEEP;
  events text; coupons valid(2)→seg{All,Valid,Invalid}; promotion-codes active(2)→seg{All,Active,
  Inactive}; connect (6 categoricals, plan-check corrected) type(3)→seg + charges_enabled/
  payouts_enabled/**details_submitted**/**deauthorized**(2)→seg — **NO livemode on connect**
  (livemode is a WEBHOOKS filter, KEPT there). owner_type:
  `owner_type_type = if length(owner_type_options) <= 3, do: :segmented, else: :select` in
  customers_live mount.
- Segmented cue: compact inline `ax-label` beside non-obvious segmented groups (coupons "valid",
  payment "method"); none for obvious (owner Org/User, livemode Live/Test).
- CONNECT FORK: connect has 6 categoricals (type + 4 booleans + search) → default inline-wrap to
  two rows (no popover).
- DEFERRED: auto active-filter chip summary; FilterChipBar lens usage stays as-is.
- TESTS: keep `data_table_filter`/`phx-debounce="300"`/`data-role="filter-form"|"clear-filters"`/
  `data-phase191-focus` anchors/`:select`/`:datalist`/`:segmented`/DataTableNav single-? merge green;
  knowingly update VISIBLE-Apply / `filter-actions`-div assertions + per-page `:select`→`:segmented`
  filter tests. Plan-check identified the EXACT test edits: `webhook_live_test.exs:82`
  `ax-kpi-grid`→`ax-stat-strip`; `customers_live_test.exs:99` `<select` (owner_type, 2 seeded
  types ⇒ segmented) → a segmented assertion (`class="ax-segmented"` / `name="owner_type"` radio);
  add the StatStrip block in `display_components_test.exs`. Other converted filters
  (invoices/charges/coupons/promo/connect) are URL-param-driven in tests (no `<select>` HTML asserts)
  → stay green. `data_table_test.exs:393` (`filter-submit`) stays green via the hidden submit. Do NOT
  run host tests.

## Guardrails

NO Tailwind (ax-* + tokens). Don't touch StatusBadge, CSP, `examples/accrue_host/mix.lock`,
`.planning/research/.cache/`, ROADMAP.md, `dashboard_live.ex` KPI treatment, or detail-page KpiCard
cards. Rebuild + commit BOTH `priv/static/accrue_admin.{css,js}` (`assets_test.exs` md5). STATE.md
"Quick Tasks Completed". Orchestrator commits docs; executor commits code. On `main`, non-worktree.

## Commits (atomic, bundle last)

1. `feat`: StatStrip component + CSS + dev-lab + tests.
2. `refactor`: migrate all list pages KPI-grid → stat strip (drop `:meta`) + tests.
3. `feat`: condensed filter toolbar in data_table.ex + CSS + tests.
4. `refactor`: per-section control-type reassignment + owner_type dynamic branch + per-page tests.
5. `chore`: rebuild committed bundle.

## Verification

`cd accrue_admin`: `mix compile --warnings-as-errors` clean; `mix accrue_admin.assets.build`; full
`mix test` (report N/M) — display_components, data_table, per-page `*_live_test`,
dev/component_registry, assets all green. Built `accrue_admin.css` contains `.ax-stat-strip` + the
inline-toolbar rules. Render-coverage guardrail green with the new stat-strip family.
