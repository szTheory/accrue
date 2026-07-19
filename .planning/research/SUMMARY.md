# Project Research Summary

**Project:** Accrue (`accrue_admin` package)
**Domain:** LiveView operator-console admin UI — information-architecture / screen-grammar pivot (v1.57 = SEED-004 **M1**)
**Researched:** 2026-07-19
**Confidence:** HIGH

## Executive Summary

v1.57 M1 is an **admin-only cohesion pivot**, not a build-out. The `accrue_admin` LiveView admin already has a mature shared component library and a canonical page skeleton that ~10 of its pages (Payments/Charges, Invoices, Customers) already follow. Two pages are outliers — **Home** (`dashboard_live.ex`) and **Subscriptions** (`subscriptions_live.ex`) — and M1 reigns them onto that shared vocabulary, retiring ~325 bespoke `.ax-*` CSS rules and trimming redundant bands so the whole admin reads as one "operator control plane over billing state" before M2's diagnostics land. All four research tracks independently converged on **HIGH confidence** because every finding is grounded in direct reads of the real modules, tests, e2e specs, and the committed CSS bundle — not speculation.

The recommended approach is **compose, don't fork, and don't add technology**. No new Hex/npm dependencies; the component library and `ax-*` token system already cover every shape M1 needs. The canonical skeleton to enforce is: `AppShell → section.ax-page → PageHeader (breadcrumbs + title + :description/:stat_strip/:filter_toolbar) → FlashGroup → DataTable (+ FilterChipBar in :list_status)` — with **nothing** sitting between FlashGroup and DataTable on a good page. Build order is **Subscriptions first** (a pure MODIFY — it already imports the vocabulary; drop override classes, collapse the triple-repeated invoice-queue CTA, delete 5 bespoke band sections, rebuild the `.ax-subscription-row-*` cell renderers to the compact idiom) **then Home** (the larger lift — adopt `PageHeader`, recompose the attention rail + launcher tiles from `.ax-card` + `Button` + `Icon` + `StatusBadge`; its KPI and Timeline zones are already canonical). Exactly **one** new shared component (`WorkQueueCallout`) is pre-authorized, and only if the work-queue "callout" shape demonstrably repeats across both pages — a decision deliberately deferred to the Subscriptions build.

The risks are almost entirely **discipline risks, not technical risks**. The highest-value guardrails: (1) **density is the point** — composing shared components at their default roomier spacing silently trades away the operator density that makes the admin cohesive, so a "no density regression vs pre-reign baseline" acceptance criterion must be written once and inherited by both phases; (2) **CSS retirement is grep-gated** — `.ax-inline-worklist*` and `.ax-audit-summary-row` are also used by the out-of-scope subscription **detail** page, so blind prefix-deletion silently breaks it in a way source-text CI cannot see; (3) **two committed generated artifacts** (`priv/static/accrue_admin.css` and `examples/accrue_host/e2e/generated/copy_strings.json`) must be rebuilt and committed in the same change as every CSS/copy edit, or the work ships dead; and (4) **scope creep into M2/M3** — the moment a "health verdict" starts synthesizing *why* something is blocked, or a plan touches `accrue/lib`, M1 has silently become M2.

## Key Findings

### Recommended Stack

**No stack additions or changes.** (See STACK.md.) M1 is a pure composition + IA exercise on top of an already-mature shared component library and `ax-*` token system (1,452 `.ax-*` rules, the styling SSOT). Every building block already ships in `accrue_admin`; the work is *retiring* bespoke markup/CSS on the two outliers and re-expressing them with the canonical vocabulary. The only defensible new authored artifact is a single small shared function component (`WorkQueueCallout`), built entirely from existing tokens + `.ax-card` — not a dependency, not a build-tool change, not a token-system change.

**Core technologies (all already present, zero change):**
- `:phoenix_live_view ~> 1.1` — renders the admin pages being reworked; the pivot is HEEx re-composition inside existing LiveViews.
- `:phoenix ~> 1.8` / `:phoenix_html ~> 4.2` — router/endpoint + HEEx helpers; unchanged (no new routes).
- `:accrue` (path / `== 1.4.0`) — billing domain data the pages already load; **no core change in M1** (core diagnosis fns are M2).
- `ax-*` CSS + design tokens (in-repo) — stays the styling SSOT; the pivot *reduces* bespoke rules. Tailwind remains a compile-time minifier only (`mix accrue_admin.assets.build`), never an authoring path.

