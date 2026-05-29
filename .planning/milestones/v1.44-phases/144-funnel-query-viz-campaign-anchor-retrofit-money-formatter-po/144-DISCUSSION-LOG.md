# Phase 144: Funnel query + viz + campaign-anchor retrofit + money formatter polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish
**Areas discussed:** Active-stage funnel attribution (DAN-01), Legacy campaign_anchor fallback (DAN-02), FunnelChart visual layout (DAN-09), Currency strategy on KPI cards (DAN-13)
**Mode:** Advisor (USER-PROFILE present), calibration tier `minimal_decisive` (opinionated philosophy → 1–2 options each, decisive single rec)

---

## Active-stage funnel attribution (DAN-01)

Advisor-researched in parallel. Decisive single recommendation per `minimal_decisive` tier.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Pure-ledger set-difference (single GROUP BY (subject_id, anchor) + `bool_or(type IN ('recovered','exhausted'))` flag, NOT EXISTS converted to anti-join by Postgres planner) | One Ecto query, ledger-canonical, immutable historical truth. Satisfies literal `from(e in Event, ...)` single-query requirement. Preserves Phase 143's pure-ledger JSONB precedent. The `bool_or` aggregation avoids correlated subqueries entirely. | ✓ |
| B. Ledger ∩ schema-join (entered tuples ∩ `subscriptions WHERE dunning_campaign_started_at IS NOT NULL` minus concluded ledger tuples) | Mirrors Phase 146 at-risk semantics for cross-surface consistency, but historical funnel counts warp if subscriptions are hard-deleted or status-mutated. Breaks Phase 143's pure-ledger precedent. Couples funnel to schema migration ordering. | |
| C. Two-step queries + MapSet.difference/2 in Elixir | Sidesteps SQL complexity but violates the literal "single Ecto query — not Task.async per stage" requirement and adds memory cost. | (disqualified by REQUIREMENTS, not presented) |

**User's choice:** A — confirmed recommended pick.
**Notes:** Implementation: `GROUP BY (subject_id, COALESCE(data->>'campaign_anchor', '__legacy__'))` with `bool_or(type IN ('dunning.recovered','dunning.exhausted'))` flag. Aggregate per-stage counts via `COUNT(...) FILTER (...)` in a single pass.

---

