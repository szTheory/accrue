# Phase 210: Reign Home + certify answer-first IA & copy integrity - Context

**Gathered:** 2026-07-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Recompose the **Home** page (`accrue_admin/lib/accrue_admin/live/dashboard_live.ex`) onto the canonical shared-component spine — replace the hand-rolled `<header class="ax-page-header">` with the canonical `PageHeader` (breadcrumbs + title + `:description`/`:actions`/`:stat_strip`), and rebuild its two signature zones (the **attention rail** and the **task-launcher tiles**) from shared primitives (`.ax-card` + `Button` + `Icon` + `StatusBadge`, `EmptyState` for empty branches). Keep the already-canonical `KpiCard` "At a glance" band and `Timeline` activity cards as-is. Then, with **both** outlier pages (Subscriptions from Phase 209, Home now) reigned, **certify** the cross-page answer-first IA and plain-language copy/nav integrity so the whole admin reads as one operator-first system. Delivers **REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02**.

**This is a REIGN, not a redesign.** No new tokens, no new palette, no new deps, **zero new shared components** (COMP-01 resolves to "inline" on both pages — see D-01). CSS **deletion** is deferred to Phase 211; Phase 210 only stops *referencing* retired `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-health-summary*` classes. Console **density is the point** — trim redundant bands but do not over-air (IA-03: no density regression vs the pre-reign baseline).

**Out of scope (binding scope fence, inherited from the milestone):** NO core `accrue/lib` change (M2); NO new nav rooms (M3); NO "why blocked"/causality/diagnosis synthesis; NO new deps; NO Tailwind migration (`ax-*` stays the styling SSOT); NO `accrue_portal` work; NO CSS class deletion (that is Phase 211, grep-gated) — 210 preserves every CSS rule until 211 retires it.

</domain>

<decisions>
## Implementation Decisions

### WorkQueueCallout — extract-or-inline (COMP-01, deferred here from Phase 209 D-02)
- **D-01: Keep both inline; resolve COMP-01 as "inline" on both pages.** With Home's attention rail now in front of the implementer, the two shapes do **not** converge enough to justify the one new component the milestone would permit. Home's rail is a **ranked exception list** (priority badge P1/P2/P3 · tone dot · metric+label · pill · action, sorted by severity); Subscriptions' worklist callout is an at-risk-items card. Building a shared `WorkQueueCallout` would force a lowest-common-denominator abstraction that fails the milestone's "demonstrably repeats" bar. Both stay composed from `.ax-card` + primitives directly. **Net: this milestone adds zero new shared components.**

### Customer-search de-duplication (IA-02 / COPY-02)
- **D-02: Fold the customer-lookup control into `PageHeader :actions`; remove the dedicated strip section AND the launcher tile.** Home's customer-search entry appears **three times** today — the header CTA (`ax-home-customer-search-cta`, command-palette trigger), the dedicated `ax-home-customer-search-strip` section, and the `ax-launcher-customer` tile. Collapse to **one** discoverable, always-visible control living in the header actions (the command-palette trigger), matching the single-CTA-in-header grammar Subscriptions adopted in Phase 209. The strip `<section>` and the customer launcher tile are both removed.
- **D-02a — ROADMAP SC1 "four launcher tiles" is superseded to THREE.** Removing the customer launcher tile leaves **three** task tiles: **Open-invoice queue · Recovery/dunning · Developer/webhooks**. ROADMAP Phase 210 Success-Criterion 1's literal phrase "four launcher tiles are rebuilt" was descriptive of today's grid, **not** a target — the binding intent is SC2 (customer-search folds into `PageHeader :actions`). **Planner + verifier MUST treat "three tiles" as correct and NOT flag the tile-count drop as a regression.** (This is the one place the discussion overrode a literal ROADMAP phrasing; flagged deliberately.)

