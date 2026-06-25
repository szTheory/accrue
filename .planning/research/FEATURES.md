# v1.54 — Page-Archetype & Information-Architecture Research

**Milestone:** v1.54 — Admin UI Page-Level Streamlining & Storybook
**Domain:** Dense operator/admin tooling for an Elixir/Phoenix billing library (`accrue_admin`)
**Researched:** 2026-06-24
**Overall confidence:** HIGH (curated design-system docs + NN/g + GOV.UK + named-product UX commentary; cross-checked)
**Downstream consumer:** v1.54 REQUIREMENTS.md (EXE/PRP/PGH) + the per-archetype "pattern spec" locked in Phase 193 and instantiated in Phases 194–196.

This is a **page-level / IA / progressive-disclosure / density** research brief. It deliberately proposes **no new billing features** — only how the three repeatable page archetypes should be laid out, what to disclose vs. defer, and how to strip "info dump" noise, each scored against alternatives with the counterposition argued first.

---

## Executive Summary

The `accrue_admin` UI is already **component-correct** (v1.53) and **job-shaped at the entry point**: `dashboard_live.ex` is a clean four-zone overview (exceptions rail → verb task-launchers → demoted KPIs → recent activity) that already follows GOV.UK "exceptions-first, tasks-as-doors" thinking. The overview archetype needs *refinement, not rescue*.

The pain is the **object-detail archetype**. `subscription_live.ex` (1,234 LOC) renders ~25 flat-stacked zones in a single scroll: breadcrumbs, summary card, a related-resources strip, a flash group, a 3-card KPI grid, a **second** "related billing" nav card that *duplicates* the related-resources strip, a dunning panel, a tax-ownership card, a 2-column grid whose left column contains **ten permanently-expanded inline `<form>`s** (cancel-now, cancel-at-period-end, pause, resume, swap-plan, update-quantity, add-item, update-item-quantity, remove-item, comp) plus a conditional confirm panel, a timeline, a raw JSON viewer, and a step-up-auth modal. Every operator action is visible at all times as its own labeled form — the textbook "info dump." This is the gold-standard target for Phase 195.

The list archetype (9 pages) is the most internally consistent already (stat-strip + filter-chip toolbar + `data_table` that degrades to mobile cards, with work-queue defaults locked in v1.51). It mostly needs the shared `PageHeader` extraction (a pending todo) and tightening of chrome/padding.

**The single most important cross-archetype principle from the research:** *default to the full page, disclose the rest in place, and reserve overlays only where interruption genuinely adds value.* Concretely for Accrue:

- **Detail = summary-then-drill, not tabs-first and not everything-at-once.** A persistent **summary header** (GOV.UK summary-list semantics: key/value rows with row-level "Change" affordances) carries the answer to *"what is this subscription's state right now?"* The 10 action forms collapse behind a **single action menu** (PatternFly: ≤2 primary buttons visible, the rest in an overflow menu), each action opening **in place / in a side-drawer**, not pre-expanded. Deep plumbing (raw JSON, full event ledger) moves below the fold or behind a lazy "Developer"/"Activity" section.
- **Tabs are a measured tool, not the default.** NN/g + Baymard: 27–43% of users *completely miss* horizontal tabs; "vertically collapsed sections" hid content from only 8%. So tabs are acceptable only for **peer, supplemental, mutually-exclusive** content groups with strong-scent 1–2-word labels — never to hide the primary state or a critical action.
- **Reduce noise by deleting, not by hiding.** The duplicated related-card, double-bordered card-in-card nesting, and padding bloat are pure subtraction wins that need no progressive-disclosure mechanism at all.

---

## Key Findings (one-liners)

