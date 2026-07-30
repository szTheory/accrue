# Phase 209: Reign Subscriptions (list + detail CSS coordination) - Context

**Gathered:** 2026-07-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Recompose the **Subscriptions list** page (`accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`) onto the canonical shared component spine (AppShell → `section.ax-page` → `PageHeader` → `FlashGroup` → shared `DataTable` + `FilterChipBar`), pivoting it to answer-first IA: collapse the triplicated health verdict to **one**, the triplicated "Open dedicated invoice queue" CTA to **one**, remove the five bespoke band `<section>`s between the header and the table, rebuild the compact table cells from shared primitives, and coordinate the CSS shared with the out-of-scope subscription **detail** page (`subscription_live.ex`). Delivers **REIGN-01, REIGN-02, COMP-01**.

**This is a REIGN, not a redesign.** No new tokens, no new palette, no new deps, at most one new shared component (`WorkQueueCallout` — decision deferred to Phase 210, see D-02). CSS **deletion** is deferred to Phase 211; Phase 209 only stops *referencing* retired classes. Console **density is the point** — do not over-air.

</domain>

<spec_lock>
## Requirements (locked — UI-SPEC + milestone REQUIREMENTS)

**Two locked contracts govern this phase — downstream agents MUST read both before planning:**

1. `.planning/phases/209-reign-subscriptions-list-detail-css-coordination/209-UI-SPEC.md` — the approved visual & interaction design contract (design system, spacing, typography, color, copywriting contract, 8-point interaction/structural contract). Locks the *how it looks and reads*.
2. `.planning/REQUIREMENTS.md` — milestone requirements. This phase delivers **REIGN-01** (list composed only from the canonical skeleton; bespoke `.ax-subscriptions-*` / `.ax-inline-worklist*` bands + override classes removed), **REIGN-02** (compact shared cell idiom, no in-cell action buttons), **COMP-01** (`WorkQueueCallout` extract-or-inline decision).

**In scope:** `accrue_admin` LiveView template (`subscriptions_live.ex`) + `assets/css`; markup/selector migration for retired classes; both generated-artifact rebuilds (`priv/static/accrue_admin.css` via `mix accrue_admin.assets.build`, `examples/accrue_host/e2e/generated/copy_strings.json` via `mix accrue_admin.export_copy_strings`); `AccrueAdmin.Copy` additions for new strings.

**Out of scope (binding scope fence):** NO core `accrue/lib` change (M2); NO new nav rooms (M3); NO "why blocked"/causality/diagnosis synthesis; NO new deps; NO Tailwind migration (`ax-*` stays the styling SSOT); NO `accrue_portal` work. **CSS class deletion is Phase 211** (grep-gated) — 209 preserves every CSS rule shared with the detail page. Home (`dashboard_live.ex`) is Phase 210.

</spec_lock>

<decisions>
## Implementation Decisions

### Per-row action treatment (REIGN-02)
- **D-01:** **Drop the per-row action entirely — the whole row navigates.** The reference list pages (`invoices_live.ex`, `customers_live.ex`) have **no** per-row action column; the identity cell is an `ax-link` and the row navigates to the detail page (`DropdownMenu`/`action_menu` appear only on *detail* pages, never list pages). The Subscriptions list matches this exactly: identity cell → `ax-link` to `/subscriptions/:id` (the subscription detail); the current in-cell "Work open invoices" button is removed, **no** actions column and **no** per-row `DropdownMenu` are added. The invoice-queue action exists **only** as the single `PageHeader` `:actions` CTA. Best density, best consistency with the good pages.
- **Content-preservation implication:** removing the in-cell action AND the open-invoice preview-list band means the open-invoice count/exposure data is preserved by relocating it into the StatStrip verdict (see D-03), not lost.