### Single health verdict composition (IA-01 / IA-04)
- **D-03: One verdict = `StatusBadge` + exposure-first `StatStrip` in `PageHeader`; mirror Subscriptions D-03 for cross-page parity.** Home's verdict renders **three times** today: the `<h1>` "Billing health: Unhealthy", the header `ax-home-header-health` block (`attention_health_summary` + `attention_health_issue_summary`), and the attention-rail `ax-attention-summary` block ("Billing status: Unhealthy."). Collapse to a single verdict in the `PageHeader`: a `StatusBadge` (`Healthy` moss / `Action required` amber-danger) + an exposure-first `StatStrip` leading with money-at-risk — the same grammar Subscriptions adopted in Phase 209 (D-03). **Drop** the verdict-sentence from the `<h1>` (page title returns to a plain title/headline) **and drop** the attention-rail `ax-attention-summary` block.
- **D-03a — no re-duplication against the kept KpiCard band.** The canonical `KpiCard` "At a glance" band stays (SC1). Division of labor: header `StatStrip` = the **one-line answer** (exposure-first verdict); KpiCard "At a glance" band = the **detailed metric drill-down**. They must not repeat the same numbers as the same statement — the StatStrip leads with money-at-risk framing, the KPI band is the metric grid. Content-preservation proof (à la 209 D-03): every datum currently spread across the three removed verdict renderings must land in either the StatStrip or the retained KPI band — nothing lost.

### Copy plain-language pass (COPY-01 / COPY-02)
- **D-04: Set the copy principles now; defer exact final strings to the UI-SPEC/planner.** Locked rules for the pass: (1) **no "workspace" jargon** ("Open invoice queue workspace" → plain "Open invoice queue"; audit `Copy.dashboard_kpi_invoices_aria_label`, `home_launcher_recovery_meta`, and similar); (2) **sentence case, not SHOUTING** ("Find ONE customer" → "Find one customer"); (3) **affirmative, no double-negative** healthy-state wording (the requirements-flagged "No — billing is not active" pattern); (4) **all operator strings sourced from `AccrueAdmin.Copy`** — no inline template literals in `dashboard_live.ex`. Exact final wording is pinned by `/gsd-ui-phase 210` (UI-SPEC copy contract) or the planner, consistent with the Phase 209 copy contract. Home currently has several inline literals in the template (e.g. "Billing status", "Priority exceptions", "Billing status: Unhealthy.", "Find ONE customer", "Open invoice queue workspace") that must migrate into `Copy`.
- **D-04a — breadcrumbs (COPY-02):** Home's breadcrumb is a single real crumb `[ Home ]` (it is the root) — confirm no fake non-navigable parent (e.g. "Billing health overview") is introduced. Mirrors the 209 fix that removed the fake parent from Subscriptions.

### Verification-gate migration (in-phase, from ROADMAP SC5)
- **D-05: Migrate the named test/e2e selectors to the shared-component DOM within this phase.** The reign changes DOM, so the following assertions move to the new shared-component selectors as part of 210 (not left red): `dashboard_live_test` at L107 (`ax-home-health-answer`), L130 (`ax-launcher-primary`), L184 (`ax-home-customer-search-cta`); and the `e2e/admin-spec-overview-phase194` + `admin-interaction-overlay-phase199` `.ax-attention-rail*` selectors. `admin-a11y.spec.js` (axe) must stay green with landmark/heading/visually-hidden semantics preserved.

