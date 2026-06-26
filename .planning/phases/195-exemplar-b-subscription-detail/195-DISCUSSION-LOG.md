# Phase 195: Exemplar B — Subscription detail - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 195-exemplar-b-subscription-detail
**Areas discussed:** Action prioritization, Band structure + default-open, Overlay primitive scope, Action-menu mechanism

**Method:** User selected all four gray areas and requested deep multi-lens parallel research (Elixir/LiveView idiom; named-competitor lessons; JTBD/persona; a11y; brand voice; software architecture) followed by a single cohesive recommendation package. Four `gsd-advisor-researcher` subagents ran in parallel; their reports were synthesized into the locked decisions in CONTEXT.md.

---

## Action prioritization

| Option | Description | Selected |
|--------|-------------|----------|
| A. Change plan + Cancel renewal | JTBD-frequency pair; mirrors Stripe ("Update" dominant, cancel one rung down) | ✓ |
| B. Change plan only + everything in overflow | Safest single-primary; under-serves the frequent cancel job | |
| C. "Manage subscription" grouped-primary + Cancel | Vague verb (violates brand voice); duplicates the overflow menu | |
| D. Cancel renewal + Pause collection | Wrong JTBD weight; two Stripe-only primaries; two dangerous-adjacent primaries | |

**Selected:** A — `[Change plan]` (swap_plan, filled primary) + `[Cancel renewal]` (cancel_at_period_end, secondary, Stripe/Fake only). Single grouped overflow menu (Edit billing / Collection / Danger zone). Destructive `cancel_now` + `comp_subscription` are menu-only, danger-styled, → step-up modal.
**Notes:** `cancel_at_period_end` (reversible) is the visible cancel; `cancel_now` (immediate) is buried + re-auth-gated — resolves "cancel is frequent AND destructive." Provider gating reuses existing predicates (Braintree → one primary). Microcopy relabels: Swap→Change plan, Cancel at period end→Cancel renewal, Cancel now→Cancel immediately, Create comp replacement→Comp this subscription. The band-research "Retry payment" strawman is not in scope (invoice-level, no such subscription action).

---

## Band structure + default-open

| Option | Description | Selected |
|--------|-------------|----------|
| A. SPEC-canonical 6 bands | summary-list header → action band → drills (one open) → related → timeline → JSON | ✓ |
| B. Add a standalone dunning alert band | Folded into A as the *conditional* default-open promotion, not a permanent 7th band | ✓ (folded) |
| C. Tabs-first | Violates SPEC ("tabs only for peer record-sets"); hides primary state | |

**Selected:** A, with B folded as the dunning-active variant. New `Detail.summary_list/1` GOV.UK component (row-level Change). Default-open drill = "Billing & items", except "Dunning & recovery" when `dunning_campaign_active?`.
**Notes:** Delete the Status KPI + "Canonical predicates" KPI (hide-the-backend leak) + timeline-row count; fold price into Plan/price row. Delete the standalone dunning card (state → header row, detail → drill) and the duplicate related card (migrate unique links into `related_items/3`). Flatten card-in-card by removing the outer actions card (forms move to drawer). Lazy-gate timeline + JSON behind first-expand.

---

## Overlay primitive scope

| Option | Description | Selected |
|--------|-------------|----------|
| A. Build full canonical `<.overlay>` in 195, freeze API; 199 sweeps | Least rework; only reading coherent with 193 D-01 + 198 needing a frozen API | ✓ |
| B. Drawer-scoped, extract/generalize in 199 | Rework; forces the in-scope action-menu popover into a forbidden parallel path | |
| C. Full mechanism in 195 but defer step-up-modal migration to 199 | Same seam quality; budget-relief fallback | ✓ (fallback) |

**Selected:** A, with C as an executor-discretion budget fallback. `<.overlay>` (modal/drawer/popover) + `#ax-overlay-root` body-level portal in root layout + ref-counted iOS-safe `scroll_lock.js` + `inert` toggle + reuse FocusTrap. Re-point `detail_drawer.ex`.
**Notes:** SPEC-DETAIL invariant 4 (`assertTopPointerTarget` + body-scroll) makes portal+inert+scroll-lock non-deferrable for this drawer, so the only choice is sweep (A) vs extract-after (B) — A wins. Prefer native `phx-portal` if confirmed in our pinned LV 1.1, else a portal hook (flagged for research). Mature systems (Radix/Headless/shadcn/Vaul) build the substrate once, never extract after a drawer-only build. 195↔199 boundary captured explicitly in CONTEXT D-03a.

---

## Action-menu mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| A. `<details>`-based `action_menu/1`; only the drawer/modal it opens routes through the primitive | Reuses shipped disclosure + dismissal grammar; honors D-01's actual intent; YAGNI | ✓ |
| B. Render the menu through the overlay primitive as a portal popover | Over-engineers a lightweight menu; couples to in-flight machinery; menu-vs-dialog mixup | |
| C. `<details>` + origin-aware + shared dismissal, no scroll-lock/inert | Folded into A as "A done right" | ✓ (folded) |

**Selected:** A refined by C. Dedicated `action_menu/1` (button/menuitem items, not links), `aria-haspopup="menu"`, reuse dropdown.js dismissal, add `transform-origin: top right`.
**Notes:** Reconciling principle — D-01's "no parallel overlay path" governs the scrim surface (the drawer/modal the menu opens), not the trigger menu; the menu shares dismissal+origin grammar, not scrim/scroll-lock/inert/focus-trap (Radix precedent: DropdownMenu ≠ Dialog). Danger items last, after divider, → step-up modal. Enroll the menu's ancestor in 199's transformed-ancestor audit; portal-the-menu only as an evidence-driven exception.

---

## Claude's Discretion

- Exact `summary_list` markup/CSS, `data-ax-*` placement, new-vs-reused drill copy strings (bounded by no-Tailwind + bundle-rebuild + copy-regen).
- `<.overlay>` slot/attr signature; whether `scroll_lock.js` carries the `inert` toggle inline vs a companion hook.
- Whether D-03b (defer step-up-modal migration to 199) is taken, based on realized plan budget.
- Whether arrow-key roving is added to `action_menu/1` beyond Tab-through (only if UAT asks).
- Placement of the two new `surface_type:"page-flow"` cells relative to `baseline.page-flow.cells.json`.

## Deferred Ideas

- Cross-cutting overlay sweep across all ~20 pages + transformed-ancestor audit + native-`<dialog>` fallback + full IXN battery + microcopy sweep + fixture stress → Phase 199 (IXN-01 owner).
- step-up-modal migration onto `:modal` may slip to 199 (D-03b).
- Portaling the action-menu only if 199's audit finds an unremovable clipping ancestor.
- Arrow-key roving for the action menu (only if UAT asks).
- SPEC-DETAIL propagation to other detail/analytics pages → Phase 198.
- Richer subscription analytics / time-trend → out of scope (structural-streamlining exemplar).
