# Phase 194: Exemplar A — Dashboard - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

The first **exemplar** phase of v1.54. It makes the **Dashboard** the locked gold-standard for the *overview* archetype and re-grammars **Recovery analytics** so at-risk work reads as a work-queue, not a chart wall. Both pages conform to the SPEC-OVERVIEW contract locked in Phase 193.

Two surfaces, one archetype:
1. **Dashboard** (`dashboard_live.ex`) — **refine, not rebuild**. The four-zone grammar already exists (attention-rail → task-launchers → demoted KPIs → recent activity, with comment-labeled zones). This phase makes it conform to SPEC-OVERVIEW's machine-checkable invariants and tightens visual hierarchy — it does not redesign the page.
2. **Recovery analytics** (`live/analytics/recovery_live.ex`) — **re-grammar** to `hero metric pair → at-risk work-queue table → supporting trend`. Today it renders `hero KPIs → FunnelChart → AtRiskTable`; the core change is moving the at-risk table above the funnel so operators act on at-risk records before seeing the chart.

**Requirement:** EXE-01.

**Fixed guardrails (carried from 193, not re-litigated):** scope is `accrue_admin` operator UI only; no new billing primitives/domain features/breaking routes; no Tailwind (custom `ax-*` CSS + tokens stay SSOT — editing source CSS ships nothing until `mix accrue_admin.assets.build` + commit); zero new motion tokens; the forward-only scored-cell page-flow gate is the regression mechanism (no pixel-diff); the `/dev/components` kitchen + drift locators stay untouched.

</domain>

<decisions>
## Implementation Decisions

All four gray areas resolved to the **conservative, lowest-risk refine-not-rebuild** package — coherent because the page-flow zero-regression baseline penalizes churn, and this is an *exemplar* (the goal is a clean locked reference, not a redesign).

### Recovery analytics re-grammar
- **D-01 — Keep the existing `FunnelChart` as the "supporting trend"; just re-order.** The `AtRiskTable` moves **above** the `FunnelChart`; the funnel stays as the supporting viz at the bottom. This is the truest refine-not-rebuild reading — no new chart component, no new data plumbing. The funnel is conversion-shaped rather than a literal time-series, but SPEC-OVERVIEW's machine criterion is only "no chart appears before the work-queue table," which the re-order satisfies. **Rejected:** replacing the funnel with a built time-trend line chart (a rebuild — out of scope, adds a component + risk).
- **D-02 — Hero metric pair stays as-is** (Recovered MRR / Exhausted MRR KPI pair) — already the leading zone; no change beyond confirming it remains above the (now-promoted) at-risk table.

### Dashboard refine depth
- **D-03 — Conformance hooks + light polish.** Add the machine-checkable hooks (zone markers + ⌘K selector + empty-rail guard) so all SPEC-OVERVIEW invariants pass, AND do a *light* visual pass: demote the KPI cluster (type scale / card weight) and strengthen the exception-rail weight **only where the 12-dim rubric flags "exceptions higher-signal than KPIs."** Do **not** do a broad type-scale/spacing rework. **Rejected:** conformance-hooks-only (risks not moving the judge-graded hierarchy cells) and active visual rework (higher regression risk against the v1.53 baseline).

### Machine-checkable hook wiring
- **D-04 — Additive `data-ax-*` hooks; leave behavior attributes alone.** Add new `data-ax-zone="attention-rail|task-launcher|kpi-cluster|recent-activity"` markers (in DOM order) to both pages, and add a `data-ax-command-palette-trigger` marker **alongside** the existing `data-command-palette-trigger` (which `command_palette.js` binds to). The page-flow assertions target the new `data-ax-*` markers; the JS hook behavior is untouched. **Rejected:** renaming `data-command-palette-trigger` → `data-ax-command-palette-trigger` across `command_palette.js` + `topbar.ex` + dashboard (cleaner namespace, but touches the JS hook and a third surface — unnecessary risk for an exemplar phase).
- **D-05 — Zone-marker DOM order encodes the invariant:** `attention-rail` index < `task-launcher` index < `kpi-cluster` index in `querySelectorAll('[data-ax-zone]')`. Markers go on the existing zone `<section>`s; structure is not moved.