### Claude's Discretion
- Exact `PageHeader` slot wiring (`:description` / `:stat_strip` / `:actions`), the specific `StatStrip` stat structs and their order, the `.ax-card` recomposition of the attention rail rows, and the three-tile launcher grid rebuild from `Button`/`Icon`/`StatusBadge` — left to the planner/executor, constrained by any UI-SPEC produced by `/gsd-ui-phase 210` and by cross-page parity with Phase 209's reigned Subscriptions page.
- Removal of now-dead helpers/markup made unreachable by the collapse (e.g. the `ax-home-header-health` block, the `ax-home-customer-search-strip` section, the customer launcher tile, and any verdict-summary helper left with no caller) should be cleaned up as part of the band removal.
- Whether the "no density regression" proof needs its own PNG baseline capture step vs reusing the existing pre-reign screenshot is a planner call (ROADMAP SC3 requires PNG compare against both the canonical reference and the pre-reign screenshot).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked contracts (read first)
- `.planning/REQUIREMENTS.md` — milestone requirements; this phase delivers **REIGN-03, IA-01, IA-02, IA-03, IA-04, COPY-01, COPY-02** (see the "Traceability" table + the two closing notes explaining why IA/COPY close in 210 once the second page is reigned).
- `.planning/ROADMAP.md` § "Phase 210" — the five Success Criteria are the acceptance checklist; § "v1.57 Admin Operator Control Plane (SEED-004 M1)" holds the scope fence, generated-artifact rules, and grep-gate/CSS-retirement sequencing. **Note D-02a: SC1's "four launcher tiles" is superseded to three by this discussion.**
- `.planning/phases/209-reign-subscriptions-list-detail-css-coordination/209-CONTEXT.md` — the immediately-prior reign; D-03 (exposure-first StatStrip verdict) and D-01 (no per-row action / whole-row nav) are the cross-page parity targets Home must match. **D-02 there deferred COMP-01 to here — now resolved as D-01 above.**
- `.planning/phases/209-reign-subscriptions-list-detail-css-coordination/209-UI-SPEC.md` — the approved 209 visual/interaction/copy contract; Home's UI-SPEC (if `/gsd-ui-phase 210` is run) should mirror its 8-point interaction/structural contract and copy grammar for one-system cohesion.

### Milestone design sources
- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — SEED-004 north-star ("operator control plane over billing state").
- `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` — self-contained synthesis.
- `.planning/research/admin-ratchet-round99-confirmed-findings.json` — 23 ratchet-confirmed IA findings; the Home subset is acceptance-checklist input (the triplicated customer-search + triplicated verdict are the load-bearing Home defects).