- **Overview pattern:** keep the four-zone exceptions-first dashboard; the Recovery analytics page should adopt the same zone grammar (one hero metric pair → at-risk work queue → trend), not a chart wall.
- **List pattern:** table-first with row→detail navigation; **stacked label/value cards** below the responsive breakpoint (not a shrunk grid); chips + result count + "clear all" always visible; work-queue default with "All" one chip away.
- **Detail pattern:** **summary header (summary-list) → primary KPIs → in-place action menu → drill-down sections (collapsible / lazy) → activity & raw payload last.** No pre-expanded action forms; one canonical related-resources strip (delete the duplicate).
- **Critical anti-pattern:** tabs/accordions that hide the *primary* state or a *critical* action; nested modals; modal-behind-scrim; double-bordered card-in-card; "ten forms always open."
- **Adversarial conclusion held:** even after arguing the pro-tabs and pro-everything-visible counterpositions, **summary-then-drill with an action menu wins** for a billing detail page used by mixed personas.

---

## Archetype A — Overview / Home (Dashboard + Recovery analytics)

### A.1 Chosen direction

**Keep the existing four-zone "task-launcher with exceptions rail" grammar; do not redesign it. Propagate the same grammar to the Recovery analytics page.**

The zones (already shipped in `dashboard_live.ex`):

