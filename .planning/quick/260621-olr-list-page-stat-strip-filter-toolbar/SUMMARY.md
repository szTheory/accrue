---
quick_id: 260621-olr
slug: list-page-stat-strip-filter-toolbar
date: 2026-06-21
status: complete
validate: true
verify: Verified
---

# Summary: Admin list pages — compact stat strip + condensed filter toolbar

Research-backed redesign of every admin list/index page: oversized KPI cards + a tall label-stacked
filter form pushed the table below the fold. Tightened both, within brand, across all 9 list pages
(`--validate`: plan-check PASS 1st iteration w/ 3 corrections folded in; verification PASS 7/7,
suites independently re-run). 5 atomic code commits on `main`, non-worktree.

## What changed

**Part A — metrics → compact inline "stat strip"** (cuts the ~200px KPI band to ~48-56px; v1.51
"demoted KPIs"):
- NEW `components/stat_strip.ex`: chromeless `<dl class="ax-stat-strip">` + `:stat` slot
  (label/value/optional tone moss|cobalt|amber/optional href). Tone colors the VALUE only (no wash);
  hairline dividers; tokens-only CSS; stacks + drops dividers <30rem. Dev-lab `stat-strip` family
  registered + a dedicated `do_render_specimen` clause (render-coverage guardrail 8/8).
- Migrated all 9 list pages (customers, subscriptions, invoices, charges, webhooks, events, coupons,
  promotion_codes, connect_accounts) from `ax-kpi-grid` + KpiCard → StatStrip; dropped the `<:meta>`
  captions. **KpiCard untouched** on the dashboard, recovery, and all detail pages (frozen surfaces).

**Part B — filters → condensed instant-apply toolbar:**
- `data_table.ex`: single flex toolbar (search grows; controls wrap <768px). Per-field labels →
  `ax-visually-hidden`; **dropped the visible Apply button** (instant `phx-change` already applies;
  text debounced 300ms) while keeping a visually-hidden submit (preserves the `filter-submit`
  anchor). Context-only **Clear** rendered only when `any_filter_active?/1`. `:select` primitive
  gained an optional `all_label` so the default option names its dimension ("All owner types" etc.).
- **Control-type reassignment** — 2–3-value `:select`s → `:segmented` toggles (each prepends
  `{"", "All"}`): customers has_default_payment_method; invoices collection_method; charges
  fees_settled; coupons valid; promotion_codes active; connect type + charges_enabled +
  payouts_enabled + details_submitted + deauthorized (6 categoricals, plan-check-corrected — no
  livemode on connect). **owner_type** uses a dynamic branch: `length(options) <= 3 → :segmented,
  else :select` — so the 2-value Organization/User case is now a toggle, not a dropdown (the user's
  specific complaint). Webhooks keeps select(+counts)/datalist/segmented; subscriptions/invoices
  status stay `:select`.

Rebuilt the committed `priv/static/accrue_admin.css` (final commit); `accrue_admin.js`
byte-unchanged (no JS edits).

## Result

`mix compile --warnings-as-errors` clean; full `mix test` → **350 tests, 0 failures**
(display_components +StatStrip block, data_table, all 9 per-page `*_live_test`,
dev/component_registry 8/8, assets md5 3/3). Built `accrue_admin.css` contains `.ax-stat-strip` +
the inline-toolbar rules.

## Commits
- `d127a7e0` — feat: StatStrip component + CSS + dev-lab registration + tests
- `1d437ebb` — refactor: migrate all 9 list pages KPI-grid → stat strip (drop `:meta`)
- `303f8179` — feat: condensed instant-apply filter toolbar in data_table.ex + CSS
- `f9cf6579` — refactor: per-section control-type reassignment + owner_type dynamic branch + tests
- `24033366` — chore: rebuild committed CSS bundle

## Notes / decisions
- **Plan-check corrections folded in before execution:** connect's real 6-categorical set (+
  details_submitted/deauthorized, no livemode); self-labeling "All X" is a `:select` *primitive*
  edit (`all_label`), not per-field; exact dev-lab registration shape + dedicated specimen clause.
- **Accepted deviation (executor was right, plan was wrong):** did NOT flip
  `webhook_live_test.exs:82` `ax-kpi-grid`→`ax-stat-strip` — line 82 tests the webhooks **detail**
  page (`/billing/webhooks/:id`, keeps KpiCard per guardrail); the webhooks **list** test has no
  such pin. Plan-check misattributed detail-vs-list.
- **Minor:** segmented groups self-label via `aria-label` + visually-hidden labels + self-describing
  option text (e.g. "On file/Missing") rather than adding visible inline `ax-label` cues — the cue
  was an optional styling suggestion, not a requirement; no a11y regression.
- Guardrails honored: no Tailwind; StatusBadge/CSP/host mix.lock/ROADMAP/dashboard/recovery/detail
  KpiCard untouched; no host tests run (off-limits stale host mix.lock).

## Browser-only follow-up (user visual confirm on the demo)
`/admin/customers`, `/admin/subscriptions`, `/admin/webhooks` (mobile + desktop, light/dark/system):
(a) metrics are a compact one-line strip; (b) the filters/table sit near the top, not below the
fold; (c) filters are a single tidy row that wraps on mobile, owner-type is a toggle (no 2-value
dropdown), filtering is instant (no Apply click), Clear shows only when a filter is active; (d) no
decorative accent wash, no hover/focus weirdness.

## Related follow-up captured
Todo `.planning/todos/260622-admin-page-header-microcopy-audit.md` — systematic audit of per-section
page-header microcopy (h1 + subtitle) for a consistent JTBD-oriented voice (recovery page has no
subtitle; align all sections with the customers philosophy). Pairs naturally with this redesign.
