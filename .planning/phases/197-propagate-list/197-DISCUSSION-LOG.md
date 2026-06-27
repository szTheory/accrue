# Phase 197: Propagate LIST - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-27
**Phase:** 197-propagate-list
**Areas discussed:** Work-queue defaults, PageHeader and JTBD copy, Filter chips and list states, Verification breadth

---

## Todo Handling

| Option | Description | Selected |
|--------|-------------|----------|
| PageHeader only | Fold the direct shared PageHeader/list-page todo; keep portal work out of scope. | ✓ |
| Fold both | Fold PageHeader and record the portal todo as a boundary/deferred signal. | |
| Fold neither | Treat both matches as reviewed context only. | |

**User's choice:** Auto-selected conservative default because interactive picker was unavailable.
**Notes:** The shared PageHeader todo is direct Phase 197 propagation scope after Phase 196 created the component. The portal design-system todo was reviewed and deferred as future `accrue_portal` work.

---

## Work-queue Defaults

| Option | Description | Selected |
|--------|-------------|----------|
| Strict exception queue on every page | Forces every page to open on a narrowed exception queue. Uniform but manufactures weak queues for lookup/ledger surfaces. | |
| Semantic per-resource default lens | Treats "work queue" as the default operator job: exception queues where real, all/reference defaults where least-surprise. | ✓ |
| All-by-default everywhere | Predictable for lookup but violates SPEC-LIST expectations for invoices/payments/webhooks/subscriptions. | |
| Saved views / lenses / scope DSL | Extensible pattern similar to Polaris saved views or Nova lenses, but new capability and abstraction creep for Phase 197. | |

**User's choice:** User requested all areas be researched and delegated final recommendations.
**Notes:** Advisor research recommended semantic defaults: customers all lookup; invoices needs collection; payments failed; coupons valid; promotion codes active; webhooks needs replay; events all ledger with actor lens; connect needs attention. This preserves SPEC-LIST intent without hiding expected reference data.

---

## PageHeader and JTBD Copy

| Option | Description | Selected |
|--------|-------------|----------|
| Strict exemplar parity | Adopt `PageHeader` on all 8 pages, write per-page JTBD copy, keep filters/resource state LiveView-owned. | ✓ |
| Visual normalization only | Wrap current headers but leave uneven chips, states, and generic copy in place. Lower risk, incomplete SPEC-LIST. | |
| New `ListPage` facade/resource DSL | Centralize header/table/filter/chip behavior in one runtime abstraction. Strong DRY, but premature and leaky. | |

**User's choice:** User requested one-shot recommendations optimized for DX, UI/UX, least surprise, and project vision.
**Notes:** Research across Phoenix, Polaris, GOV.UK/MOJ, Stripe, ActiveAdmin, and Nova pointed to a page shell separated from resource-owned filters/actions. `PageHeader` remains stateless; each LiveView owns query params, copy, and bulk behavior.

---

## Filter Chips and List States

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView-owned exemplar propagation with visible counts | Copy the Subscriptions structure page-by-page: URL state in LiveView, `FilterChipBar` for chips/count/clear-all, visible row counts. | ✓ |
| Narrow shared helper | Extract a pure helper if repeated chip/clear/list-state boilerplate appears after a few migrations. | |
| DataTable-owned chips/count/clear-all config | Push selected-filter semantics into `DataTable`. Strong invariant enforcement, but hides resource semantics and bloats the component. | |
| Exact total query extension | Add exact count queries for every page. More precise, but heavier and often misleading under cursor/scoped queries. | |

**User's choice:** User requested coherent recommendations rather than manual selection.
**Notes:** Decision keeps `FilterChipBar` in the `DataTable` `:list_status` slot and uses honest visible counts unless exact scoped counts are genuinely implemented. Clear-all must preserve owner scope and avoid redirect loops.

---

## Verification Breadth

| Option | Description | Selected |
|--------|-------------|----------|
| Direct full matrix across all 8 pages | Exhaustive `8 x 4 states x themes x viewports` browser proof. High confidence, high runtime/fixture cost, overlaps Phase 200. | |
| Focused subset + shared component tests + all-page smoke | Component tests for shared contracts, LiveView tests for every page, all-page Playwright smoke, and representative deep coverage. | ✓ |
| Hand-authored/generated LIST contracts | Thin test manifest for route/list/default expectations. Useful if hand-authored; dangerous if it becomes a DSL. | ✓ as test-only support |

**User's choice:** User requested research-backed final recommendations.
**Notes:** Recommendation is all-page contract smoke plus deeper representative coverage, with a small hand-authored test manifest if useful. Full union baseline, Storybook breadth, axe/no-FOUC, and final sign-off remain Phase 200.

---

## Claude's Discretion

- Exact chip and empty-state copy within the locked per-page default lenses and brandbook voice.
- Whether to extract a narrow helper after early migrations prove repeated boilerplate.
- Exact representative page set for deeper Playwright coverage, provided reference, queue, bulk-action, ledger, and OR-lens cases are covered.
- Placement of a test-only LIST contract manifest.

## Deferred Ideas

- Runtime `ListPage` facade/resource DSL.
- Saved views, persisted lenses, or user-defined queues.
- Exact total-count API across every list.
- Full all-pages browser state matrix, Storybook completeness, axe/no-FOUC, and final zero-regression sign-off.
- Cross-cutting overlay/interaction/fixture-stress/microcopy sweep.
- `accrue_portal` white-label billing portal design-system pass.