**Shared components to reuse (the whole M1 toolbox):** `PageHeader`, `StatStrip`, `KpiCard`, `DataTable` (+ `filter_toolbar`), `FilterChipBar`, `Button`, `StatusBadge`, `EmptyState`, `DropdownMenu`, `Timeline`, `Icon`.

### Expected Features

M1's job is a **coherence layer**, not new capability. (See FEATURES.md.) The blueprint thesis: "Accrue Admin is not a CRUD interface — it is an operator control plane over billing state," where every screen answers *What needs attention? / What is the true billing state? / What safe action can I take?* faster than anything else. The 12 of 23 round-99 findings on `dashboard` + `subscriptions` are the M1 acceptance checklist.

**Must have (table stakes for M1 cohesion):**
- **Reign Home + Subscriptions onto the shared vocabulary** — the single largest lever; retire `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-subscriptions-*` / `.ax-inline-worklist*`.
- **One scannable health verdict per page** — Home renders the verdict *three times* today; collapse to one in the `PageHeader` title slot.
- **One primary action per zone / de-dup entry points** — the "Open dedicated invoice queue" CTA appears 3×+ on Subscriptions; collapse to one canonical entry point (the most-confirmed round-99 defect, `f-5a1ecbfd`).
- **Trim redundant bands + tighten density to the reference** — delete the 5 stacked Subscriptions bands; match Payments/Customers/Invoices density, do not add "designed" air.
- **Plain-language verdicts + precise action labels** — kill double-negatives ("No — billing is not active") and jargon ("workspace"); copy stays in `AccrueAdmin.Copy` SSOT.
- **Answer-first content order** (verdict → primary action → demoted KPIs → records) on both pages.

**Should have (competitive — makes it read best-in-class):**
- **Reusable "health verdict" pattern** and **`WorkQueueCallout`** — the likely one-new-shared-component, only if the callout shape repeats.
- **"One door per JTBD" launcher as shared cards** — Home's four task launchers rebuilt on `.ax-card` + `Button`, preserving the strong task-launcher IA while shedding bespoke CSS.
- Correct nav/breadcrumb integrity (make Home genuinely the "Billing health overview" the Subscriptions breadcrumb promises); customer lookup promoted to one prominent entry.

**Defer (M2 / M3 — explicitly out of scope, must not be pulled in):**
- "Why blocked?" diagnosis card, causality graph/timeline, unified `billing_state_for_customer/1`, freshness/stale chips — all **M2** (require core `accrue` diagnosis fns).
- New rooms (Usage/meters, checkout, Connect matrix, fee reconciliation), `+Usage`/`+Settings` nav groups — **M3**.
- De-tab Customer-360, subscription-**detail** same-grammar cleanup, sensitive-action A/B/C + step-up, "View event" toasts — later M1-family / M2 slices.

### Architecture Approach

This is **integration architecture, not greenfield**. (See ARCHITECTURE.md.) The canonical spine is "caller-owned content on a shared chassis": `<section class="ax-page">` → `PageHeader` → `FlashGroup` → `DataTable`, with the default lens + "All one click away" expressed entirely through `work_queue_chips/2` in the DataTable's `:list_status` slot — no band `<section>`s between flash and table. Data flow is unchanged (presentation pivot only); both targets keep their existing `mount → summary/stats → handle_params default-lens → render`.

**Major components / moves:**
1. **Subscriptions (~90% on the skeleton — pure MODIFY)** — drop `ax-page-compact ax-subscriptions-page` + header override classes; short-noun title + single verdict; collapse the 3× invoice-queue CTA to one `Button` in `:actions`; unwrap `StatStrip`; **delete the 5 bespoke bands** (L196–279); rebuild `identity_cell/3` + `billing_signals_cell/3` from 15–20-line bespoke raw HTML to the compact `ax-stack-xs`/`ax-link`/`ax-chip` + `StatusBadge` idiom, pushing per-row action buttons out of cells; delete the now-dead `open_invoice_queue/1` query.
2. **Home (the larger lift)** — adopt `PageHeader` (it currently hand-rolls a `<header>` and never uses the existing `:actions` slot); recompose the attention rail and launcher tiles from `.ax-card` + `Button` + `Icon` + `StatusBadge` + `EmptyState`; fold the duplicated customer-search strip into `PageHeader` `:actions`; **keep** the already-canonical KpiCard (Zone 3) and Timeline (Zone 4) zones as-is.
3. **Grep-gated CSS retirement** — delete retired `.ax-*` rules from `assets/css/app.css` **last**, only for classes with zero remaining `.ex` references after both pages are rebuilt; retain the detail-page-shared classes.

