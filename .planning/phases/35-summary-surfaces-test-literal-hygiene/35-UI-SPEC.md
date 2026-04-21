# Phase 35 — UI design contract

**Selected framework:** Phoenix LiveView + HEEx (`accrue_admin`)  
**Status:** Planning artifact — token-safe KPI rows and copy SSOT for operator dashboard.

---

## Surfaces in scope

| Surface | Route(s) | Intent |
|---------|----------|--------|
| Operator dashboard | `live("/", DashboardLive)` | KPI grid, page chrome (`ax-page-header`), dual `Timeline` columns; all operator-visible English routes through `AccrueAdmin.Copy`; layout stays `ax-*` only (no ad-hoc hex in HEEx). |

---

## Visual + interaction rules

1. **Tokens (OPS-04)** — Reuse existing `ax-display`, `ax-eyebrow`, `ax-body`, `ax-kpi-grid`, `ax-card`, `ax-timeline` classes only. Any new KPI chrome extends `accrue_admin/assets/css/app.css` with variables already used by `KpiCard` / shell; document exceptions in plan notes if a new semantic token is unavoidable.
2. **Copy SSOT (OPS-05)** — Every literal shown to operators on this page (headlines, KPI labels, `<:meta>` blurbs, section `aria-label`s, timeline `label` / `empty_label`, breadcrumb crumb) is a `AccrueAdmin.Copy` function; no raw English in `dashboard_live.ex` HEEx except dynamic fragments composed from `Copy` + numeric/format helpers.
3. **Linked KPI cards** — Unchanged from Phase 34: `href`, `aria_label`, `ScopedPath.build/3`; `aria_label` strings also live in `AccrueAdmin.Copy`.
4. **Timelines** — `Timeline` slots pass `Copy.*` for `label` and `empty_label`; event row `title`/`body` remain data-driven from projections (not copy SSOT).

---

## Tests + VERIFY-01

- **ExUnit:** Assertions use `AccrueAdmin.Copy.*` (or `html =~ Copy.foo()`) so literals cannot drift from SSOT.
- **Playwright / Node smoke:** Strings asserted in JS import a single `examples/accrue_host/e2e/support/copy_dashboard.js` module kept in lockstep with `AccrueAdmin.Copy` (same PR touches both; acceptance greps prove headline appears exactly once per file).

---

## Out of scope (Phase 35)

- Nav label rewrites (`AccrueAdmin.Nav`) beyond what VERIFY-01 already matches with regex.
- `Timeline` internals (`Inspect details` default) unless explicitly passed from `DashboardLive`.
- New charting, new KPI metrics, billing query changes.

---

*Contract locked for Phase 35 planning.*
