# Phase 190: Navigation, data-display & meta-component cohesion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 190-navigation-data-display-meta-component-cohesion
**Areas discussed:** Group proof model, Data-display degradation, Hierarchy rhythm, Overlay/meta boundary

---

## Group Proof Model

| Option | Description | Selected |
|--------|-------------|----------|
| Lab specimens only | Extend `/billing/dev/components` with explicit group specimens and make it the sole proof surface. | |
| Live pages only | Rely on existing admin pages and baseline routes to prove group cohesion in production context. | |
| Hybrid proof | Use `/billing/dev/components` as the canonical group proof surface and add narrow live-page probes for integration drift. | yes |

**User's choice:** The user selected all gray areas and requested subagent-backed, recommendation-first research.
**Notes:** Advisor research found Phase 187 owner-phase 190 defects are mostly visibility/proof gaps, especially `detail-header/metadata/actions`. The locked recommendation is hybrid proof: deterministic group specimens plus representative live integration probes.

---

## Data-Display Degradation

| Option | Description | Selected |
|--------|-------------|----------|
| Everything through DataTable | Standardize all dense records on `DataTable` with desktop table and mobile card mode. | |
| Specialized tables per domain | Keep domain-specific tables such as `AtRiskTable` and make each responsive independently. | |
| Shared behavior contract | Keep `DataTable` canonical for entity queues while requiring specialized displays to implement the same state, responsive, pagination, and action contract. | yes |

**User's choice:** Recommendation-first research; user asked for one coherent package.
**Notes:** The selected path standardizes behavior rather than markup. Entity queues use `DataTable`; `AtRiskTable` and KPI/chart/table clusters can stay specialized only if they meet the shared contract.

---

## Hierarchy Rhythm

| Option | Description | Selected |
|--------|-------------|----------|
| Local fixes only | Audit and repair each group in place without writing a shared contract. | |
| Full group framework | Add formal shared group grammar/classes/components across most pages. | |
| Small group contract | Define a small canonical group contract, add kitchen specimens, refine CSS/API where repeated markup already drifts. | yes |

**User's choice:** Recommendation-first research; user asked for expert judgment.
**Notes:** The selected path avoids both one-off drift and over-abstraction. It preserves current Phoenix components and adds slots/classes/specimens only where they pay back.

---

## Overlay/Meta Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Leave overlays to 191 | Only document overlay ownership in 190 and defer most work. | |
| Complete overlay contracts now | Build/refine overlay behavior and group contracts in 190. | |
| Group composition now, behavior handoff | Fix reusable visual/group composition in 190 and hand off focus/scroll/page-flow behavior to 191. | yes |

**User's choice:** Recommendation-first research; user asked for scope discipline and cohesive decisions.
**Notes:** The selected boundary matches GRP versus IXN/PAGE requirements. Phase 190 defines title/description/action/layout/layer contracts; Phase 191 handles full focus trap, Escape/click-outside, scroll, patch focus, fixtures, and broad microcopy.

---

## Claude's Discretion

- Exact group-contract artifact shape: registry entries, `GROUP-CONTRACTS.md`, component kitchen sections, or a combination.
- Exact group locator slug grammar, provided it maps directly to Phase 187 `COMPONENT_GROUPS`.
- Exact representative live routes for integration probes.
- Exact CSS versus slot/API split, provided new abstractions are only added where repeated group markup already drifts.

## Deferred Ideas

- Full modal/drawer focus and dismissal behavior - Phase 191.
- Disconnected/reconnecting state, fixture stress, permission-denied state, and page-flow microcopy - Phase 191.
- PhoenixStorybook and pixel-diff visual-regression tooling remain deferred milestone tooling ideas.
