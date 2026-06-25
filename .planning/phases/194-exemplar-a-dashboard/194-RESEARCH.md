# Phase 194: Exemplar A — Dashboard - Research

**Researched:** 2026-06-25
**Domain:** `accrue_admin` operator-UI conformance (Phoenix LiveView + custom `ax-*` CSS), forward-only scored-cell page-flow gate, CI source guards
**Confidence:** HIGH (all findings grounded in the actual repo files; no external dependencies introduced)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 — Recovery re-grammar = re-order only.** Keep the existing `FunnelChart` as the "supporting trend"; move `AtRiskTable` **above** `FunnelChart`. No new chart component, no new data plumbing. SPEC-OVERVIEW's machine criterion is only "no chart appears before the work-queue table," which the re-order satisfies. **Rejected:** replacing the funnel with a built time-trend line chart (out of scope).
- **D-02 — Hero metric pair stays as-is** (Recovered MRR / Exhausted MRR KPI pair). No change beyond confirming it remains above the (now-promoted) at-risk table.
- **D-03 — Conformance hooks + light polish.** Add machine-checkable hooks (zone markers + ⌘K selector + empty-rail guard) so all SPEC-OVERVIEW invariants pass, AND a *light* visual pass: demote the KPI cluster (type scale / card weight) and strengthen the exception-rail weight **only where the 12-dim rubric flags "exceptions higher-signal than KPIs."** No broad type-scale/spacing rework. **Rejected:** conformance-hooks-only; active visual rework.
- **D-04 — Additive `data-ax-*` hooks; leave behavior attributes alone.** Add new `data-ax-zone="attention-rail|task-launcher|kpi-cluster|recent-activity"` markers (in DOM order) to both pages, and add a `data-ax-command-palette-trigger` marker **alongside** the existing `data-command-palette-trigger` (which `command_palette.js` binds to). Page-flow assertions target the new `data-ax-*` markers; the JS hook behavior is untouched. **Rejected:** renaming `data-command-palette-trigger`.
- **D-05 — Zone-marker DOM order encodes the invariant:** `attention-rail` index < `task-launcher` index < `kpi-cluster` index in `querySelectorAll('[data-ax-zone]')`. Markers go on the existing zone `<section>`s; structure is not moved.
- **D-06 — Refine the existing empty card into a deliberate "all clear" hero.** Keep the check-circle empty card but elevate its hierarchy/reassurance copy. It MUST stay non-interactive — no `cursor:pointer`, no `role="button"` on `.ax-attention-rail--empty` (the SPEC-OVERVIEW machine guard). **Rejected:** leave-as-is.

### Claude's Discretion
- Exact `data-ax-zone` attribute placement and the precise CSS deltas for the KPI demotion / exception-rail emphasis — bounded by "light polish" (D-03) and the no-Tailwind / committed-bundle-rebuild constraint.
- Whether the empty-rail guard is enforced as a new `require_regex` source guard in `verify_package_docs.sh` (mirrored into `PackageDocsVerifierTest seed_tmp_dir!`) or only as a page-flow Playwright assertion — research must confirm which mechanism SPEC-OVERVIEW already wired in 193 vs. what 194 must add. **[RESOLVED below — Q2.]**
- Where the new `surface_type:"page-flow"` cells for these two pages live relative to `baseline.page-flow.cells.json`. **[RESOLVED below — Q3: cells already exist; 194 scores them, does not create them.]**

### Deferred Ideas (OUT OF SCOPE)
- Actual recovered-vs-lost time-trend line chart for Recovery (a rebuild).
- Renaming `data-command-palette-trigger` → `data-ax-command-palette-trigger` repo-wide.
- Broad type-scale / spacing rework of the Dashboard.
- Sweeping the overview grammar across the *other* overview pages (that is Phase 198).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXE-01 | The Dashboard is refined to the locked four-zone overview spec (refine-not-rebuild) and the Recovery analytics page is re-grammared to `hero metric pair → at-risk work-queue → trend`. | The four-zone scaffold already exists in `dashboard_live.ex` (comment-labeled Zone 1–4); the re-grammar is a single render-block swap in `recovery_live.ex` (L145–L152). All conformance hooks (markers, guard) and the scoring path are mapped below. |
</phase_requirements>

## Summary

This is a **refine-not-rebuild conformance phase** against an already-shipped, well-understood codebase. The four-zone Dashboard scaffold and the Recovery page both physically exist; the phase's job is to (1) wire SPEC-OVERVIEW's machine-checkable hooks, (2) do a *light* CSS polish bounded by the rubric, (3) re-order one Recovery render block, and (4) prove zero regression against the page-flow baseline. There are **no new dependencies, no new domain code, no new routes.**

The single most important research finding is the **gate-machinery delta**: SPEC-OVERVIEW (locked in Phase 193) *documents* four machine-checkable invariants and *names the verification mechanisms* (`assertFocusWithin`, `assertTopPointerTarget`, the `data-ax-zone` DOM-order assertion, a `require_regex` source guard on `.ax-attention-rail--empty`), but **none of these invariant assertions are actually wired yet.** The `data-ax-zone` / `data-ax-command-palette-trigger` markers do not exist in any source file; the `.ax-attention-rail--empty` CSS class does not exist; the empty-rail `cursor:pointer` source guard is not in `verify_package_docs.sh`; and the existing page-flow spec (`admin-page-flow-phase191.spec.js`) asserts the Phase-191 AX187 harness, *not* the SPEC-OVERVIEW invariants. **Phase 194 must build all of this conformance machinery** — it is the first consumer of the SPEC-OVERVIEW contract, so it is where the contract becomes enforced.