### Critical Pitfalls

(Top items from PITFALLS.md — all discipline risks, not technical ones.)

1. **Over-airing the console (density regression).** Composing shared components at their default roomier spacing silently trades away operator density and *loses* cohesion even though the components are now "shared." Avoid: write "no density regression vs pre-reign baseline" as an explicit acceptance criterion; PNG-compare reigned pages against both the canonical reference and the pre-reign screenshot (row height, rows-per-viewport, header band height must not regress); reuse existing compact modifiers.
2. **Deleting CSS the subscription DETAIL page still uses.** `.ax-inline-worklist*` and `.ax-audit-summary-row` are referenced by the out-of-scope `subscription_live.ex` (detail); blind prefix-delete breaks its styling invisibly to source-text CI. Avoid: grep-gate every candidate class against the whole `lib/` tree, delete CSS **last** and only at zero references, sequence Subscriptions list + detail together, and PNG-verify the detail page after the list reign.
3. **The committed-bundle footgun.** The served stylesheet is the git-tracked minified `priv/static/accrue_admin.css`, not source `app.css` — editing source without `mix accrue_admin.assets.build` + committing the bundle ships dead CSS (burned Phase 189). Avoid: rebuild + `git add priv/static/accrue_admin.css` in the same commit; verify PNGs against the *served* bundle.
4. **Host `copy_strings.json` staleness (cross-repo coupling).** Reigning changes copy; `examples/accrue_host/e2e/generated/copy_strings.json` is regenerated by host-integration but read as-committed by Playwright shards. Avoid: re-run `mix accrue_admin.export_copy_strings` and commit the JSON in the same change; keep copy in `AccrueAdmin.Copy`.
5. **IA over-reach into M2/M3.** A "health verdict" that starts summarizing *why* something is blocked, or any plan touching `accrue/lib` or adding a nav room, has silently become M2/M3. Avoid: hard scope fence (no core fns, no new rooms, no causality/diagnosis synthesis); plan-review rejects any plan importing M2/M3 surfaces.
6. **Losing operator content while "trimming redundant bands."** Redundancy (same datum twice) and density (many distinct facts compactly) look alike in a screenshot. Avoid: build a content inventory before deleting; trim only true duplication/decoration; treat deleted copy-test assertions as a red flag.
7. **Test + selector breakage against retired classes** (`dashboard_live_test` L107/130/184, `subscriptions_live_test:111`, `admin-spec-overview-phase194`, `admin-interaction-overlay-phase199`, `region-tags.js`). Avoid: grep + migrate every assertion to the shared-component selector in the *same* phase; retire, don't alias; never leave the suite red across a phase boundary.

## Implications for Roadmap