### WorkQueueCallout — extract-or-inline (COMP-01)
- **D-02:** **Inline now, decide extraction in Phase 210.** Compose the Subscriptions worklist callout from `.ax-card` directly in Phase 209 (reusing the existing `moss`/`cobalt`/`amber`/`slate`/`ink` tone scale). COMP-01 formally resolves as **"inline"** for 209. The extract-vs-keep-inline call is made in Phase 210 when Home's attention rail is actually in front of the implementer and the "demonstrably repeats" test is genuinely provable — avoiding a speculative abstraction built before its second consumer is seen. If Home's shape matches in 210, `WorkQueueCallout` is extracted then and both pages adopt it; otherwise both stay on `.ax-card`.

### Health verdict composition (IA-01 / content-preservation)
- **D-03:** **Exposure-first single verdict.** The collapsed single verdict renders as a `StatusBadge` (`Healthy` moss / `Action required` amber-danger) + a `StatStrip` leading with money-at-risk: **Open invoices (count) · Exposure ($ to collect) · At-risk subscriptions (count) · Last webhook (status · time)**. Money-at-risk leads because it is the operator's first question. Every datum currently spread across the five removed bands (at-risk exposure, last-webhook status, open-invoice count/exposure) must land in this StatStrip — the content-preservation proof required by the UI-SPEC drives the final set.

