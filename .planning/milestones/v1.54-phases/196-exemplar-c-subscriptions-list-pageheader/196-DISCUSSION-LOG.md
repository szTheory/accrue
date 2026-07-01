# Phase 196: Exemplar C - Subscriptions list + PageHeader - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-26
**Phase:** 196-exemplar-c-subscriptions-list-pageheader
**Areas discussed:** PageHeader slot contract, Subscriptions list grammar, Four-state coverage, Propagation boundary

---

## Todo Folding

| Option | Description | Selected |
|--------|-------------|----------|
| PageHeader only | Fold the direct shared page header TODO and leave the portal design-system TODO out of this admin phase. | |
| Both TODOs | Fold both matched TODOs into context, while preserving phase scope boundaries. | ✓ |
| Neither TODO | Do not fold either matched TODO. | |

**User's choice:** Both TODOs.
**Notes:** The shared PageHeader TODO is direct Phase 196 scope. The portal design-system TODO is folded as a boundary/deferred signal only; Phase 196 remains `accrue_admin` only.

---

## PageHeader Slot Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Attr-heavy header DSL | `breadcrumbs`, `title`, `description`, `stats`, `actions`, and `filters` as maps. Compact, but duplicates child component APIs and invites API bloat. | |
| Pure slot shell | Caller supplies every piece, including title markup. Flexible, but too little guardrail for one-`h1` and Phase 197 propagation. | |
| Hybrid semantic attrs + bounded slots | Required title/breadcrumb attrs plus bounded slots for description, stat strip, actions, and filter toolbar. Preserves invariants and flexibility. | ✓ |
| Full `ListPage` wrapper | One facade owns header, chips, table, and states. Strong consistency but too much state/resource coupling for Phase 196. | |

**User's choice:** Delegated to research-backed recommendation.
**Notes:** Advisor research selected the hybrid Phoenix function component. It follows idiomatic `attr`/`slot` contracts and keeps `PageHeader` state-free.

---

## Subscriptions List Grammar

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current split grammar | Lowest churn, but incomplete as the LIST archetype because PageHeader, count/clear-all, and column priority remain weak. | |
| `PageHeader` + queue chips + table-owned rows/filters | Matches SPEC-LIST, preserves server-side URL filters and dense table scan, and gives Phase 197 a clear pattern. | ✓ |
| Scope tabs / index views | Familiar admin pattern, but risks duplicating chip state and hiding the current-view explanation. | |
| Nova-style lenses / saved views | Powerful for named resource queues, but overbuilt for this exemplar and likely to create persistence/query ownership churn. | |

**User's choice:** Delegated to research-backed recommendation.
**Notes:** The selected grammar keeps the default `past_due,canceling` queue but presents it as operator work ("At risk"), keeps "All" one chip away, and prioritizes customer/subscription, state, plan/amount, renewal/end time, and signals.

---

## Four-State Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit shared DataTable state resolver | `DataTable` classifies populated, first-run-empty, filtered-empty, and loading-skeleton with stable markers. | ✓ |
| Query-module total count contract | More accurate first-run/filter distinction and true counts, but broad query/API churn. | |
| Parent-owned async DataTable | Clean async lifecycle, but a major rewrite of current LiveComponent ownership and not needed for fast SSR lists. | |
| LiveView loading classes / fixture skeletons only | Cheap as a supporting mechanism, but too weak as the production state model. | |

**User's choice:** Delegated to research-backed recommendation.
**Notes:** Production can remain SSR-synchronous. Loading skeletons are explicit fixture/async states, not fake animation for every patch. Empty copy must distinguish first-run, filtered-empty, and queue-clear.

---

## Propagation Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Exemplar-only, no shared API lock | Lowest churn, but underdelivers PGH-01 and leaves Phase 197 unstable. | |
| Lock `PageHeader` + additive LIST contracts in Phase 196 | Freezes the API and selectors on Subscriptions, then Phase 197 propagates. | ✓ |
| Extract full `ListPage` facade | Strong uniformity, but leaky over resource-specific filters, scoped paths, copy, and bulk actions. | |
| Defer `PageHeader` lock to Phase 197 | Lets API emerge later, but violates the 196 -> 197 dependency and multiplies churn. | |

**User's choice:** Delegated to research-backed recommendation.
**Notes:** Phase 196 locks slot names and `data-ax-*` markers; Phase 197 applies them across remaining list pages; Phase 199/200 keep overlay/theme/final verification ownership.

---

## Claude's Discretion

- Exact CSS layout within existing `ax-*` tokens.
- Exact filter-toolbar extraction shape, provided `PageHeader` proves the `:filter_toolbar` slot without owning filter state.
- Exact lifecycle and plan/amount fallback wording through `AccrueAdmin.Copy`.
- Whether result count lives in `FilterChipBar` or a thin list-status wrapper.

## Deferred Ideas

- Full `ListPage` resource facade.
- Saved views / lenses / scope tabs.
- Exact total-count API across all lists.
- Broad async DataTable rewrite.
- Subscription bulk actions.
- Cross-page overlay/interaction/theme/microcopy sweep.
- `accrue_portal` white-label design-system pass.