Based on the combined research, the two-page reign decomposes cleanly. **Sequence: Subscriptions before Home** (Subscriptions is closest to canonical → lower-risk fast coherence win, and it surfaces the `WorkQueueCallout` decision before Home's attention rail needs to consume it). A shared "milestone scope + verification discipline" gate should be written once and inherited by both build phases.

### Phase 0 (SPEC / discuss — written once, before build): Scope fence + shared verification contract
**Rationale:** Pitfalls #1, #2, #5, and the two generated-artifact couplings are cross-cutting; they must be locked as written requirements before either build phase so both inherit them.
**Delivers:** A scope fence (no core `accrue`, no new nav rooms, no "why blocked"/causality/diagnosis synthesis, one-new-component budget) and a shared verification checklist: no-density-regression gate, grep-before-delete + CSS-deleted-last protocol, `mix accrue_admin.assets.build` + commit bundle, `export_copy_strings` + commit JSON, axe (`admin-a11y.spec.js`), selector migration.
**Avoids:** #2 IA over-reach, #5 bundle footgun, #8 copy staleness — set as gates, not afterthoughts.

### Phase 1: Reign Subscriptions (list + detail as one CSS unit)
**Rationale:** ~90% already on the skeleton — override-drop + band-trim + cell-rebuild, not a from-scratch compose; lowest risk; surfaces the `WorkQueueCallout` decision first.
**Delivers:** Subscriptions on the canonical spine — single verdict, one invoice-queue entry point, 5 bespoke bands deleted, compact cell renderers, `open_invoice_queue/1` removed; grep-gated retirement of the LIST-only `.ax-subscriptions-*` / `.ax-subscription-row-*` sets; detail page's shared `.ax-inline-worklist*`/`.ax-audit-summary-row` retained or reigned.
**Addresses (FEATURES):** reign onto vocabulary, one primary action per zone, trim bands + density, plain-language copy, answer-first order, lens-default confirm.
**Avoids (PITFALLS):** #3 content loss (content inventory), #4/#7 selector churn (`subscriptions_live_test:111`), #6 detail-page CSS break (grep-gate, delete CSS last, verify detail after list), #1 density.
**Decision point:** whether the trimmed worklist callout shape justifies extracting the one allowed `WorkQueueCallout` component.

### Phase 2: Reign Home
**Rationale:** The larger lift (fully bespoke; needs full `PageHeader` adoption + recomposition of two zones with no shared component today); done second so it can reuse anything Subscriptions establishes (incl. `WorkQueueCallout`).
**Delivers:** Home on `PageHeader`; single health verdict; attention rail + four launcher tiles recomposed from `.ax-card` + `Button` + `Icon` + `StatusBadge` + `EmptyState`; customer search promoted to one entry; KpiCard/Timeline zones kept; grep-gated retirement of `.ax-home-*` / `.ax-launcher*` / `.ax-attention*` / `.ax-health-summary*`.
**Uses (STACK):** `PageHeader`, `StatStrip`/`KpiCard`, `Button`, `Icon`, `StatusBadge`, `EmptyState` + optional `WorkQueueCallout`.
**Avoids (PITFALLS):** #1 density, #4/#7 selectors (`dashboard_live_test` L107/130/184, `admin-spec-overview-phase194`, `admin-interaction-overlay-phase199`), #5 bundle, #7/a11y, #8 copy.

### Phase 3 (fold into whichever phase retires the shared classes): Kitchen / Storybook + selector-map cleanup
**Rationale:** `component_kitchen_live.ex` and `priv/static/storybook.css` also render the retired vocabulary; the parked `region-tags.js` selector map still points at `.ax-attention-rail`.
**Delivers:** kitchen/storybook entries updated + `storybook.css` rebuilt (same bundle footgun); phase200 storybook specs green; opportunistic `region-tags.js` fix so the eventual ratchet re-freeze starts from a non-dangling selector map.

### Phase Ordering Rationale
- **Subscriptions before Home** because it is closest to canonical (fast, low-risk coherence win) and surfaces the one-new-component decision before Home needs to consume it. Building Home first would force that decision blind.
- **CSS deletion is sequenced last within each page's reign** and grep-gated across the whole tree — the detail-page sharing hazard (`.ax-inline-worklist*`, `.ax-audit-summary-row`) makes ordering load-bearing, not cosmetic.
- **List + detail are treated as one CSS unit** in the Subscriptions phase because they share bespoke classes; splitting them across phase boundaries is how the silent detail-page break happens.
- **Ratchet re-freeze is explicitly deferred** to post-M3 (the v1.56 harness is parked); do NOT gate on it during M1.

### Research Flags

Phases likely needing deeper research during planning:
- **None require external/web research** — the entire domain is grounded in in-repo reads (HIGH confidence across all four tracks).
- **Phase 1 (Subscriptions)** warrants a planning-time *code inventory* (not research): the exact grep census across `lib/`, `test/`, `e2e/` for each retirement class, and a content inventory of every operator-facing datum before deletion. This is the highest-uncertainty area (content-loss + detail-page-sharing hazard), and the `WorkQueueCallout` extract/no-extract decision resolves here.

Phases with standard patterns (skip research-phase):
- **Phase 2 (Home)** — the canonical spine is fully documented in ARCHITECTURE.md; it is applying a known grammar, just to more surface area.
- **Phase 0 / Phase 3** — pure discipline/mechanics already specified in the pitfalls and architecture research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Grounded in `accrue_admin/mix.exs`, the shipped component library, and the assets build task — "no new deps" is verified, not assumed. |
| Features | HIGH | Traced to the SEED-004 blueprint synthesis, the 23 round-99 confirmed findings (12 = M1 checklist), and direct reads of both target LiveViews. |
| Architecture | HIGH | Direct reads of all canonical + target LiveViews and every shared component; grep-verified the detail-page CSS-sharing hazard. |
| Pitfalls | HIGH | Every pitfall names concrete file/line evidence in source, tests, e2e specs, and the committed bundle; corroborated by prior-incident project memory (Phase 189, CI green-up 260622). |

**Overall confidence:** HIGH

### Gaps to Address

- **Exact retirement rule count varies by measurement** (PITFALLS measured ~284 rules; STACK/PROJECT estimate ~325; ARCHITECTURE sums the clearly-retirable sets to ≈325). This is a counting-method difference, not a disagreement — resolve during planning with a definitive grep census; the *set* of prefixes to retire is agreed.
- **`WorkQueueCallout` extract-or-inline is intentionally unresolved** — it is a build-time decision made during the Subscriptions reign (does the callout shape genuinely repeat across Home's attention rail and Subscriptions' consolidated worklist?). Default to "compose inline, add no component" unless the shape clearly repeats.
- **Detail-page (`subscription_live.ex`) reach** — it is out of M1's *feature* scope but in scope for the *CSS-sharing* hazard. Planning must decide per shared class: retain the class, or reign the detail worklist onto the shared component in the same phase. Do not extend M1 into a full detail-page redesign.
- **Ratchet re-freeze is a recorded downstream breadcrumb, not an M1 task** — leave it in the RETROSPECTIVE/RESULT; do not attempt to keep the parked ratchet green during M1.

## Sources

### Primary (HIGH confidence)
- `accrue_admin/lib/accrue_admin/live/{charges,invoices,customers,subscriptions,dashboard,subscription}_live.ex` — canonical spine + both target outliers + detail-page sharing check.
- `accrue_admin/lib/accrue_admin/components/{page_header,stat_strip,data_table,filter_chip_bar,button,status_badge,empty_state,kpi_card,timeline,dropdown_menu,icon}.ex` — the complete shared vocabulary.
- `accrue_admin/lib/accrue_admin/assets.ex`, `lib/mix/tasks/accrue_admin.assets.build.ex`, `assets/css/app.css` vs committed `priv/static/accrue_admin.css` — bundle mechanics + rule-count census (`ax-subscriptions` 146, `ax-attention` 43, `ax-home` 38, `ax-launcher` 37, `ax-inline-worklist` 20).
- `accrue_admin/test/accrue_admin/live/{dashboard_live_test,subscriptions_live_test,subscription_live_test}.exs` — retired-class + copy assertions at named lines.
- `accrue_admin/e2e/{admin-spec-overview-phase194,admin-interaction-overlay-phase199,admin-a11y}.spec.js`, `e2e/ratchet/region-tags.js` — `.ax-attention-rail*` selector couplings.
- `lib/mix/tasks/accrue_admin.export_copy_strings.ex` + `examples/accrue_host/e2e/generated/copy_strings.json` — cross-repo copy coupling.
- `.planning/research/admin-ratchet-round99-confirmed-findings.json` — 23 confirmed findings; 12 on `dashboard`+`subscriptions` = M1 acceptance checklist.
- `.planning/PROJECT.md` (Current Milestone v1.57), `.planning/seeds/SEED-004-admin-ui-blueprint-redesign.md`, `.planning/research/ADMIN-UI-REDESIGN-BLUEPRINT-SYNTHESIS.md` — M1 scope fence, guardrails, M1/M2/M3 decomposition.

### Secondary (MEDIUM confidence)
- North-star blueprint `prompts/accrue_admin_operator_ui_journey_blueprint.md` (read through the self-contained synthesis, not verbatim) — §4 domain-language, §8 grammars, §12 ⌘K, §41 answer-order.
- Project memory — Phase 189 "dead CSS" incident and "CI green-up 260622" copy-strings staleness (prior-incident recall corroborating Pitfalls #5 and #8).

### Tertiary (LOW confidence)
- None — no inference-only or single-source claims material to the roadmap.

---
*Research completed: 2026-07-19*
*Ready for roadmap: yes*