### Healthy empty-state
- **D-06 — Refine the existing empty card into a deliberate "all clear" hero.** Keep the check-circle empty card but elevate its hierarchy/reassurance copy so it reads as an intentional healthy state, not a thin empty box (success criterion 1: "prominent healthy empty-state"). It MUST stay non-interactive — no `cursor:pointer`, no `role="button"` on `.ax-attention-rail--empty` (the SPEC-OVERVIEW machine guard). **Rejected:** leave-as-is (satisfies the guard but misses the "prominent" criterion).

### Claude's Discretion (planner/executor decide)
- Exact `data-ax-zone` attribute placement and the precise CSS deltas for the KPI demotion / exception-rail emphasis — bounded by "light polish" (D-03) and the no-Tailwind / committed-bundle-rebuild constraint.
- Whether the empty-rail guard is enforced as a new `require_regex` source guard in `verify_package_docs.sh` (mirrored into `PackageDocsVerifierTest seed_tmp_dir!` per the coupling invariant) or only as a page-flow Playwright assertion — research should confirm which mechanism SPEC-OVERVIEW's invariant table already wired in 193 vs. what 194 must add.
- Where the new `surface_type:"page-flow"` cells for these two pages live relative to the additive `baseline.page-flow.cells.json` from 193.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked design contract (read first)
- `accrue_admin/guides/spec-overview.md` — **the SPEC-OVERVIEW contract this phase conforms to.** Machine-checkable invariants table (one `<h1>`; ⌘K trigger present+focusable; KPI cluster DOM-sibling after attention+tasks; non-interactive healthy empty-rail) + judge-graded criteria (exceptions higher-signal than KPIs; KPIs demoted-not-deleted; Recovery as work-queue not chart wall). Its footer names Phases 194 + 198 as downstream consumers.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-CONTEXT.md` — the foundation decisions (D-09..D-12 spec rigor, the machine-vs-judge line, overlay primitive context for later phases).

### Design source / rationale
- `.planning/research/SUMMARY.md` — v1.54 synthesis; defects are STRUCTURAL; the rendered state-matrix gate.
- `.planning/research/FEATURES.md` — overview-archetype direction (exceptions-first, tasks-as-doors); seed material behind SPEC-OVERVIEW.
- `.planning/research/ARCHITECTURE.md` — overview/recovery structural notes.

### Forward-only gate machinery (reuse, do not rebuild)
- `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` — the 12-dimension rubric the page-flow cells (and the "exceptions higher-signal" judgment) score against.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` — the v1.53 baseline; the page-flow cells extend it via the additive `baseline.page-flow.cells.json` sibling (Phase 193 D-16).
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` + `accrue_admin/e2e/phase191-page-flow-helpers.js` — the page-flow Playwright driver to reuse; exposes `assertTopPointerTarget` / `assertScrollReachable` / `assertNoHorizontalClip` / `assertFocusWithin`.

### Surfaces this phase edits
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` — the four-zone dashboard (zones comment-labeled `Zone 1..4`); refine target.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` — re-grammar target (swap `AtRiskTable` above `FunnelChart`).
- `accrue_admin/assets/js/hooks/command_palette.js` + `accrue_admin/lib/accrue_admin/components/topbar.ex` — own the existing `data-command-palette-trigger` attribute (do NOT rename — D-04); referenced only to confirm the additive `data-ax-command-palette-trigger` marker doesn't collide.
- `accrue_admin/assets/css/app.css` (+ `theme.css` tokens) — the source CSS for any KPI-demotion / exception-emphasis / empty-state polish; **must be rebuilt to the committed bundle** (`mix accrue_admin.assets.build`) + committed or nothing ships.

### Source-guard coupling (if a new guard is added)
- `scripts/ci/verify_package_docs.sh` — `require_regex`/`require_fixed` guard host (e.g. an empty-rail `cursor:pointer` ban) — pairs with `PackageDocsVerifierTest seed_tmp_dir!` (the D-08 coupling invariant: a new needle here MUST be mirrored there or all 6 negative tests fail).

### Brand voice
- `prompts/accrue-brand-book.md` (gitignored, may be absent) — "well-made dev tooling, quiet polish," not fintech; informs the empty-state copy + KPI tone. If absent, `accrue_admin/guides/admin_ui.md` carries the same voice.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Dashboard four-zone scaffold** (`dashboard_live.ex`): zones already exist and are comment-labeled (`Zone 1 — Attention rail`, `Zone 2 — Task launchers`, `Zone 3 — At a glance: demoted KPIs`, Zone 4 recent activity). Refine in place; add `data-ax-zone` markers to the existing `<section>`s.
- **Visible ⌘K search** (`dashboard_live.ex` ~L99-110): already a focusable `<button role="search">` with `data-command-palette-trigger` + "⌘K" placeholder (IA-01). Add the `data-ax-command-palette-trigger` marker here.
- **`KpiCard.kpi_card`**: the demoted-KPI component on both pages (dashboard 4-up grid; recovery hero pair). Demotion is a styling concern, not a structural one.
- **`AtRiskTable.at_risk_table` + `FunnelChart.funnel_chart`** (recovery): both already rendered — the re-grammar is purely their order.
- **Attention empty-state** (`dashboard_live.ex` ~L85): existing `ax-card ax-empty` with check-circle icon — the elevate-to-hero target; keep non-interactive.
- **Page-flow Playwright driver** (Phase 191): reuse for the two new `surface_type:"page-flow"` cells.

### Established Patterns
- **Source-lint where mechanical, render-detect where compositional** — invariants that the page-flow driver / source guards / axe-core can decide are machine assertions; "exceptions higher-signal," "KPIs demoted not dominant," "work-queue not chart wall" stay judge-graded rubric cells (193 D-10).
- **Custom `ax-*` CSS + committed bundle is SSOT** — editing `app.css` ships nothing until rebuilt + committed (a repeatedly-hit footgun; Phase 189 shipped dead CSS this way).
- **`verify_package_docs.sh` ↔ `PackageDocsVerifierTest` coupling** — any new needle mirrored into `seed_tmp_dir!` (193 D-08).

### Integration Points
- New `data-ax-zone` + `data-ax-command-palette-trigger` markers wire into the page-flow spec's DOM-order + visibility assertions.
- Two new page-flow cells fold into the unchanged `regressions.ndjson` zero-regression gate against `baseline.page-flow.cells.json`.

</code_context>

<specifics>
## Specific Ideas

- "Refine, not rebuild" is the literal operating instruction for the Dashboard — the four zones exist; this phase conforms + lightly polishes, it does not redesign.
- Recovery's one structural move: **AtRiskTable above FunnelChart.** Everything else (hero pair, funnel-as-supporting-viz) stays.
- The healthy attention-rail should read as a deliberate "all clear" reassurance hero, not an empty placeholder — but never interactive (SPEC-OVERVIEW guard).
- `data-ax-*` markers are **additive** — never rename the working `data-command-palette-trigger` behavior attribute.

</specifics>

<deferred>
## Deferred Ideas

- **Actual recovered-vs-lost time-trend line chart** for Recovery — a rebuild; out of scope here (D-01 keeps the existing funnel). Candidate for a future analytics phase if "supporting trend" is later read literally.
- **Renaming `data-command-palette-trigger` → `data-ax-command-palette-trigger` repo-wide** — a namespace-consistency cleanup touching `command_palette.js` + `topbar.ex`; defer to a dedicated tidy pass, not this exemplar.
- **Broad type-scale / spacing rework of the Dashboard** — beyond "light polish"; out of scope to protect the zero-regression baseline.
- **Sweeping the overview grammar across the *other* overview pages** — Phase 198 (SPEC-OVERVIEW footer names 198 as the second consumer).

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 194-exemplar-a-dashboard*
*Context gathered: 2026-06-25*