1. **Attention rail** — exceptions only, non-zero rows, highest-signal first; a *prominent healthy empty-state* ("Nothing needs attention") which the prior design source correctly flags as "the product's most important reassurance."
2. **Task launchers** — one door per JTBD, labeled by **verb** ("Look up a customer," "Clear the invoice queue," "Recover at-risk revenue," "Investigate an incident"), plus a visible labeled ⌘K search field (Support's primary entry).
3. **At-a-glance KPIs** — *demoted below* the tasks, not the page's headline.
4. **Recent activity** — two parallel timelines (local events / webhook pipeline).

This directly matches GOV.UK's "one thing per page" reframed for a dashboard: *the "thing" is a decision/task, not a metric* ([GOV.UK: One thing per page](https://designnotes.blog.gov.uk/2015/07/03/one-thing-per-page/)). It matches the Linear/Stripe ethos that an operator surface should let the tool "disappear" and route you to the next action fast ([Linear conceptual model](https://linear.app/docs/conceptual-model)).

**For the Recovery analytics page specifically:** apply the same zone discipline — lead with a **single hero metric pair** (Recovered MRR / Lost MRR, which already exist as `KpiCard`s), then the **at-risk work queue as a table** (the actual job: work the at-risk list), then trend/funnel as *supporting* visualization below. Resist the "analytics page = wall of charts" reflex; the persona's job (Recovery Ops) is *acting on at-risk subscriptions*, not admiring a funnel.

### A.2 Counterposition (argued, then rejected)

*"An overview should lead with the big numbers — that's what a dashboard is."* Rejected: the research and the existing design source agree that **KPI-first dashboards become wallpaper** — operators glance, see green, and learn nothing actionable. Wildnet/admin-UI guidance explicitly warns that dashboards "feel like cluttered messes" when they prioritize metric density over "clear insights and control" ([Wildnet: Modern Admin Dashboard UI](https://www.wildnetedge.com/blogs/what-to-include-in-a-modern-admin-dashboard-ui)). Exceptions-first + verb-tasks demonstrably serves both the daily-glance Operator and the per-ticket Support persona better. KPIs stay — demoted, click-through to their filtered list.

### A.3 Anti-patterns to avoid

| Anti-pattern | Why it hurts | Instead |
|---|---|---|
| KPI grid as the page headline | Becomes wallpaper; no next action | Exceptions + verb-tasks first; KPIs demoted, clickable |
| Hiding the ⌘K search behind a hotkey only | Support persona never discovers it | Visible labeled search field (already done — keep) |
| Suppressing the healthy empty-state | Loses the "all clear" reassurance | Keep the prominent "Nothing needs attention" card |
| Recovery page = chart wall | Recovery Ops needs to *act*, not admire | Hero pair → at-risk queue table → trend below |

---

## Archetype B — List (9 pages: stat-strip + filter toolbar/chips + responsive table)

### B.1 Chosen direction

**Table-first, row→full-page-detail navigation, degrading to stacked label/value cards below the responsive breakpoint. Work-queue default filter with "All" one chip away. Persistent filter chips + result count + "clear all."**

Rationale, grounded in the research:

- **Table vs. cards:** Tables win when "users need to scan across rows, compare values, find outliers, or act on multiple items at once" — exactly the Finance-Ops invoice-queue and Support customer-lookup jobs. Cards win for *heterogeneous, browse-y* content, which billing lists are not ([Eleken: Table design UX](https://www.eleken.co/blog-posts/table-design-ux); [NN/g: Mobile Tables](https://www.nngroup.com/articles/mobile-tables/)). **So: table is correct for all 9 lists.**
- **Mobile degradation:** *Do not shrink the desktop grid.* The validated mobile pattern is **row→card stacking** (each row becomes a mini label/value card) for scanning-one-record-at-a-time, which is the dominant mobile billing task. Accrue already does this via the `data_table` responsive degradation — keep and tighten it.
- **Column prioritization on narrow widths:** show identity + state + money + time; defer plumbing columns (processor IDs, internal UUIDs) to the detail page or a secondary line. Sticky header + frozen first column *only if* horizontal scroll is unavoidable.
- **Defaults:** work-queue default (`/invoices` → open/uncollectible) reduces overwhelm and serves the job, with "All" one filter-chip away — the v1.51 decision, **retained**. Show **active filters as removable chips above the table, paired with a visible result count and a "clear all" control** so operators always know "what am I looking at right now" without reopening a panel.
- **Pagination vs. infinite scroll:** **server-side pagination, not infinite scroll.** Billing lists are reference/queue data operators *return to* and *cite* ("invoice #X is on page 2"); infinite scroll destroys position memory, breaks "back" from a detail page, and hides the footer. Virtualize/server-page past ~1,000 rows.

### B.2 Counterposition (argued, then rejected)

*"Cards everywhere are friendlier and more modern; tables feel like a spreadsheet."* Rejected for billing operators: friendliness is the wrong optimization for a scan/compare/act job. The research is explicit that cards *lose* for "identical items that need sorting or comparing." Cards are reserved for the **mobile degradation only**, where comparison across rows is already impossible.

*"Infinite scroll feels faster."* Rejected: it sacrifices the position memory and citeability that an operator queue depends on, and breaks the round-trip to a detail page and back.

### B.3 List states (must all be reachable — feeds the seed-coverage requirement)

| State | Pattern |
|---|---|
| First-run empty (no data ever) | Onboarding empty-state: what this list is + how the first row arrives |
| Filtered-empty (filter excludes all) | *Distinct* copy: "No open invoices — the queue is clear" + a "clear filters" affordance. **Never** show the first-run empty here (misleads operator into thinking data is gone) |
| Loading | Skeleton rows matching the table shape, not a spinner |
| Error | Inline recoverable-error with retry, scoped to the query |
| Single-item / overflow / long-string / multi-currency | Verified via fixtures (already a v1.51 practice) |

### B.4 Extract the shared `PageHeader` (the pending todo)

All 9 list pages currently re-implement the breadcrumb + title + stat-strip + filter-toolbar header inline. Phase 196 extracts one `PageHeader` component (slots: breadcrumbs, title/eyebrow, stat-strip, actions, filter-toolbar) adopted by every list page — the single highest-leverage DRY win for the list archetype, and the substrate that makes "internally consistent across all list pages" enforceable.

### B.5 Anti-patterns to avoid

| Anti-pattern | Why it hurts | Instead |
|---|---|---|
| Shrunk desktop grid on mobile | Unreadable, horizontal+vertical scroll | Row→card stacking |
| Filter state hidden in a panel | "What am I looking at?" requires reopening | Removable chips + result count + clear-all, always visible |
| Plumbing columns (UUIDs, processor IDs) on narrow widths | Crowds out identity/state/money | Defer to detail page or secondary line |
| Padding bloat on dense rows | Fewer rows per viewport, more scrolling | Compact row rhythm; reserve generous padding for cards |
| Infinite scroll on a queue | Breaks position memory + back-navigation | Server pagination |

---

## Archetype C — Object Detail (10+ pages; worst offender: Subscription @ 1,234 LOC / 25+ zones)

This is the milestone's center of gravity. The chosen pattern must convert the flat 25-zone dump into a **layered disclosure** without hiding anything an operator needs *now*.

### C.1 The disclosure-mechanism decision (tabs vs. accordion vs. sectioning vs. summary-then-drill vs. lazy-load vs. side-peek)

| Mechanism | WINS when | FRUSTRATES when | Verdict for Accrue detail |
|---|---|---|---|
| **Summary-then-drill** (persistent summary header + drill sections) | Primary state must always be visible; mixed personas need the gist before specifics | — (it's the safe default) | **PRIMARY pattern.** The summary header answers "what is this, what state, what's wrong" always-on |
| **Tabs** | Peer, supplemental, **mutually-exclusive** groups; short strong-scent labels; non-default content is genuinely secondary | Critical info/actions hidden behind a non-default tab (27–43% miss them); labels need >2 words; tab overflow → carousel | **SECONDARY, sparingly.** Acceptable for peer record-sets (e.g. Customer-360's Subscriptions/Invoices/Payments) — *never* for primary state or a critical action |
| **Accordion / collapsible section** | Independent sections users open selectively; "show me only what I care about" | Everything must be expanded to find anything → accordion fatigue; can't scan collapsed content | **TERTIARY.** Good for the *long tail* (Tax, Dunning, Metadata, raw payload). Open the most-relevant by default |
| **Plain sectioning** (always-visible, headed) | Content is short and all matters | Page becomes the 25-zone dump (current state) | Use only for the 2–3 truly-always-relevant blocks |
| **Lazy-load** | Expensive/rarely-needed content (full event ledger, raw JSON) | Hiding cheap, frequently-needed content adds a needless click | **YES for raw JSON + full timeline** — load on expand |
| **Side-peek / drawer** | A sub-task that needs the record visible behind it (run an action, preview an upcoming invoice, inspect one event) | Complex multi-step flows; comparison across records | **YES for action execution + preview.** Drawer keeps the subscription in context while you act |

**Evidence anchors:** NN/g — tabs are for content of *unequal* importance where "non-default tab content is supplemental rather than critical," labels 1–2 words, and tab overflow becoming a carousel is a known failure ([NN/g: Tabs, Used Right](https://www.nngroup.com/articles/tabs-used-right/)). Baymard — 28% of sites use horizontal tabs despite **43% of users overlooking them** at REI; "vertically collapsed sections" were missed by only **8% vs 27%** for horizontal tabs ([Baymard: Avoid Horizontal Tabs](https://baymard.com/blog/avoid-horizontal-tabs)). NN/g — accordions help "users control when they see content" but force expansion-to-find friction if overused ([NN/g: Accordions on Desktop](https://www.nngroup.com/articles/accordions-on-desktop/)). Smashing — **pages are the default**; overlays only where interruption adds value; drawers bridge "demanding sub-tasks that need the record in context" ([Smashing: Modal vs Page Decision Tree](https://www.smashingmagazine.com/2026/03/modal-separate-page-ux-decision-tree/)).

### C.2 Chosen detail layout (the gold-standard spec for Phase 195)

A single, scannable vertical spine — **never a 2-column form wall**:

1. **Breadcrumbs** (keep — cheap orientation).
2. **Summary header = GOV.UK summary-list.** Key/value rows for the answer-at-a-glance: status badge, customer, current period, next renewal/cancel-at, lifecycle predicate summary, dunning state. Row-level **"Change"** affordances where an action edits that exact field (GOV.UK summary-list semantics, with visually-hidden context on each "Change" link) ([GOV.UK: Summary list](https://design-system.service.gov.uk/components/summary-list/)). This replaces *both* the current `summary_card` *and* the 3-card KPI grid's redundancy.
3. **Action menu — ONE control, not ten forms.** Surface **≤2 primary actions as buttons** (the contextually-likely next action, e.g. "Cancel renewal"), and collapse the remaining 8 into a single **overflow/dropdown menu**, grouped logically with destructive actions visually separated and confirmation-gated. PatternFly: "no more than 2 buttons… reserve the rest for an overflow menu… do not use an overflow menu when there are ≤2 actions" ([PatternFly: Toolbar](https://www.patternfly.org/components/toolbar/design-guidelines/); [Overflow menu](https://www.patternfly.org/components/overflow-menu/design-guidelines/)). Each selected action opens its small form **in a side-drawer** (keeps the subscription visible), and **destructive actions** (cancel-now, comp) route through the existing **step-up-auth modal** — a legitimate modal use ("destructive action confirmation," per Smashing's modal-appropriate list). The swap-plan **upcoming-invoice preview** renders inside that drawer before commit.
4. **Drill sections (collapsible, most-relevant-open-by-default):** Dunning state, Tax ownership, Subscription items. These are the long tail — present, scannable, but not screaming.
5. **Related resources — ONE canonical strip.** Delete the duplicate "related billing" nav card (lines ~191–233 duplicate the `RelatedResources` strip at line 168). Threading stays bidirectional (the v1.51 mandate), including Webhook→Event→entity.
6. **Activity (timeline) + raw payload (JSON) — last, lazy-loaded.** Compliance/Developer plumbing lives at the bottom, behind expand, loaded on demand. This is exactly the "lazy-load expensive/rarely-needed content" win.

**Net effect:** ~25 always-visible zones → ~6 always-visible bands, with the 10 action forms behind one menu and the developer plumbing lazy at the bottom. No information is *deleted* (except the genuine duplicate); it is *layered by frequency-of-need per persona*.

### C.3 Counterposition #1 — "Just use tabs" (argued, then rejected)

*"A 25-zone page obviously wants tabs: Overview / Actions / Items / Activity / Raw."* This is the seductive default and it's **wrong as the primary mechanism** here:

- The **primary state** (status, dunning, next renewal) must be visible *regardless of tab*, or Support/Finance operators miss it — and the data says they will (43% miss rate at REI; 27% for horizontal tabs vs 8% for collapsed sections).
- A **critical action** behind a non-default tab is an anti-pattern; an operator hunting "how do I cancel this?" should not have to guess which tab.
- Billing tab labels resist 1–2 words ("Subscription items & quantities," "Dunning & recovery") → weak scent → the exact failure NN/g warns about.

**Where tabs *do* win:** the **Customer-360** page's peer record-sets (Subscriptions / Invoices / Payments are genuinely mutually-exclusive, equal-weight lists with short labels) — that's the v1.51 "primary tabs + More" tiering, and it's correct *there*. So the rule is: **tabs for peer record collections; summary-then-drill for a single object's state+actions.**

### C.4 Counterposition #2 — "Keep everything visible; operators are power users who hate clicks" (argued, then rejected)

*"Power users (cf. Linear) want zero clicks; every action visible is faster."* Linear is the strongest version of this argument — and it actually *refutes* the everything-visible reading. Linear achieves speed not by **showing every control at once** but by **multiple fast paths to a focused action** (buttons, contextual menus, **command palette**, keyboard shortcuts), with the UI staying calm ([Linear keyboard shortcuts](https://linear.app/changelog/2021-03-25-keyboard-shortcuts-help)). The "ten forms always open" page is *slower*, not faster, because it forces visual search across ten near-identical forms to find the right one. The correct Linear-flavored answer: **collapse the ten into one menu, then make the menu fast** (already have ⌘K; the action menu is keyboard-navigable; destructive actions confirm). Power-user speed comes from *findability and muscle memory*, not from *simultaneous exposure*.

### C.5 Detail anti-patterns to avoid

| Anti-pattern | Where it appears today | Fix |
|---|---|---|
| Every action a pre-expanded inline form | The 10 forms in the left column (lines ~298–469) | One action menu; forms in a side-drawer on demand |
| Duplicate related-resources card | "related billing" nav card duplicates the `RelatedResources` strip | Delete the duplicate; keep one canonical strip |
| Card-in-card / double borders | `ax-card` nested inside `ax-card` (e.g. tax-risk panel inside the actions card; confirm-panel inside actions card) | Flatten; one border level per band; use spacing not nesting |
| Raw JSON always rendered | `JsonViewer` always in the spine | Lazy-load at the bottom behind "Raw payload" |
| Tabs hiding primary state/critical action | (risk if tabs are over-applied in the redesign) | Summary header always-on; actions in a discoverable menu, not a tab |
| Modal-behind-scrim / nested modals | Known firsthand defect class (PROJECT.md) | One modal at a time; destructive-confirm only; drawer for sub-tasks |
| Modal for a complex multi-field action | Risk if action forms get jammed into a modal | Side-drawer for multi-field actions; modal only for the step-up confirm |

---

## Reducing Visual Noise / "Info Dump" (cross-archetype subtraction list)

These are *pure deletions* — no progressive-disclosure mechanism required, lowest-risk highest-value:

1. **Delete the duplicate related card** on Subscription detail.
2. **Collapse card-in-card nesting** — one border level per band; the research consensus is whitespace and hierarchy, not nested chrome, separate content ([Tableau: reduce visual clutter](https://www.tableau.com/blog/use-dashboard-actions-reduce-visual-clutter-68473)).
3. **Kill redundant affordances** — the summary-list with row-"Change" links *replaces* a parallel KPI grid + a separate actions list that restate the same facts.
4. **De-emphasize plumbing** — processor IDs, internal UUIDs, raw status strings become secondary/mono small text, not headline values; emphasize the persona's job-relevant fields (money, state, who/when).
5. **Padding discipline** — dense list rows get compact rhythm; generous padding is for cards/summary headers, not every row.
6. **One eyebrow, one heading** — several cards today render the *same string* as both eyebrow and `<h3>` (e.g. the related-billing card). Pick one.
7. **Per-persona emphasis** — Finance Ops sees money+state first; Developer sees event/webhook IDs; Compliance sees actor+timestamp. The summary-list ordering and the lazy "Activity/Raw" section encode this without per-persona forks.

---

## User Loves / Hates (mined feedback, with citations)

**Operators/power users LOVE:**
- **Speed and "the tool disappearing"** — Linear's whole reputation: "every interaction designed to be fast… the tool should disappear" ([Linear conceptual model](https://linear.app/docs/conceptual-model)); "microsecond savings across hundreds of daily interactions" ([Linear shortcuts changelog](https://linear.app/changelog/2021-03-25-keyboard-shortcuts-help)).
- **Multiple paths to the same action** (button / menu / palette / shortcut) → "easy to figure out how to do anything… build muscle memory" (ibid.).
- **Clarity & predictable layouts, no hidden actions** — explicitly cited as why "Stripe users love clarity and predictable layouts… without hidden actions or confusing elements" ([Stripe Dashboard basics](https://docs.stripe.com/dashboard/basics)).
- **Filter chips that answer "what am I looking at"** + result count + clear-all ([Eleken table UX](https://www.eleken.co/blog-posts/table-design-ux)).
- **Information density where it serves the job** — fintech/operator users value dense, scannable data over whitespace *when the job is scan/compare* ([GridRebels: SaaS designs 2026](https://www.gridrebels.studio/post/20-best-saas-website-designs-in-2026-examples-that-actually-convert)).

**Operators/power users HATE:**
- **Cluttered "info-dump" dashboards** — "admin dashboards that feel like cluttered messes rather than helpful tools… clear insights and control without the overwhelm" ([Wildnet](https://www.wildnetedge.com/blogs/what-to-include-in-a-modern-admin-dashboard-ui)).
- **Hidden tabs** — "a significant subset of users will completely miss the tabs" (43% at REI) ([Baymard](https://baymard.com/blog/avoid-horizontal-tabs); [NN/g tabs](https://www.nngroup.com/articles/tabs-used-right/)).
- **Accordion fatigue** — having to expand every section to find anything ([NN/g accordions](https://www.nngroup.com/articles/accordions-on-desktop/)).
- **Modals that block comparison** — "users re-open the same page in multiple tabs instead" because modals block reference; "needy" auto-popup patterns ([Smashing modal-vs-page](https://www.smashingmagazine.com/2026/03/modal-separate-page-ux-decision-tree/); [NN/g needy patterns](https://www.nngroup.com/articles/needy-design-patterns/)).
- **Infinite scroll on reference data** — destroys position memory and "back" round-trips.
- **Padding bloat / low data-per-screen** on what should be a dense queue.

---

## Implications for v1.54 Requirements & Phase Plan

| Phase | Archetype work this research locks |
|---|---|
| **193** Pattern lock | Adopt the three pattern specs below verbatim as design contracts; stand up PhoenixStorybook to host the canonical summary-header / action-menu / responsive-table stories |
| **194** Dashboard exemplar | *Refine, don't rebuild* — keep four-zone grammar; apply same grammar to Recovery analytics (hero pair → at-risk queue → trend) |
| **195** Subscription detail exemplar | Instantiate the **summary-then-drill + action-menu + side-drawer + lazy plumbing** spec; delete the duplicate related card; flatten card-in-card; 25 zones → ~6 bands |
| **196** Subscriptions list exemplar + `PageHeader` | Table-first, chips+count+clear-all, work-queue default, row→card mobile degradation; extract shared `PageHeader` |
| **197** Propagate LIST | Apply locked list spec to the other 8 list pages |
| **198** Propagate DETAIL + overview | Apply summary-then-drill to the 8 other detail pages + Recovery/Campaign |
| **199** Interaction correctness | Modal/drawer/scroll/focus correctness (the firsthand-observed defect class) across all pages |

### The three pattern specs (turn directly into design contracts)

**SPEC-OVERVIEW:** zones in fixed order = `attention-rail (exceptions-only, prominent healthy empty-state) → verb task-launchers (+ visible ⌘K) → demoted clickable KPIs → recent activity`. Analytics variant = `hero metric pair → work-queue table → supporting trend`. No KPI-first headline.

**SPEC-LIST:** `PageHeader(breadcrumb, title, stat-strip, actions, filter-toolbar) → filter chips + result count + clear-all → table (identity·state·money·time prioritized; plumbing deferred) → row→card stacking below breakpoint → server pagination`. Work-queue default, "All" one chip away. Four distinct states: first-run-empty ≠ filtered-empty ≠ loading-skeleton ≠ error-retry.

**SPEC-DETAIL:** `breadcrumbs → summary-list header (state + row-"Change") → ≤2 primary buttons + overflow action menu (actions open in side-drawer; destructive → step-up modal; swap-plan preview in drawer) → collapsible drill sections (most-relevant open) → ONE related-resources strip (bidirectional threading) → lazy activity timeline + lazy raw JSON`. Never a 2-column form wall; never tabs for primary state/critical action; tabs allowed only for peer record-sets (Customer-360).

---

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Overview pattern | HIGH | Existing dashboard already exemplary; refinement is low-risk |
| List pattern | HIGH | Strong consensus across NN/g, Eleken, Baymard; matches shipped v1.51 decisions |
| Detail disclosure mechanism | HIGH | Converging evidence (NN/g tabs+accordions, Baymard tab-miss rates, Smashing modal-vs-page, PatternFly action menus, GOV.UK summary-list) |
| User loves/hates | MEDIUM-HIGH | Named-product UX commentary + design-house writeups; direct HN/Reddit threads were thin in results, so citations lean on synthesized UX-authority sources and product docs |
| Per-persona emphasis | MEDIUM | Personas are well-defined in v1.51 source; the *ordering* claims are reasoned, not user-tested |

## Gaps to Address (flag for later phases)

- **Side-drawer component**: confirm `detail_drawer.ex` can host action forms + a step-up handoff without the modal-behind-scrim defect; may need a small extension (Phase 199 territory).
- **Action-menu component**: no overflow/dropdown action-menu primitive is confirmed in the read set — Phase 195 likely needs one (and it should land in PhoenixStorybook).
- **`PageHeader` slot contract**: lock the exact slots before Phase 197 propagation to avoid re-churn across 8 list pages.
- **Empirical loves/hates**: if time permits, a targeted HN/Reddit (r/ExperiencedDevs, r/SaaS) pull would harden the MEDIUM-confidence feedback section with verbatim operator quotes.

---

## Sources

- [GOV.UK Design System — Summary list](https://design-system.service.gov.uk/components/summary-list/) (HIGH)
- [GOV.UK Design System — Task list](https://design-system.service.gov.uk/components/task-list/) (HIGH)
- [GOV.UK — One thing per page](https://designnotes.blog.gov.uk/2015/07/03/one-thing-per-page/) (HIGH)
- [NN/g — Tabs, Used Right](https://www.nngroup.com/articles/tabs-used-right/) (HIGH)
- [NN/g — Accordions on Desktop](https://www.nngroup.com/articles/accordions-on-desktop/) (HIGH)
- [NN/g — Mobile Tables](https://www.nngroup.com/articles/mobile-tables/) (HIGH)
- [NN/g — Needy Design Patterns](https://www.nngroup.com/articles/needy-design-patterns/) (MEDIUM)
- [Baymard — Avoid Horizontal Tabs](https://baymard.com/blog/avoid-horizontal-tabs) (HIGH)
- [Smashing Magazine — Modal vs. Separate Page Decision Tree](https://www.smashingmagazine.com/2026/03/modal-separate-page-ux-decision-tree/) (HIGH)
- [PatternFly — Toolbar design guidelines](https://www.patternfly.org/components/toolbar/design-guidelines/) (HIGH)
- [PatternFly — Overflow menu](https://www.patternfly.org/components/overflow-menu/design-guidelines/) (HIGH)
- [Eleken — Table design UX](https://www.eleken.co/blog-posts/table-design-ux) (MEDIUM)
- [Stripe — Web Dashboard basics](https://docs.stripe.com/dashboard/basics) (MEDIUM)
- [Stripe — Design your app (surfaces / details pages)](https://docs.stripe.com/stripe-apps/design) (MEDIUM)
- [Linear — Conceptual model](https://linear.app/docs/conceptual-model) (MEDIUM)
- [Linear — Keyboard shortcuts changelog](https://linear.app/changelog/2021-03-25-keyboard-shortcuts-help) (MEDIUM)
- [Wildnet — Modern Admin Dashboard UI](https://www.wildnetedge.com/blogs/what-to-include-in-a-modern-admin-dashboard-ui) (LOW-MEDIUM)
- [Tableau — Reduce visual clutter](https://www.tableau.com/blog/use-dashboard-actions-reduce-visual-clutter-68473) (LOW-MEDIUM)
- [GridRebels — Best SaaS designs 2026](https://www.gridrebels.studio/post/20-best-saas-website-designs-in-2026-examples-that-actually-convert) (LOW)
- In-repo: `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (the 1,234-LOC info-dump), `dashboard_live.ex` (exemplary overview), `nav.ex` (IA), `.planning/research/v1.51-admin-ui-depth-design.md` (personas + prior decisions) (HIGH — primary source)
