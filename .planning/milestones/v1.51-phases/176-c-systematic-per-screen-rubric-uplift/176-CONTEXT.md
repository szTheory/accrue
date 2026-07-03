# Phase 176: C — Systematic Per-Screen Rubric Uplift - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Bring every admin screen up to one consistent rubric baseline (≥2 on all 10 dimensions in both light & dark, at desktop & mobile @360px), eliminating the uneven depth left after v1.50. Enumerate the touchpoint matrix, capture baseline scores, and lift the under-iterated tail worst-first (payments/charges, coupons, promotion-codes, connect, events, webhooks, invoice detail, + the new EventLive). Apply mobile-first responsive layout on the Phase 174 breakpoint tokens and a reading-measure max-width container on dense prose regions. **This is the heavy phase — wave-split per screen-group.** No new IA/nav changes (Phase 175 shipped those), no motion (Phase 177), no seed/state work (Phase 178), no screenshot QA sign-off (Phase 179 — this phase does code-level scoring; the photographic proof is F). Satisfies SCR-01, SCR-02, SCR-03, SCR-04.

</domain>

<decisions>
## Implementation Decisions

Three areas proposed as a synthesized package grounded in the locked design source (`v1.51-admin-ui-depth-design.md` §4 Phase C + §6 rubric) and a codebase scout, accepted as-is by the user (calibration: `minimal_decisive`). Key scout findings that shaped the package: the prior baseline lives at `.planning/research/v1.51-admin-ux-baseline-audit.md`; the `data_table` component **already supports mobile card-collapse** (`card_fields`/`card_title`/`ax-data-table-cards`); Phase 174's `--ax-bp-*` breakpoint tokens are already in use in app.css; and `.ax-measure` (68ch) exists as a utility but is **applied to no screen yet**.

### Scope, screen inventory & wave-split (SCR-01, SCR-03)
- **Scope:** ALL ~20 admin screens must score ≥2 on every dimension, but *effort* concentrates on the under-iterated tail (payments/charges, coupons, promotion-codes, connect, events, webhooks, invoice detail, + the new `/events/:id` EventLive). Frozen screens (Home, primary nav, global search) and the v1.50-heavily-iterated screens (Customer-360, dashboard) are touched **only on a rubric-flagged miss** (anti-churn).
- **Wave-split = by screen-group:** Wave 1 = list screens; Wave 2 = catalog/specialist detail (coupon, promotion_code, connect, event, webhook); Wave 3 = dense financial detail (invoice, payment/charge, subscription) + reading-measure application. (Planner may refine grouping for parallelism.)
- **Baseline-scoring method:** a per-screen × 10-dimension **SCORECARD.md** in the phase dir, captured by **code-level audit**, recording before + after scores per screen. Screenshot-based scoring is deferred to Phase 179 — this phase produces the documented before/after deltas required by SCR-03.
- **Ordering:** **worst-first** — score baseline, lift the lowest-scoring screens first, stop when all dimensions are ≥2.

### Mobile-first & responsive mechanics (SCR-02, SCR-04)
- **List screens:** reuse the `data_table` component's **existing card-collapse** (`card_fields`/`card_title`); audit which list screens don't set those attrs and add them so tables collapse to cards below `--ax-bp-md`. Do NOT build a new mobile layout.
- **Detail screens:** stack multi-column detail layouts to a single column below `--ax-bp-md` using existing `ax-*` grid utilities + the Phase 174 breakpoint tokens; verify tap targets and overflow are usable @360px.
- **600/640 breakpoint reconciliation:** Phase 174 (D-05) deferred reconciling the `600px`/`640px` proximity to this phase's mobile-first rewrite — **reconcile now**: collapse to a single content step OR document explicitly why both remain.
- **@360px verification:** add structural assertions where cheap (no horizontal scroll, card layout active at mobile width); the full *visual* @360 proof is Phase 179.

