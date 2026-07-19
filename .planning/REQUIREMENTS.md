# Requirements: Accrue — Milestone v1.57 Admin Operator Control Plane (SEED-004 M1)

**Defined:** 2026-07-19
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX. This milestone begins the SEED-004 redesign of `accrue_admin` from a CRUD surface into an operator control plane, starting with the M1 information-architecture / grammar pivot.

**Milestone goal:** Reign the two outlier pages (Home + Subscriptions) onto the same shared component vocabulary the rest of the admin already uses, and pivot their information architecture to "answer-first" (one health verdict + one primary action per zone, redundant bands trimmed) — so the whole admin reads as one cohesive, operator-first system, as a proper baseline before M2's signature diagnostic surfaces.

**Authoritative design sources:** `prompts/accrue_admin_operator_ui_journey_blueprint.md` (north-star), `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` (synthesis), `.planning/research/admin-ratchet-round99-confirmed-findings.json` (23 ratchet-confirmed IA findings; the 12 on `dashboard` + `subscriptions` are the M1 acceptance checklist), plus `.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS,SUMMARY}.md`.

**Scope guardrails (binding):** Admin-only — `accrue_admin` LiveView templates + `assets/css`. NO core `accrue` change (M2), NO new nav rooms (M3), NO new deps, NO Tailwind migration, `ax-*` stays the styling SSOT, no `accrue_portal` work. Reuse the shared component library (compose, don't fork; improving a shared component is allowed, forking is not). Keep the Cobalt / quiet-confidence brand and the prior de-garish + card-grammar polish passes. Console **density is the point** — do not over-air. Every CSS/copy change rebuilds + commits the two generated artifacts (`priv/static/accrue_admin.css`, `examples/accrue_host/e2e/generated/copy_strings.json`); CSS retirement is grep-gated (classes shared with the out-of-scope subscription detail page are preserved). PNG-verify against the canonical Payments/Customers/Invoices reference.

---

## v1 Requirements

Requirements for this milestone (M1). Each maps to exactly one roadmap phase.

### Shared-Component Reign (REIGN)

- [x] **REIGN-01**: The Subscriptions list page is composed only from the canonical shared skeleton (AppShell → `section.ax-page` → `PageHeader` with `:description`/`:stat_strip`/`:filter_toolbar` → `FlashGroup` → shared `DataTable` with `FilterChipBar` in `:list_status`); the bespoke `.ax-subscriptions-*` / `.ax-inline-worklist*` band sections between the header and the table are removed, and the page-specific override classes (`ax-page-compact`, `ax-subscriptions-header`, `ax-kpi-row` wrapper) are dropped.
- [x] **REIGN-02**: Subscriptions table cells render via the compact shared idiom (`StatusBadge`, `ax-stack-xs`, `ax-link`, `ax-chip ax-label`) with no in-cell action buttons — per-row actions move to a shared control (dedicated actions column or `DropdownMenu`), matching the good pages.
- [ ] **REIGN-03**: The Home page is composed from the canonical `PageHeader` (breadcrumbs + title + `:description`/`:actions`/`:stat_strip`) instead of a hand-rolled header, and its attention rail + task-launcher tiles are rebuilt from shared primitives (`.ax-card` + `Button` + `Icon` + `StatusBadge`, `EmptyState` for empty branches); the already-canonical `KpiCard` "At a glance" band and `Timeline` activity cards are kept.
- [ ] **REIGN-04**: The bespoke `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-subscriptions-*` / `.ax-inline-worklist*` / `.ax-subscription-row-*` CSS is retired (grep-gated — only classes with zero remaining `.ex` references; classes still used by the subscription detail page `subscription_live.ex` are preserved), the committed `priv/static/accrue_admin.css` bundle is rebuilt, and all in-repo test/e2e selector assertions on retired classes are migrated in the same phase.

### Answer-First Information Architecture (IA)

- [ ] **IA-01**: Each of the two pages presents exactly one scannable billing-health verdict — Home's verdict (currently rendered three times) and the Subscriptions sentence-title verdict collapse to a single clear statement per page.
- [ ] **IA-02**: Each zone offers one unambiguous primary action — the duplicated invoice-queue entry point (Subscriptions "Open dedicated invoice queue", currently 3+ occurrences — the most-confirmed round-99 defect) and the triplicated customer-search entry (Home) are each de-duplicated to a single clear control.
- [ ] **IA-03**: Redundant bands/sections are trimmed so each page leads with its answer, while operator console density is preserved — the reigned pages show no spacing-density regression versus their pre-reign state.
- [ ] **IA-04**: Content on both pages is ordered answer-first (health verdict → primary action → supporting detail), matching the grammar the reference list pages already exhibit.

### Copy & Navigation Integrity (COPY)

- [x] **COPY-01**: Operator-facing copy on the two pages is plain-language (no double-negative "No — billing is not active"; unexplained "workspace" jargon clarified) and sourced from `AccrueAdmin.Copy`, not inline template strings.
- [x] **COPY-02**: Breadcrumbs on the two pages point only to real navigable parents (no fake "Billing health overview" parent without a target), and the primary customer-lookup control is discoverable rather than buried.

### Shared Component Additions (COMP)

- [x] **COMP-01**: If (and only if) the work-queue "callout" shape proves to repeat across Home's attention rail and Subscriptions' worklist strips, exactly one small shared component (e.g. `WorkQueueCallout`) is added — composed from existing tokens + `.ax-card`, reusing the existing tone scale (`moss`/`cobalt`/`amber`/`slate`/`ink`) — and consumed by both pages; otherwise both compose from `.ax-card` directly. No other new components; no new deps.

---

## Future Requirements (deferred — SEED-004 M2/M3)

- **M2 — signature diagnostic surfaces + core diagnosis:** the "Why blocked?" diagnosis card, causality graph / causal timeline, unified billing-state synthesis, and the core `accrue` diagnosis functions they require (`blocking_reason_for_owner/1`, `billing_state_for_customer/1`, `causality_chain_for_event/1`) + durable event-name contracts.
- **M3 — new rooms + structure:** new Usage/meters, checkout-sessions, Connect-capabilities, and fee-reconciliation rooms; `+Usage` / `+Settings` nav groups; de-tabbing Customer-360; and the v1.56-ratchet re-freeze (refresh design-lens rubric + persona exemplars + re-freeze baseline) that re-locks the landed redesign.
- Applying the answer-first reign to the remaining detail surfaces (subscription-detail, customer-detail, component-kitchen) beyond the shared-CSS coordination already required by REIGN-04.

## Out of Scope (explicit exclusions this milestone)

- Any change to `accrue/lib` (core) — M1 is admin-only by construction; a diff touching core is a scope breach.
- New navigation rooms or nav groups, de-tabbing Customer-360 (M3).
- Sensitive-action class A/B/C step-up, "View event" toasts, freshness/stale chips, optimistic-lock handling — the two M1 pages are read/navigate surfaces with no state-changing actions to guard (later slices).
- Reskinning the already-cohesive pages (Payments/Customers/Invoices/Events/Webhooks/…) — they are the reference, not the target.
- Un-parking or gating on the v1.56 ratchet during M1; the ratchet re-freeze is a post-M3 breadcrumb, not an M1 task.
- New dependencies, Tailwind migration, or replacing the `ax-*` token SSOT.

---

## Traceability

Each v1 requirement maps to exactly one phase. Coverage: **11/11 mapped, 0 orphans, 0 duplicates.**

| Requirement | Phase | Status |
|-------------|-------|--------|
| REIGN-01 | Phase 209 — Reign Subscriptions (list + detail CSS coordination) | Complete |
| REIGN-02 | Phase 209 — Reign Subscriptions (list + detail CSS coordination) | Complete |
| COMP-01 | Phase 209 — Reign Subscriptions (list + detail CSS coordination) | Complete |
| REIGN-03 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Pending |
| IA-01 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Pending |
| IA-02 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Pending |
| IA-03 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Pending |
| IA-04 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Pending |
| COPY-01 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Complete |
| COPY-02 | Phase 210 — Reign Home + certify answer-first IA & copy integrity | Complete |
| REIGN-04 | Phase 211 — Grep-gated CSS retirement & cross-surface cleanup | Pending |

**Mapping notes:**

- **REIGN-01/REIGN-02** carry the Subscriptions-page structural reign in Phase 209; because band removal + single-verdict + single-CTA + compact cells *are* the Subscriptions answer-first pivot, that page's IA work is delivered physically under these two requirements. The cross-page IA/COPY requirements (IA-01..04, COPY-01/02) become fully TRUE only once the second page (Home) is reigned, so they close in Phase 210.
- **COMP-01** (the one-new-component budget) resolves in Phase 209 — the `WorkQueueCallout` extract-or-inline decision surfaces during the Subscriptions reign and, if extracted, is consumed by Home in Phase 210.
- **REIGN-04** (grep-gated CSS retirement) is sequenced last in Phase 211 — it can only run safely after both target templates land, because `.ax-inline-worklist*` / `.ax-audit-summary-row` are shared with the out-of-scope subscription detail page. Per-page markup/selector migration happens in the reign phases (209/210); Phase 211 does the zero-reference-verified deletion + bundle rebuild + kitchen/storybook/`region-tags.js` cleanup.
- **Density (IA-03)** and **PNG-parity** are cross-cutting done-criteria repeated as success criteria on *both* reign phases (209 and 210), even though IA-03 formally maps to Phase 210.