## Legacy `campaign_anchor` fallback (DAN-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `COALESCE(data->>'campaign_anchor', '__legacy__')` — sentinel-per-subject | Collapses all pre-retrofit events for a subject into ONE tuple per stage ("earliest known single-row stage attribution" per REQUIREMENTS line 22). Canonical Postgres NULL-tolerant `COUNT(DISTINCT)` idiom. Under-count is the safe failure mode — Pitfall #1 was double-counting. | ✓ |
| B. `COALESCE(data->>'campaign_anchor', e.id::text)` — per-event surrogate | Preserves raw event count fidelity but directly contradicts REQUIREMENTS line 22; over-counts cycled subjects; inflates the trust-critical recovered-revenue KPI (Pitfall #1 re-introduced). | |
| C. `WHERE data ? 'campaign_anchor'` — filter-out legacy entirely | Heavy under-count; effectively the same as the *de facto* NULL-drop behavior of `COUNT(DISTINCT (subject_id, NULL))` but explicit. | (disqualified — heavy under-count, presented in research for context) |

**User's choice:** A — confirmed recommended pick.
**Notes:** Operational footprint near-zero — v1.4.0 unpublished, "legacy" window is only Phase 143 → Phase 144 in adopter dev envs. Pair with extending DAN-14's "Showing data since YYYY-MM-DD" cutoff badge for the funnel anchor cutoff (Phase 148 scope; P144 only documents the semantics in the `funnel/1` `@doc`).

---

## FunnelChart visual layout (DAN-09)

| Option | Description | Selected |
|--------|-------------|----------|
| B. Left-aligned horizontal proportional bars (each stage = one `<rect>` width = `stage_count / entered_count`) | Trivial SVG math; reuses `ax-kpi-sparkline` idiom; themes free via `currentColor` + `var(--ax-accent)`; per-bar `<title>` for hover tooltips; external `<dl>` legend for a11y/zoom; concrete `viewBox="0 0 100 36"` + per-row `<g transform="translate(0, idx*12)">` SVG sketch returned. | ✓ |
| A. Centered trapezoidal classic funnel (polygon SVG narrowing top-to-bottom) | Visually iconic "funnel" silhouette but stylistically incompatible with Accrue's restrained rectangular `ax-card` idiom — reads as a third-party chart-library widget bolted on. Trapezoid math non-trivial; degrades poorly at severe drop-offs. | |
| C. Vertical column chart | Loses "funnel" semantic; treats stages as equivalent categories rather than flow. | (disqualified — doesn't read as funnel, dropped by advisor under `minimal_decisive`) |

**User's choice:** B — confirmed recommended pick.
**Notes:** Concrete SVG markup sketch + tone palette (slate/moss/amber from `ax-kpi-delta-*`) captured in CONTEXT.md D-13 through D-18. Component file: `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`. Closest analog: `accrue_admin/lib/accrue_admin/components/kpi_card.ex`.

---

## Currency strategy on KPI cards (DAN-13, pre-DAN-07)

| Option | Description | Selected |
|--------|-------------|----------|
| A. `Accrue.Config.default_currency()` | Deterministic, host-controlled, matches Pay/Cashier "tenant default" convention. Leaves `recovered_vs_lost_mrr/1` shape UNTOUCHED → Phase 148's per-currency widening is a single clean BREAKING edit, not "undo P144 first then widen". JPY regression test passes via `Application.put_env(:accrue, :default_currency, :jpy)` in setup (standard ExUnit pattern). When P148 widens, this code path is DELETED wholesale — zero migration churn. | ✓ |
| B. `MAX(currency)` from the aggregation (data-driven) | DAN-13 JPY test passes "naturally" without config override but introduces an intermediate API shape that P148 must undo. The `cents` value is already a cross-currency sum, so adding the latest event's symbol is no MORE honest than the tenant default. Churns the P148 migration. | |
| C. Move DAN-07 forward into P144 (widen API now) | Ships correctly first time but breaks the milestone roadmap structure — DAN-07 is explicitly bundled with DAN-06/14/15/16 as the "freeze for 1.4.0 publish" slice. | (disqualified — violates milestone structure, presented in research for context) |
| D. Group_by currency in aggregation now | Forward-compatible with DAN-07 but renders multiple cards in P144 — UX inconsistency between P144 ship and P148 ship. | (disqualified, dropped under `minimal_decisive`) |

**User's choice:** A — confirmed recommended pick.
**Notes:** Use `AccrueAdmin.Components.MoneyFormatter` (already wired through CLDR `Render.format_money/3`) instead of `format_minor/1`. The single-aggregate `%{recovered_cents, lost_cents}` shape stays untouched in P144; P148 widens cleanly.

---

## Claude's Discretion

Items not bounced back to the user — planner has flexibility:
- Test file placement for the campaign-anchor retrofit assertions (`dunning_exhaustion_test.exs` for exhausted edge; `dunning_campaign_keying_test.exs` or a new `dunning_recovery_test.exs` for recovery edge).
- Exact CSS values for `.ax-funnel-*` classes (pick from existing `ax-` tokens; no new design-system tokens).
- Exact `stream_data` generator shape for the funnel property test (subject_id pool size, event sequence length distribution).
- Whether to extract a shared `defp safe_mrr_cents_sum` macro/helper for the JSONB CASE-WHEN cast or inline at each call site (lean inline — only 1–2 call sites in P144).
- ExDoc `@doc` examples on `funnel/1` (include at least one `iex>` example with a cycled-dunning fixture so the DISTINCT-tuple semantics are self-documenting).
- Exact yearly-plan worked-example copy in the "Exhausted MRR" tooltip — phrasing the planner can polish.

## Deferred Ideas

All v1.44-out-of-scope items already documented in `.planning/REQUIREMENTS.md` §"Out of Scope" — no new deferrals surfaced in this discussion. Cross-phase work explicitly handed off in CONTEXT.md §Deferred:
- Per-currency widening, `recovery_rate/1`, `guides/analytics.md`, adopter-proof matrix row, `@moduledoc` expansion → Phase 148.
- Time-window URL plumbing → Phase 145.
- At-risk query + table + last-failure enrichment → Phase 146.
- `campaign_timeline/2` + drill-down route + `CampaignLive` → Phase 147.
- "Showing data since YYYY-MM-DD" cutoff badge UI → Phase 148 (P144 only documents semantics).