The second key finding is that the **page-flow baseline cells already exist** and are *pending*, not absent. `baseline.page-flow.cells.json` (Phase 193 D-16) already contains 432 `p193__dashboard__*` cells and 432 `p193__recovery__*` cells, all `coverage_status: "pending"`, `score: null`. Phase 194 does **not** create cells — it *scores* the existing dashboard + recovery cells against the v1.53 baseline via `regressions.ndjson` (the `score-downgrade` check). This dramatically narrows scope.

**Primary recommendation:** Treat the phase as four tightly-scoped slices — (A) Dashboard hooks + light CSS, (B) Recovery render-order swap + hooks, (C) the SPEC-OVERVIEW page-flow assertion spec (new), (D) the empty-rail source guard + `PackageDocsVerifierTest` mirror — followed by the mandatory `mix accrue_admin.assets.build` + commit of `priv/static/accrue_admin.css`. Enforce the empty-rail non-interactivity as **both** a Playwright `assertTopPointerTarget` assertion *and* a `require_regex` source guard (SPEC-OVERVIEW's invariant table specifies both, and neither exists today).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Four-zone overview grammar + zone markers | Frontend Server (LiveView render) | — | `dashboard_live.ex` `render/1` HEEx; markers are DOM attributes, no socket runtime needed |
| Recovery render-order (table above funnel) | Frontend Server (LiveView render) | — | Pure render-block re-order in `recovery_live.ex` `render/1` (L145–152) |
| KPI demotion / exception emphasis / empty-state polish | CDN / Static (committed CSS bundle) | Frontend Server (class names) | Visual weight is a CSS concern in `app.css`; served from committed `priv/static/accrue_admin.css` |
| ⌘K trigger focusability + presence | Browser / Client (`command_palette.js` hook, untouched) | Frontend Server (the additive marker attribute) | Behavior is the existing JS hook (D-04: do not touch); 194 only adds a sibling detection marker |
| SPEC-OVERVIEW invariant assertions | Test infra (Playwright page-flow driver) | — | Deterministic DOM/focus/pointer checks via `phase191-page-flow-helpers.js` |
| Empty-rail non-interactivity guard | Test infra (CI source guard) + Test infra (Playwright) | — | Source-lint where mechanical (`verify_package_docs.sh`) + render-detect (`assertTopPointerTarget`) |
| Zero-regression scoring | Planning artifact (scored cells) | Test infra (scorecard) | `regressions.ndjson` `score-downgrade` check against `baseline.page-flow.cells.json` |

## Standard Stack

No new packages. This phase uses only what is already wired. **Do not add dependencies.**

### Core (already present — reuse verbatim)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `phoenix_live_view` | `~> 1.1` | The two target LiveViews render via `~H`/HEEx | Already the admin dashboard runtime |
| Custom `ax-*` CSS + `theme.css` tokens | — | SSOT for all visual weight | Project mandate: no Tailwind utilities as authoring path (CLAUDE.md) |
| `tailwindcss@3.4.17` (CLI, as CSS processor) | pinned in `accrue_admin.assets.build.ex` L20 | Minifies `app.css` → committed `priv/static/accrue_admin.css` | The asset build pipeline; **not** a utility authoring path |
| `esbuild@0.25.3` (CLI) | pinned L21 | Bundles `app.js` → `priv/static/accrue_admin.js` | JS bundle (not touched this phase — D-04) |
| `@playwright/test` | (e2e dev) | Page-flow driver + new SPEC-OVERVIEW assertions | Phase 191 harness reused |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Both source-guard + Playwright for empty-rail | Playwright-only | SPEC-OVERVIEW's invariant table explicitly names *both* mechanisms; source guard catches the regression at compile-cost-free CI lint before a browser even boots. Use both. |
| Re-scoring existing cells | Creating new "spec-overview" cells | Cells already exist as `p193__dashboard__*` / `p193__recovery__*`; creating new ones would fork the baseline and break the zero-regression union-load. Do not create cells. |

**Installation:** none.

## Package Legitimacy Audit

> Not applicable — this phase installs no external packages. All tooling (`phoenix_live_view`, `tailwindcss` CLI, `esbuild` CLI, `@playwright/test`) is already present and was vetted in earlier phases / CLAUDE.md.

## Architecture Patterns

### System Architecture Diagram

```
                       SOURCE (authoring)                          COMMITTED (served)
                       ────────────────────                        ────────────────────
  dashboard_live.ex  ─┐
  recovery_live.ex   ─┤ HEEx render/1  ── data-ax-zone markers ──►  (LiveView at runtime)
                      │                    data-ax-command-palette-trigger
                      │                    .ax-attention-rail--empty class
                      ▼
  assets/css/app.css ── mix accrue_admin.assets.build ─(tailwind CLI minify)─► priv/static/accrue_admin.css
       │  (KPI demotion / exception emphasis / empty-state hero deltas)              ▲
       │                                                                            │ THIS bundle is served.
       └─ FOOTGUN: editing app.css alone ships NOTHING ─────────────────────────────┘ Editing source without
                                                                                      rebuild+commit = dead CSS.

  ── VERIFICATION ────────────────────────────────────────────────────────────────────────
  scripts/ci/verify_package_docs.sh ── require_regex on .ax-attention-rail--empty {no cursor:pointer}
       │  (NEW guard)  ◄── MUST be mirrored into ──►  PackageDocsVerifierTest seed_tmp_dir! (D-08 coupling)
       │
  e2e/<new>-spec-overview.spec.js (NEW) ── reuses phase191-page-flow-helpers.js:
       │   • page.locator('h1').count() === 1
       │   • locator('[data-ax-command-palette-trigger]') visible + assertFocusWithin
       │   • querySelectorAll('[data-ax-zone]') index order: attention < task < kpi
       │   • assertTopPointerTarget(empty-rail) === NOT a pointer target
       │   • recovery: at-risk table index < funnel index (no chart before work-queue)
       ▼
  regressions.ndjson  ◄── scores p193__dashboard__* / p193__recovery__* cells vs v1.53 baseline.cells.json
       (score-downgrade check: final_score >= baseline_score, zero regressions)
```

File-to-implementation mapping is in the Component Responsibilities table; the diagram shows the data/verification flow.

### The Two Target LiveViews (verified line numbers)

**`accrue_admin/lib/accrue_admin/live/dashboard_live.ex`** — `render/1` at L39–234. Confirmed current structure:
- L49 `<section class="ax-page ax-home">` — page root
- L50–54 `<header class="ax-page-header">` with the **single** `<h1 class="ax-display">` at L52 (✅ one-h1 invariant already satisfied)
- L56 `<%!-- Zone 1 — Attention rail ... --%>`, L57 `<section class="ax-home-section" aria-label="Billing exceptions">` — **add `data-ax-zone="attention-rail"` here**
- L70–83 the populated attention list (`.ax-card.ax-attention`)
- **L85–89** the empty card: `<div :if={@attention == []} class="ax-card ax-empty">` with `check_circle` icon + `ax-empty-title` + `ax-empty-copy` — **this is the D-06 hero target.** Add the `.ax-attention-rail--empty` class here and elevate hierarchy.
- L92 `<%!-- Zone 2 — Task launchers --%>`, L93 `<section class="ax-home-section" aria-label="Tasks">` — **add `data-ax-zone="task-launcher"` here**
- **L99–110** the visible ⌘K search: `<button ... class="ax-input-search" role="search" data-command-palette-trigger="true">` at L100–106 with the "⌘K" placeholder at L108. **Add `data-ax-command-palette-trigger="true"` to this button alongside the existing attribute** (D-04).
- L148 `<%!-- Zone 3 — At a glance: demoted KPIs --%>`, L149 `<section class="ax-home-section" aria-label={...}>` — **add `data-ax-zone="kpi-cluster"` here**; the `ax-kpi-grid ax-kpi-grid-4` (L154) holds 4 `KpiCard.kpi_card`
- L197 `<%!-- Zone 4 — Recent activity --%>`, L198 `<section class="ax-grid ax-grid-2" ...>` — **add `data-ax-zone="recent-activity"` here**

DOM source order already is attention(L57) < task(L93) < kpi(L149) < recent(L198), so D-05's invariant holds purely from marker placement — **no structural move on the dashboard.**

**`accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex`** — `render/1` at L90–156. Confirmed current structure:
- L100 `<section class="ax-page">` root
- L101–119 `<header class="ax-page-header">` with the **single** `<h1 class="ax-display">` at L104 (✅ one-h1)
- L121–143 the `@kpi_pairs` loop rendering the hero metric pair (Recovered MRR / Exhausted MRR) — stays leading (D-02). Wrap/attach `data-ax-zone="attention-rail"` semantics carefully: Recovery has no exception rail; its overview-grammar leading zone *is* the hero metric pair. **The planner must decide zone-marker mapping for Recovery** — recommended: mark the hero `<section>` as the leading zone and the at-risk table as `task-launcher`/work-queue, OR mark only what the SPEC-OVERVIEW assertion checks (the at-risk-table-before-funnel order). See Open Questions Q-A.
- **L145–150** `<FunnelChart.funnel_chart ... />` — currently renders **before** the table.
- **L152** `<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />` — currently **after** the funnel.
- **The single structural change (D-01):** swap L145–150 and L152 so the at-risk table renders above the funnel.

### Anti-Patterns to Avoid
- **Editing `app.css` without rebuilding the bundle** — the served file is committed `priv/static/accrue_admin.css`, *not* `app.css`. Phase 189 shipped dead CSS exactly this way (MEMORY). Always run `mix accrue_admin.assets.build` and commit the bundle.
- **Renaming `data-command-palette-trigger`** — D-04 forbids it; `command_palette.js` binds to it. Add the `data-ax-*` marker *alongside*.
- **Creating new page-flow cells** — they already exist (pending). Score the existing ones.
- **Adding a new chart / time-series for Recovery** — explicitly deferred (D-01).
- **Adding a source guard needle without mirroring into `PackageDocsVerifierTest`** — D-08 coupling: all 6 negative tests fail otherwise (MEMORY: `verify_package_docs ↔ test coupling`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DOM-order / focus / pointer assertions | Custom Playwright eval blocks | `phase191-page-flow-helpers.js` exports `assertFocusWithin`, `assertTopPointerTarget`, `assertScrollReachable`, `assertNoHorizontalClip` | Already battle-tested; the SPEC-OVERVIEW invariant table names these exact helpers |
| Source-text guard | Inline grep in CI yml | `require_regex` / `require_fixed` helpers in `verify_package_docs.sh` (L23–35) | Established pattern; auto-fails CI with a clear message |
| Cell scoring / regression detection | Custom diff script | `phase192-scorecard.mjs` `score-downgrade` check (L457–465) | Already loads page-flow lens and compares against baseline |
| Asset bundling | Manual tailwind/esbuild invocation | `mix accrue_admin.assets.build` | Pins the exact CLI versions, writes only the two bundle files |
| Spacing / type tokens | Raw px literals | `--ax-space-*` / `--ax-type-*` tokens | RES-04 Guard A bans raw px on padding/margin/gap outside the allowlist |

**Key insight:** Every mechanism this phase needs already exists as a reusable primitive. The phase is *wiring*, not building.

## Common Pitfalls

### Pitfall 1: The "dead CSS" footgun
**What goes wrong:** Visual deltas (KPI demotion, empty-state hero) are written to `assets/css/app.css` but never appear because the served bundle is the committed `priv/static/accrue_admin.css`.
**Why it happens:** The build is decoupled — `app.css` is source, the minified bundle is the served artifact.
**How to avoid:** After every CSS edit, run `mix accrue_admin.assets.build` (from `accrue_admin/`) and `git add accrue_admin/priv/static/accrue_admin.css`. The 194 plan MUST include this as an explicit task step.
**Warning signs:** Page-flow rubric cells don't move despite "completed" CSS work; `git diff` shows only `app.css` changed, not the bundle.

### Pitfall 2: RES-04 Guard A trips on new spacing literals
**What goes wrong:** A KPI-demotion or empty-state CSS delta introduces `padding: 12px` (raw px) and CI `verify_package_docs.sh` fails.
**Why it happens:** Guard A (L555–568) bans raw px on `padding|margin|gap` unless the line uses `var(--ax-` or carries an `/* ax-spacing-exception: ... */` comment.
**How to avoid:** Use `--ax-space-*` tokens. If a genuine new exception is needed, annotate with the `ax-spacing-exception:` comment convention (193 D-15).
**Warning signs:** CI fails with "must not use raw px spacing outside --ax-space-* tokens (RES-04 spacing-literal guard)".

### Pitfall 3: Adding a source-guard needle without the test mirror (D-08 coupling)
**What goes wrong:** A new `require_regex`/`require_fixed` needle is added to `verify_package_docs.sh` but the standalone script stays green while `mix test ...package_docs_verifier_test.exs` fails all 6 negative tests.
**Why it happens:** `PackageDocsVerifierTest` `seed_tmp_dir!` seeds a fixture tree; a needle pointing at a file not seeded there fails the negative tests (193 D-08; MEMORY).
**How to avoid:** For the empty-rail guard, the needle targets `app.css` (already seeded, per 193-05 which appended CSS-guard fixtures). Confirm `app.css` is in the seed set and that the new negative test plants a violating `.ax-attention-rail--empty { cursor: pointer; }` line. Mirror exactly like the three existing CSS-guard negative tests (append-with-trailing-`\n` pattern, per 193-05 deviation #4/#5).
**Warning signs:** `mix test` red, `bash scripts/ci/verify_package_docs.sh` green.

### Pitfall 4: Recovery zone-marker mapping ambiguity
**What goes wrong:** Recovery has no exception/attention rail, so the four-zone `data-ax-zone` enum doesn't map 1:1. A wrong marker set makes the DOM-order assertion meaningless or false.
**Why it happens:** SPEC-OVERVIEW's zone grammar was authored for the Dashboard; Recovery is "the same archetype" but its leading zone is the hero metric pair, not an exception rail.
**How to avoid:** For Recovery, the load-bearing machine check is **"no chart before the work-queue table"** (D-01) — assert at-risk-table DOM index < funnel DOM index. The zone-marker enum on Recovery is the planner's discretion (Open Q-A); keep it honest to what's there. Do not force an `attention-rail` marker onto a page with no attention rail unless the hero pair is explicitly designated as the leading zone.

## Code Examples

### Additive zone marker on an existing `<section>` (dashboard)
```elixir
# Source pattern — dashboard_live.ex (add attribute only; do NOT move the section)
<section class="ax-home-section" aria-label="Billing exceptions" data-ax-zone="attention-rail">
```

### Additive ⌘K marker alongside the behavior attribute (D-04)
```elixir
# dashboard_live.ex ~L100 — both attributes coexist; command_palette.js still binds the old one
<button
  type="button"
  class="ax-input-search"
  role="search"
  aria-label="Search"
  data-command-palette-trigger="true"
  data-ax-command-palette-trigger="true"
>
```

### Recovery render-order swap (D-01) — the one structural change
```elixir
# recovery_live.ex render/1 — table BEFORE funnel
<AtRiskTable.at_risk_table rows={@at_risk} base_path={@admin_mount_path} />

<FunnelChart.funnel_chart
  entered={@funnel.entered}
  recovered={@funnel.recovered}
  exhausted={@funnel.exhausted}
  active={@funnel.active}
/>
```

### New empty-rail source guard (verify_package_docs.sh) — pattern mirrors RES-04 Guards
```bash
# Phase 194 — empty-rail non-interactivity guard (SPEC-OVERVIEW)
# Source: existing RES-04 guard convention, scripts/ci/verify_package_docs.sh L552-586
empty_rail_pointer_hit=$(
  perl -0ne '
    while (/\.ax-attention-rail--empty[^{]*\{([^}]*)\}/gs) {
      my $block = $1;
      if ($block =~ /cursor\s*:\s*pointer/) { print "found cursor:pointer on empty rail\n"; last; }
    }
  ' "$app_css" || true
)
[[ -z "$empty_rail_pointer_hit" ]] || fail "$app_css must not put cursor:pointer on .ax-attention-rail--empty (SPEC-OVERVIEW non-interactive empty-rail guard)"
```
*(Exact form is the planner/executor's discretion; a `grep -E` line-guard is also acceptable. The block-scan above matches the existing Guard C style.)*

### New page-flow assertion spec (reuses Phase-191 helpers)
```javascript
// Source: existing helpers, accrue_admin/e2e/phase191-page-flow-helpers.js
const { assertFocusWithin, assertTopPointerTarget } = require("./phase191-page-flow-helpers.js");

// one h1
expect(await page.locator("h1").count()).toBe(1);

// ⌘K present + focusable
const kbd = page.locator("[data-ax-command-palette-trigger]");
await expect(kbd).toBeVisible();
await kbd.focus();
await assertFocusWithin(page, kbd, "command palette trigger");

// zone DOM order (D-05)
const order = await page.evaluate(() =>
  [...document.querySelectorAll("[data-ax-zone]")].map((n) => n.dataset.axZone)
);
expect(order.indexOf("attention-rail")).toBeLessThan(order.indexOf("task-launcher"));
expect(order.indexOf("task-launcher")).toBeLessThan(order.indexOf("kpi-cluster"));

// empty-rail non-interactive (seed the empty state first)
await assertTopPointerTarget(/* should THROW / not be a pointer target */);
```

## State of the Art

| Old Approach (pre-194) | Current Approach (194 establishes) | When Changed | Impact |
|------------------------|-----------------------------------|--------------|--------|
| SPEC-OVERVIEW invariants *documented* but not asserted | Invariants *enforced* via new page-flow spec + source guard | Phase 194 | First enforcement of the contract; Phase 198 reuses the same machinery |
| No `data-ax-*` zone/command markers in source | Additive `data-ax-zone` + `data-ax-command-palette-trigger` markers | Phase 194 | Deterministic DOM-order/visibility hooks |
| Recovery: funnel before at-risk table | At-risk table before funnel | Phase 194 (D-01) | Work-queue reads first |
| `baseline.page-flow.cells.json` all `pending` | Dashboard + Recovery cells scored | Phase 194 | Two surfaces leave `pending`; remaining 19 surfaces scored by later phases |

**Deprecated/outdated:** nothing removed. All changes are additive or single re-orders.

## Gate-Machinery Delta (the linchpin — answers Focus Q1–Q5)

### Q1 — Which SPEC-OVERVIEW invariants were ALREADY wired in 193 vs. what 194 must add

| Invariant | Wired in 193? | What 194 must add |
|-----------|---------------|-------------------|
| Exactly one `<h1>` per page | **Partially** — both pages already render exactly one `<h1 class="ax-display">` (dashboard L52, recovery L104). No *assertion* exists. | The Playwright `page.locator('h1').count() === 1` check in the new spec. Source already conformant. |
| ⌘K trigger present + focusable | **No.** The button exists (dashboard L100–106 with `data-command-palette-trigger`) but the `data-ax-command-palette-trigger` detection marker does NOT exist anywhere in source, and no assertion exists. | The additive marker (D-04) + the `locator('[data-ax-command-palette-trigger]')` visible + `assertFocusWithin` assertion. |
| KPI cluster DOM-sibling after attention+tasks | **No.** Source order is already correct, but no `data-ax-zone` markers exist and no assertion exists. | All four `data-ax-zone` markers + the `querySelectorAll('[data-ax-zone]')` index-order assertion (D-05). |
| Non-interactive healthy empty-rail | **No.** The empty card is `.ax-empty` (app.css L3330–3336, already documented "No cursor:pointer, no :hover"). The `.ax-attention-rail--empty` class named by SPEC-OVERVIEW does NOT exist; no source guard exists; no `assertTopPointerTarget` check exists. | The `.ax-attention-rail--empty` class (elevated hero, D-06) + the `require_regex` source guard + the `assertTopPointerTarget` assertion. |
| Recovery: no chart before work-queue | **No.** Funnel currently renders before table (recovery L145 vs L152). | The render-order swap (D-01) + a DOM-order assertion (at-risk-table index < funnel index). |

**Verdict:** Phase 193 locked the *contract* (the guide text in `spec-overview.md`) and built the *substrate* (page-flow cells, RES-04 CSS guards, the 191 helper library). **It did not wire a single SPEC-OVERVIEW invariant assertion.** Phase 194 is where the contract becomes machine-enforced. The available assertion API is confirmed in `phase191-page-flow-helpers.js`: `assertFocusWithin(page, target, label)`, `assertTopPointerTarget(locator, label)`, `assertScrollReachable(locator, label)`, `assertNoHorizontalClip(page, selector, label)`, plus `assertNoBodyFocus`.

### Q2 — Empty-rail guard mechanism

**Answer: BOTH, and both are NEW in 194.** SPEC-OVERVIEW's invariant table (`spec-overview.md` L31) explicitly specifies *two* mechanisms for this invariant:
> "Playwright `assertTopPointerTarget` confirms the empty-state element is not a pointer-events target; source guard (`require_regex`) ensures no `cursor:pointer` on `.ax-attention-rail--empty`."

Neither exists today (no `.ax-attention-rail--empty` class, no guard in `verify_package_docs.sh`, no assertion in any spec). So 194 must:
1. **Add the class** `.ax-attention-rail--empty` to `app.css` (the elevated D-06 hero), ensuring it carries no `cursor:pointer` and no `:hover` affordance.
2. **Add the source guard** to `verify_package_docs.sh` (sample above). Exact needle: a block/line scan rejecting `cursor:pointer` (or `cursor: pointer`) within a `.ax-attention-rail--empty` rule. The guard belongs with the other RES-04 CSS guards (L552–586).
3. **Mirror into `PackageDocsVerifierTest seed_tmp_dir!`** per D-08 (MEMORY: verify_package_docs ↔ test coupling). `app.css` is already in the seed set (193-05 added the three CSS-guard negative tests against it), so the mirror is a *new negative test* that appends a violating `.ax-attention-rail--empty { cursor: pointer; }\n` line and asserts the script fails. Use the append-with-trailing-`\n` pattern (193-05 deviations #4/#5) — full-replace breaks earlier token-consumption guards.
4. **Add the Playwright assertion** in the new spec: seed the empty attention state, then assert the empty-state element is NOT the top pointer target.

The `role="button"` half of D-06 is enforced naturally by the markup (the executor simply must not add `role="button"`); optionally add an axe/`assertTopPointerTarget` check. The markup guard can also be a `require_absent_regex` on the LiveView if desired, but the CSS `cursor:pointer` guard is the one SPEC-OVERVIEW names.

### Q3 — Where the new page-flow cells live

**Answer: they already exist; 194 does NOT create cells.** `baseline.page-flow.cells.json` (created by 193-02) already contains the full cross-product for all 21 page-flow surfaces, including **432 `dashboard` cells and 432 `recovery` cells**, all `coverage_status: "pending"`, `score: null`, prefixed `p193__`.

- **Cell ID format:** `p193__<surface>__<mode>__<theme>__<state>__d<NN>` — e.g. `p193__dashboard__chromium-desktop__light__default-populated__d02`, `p193__recovery__chromium-mobile__dark__empty__d11`.
- **Matrix per surface:** 2 modes (`chromium-desktop` 1440px, `chromium-mobile` 390px) × 2 themes (light, dark) × 9 FLOW_STATES (default-populated, empty, loading, error, permission-denied, disconnected-reconnecting, overflow, long-content, interactive-open) × 12 dimensions = **432 cells/surface**.
- **How 194 scores them:** Phase 194 sets `score` (0–3 per `scoreValue`, `phase192-scorecard.mjs` L255–259) and flips `coverage_status` to `covered` for the dashboard + recovery cells it evidences. The `regressions.ndjson` gate (scorecard L457–465) emits a `score-downgrade` row if any `final_score < baseline_score` — the v1.53 baseline is `baseline.cells.json` (the p187 cells). Success criterion 3 ("≥ baseline cells, zero regressions") = zero `score-downgrade` rows for these two surfaces.
- **Important nuance:** the page-flow cells are `p193__`-prefixed while the v1.53 baseline is `p187__`. The planner must confirm how the scorecard maps a `p193__dashboard__...` cell to its `p187__dashboard__...` baseline counterpart for the `score-downgrade` comparison (same surface/mode/theme/state/dimension, different phase prefix). See Open Q-B. This is a planning-time question, not a blocker — both sets are union-loaded by the scorecard (193-02 "affects: phase192-scorecard.mjs union-load").

### Q4 — CSS bundle rebuild reality

**Exact workflow (verified `accrue_admin.assets.build.ex`):**
```bash
cd accrue_admin
mix accrue_admin.assets.build      # runs: npx tailwindcss@3.4.17 --input assets/css/app.css --output priv/static/accrue_admin.css --minify
                                   #  then: npx esbuild@0.25.3 assets/js/app.js --bundle --format=esm --minify --outfile=priv/static/accrue_admin.js
git add accrue_admin/priv/static/accrue_admin.css   # the served, committed bundle (77KB today)
```
- **Committed served file:** `accrue_admin/priv/static/accrue_admin.css` (the JS bundle `accrue_admin.js` is NOT touched this phase — D-04 leaves `command_palette.js` alone, so no `app.js` change is expected).
- **`ax-*` token/class files involved:**
  - `accrue_admin/assets/css/app.css` (4068 lines) — the source. Relevant regions: `.ax-kpi-grid` (L519, L2602), `.ax-kpi-grid-4` (L3402), KPI card classes (`.ax-kpi-card`, `.ax-kpi-value`, `.ax-kpi-delta` — via `KpiCard`), `.ax-attention*` (L3228–3327), `.ax-empty*` (L3330–3336 — the D-06 target), `.ax-display`/`.ax-heading` (L628–643), `.ax-home-section` (L3188).
  - `accrue_admin/assets/css/theme.css` — token SSOT (`--ax-type-*`, `--ax-space-*`, `--ax-muted`, status/money tokens). Per UI-SPEC, the demotion uses *existing* tokens; **introduce no new tokens** (CONTEXT guardrail).
- **The footgun (verified against MEMORY + 193 D-15):** editing `app.css` ships nothing until rebuilt + committed. Phase 189 shipped dead CSS this way. The 194 plan must make the rebuild+commit an explicit, verifiable task step (e.g., assert `git diff --stat` includes `priv/static/accrue_admin.css` whenever `app.css` changed).
- **Note on "no Tailwind":** the build *uses the tailwind CLI as a CSS minifier/processor*, which is consistent with the CLAUDE.md rule "Tailwind utilities are not an authoring path" — the authoring path is the `ax-*` classes in `app.css`; tailwind just processes/minifies. Do not author with Tailwind utility classes.

### Q5 — The two target LiveViews

Fully mapped above ("The Two Target LiveViews"). Confirmed:
- Dashboard zone source order is already attention < task < kpi < recent (markers only, no move).
- Dashboard ⌘K button at L100–106 already has `data-command-palette-trigger="true"` and the "⌘K" placeholder (L108) — add the sibling `data-ax-command-palette-trigger`. **Do NOT rename** (D-04).
- Recovery render order today: hero KPI pairs (L121–143) → `FunnelChart` (L145–150) → `AtRiskTable` (L152). The swap moves the table above the funnel.

## Runtime State Inventory

> Not a rename/refactor/migration phase. This is a UI conformance + CSS phase. No stored data, live-service config, OS-registered state, secrets, or build artifacts carry phase-specific runtime state.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB keys/collections involve dashboard markers or CSS classes. | none |
| Live service config | None. | none |
| OS-registered state | None. | none |
| Secrets/env vars | None. | none |
| Build artifacts | `accrue_admin/priv/static/accrue_admin.css` is a committed build artifact that MUST be regenerated after any `app.css` edit. | run `mix accrue_admin.assets.build` + commit (Pitfall 1) |

## Project Constraints (from CLAUDE.md)

- **No Tailwind utilities as an authoring path** — custom `ax-*` CSS + tokens are SSOT. (The tailwind CLI is used only as a minifier in the build.)
- **Elixir 1.17+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.1+** — already the runtime; no version work.
- **GSD workflow enforcement** — file edits go through GSD commands; this phase is `/gsd-execute-phase` territory.
- **`accrue_admin` is the admin UI sibling package** — all edits stay inside `accrue_admin/` (LiveViews, CSS) plus the repo-root `scripts/ci/verify_package_docs.sh` and the `accrue/test/.../package_docs_verifier_test.exs` mirror.
- **Centralized copy** — all strings via `AccrueAdmin.Copy` (never inline LiveView strings); empty-state copy is *elevated*, not rewritten (D-06; existing `home_attention_empty_title` / `home_attention_empty_copy` are kept).

## Validation Architecture

> `nyquist_validation: true` in `.planning/config.json` — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Playwright (`@playwright/test`) for e2e page-flow; ExUnit for the `verify_package_docs.sh` mirror; bash for the source guard |
| Config file | `accrue_admin/playwright.config.js` (existing); page-flow helpers `accrue_admin/e2e/phase191-page-flow-helpers.js` |
| Quick run command | `cd accrue_admin && npx playwright test e2e/<new-spec-overview>.spec.js --workers=1` |
| Full suite command | `cd accrue_admin && npm run e2e:phase191` + `bash scripts/ci/verify_package_docs.sh` + `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |

### Phase Requirements → Test Map
| Req / Criterion | Behavior | Test Type | Automated Command | File Exists? |
|-----------------|----------|-----------|-------------------|-------------|
| SC1 / EXE-01 | Dashboard renders four-zone grammar; one `<h1>`; ⌘K visible+focusable; zone DOM order; non-interactive empty hero | page-flow (machine) | `npx playwright test e2e/<new>.spec.js` | ❌ Wave 0 (new spec) |
| SC1 (empty-rail) | `.ax-attention-rail--empty` has no `cursor:pointer` | source guard (machine) | `bash scripts/ci/verify_package_docs.sh` | ✅ host exists; ❌ needle is new |
| SC1 (empty-rail mirror) | guard fails when violated | unit (ExUnit) | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ host exists; ❌ negative test is new |
| SC2 / EXE-01 | Recovery: at-risk table renders above funnel (no chart before work-queue) | page-flow (machine, DOM-order) | `npx playwright test e2e/<new>.spec.js` | ❌ Wave 0 (new assertion) |
| SC1/SC2 (judge cells) | exceptions higher-signal than KPIs; KPIs demoted-not-deleted; Recovery as work-queue not chart wall | judge-graded rubric (12-dim, `187-RUBRIC.md`) | scored into `p193__dashboard__*` / `p193__recovery__*` cells | ✅ cells exist (pending) |
| SC3 | ≥ baseline cells, zero regressions | scorecard (machine) | `phase192-scorecard.mjs` `score-downgrade` check → `regressions.ndjson` | ✅ exists |

### Sampling Rate
- **Per task commit:** the new page-flow spec for the touched surface + `bash scripts/ci/verify_package_docs.sh`.
- **Per wave merge:** full `npm run e2e:phase191` + the `package_docs_verifier_test.exs` mirror + a fresh `mix accrue_admin.assets.build` diff check.
- **Phase gate:** zero `score-downgrade` rows in `regressions.ndjson` for dashboard + recovery; rubric cells ≥ baseline before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `accrue_admin/e2e/<new>-spec-overview.spec.js` — the SPEC-OVERVIEW invariant assertions (covers SC1, SC2 machine parts). Reuses `phase191-page-flow-helpers.js`; no new helper library needed.
- [ ] New `require_regex` empty-rail guard in `scripts/ci/verify_package_docs.sh` (covers SC1 source-guard).
- [ ] New negative test in `accrue/test/accrue/docs/package_docs_verifier_test.exs` mirroring the guard (D-08 coupling).
- [ ] `.ax-attention-rail--empty` class in `app.css` + rebuilt `priv/static/accrue_admin.css`.

## Security Domain

> `security_enforcement` is not set to `false` (config has `nyquist_validation: true`; no security_enforcement key found). This phase introduces no auth, no data flow, no new endpoints — it is read/route-only UI conformance.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged — admin auth is host-owned |
| V3 Session Management | no | unchanged |
| V4 Access Control | no | dashboard/recovery are read/route-only; no new actions |
| V5 Input Validation | no | no new inputs; the source guard reads `app.css` as untrusted input via fixed grep/perl patterns only (no code execution) |
| V6 Cryptography | no | n/a |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| New marker attribute leaks data | Information Disclosure | `data-ax-zone` / `data-ax-command-palette-trigger` carry static enum values only — no PII, no IDs |
| Source guard parses attacker-controlled CSS | Tampering | Guard uses fixed grep/perl patterns; no eval of file content (same posture as 193 CSS guards) |
| Destructive actions | Elevation | None introduced this phase (UI-SPEC: "Dashboard + Recovery are read/route-only") |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The empty-rail source guard should target the new class name `.ax-attention-rail--empty` (the literal string SPEC-OVERVIEW uses) rather than the current `.ax-empty`. | Q2 | If the executor keeps `.ax-empty` instead of adding `.ax-attention-rail--empty`, the SPEC-OVERVIEW-named guard would have nothing to bind to. The class name should match the spec; verify with the planner. |
| A2 | Phase 194 scores only the `dashboard` + `recovery` page-flow surfaces; the other 19 surfaces remain `pending` for later phases (198+). | Q3 | If the gate requires *all* page-flow cells scored before merge, scope expands. Mitigated: 193-02 explicitly says "Phase 200 will score them" — 194 only owns its two exemplar surfaces. |
| A3 | The JS bundle (`accrue_admin.js`) does not need rebuilding because no `app.js`/`command_palette.js` change occurs (D-04). | Q4 | If any JS marker requires a hook change, the JS bundle would also need rebuild+commit. D-04 forbids touching the JS hook, so this holds. |
| A4 | The scorecard maps `p193__<surface>__...` page-flow cells to their `p187__<surface>__...` baseline counterparts by matching surface/mode/theme/state/dimension. | Q3 / Open Q-B | If the prefix mismatch means page-flow cells have no baseline counterpart, the `score-downgrade` check is a no-op and SC3 is unverifiable. Confirm the scorecard's baseline-lookup keying before relying on it. |

## Open Questions (RESOLVED)

1. **Q-A: Recovery zone-marker mapping.**
   - What we know: Recovery has no exception/attention rail; its leading zone is the hero metric pair. The load-bearing machine check is at-risk-table-before-funnel (D-01).
   - What's unclear: whether to apply the full `data-ax-zone="attention-rail|task-launcher|kpi-cluster|recent-activity"` enum to Recovery or only the markers the assertion needs.
   - Recommendation: mark the hero pair `<section>` and the at-risk table; assert table-index < funnel-index. Don't force an `attention-rail` marker onto a page with no rail. Let the planner decide the exact enum mapping (it is explicit CONTEXT discretion).
   - **RESOLVED:** delegated to discretion; implemented in 194-02 (Task 2) — the hero metric pair is marked `data-ax-zone="kpi-cluster"` and the promoted at-risk table is wrapped `data-ax-zone="task-launcher"`; no `attention-rail` marker is forced onto Recovery.

2. **Q-B: `p193`↔`p187` baseline lookup in the scorecard.**
   - What we know: page-flow cells are `p193__`-prefixed; the v1.53 baseline is `p187__`. The scorecard union-loads both and runs a `score-downgrade` check.
   - What's unclear: the exact keying the scorecard uses to pair a `p193` cell with its `p187` baseline (prefix-stripped surface/mode/theme/state/dimension tuple, presumably).
   - Recommendation: the planner should read `phase192-scorecard.mjs` baseline-lookup (around L401, L457) to confirm the pairing before writing the SC3 verification step. Not a blocker for implementation, only for the gate assertion wording.
   - **RESOLVED:** carried as 194-04 Task 1 (an explicit early scorecard-inspection step that confirms the `contractedCell` / `compareCells` keying before the SC3 gate wording is finalized); resolution recorded in the 194-04 summary.

## Sources

### Primary (HIGH confidence — read in this session)
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` (L39–234) — zone structure, ⌘K button, empty card.
- `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` (L90–156) — funnel/table render order.
- `accrue_admin/guides/spec-overview.md` — the locked invariant table + verification mechanisms.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` — assertion API (`assertFocusWithin`, `assertTopPointerTarget`, etc.).
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` — confirms SPEC-OVERVIEW invariants are NOT yet asserted.
- `accrue_admin/e2e/baseline-manifest.js` — cell ID grammar, 21 page-flow surfaces, dimension/state/project taxonomy.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.page-flow.cells.json` — 9072 `p193__` cells; 432 dashboard + 432 recovery, all `pending`.
- `scripts/ci/verify_package_docs.sh` (L23–57 helpers, L552–599 RES-04/spec guards) — guard hosts, no empty-rail guard yet.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — exact build pipeline.
- `accrue_admin/assets/css/app.css` (L3228–3336 attention/empty, L519/2602/3402 kpi-grid) — `.ax-attention-rail--empty` does NOT exist; `.ax-empty` documented non-interactive.
- `.planning/phases/193-research-re-baseline-pattern-lock/193-02-SUMMARY.md` + `193-05-SUMMARY.md` — cell generation + CSS guards + D-08 mirror pattern.
- `accrue_admin/e2e/phase192-scorecard.mjs` — `score-downgrade` regression check, page-flow lens union-load.
- `.planning/REQUIREMENTS.md` (L57, L103) — EXE-01.
- `.planning/config.json` — `nyquist_validation: true`.
- `194-CONTEXT.md`, `194-UI-SPEC.md` — locked decisions D-01..D-06, design contract.

### Secondary
- MEMORY notes: `accrue_admin CSS bundle rebuild` (dead-CSS footgun), `verify_package_docs ↔ test coupling` (D-08), `v1.54 Admin Page-Level Streamlining` milestone framing.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all tooling verified in-repo.
- Architecture / gate-machinery delta: HIGH — every invariant's wiring state verified against the actual files (markers/classes/guards confirmed absent; helpers confirmed present).
- Cell scoring (SC3 keying): MEDIUM — page-flow cells confirmed present and pending, but the exact `p193`↔`p187` baseline pairing in the scorecard is flagged as Open Q-B for the planner to confirm.
- Pitfalls: HIGH — corroborated by 193 summaries + MEMORY.

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable — internal codebase, no external moving parts). Re-verify only if `baseline.page-flow.cells.json`, `verify_package_docs.sh`, or the two LiveViews change before planning.