### Reading-measure & token-compliance (SCR-04, rubric dim ①)
- **`.ax-measure` targets:** dense prose / long-form regions only — settings/empty-state descriptions, event/webhook JSON payload viewers, invoice/charge detail prose, metadata viewers. NOT data tables or KPI grids (they stay full-width).
- **Application level:** **region-level** (wrap the prose/description block), never whole-page.
- **Token-compliance during uplift:** while in each screen, eliminate any residual literal hex/px by resolving to `ax-*` tokens — this folds rubric dimension ① (token compliance) into the uplift rather than a separate pass.
- **Before/after evidence:** the per-screen **SCORECARD.md** table (10 dims × before/after) committed in the phase dir, feeding Phase 179's sign-off.

### Claude's Discretion
- Exact per-screen scores in the baseline audit, the precise worst-first ordering, and which specific screens turn out to need work are the planner/executor's call from the actual code state.
- Exact responsive grid/stacking CSS (must resolve from `ax-*` tokens + 174 breakpoints; no literals).
- Whether the 600/640 reconciliation collapses or documents — decide from the actual usage sites.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`.planning/research/v1.51-admin-ux-baseline-audit.md`** — the prior (v1.50-era) baseline; the rubric to score against. Read first when capturing the new baseline.
- **`data_table` component** (`components/data_table.ex`) — already renders a mobile card list (`ax-data-table-cards`, `card_fields`, `card_title`, `ax-data-table-card`) below the table; list-screen mobile-first is mostly an audit-and-wire task, not new construction.
- **Phase 174 tokens** — `--ax-bp-sm/md/lg/content` breakpoint tokens (in use, 15 refs in app.css), `--ax-leading-*`/`--ax-tracking-*` type micro-tokens, `--ax-measure` (68ch) + `.ax-measure` utility (defined, unused), `--ax-transition-*` bundles.
- **10-dimension rubric** (design source §6): ① token compliance ② visual hierarchy ③ spacing rhythm ④ state coverage ⑤ responsive/mobile-first ⑥ contrast ⑦ focus & semantics ⑧ brand expression ⑨ motion ⑩ reuse/DRY. Pass at ≥2.

### Established Patterns
- Custom `ax-*` BEM-adjacent CSS + tokens; Tailwind inert — NO migration. All responsive CSS resolves from `ax-*` tokens + `--ax-bp-*` breakpoints (no literal px in `@media`, per 174's grep-guard).
- Committed asset bundle — run `cd accrue_admin && mix accrue_admin.assets.build` and commit `priv/static` after any CSS edit.
- `data_table` URL-synced filters + the Phase 175 work-queue defaults are in place; uplift must not regress them.

### Integration Points
- Screen LiveViews in `accrue_admin/lib/accrue_admin/live/*_live.ex` + shared components (`detail_drawer`, `detail_section`, `data_table`, `related_resources`). Reading-measure wraps prose regions inside these.
- The SCORECARD.md (new, phase dir) is the before/after evidence artifact consumed by Phase 179.

</code_context>

<specifics>
## Specific Ideas

- **Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md` — §4 Phase C scope (lines 100–104), §6 rubric + verification commands (`npm run e2e:visuals:png-only`, `admin-a11y.spec.js`), §7 guardrails. Downstream agents MUST read it.
- **Anti-churn justification token** required per change: (a) a rubric dimension below bar w/ a before-score, (b) a named persona-job miss, or (c) a token bypass eliminated. The SCORECARD before-score IS the primary justification for dimension-driven changes.
- **Verification:** `cd accrue_admin && mix accrue_admin.assets.build`; `cd accrue_admin && mix test --seed 0` (suite currently 227 green — do not regress); `npm run e2e:visuals:png-only` for spot checks (full sweep is Phase 179). Admin mounts at `/billing`.
- **No breaking changes:** component public APIs stay backward-compatible; extend v1.50/v1.75 shared components, don't replace.

</specifics>

<deferred>
## Deferred Ideas

- **Motion / micro-interactions** on the uplifted screens → Phase 177 (D).
- **Seed/state expressiveness** so every empty/overflow/error/loading state is reachable → Phase 178 (E).
- **Screenshot-driven visual QA sign-off** (the photographic proof of ≥2 across all four matrix cells, axe in both themes) → Phase 179 (F). This phase does code-level scoring + structural mobile assertions only.

*Discussion stayed within phase scope — no IA/nav changes, no motion, no seed work.*

</deferred>

---

*Phase: 176-c-systematic-per-screen-rubric-uplift*
*Context gathered: 2026-06-04*