### Code touchpoints (target + references)
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — **the target** (~614 lines). Landmarks: hand-rolled header L52–104 (breadcrumbs L54, `<h1>` verdict L56, `ax-home-header-health` block L59–63, `:actions` incl. customer-search CTA L80–88); attention rail L107–143 (`ax-attention-summary` L119–122, `.ax-card.ax-attention` rows L124–136, empty branch L138–142); customer-search strip L145–159; task launchers L162–222 (4 tiles: invoices L168, customer L181, recovery L193, developer L209); KpiCard band L224–275 (**keep**); Timeline cards L277+ (**keep**); verdict helpers L461–471.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` — the just-reigned sibling page; the `PageHeader` + `StatStrip` verdict + single-CTA wiring to mirror for cross-page parity.
- `accrue_admin/lib/accrue_admin/live/invoices_live.ex` & `customers_live.ex` — canonical spine reference pages (`PageHeader`, `StatusBadge`, `EmptyState`, `StatStrip`, header-actions idiom).
- `accrue_admin/lib/accrue_admin/copy.ex` — copy SSOT; add/rename Home strings here (audit L1258 "queue workspace", L1279 `dashboard_kpi_invoices_aria_label`, L1314 "…customer workspace…", L1339 `home_search_customers_title`, L1360 `home_launcher_recovery_meta` for jargon).
- `accrue_admin/assets/css/app.css` (`ax-*` classes) + `accrue_admin/assets/css/theme.css` (`--ax-*` tokens) — styling SSOT. Editing requires `mix accrue_admin.assets.build` → commit `priv/static/accrue_admin.css`. **Do not delete any `.ax-*` rule (Phase 211's grep-gated job); only stop referencing.**
- Generated artifacts to rebuild + commit every change: `accrue_admin/priv/static/accrue_admin.css` (`mix accrue_admin.assets.build`) and `examples/accrue_host/e2e/generated/copy_strings.json` (`mix accrue_admin.export_copy_strings`).
- Verification gates (D-05): `accrue_admin/test/.../dashboard_live_test.exs` (L107/L130/L184 selectors); `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` + `admin-interaction-overlay-phase199.spec.js` (`.ax-attention-rail*`); `admin-a11y.spec.js` (axe).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Canonical spine components** — `AppShell`, `PageHeader` (`:description`/`:stat_strip`/`:actions` slots), `FlashGroup`, `StatusBadge`, `StatStrip`, `EmptyState`, `Button`, `Icon`, `KpiCard`, `Timeline`, `Breadcrumbs` — all already consumed by the reference pages and by 209's reigned Subscriptions. Compose from these; do not fork.
- **`KpiCard` "At a glance" band + `Timeline` activity cards** are already canonical on Home (L224–275, L277+) — **kept as-is**, not touched by the reign.
- **`AccrueAdmin.Copy`** — all operator strings live here; migrate Home's inline template literals into it (keeps `copy_strings.json` SSOT).

### Established Patterns
- **Header carries the single primary action** — the reigned Subscriptions + reference pages put the one primary CTA in `PageHeader :actions`; Home's customer-lookup control folds into this same slot (D-02).
- **Verdict = StatusBadge + exposure-first StatStrip in the header** — Phase 209 D-03 grammar; Home mirrors it (D-03) for one-system cohesion.
- **Build contract** — editing `app.css` ships nothing until `mix accrue_admin.assets.build` regenerates the committed `priv/static/accrue_admin.css`; copy changes need `mix accrue_admin.export_copy_strings`. Both artifacts committed every change.
- **CSS is stop-referencing-not-delete in reign phases** — retired `.ax-home-*`/`.ax-launcher*`/`.ax-attention*` classes are preserved until Phase 211's grep-gated retirement.

### Integration Points
- Home's `@attention` list + `@stats` assigns feed the verdict, the rail rows, and the launcher metas — the reign relocates the verdict/customer-search data into `PageHeader` while preserving the same underlying assigns (content-preservation).
- Removing the customer launcher tile drops the grid from 4 → 3 tiles; the launcher-grid CSS/markup must handle three tiles without a visual gap.
- Named test + e2e selectors on the changed DOM migrate **in this phase** (D-05) so no gate is left red across the phase boundary.

</code_context>

<specifics>
## Specific Ideas

- Cross-page parity is the through-line: Home's reigned header should read as the same grammar as Subscriptions' — `StatusBadge` verdict + exposure-first `StatStrip` + single primary action in `:actions` — so a operator moving between the two pages sees one system.
- Verdict badge language: `Healthy` (moss) vs `Action required` (amber/danger), matching the 209 copy contract — not "Unhealthy" (drop the current bespoke wording).
- Surviving three launcher tiles map to distinct JTBDs: Open-invoice queue (primary), Recovery/dunning, Developer/webhooks. Customer lookup is deliberately NOT a tile — it's the always-visible header control.
- Home breadcrumb is the single root crumb `[ Home ]`; no fake parent.

</specifics>

<deferred>
## Deferred Ideas

- **CSS class deletion** (`.ax-home-*`, `.ax-launcher*`, `.ax-attention*`, `.ax-health-summary*`, etc.) — deferred to **Phase 211** (grep-gated, zero-reference-verified) per REIGN-04. 210 only stops referencing them.
- **Component-kitchen / storybook / `region-tags.js` cleanup** of retired vocabulary — Phase 211.
- **SEED-004 M2** (why-blocked/causality diagnosis surfaces + core `accrue` diagnosis fns) and **M3** (new rooms + ratchet re-freeze) — future milestones, hard scope fence for this phase.

None of the above are scope creep introduced in discussion — they are the roadmap's own sequencing boundaries.

</deferred>

---

*Phase: 210-reign-home-certify-answer-first-ia-copy-integrity*
*Context gathered: 2026-07-19*