### Detail-page shared-CSS coordination (REIGN-02 → REIGN-04/Phase 211 handoff)
- **D-04:** **Grep-gate + zero shared-CSS edits + PNG-verify the detail page.** Procedure: (1) after the list template migration, `grep` the `.ax-inline-worklist*` / `.ax-inline-worklist-copy` / `.ax-inline-worklist-actions` / `.ax-audit-summary-row` classes across `*.ex` to confirm the only remaining references are `subscription_live.ex` (the out-of-scope detail page); (2) make **zero** edits to those shared CSS rules in Phase 209 (all deletion is Phase 211's grep-gated job); (3) PNG-capture the subscription **detail** page before/after the list changes and confirm it is visually identical. This is the phase's namesake risk — the detail page must be provably unbroken.

### Claude's Discretion
- Exact `PageHeader` slot wiring (`:description` / `:stat_strip` / `:filter_toolbar` / `:actions`), the specific `StatStrip` stat structs, and the DataTable column render-fn refactor (rebuilding `identity_cell/3` + `billing_signals_cell/3` from `StatusBadge` + `.ax-stack-xs` + `.ax-link` + `.ax-chip.ax-label`) are left to the planner/executor, constrained by the UI-SPEC contract.
- The now-dead `open_invoice_queue/1` query (and `invoice_queue_record_href` helpers feeding the removed preview band) should be removed as part of the band removal.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked phase contracts (read first)
- `.planning/phases/209-reign-subscriptions-list-detail-css-coordination/209-UI-SPEC.md` — approved visual & interaction design contract; the 8-point "Interaction & Structural Contract" is the load-bearing reign checklist.
- `.planning/REQUIREMENTS.md` — milestone requirements; REIGN-01 / REIGN-02 / COMP-01 are this phase's acceptance items (§ "Traceability" table maps them to Phase 209).

### Milestone design sources
- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — SEED-004 north-star ("operator control plane over billing state").
- `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` — self-contained synthesis.
- `.planning/research/admin-ratchet-round99-confirmed-findings.json` — 23 ratchet-confirmed IA findings; the subset on `subscriptions` is the acceptance checklist input (triplicated CTA is the most-confirmed defect).
- `.planning/ROADMAP.md` § "v1.57 Admin Operator Control Plane (SEED-004 M1)" — phase sequencing, scope fence, generated-artifact + grep-gate rules.

### Code touchpoints (target + references)
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — the target (currently ~line 98 bespoke bands, 143 kpi-row wrapper, 198–264 five bands, 298–319 cell render-fns, 407+ `open_invoice_queue/1`).
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` & `customers_live.ex` — the canonical reference list pages (spine + compact-cell + whole-row-nav idiom to match).
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` — the out-of-scope detail page sharing `.ax-inline-worklist*` / `.ax-audit-summary-row` (PNG-verify unbroken).
- `accrue_admin/assets/css/theme.css` (semantic `--ax-*` tokens) + `accrue_admin/assets/css/app.css` (`ax-*` classes) — styling SSOT; edits require `mix accrue_admin.assets.build` + committing `priv/static/accrue_admin.css`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Canonical spine components:** `AppShell`, `PageHeader` (`:description`/`:stat_strip`/`:filter_toolbar`/`:actions`), `FlashGroup`, `DataTable`, `FilterChipBar` (used in `:list_status`), `StatusBadge`, `EmptyState`, `StatStrip` — all already consumed by `invoices_live.ex` / `customers_live.ex`. Compose from these; do not fork.
- **Compact cell idiom** (from `invoices_live.ex:240`): identity cell is `<span class="ax-stack-xs"><a href=… class="ax-link">…</a><a class="ax-label ax-muted">…</a></span>` — the exact pattern the Subscriptions cells rebuild to.
- **`AccrueAdmin.Copy`** — all operator strings sourced here (add `Copy.Subscription`/`Copy` fns); no inline template literals, keeps `copy_strings.json` SSOT.

### Established Patterns
- **List pages have no per-row action column** — whole row navigates via `ax-link`; `DropdownMenu`/`action_menu` are a detail-page-only idiom (confirms D-01).
- **FilterChipBar** lives in the DataTable `:list_status` slot with `filter_chip_label/1` + `filter_chip_value/2` helpers (see `customers_live.ex:288–347`, `invoices_live.ex:346–387`) — mirror for Subscriptions filters.
- **Build contract:** editing `app.css` ships nothing until `mix accrue_admin.assets.build` regenerates the committed `priv/static/accrue_admin.css`; copy changes need `mix accrue_admin.export_copy_strings`. Both artifacts committed every change.

### Integration Points
- Subscriptions filters already feed the DataTable; the reign preserves filter behavior while relocating verdict/queue data into `PageHeader`/`StatStrip`.
- Retired-class selector assertions (e.g. `subscriptions_live_test` on `ax-kpi-row ax-subscriptions-kpi-row`, ~line 111) migrate to shared-component selectors **in this phase**.

</code_context>

<specifics>
## Specific Ideas

- Row navigation target is the subscription **detail** page (`/subscriptions/:id`), matching how Invoices/Customers rows navigate to their detail.
- Verdict badge language is locked by the UI-SPEC copy contract: `Healthy` (moss) vs `Action required` (amber/danger); primary CTA is `Open invoice queue` (drop "dedicated").
- Breadcrumbs are a real 2-crumb trail `[ Home , Subscriptions ]` — the fake `"Billing health overview"` parent is removed (no navigable target).

</specifics>

<deferred>
## Deferred Ideas

- **`WorkQueueCallout` extraction** — deferred to Phase 210 (D-02); decided there once Home's attention rail proves (or disproves) the repeated shape.
- **CSS class deletion** (`.ax-subscriptions-*`, `.ax-inline-worklist*`, `.ax-audit-summary-row`, etc.) — deferred to **Phase 211** (grep-gated, zero-reference-verified) per REIGN-04. 209 only stops referencing them from the list.
- **Home page reign** (`dashboard_live.ex`) + the cross-page IA-01..04 / COPY-01/02 certification — **Phase 210**.
- **Answer-first reign of remaining detail surfaces** (subscription-detail, customer-detail, component-kitchen) beyond the shared-CSS coordination — out of milestone (noted in REQUIREMENTS "Out of scope").

None of the above are scope creep introduced in discussion — they are the roadmap's own sequencing boundaries.

</deferred>

---

*Phase: 209-reign-subscriptions-list-detail-css-coordination*
*Context gathered: 2026-07-19*
