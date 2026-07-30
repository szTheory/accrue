# Phase 211: Grep-gated CSS retirement & cross-surface cleanup - Research

**Researched:** 2026-07-19 (original) — **Refreshed:** 2026-07-28
**Domain:** CSS dead-code retirement in a Phoenix/LiveView admin package (grep-based liveness census, Tailwind bundle rebuild, dev-tooling secondary-surface cleanup)
**Confidence:** HIGH (every finding below is `[VERIFIED: codebase grep/read]` against the actual repository state on 2026-07-28, re-run from scratch and cross-checked against the 2026-07-19 census — see `## Refresh Delta` immediately below for what changed and what didn't)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REIGN-04 | Retire bespoke `.ax-home-*`/`.ax-launcher*`/`.ax-attention*`/`.ax-subscriptions-*`/`.ax-inline-worklist*`/`.ax-subscription-row-*` CSS (grep-gated — ONLY zero-reference classes; classes still used by `subscription_live.ex` preserved), rebuild the committed bundle, migrate test/e2e selectors in the same phase | Full class-by-class census below (`## Class Census`) is the direct implementation input; `## Bundle Rebuild` gives exact commands; `## Test/E2E Migration Surface` proves zero migrations are actually needed (already done in 209/210) |

No CONTEXT.md exists for this phase (re-confirmed 2026-07-28 — directory still has no `*-CONTEXT.md` file). The ROADMAP.md Phase 211 entry and REQUIREMENTS.md REIGN-04 text are unchanged since 2026-07-19 (re-read and re-confirmed verbatim this session) and remain the binding scope definition.
</phase_requirements>

## Summary

The safe-retirement approach is unchanged from the original research: (1) run an exact-token grep census (not substring matching — see Pitfall 1) across `lib/`, `test/`, `e2e/` for every selector actually defined under the eight named `.ax-*` prefix families in `assets/css/app.css`; (2) delete only the rule blocks/branches whose selector has zero references anywhere in the three trees, being careful with comma-separated and compound selectors that mix a dead class with a still-live one; (3) rebuild `priv/static/accrue_admin.css`/`.js` via `mix accrue_admin.assets.build` and manually recompose `priv/static/storybook.css` (still no dedicated rebuild task); (4) confirm the component kitchen needs **no markup changes** and only `region-tags.js` needs a one-line selector fix; (5) confirm via project-wide grep — not assumption — that **zero test/e2e assertions reference any of the 92 dead classes**, because Phases 209 and 210 already migrated their own selectors.

**This refresh re-ran the entire census from scratch against the current repository state (post `9147ea02` FND-01 annotation commit + the 4 subsequent CI-remediation commits) and confirms the class-by-class verdict set is byte-for-byte identical to 2026-07-19: 92 dead, 16 preserve, same names.** The only material change is `app.css` line-number drift (file grew 8091 → 8326 lines, +235) because none of the intervening commits touched any of the 8 candidate families or the two shared PRESERVE classes — they annotated type declarations and fixed unrelated detail-page/page-shell/data-table responsive bugs. See `## Refresh Delta` for the full accounting, including a **new, more exhaustive Pitfall-2 finding** (9 comma-branch "mixed dead/live" rule sites were located this session vs. 1 example in the original research — all pre-existing, not introduced by the recent commits, just more thoroughly enumerated this pass).

**Primary recommendation: unchanged.** Delete the 92 zero-reference selectors (grouped below, at the *current* line numbers), preserve the 16 live ones verbatim, rebuild both `accrue_admin.css`/`.js` and `storybook.css`, fix the single dangling `region-tags.js` selector, and treat "test/e2e migration" as a verification step (grep confirms clean), not an editing step. **The 4 existing plans (211-01 through 211-04) do not need their editing instructions or task scope re-derived — the census and every technical conclusion they depend on is unchanged. Only their in-body `app.css` line-number anchors (e.g. "currently around lines 5570-5840") are stale; each plan already instructs the executor to re-read the live file before editing, so this is a low-risk staleness, not a blocking one.**

## Refresh Delta (vs 2026-07-19)

**Bottom line: the census is materially UNCHANGED. Only line numbers moved.** Read this section first if deciding whether the 4 existing plans can execute as-is.

| Item | 2026-07-19 finding | 2026-07-28 re-verification | Verdict |
|------|--------------------|-----------------------------|---------|
| Total candidate classes | 108 unique selector names across 8 families | 108 — identical list, re-extracted independently from current `app.css` | **UNCHANGED** |
| Dead count | 92 | 92 — same 92 class names, re-grepped exact-token against current `lib/`, `test/`, `e2e/` | **UNCHANGED** |
| Preserve count | 16 | 16 — same 16 class names, same referencing files | **UNCHANGED** |
| `.ax-subscription-setup-gap` landmine | PRESERVE (rendered by `subscriptions_live.ex:418`) | Still PRESERVE, still `subscriptions_live.ex:418` — **exact same line number**, `.ex` file untouched since 07-19 | **UNCHANGED** |
| `.ax-inline-worklist`/`-copy`/`-actions` | PRESERVE, shared with `subscription_live.ex:304-305` + `component_kitchen_live.ex` (×4) | Still PRESERVE, still `subscription_live.ex:304-305` (exact same lines) + `component_kitchen_live.ex` ×4 each (lines 141/159/183/200, 142/160/184/201, 149/173/193/207) | **UNCHANGED** |
| `.ax-audit-summary-row` | PRESERVE, 4 call sites (`dashboard_live.ex:311`, `subscription_live.ex:480`, `component_kitchen_live.ex` ×2) | Still PRESERVE, still `dashboard_live.ex:311` + `subscription_live.ex:480` (exact same lines) + kitchen at 220/974 | **UNCHANGED** |
| Phase-210 kept structural wrappers (`ax-launchers`, `ax-launchers-tri`, `ax-home-launcher-*`) | PRESERVE, `dashboard_live.ex:179`/`×3` | Still PRESERVE, still `dashboard_live.ex:179` (exact same line); in-CSS Phase 210 comment block still byte-identical | **UNCHANGED** |
| Adjacent findings (5 dead orphan rules outside the 8 families) | `.ax-page-header-compact`/`.ax-page-actions`/`.ax-dashboard-title-row` nested under `.ax-home`, all dead | Re-verified all 5 still zero-referenced; still caused by the same Phase 210 PageHeader migration | **UNCHANGED** (new line numbers below) |
| `app.css` total lines | 8091 | 8326 (**+235**) | Grew — `9147ea02` added 168 `ax-type-exception` comment annotations; `3d82e406`/`b79e89e4`/`1dce1262`/`bed032ff`/`55bb57b7` added new detail-page/page-shell/data-table rules (`.ax-page` grid-template-columns, `.ax-detail-health-summary` box-sizing, `.ax-detail-priority-links`, scoped `.ax-link-quiet`, a `@media (max-width: 599.98px)` block for `.ax-data-table-filter*`/`.ax-segmented`) — **none of these touch any of the 8 candidate families or the 2 shared-with-detail-page classes** |
| `ax-home-*` block (search/health remnants) | ~5611-5781 | **5639-5941** (shift +~28 to +160 depending on position in block) | Line numbers moved; contents/verdicts unchanged |
| `ax-launcher*` block | ~6083-6274 | **6230-6417** main block (+ small mixed-selector fragments at 7935-7954, 8009-8019 — see new Pitfall 2 table) | Line numbers moved; contents/verdicts unchanged |
| `ax-attention*`/`ax-health-summary*` blocks | ~2986-6045 | **`ax-health-summary` 3030-3176; `ax-attention` main 5974-6191**; two small mixed-selector fragments at 6096-6097, 6126-6127; plus a distant utility-rule fragment at 8057-8077 (see new Pitfall 2 table) | Line numbers moved; contents/verdicts unchanged |
| `ax-subscriptions-*`/`ax-subscription-row-*`/`ax-subscription-setup-gap` block | ~1086-4429 | **Main dense block 2909-4693**; the `:has()` mixed-selector rule (Pitfall 2's original example) now appears **twice**: 1090-1094 (unconditional) and 6439-6443 (duplicated inside `@media (min-width: 1024px)`); one stray duplicate `.ax-subscription-row-webhook-action` rule at 7348 | Line numbers moved; contents/verdicts unchanged; **the duplicated `:has()` rule at two locations is a re-confirmation, not new — both copies must have their dead branch removed** |
| Component kitchen (`component_kitchen_live.ex`) | Zero dead-vocab references; renders the 2 shared PRESERVE families only | Re-verified zero dead-vocab references. **File WAS touched** by `b79e89e4` (07-27, restores a `DetailDrawer.detail_drawer` wrapper around the drawer specimen) but that edit only touches `ax-dev-group-drawer-*`/`ax-detail-drawer-*` classes, entirely outside the 8 candidate families and outside the 2 shared-with-detail-page classes | **UNCHANGED conclusion**; file line count 1894→1892 (net -2, irrelevant to this phase) |
| Storybook (`priv/static/storybook.css`) | Composed of PSB CSS + `accrue_admin.css` (stale, pre-retirement) + dark-mode shim tail; needs rebuild after retirement | **File WAS touched** by `74a4c0be` (07-27) — but only the *dark-mode shim tail's* 3 token values were edited (verbatim-mirroring theme.css dark tokens), not the PSB-CSS or embedded-`accrue_admin.css` sections. Structure (3-part composition, `D-17 Spike B` marker) is byte-identical; still embeds a stale (pre-retirement) `accrue_admin.css`; still needs the same rebuild recipe | **UNCHANGED conclusion** — recipe in `## Bundle Rebuild` needs zero changes |
| `region-tags.js` dangling `attention-rail` selector | Line 91, `"ax-attention-rail"`, dangling | File untouched since 2026-07-03 (pre-dates old research); still line 91, still `"ax-attention-rail"`, still dangling | **UNCHANGED, same line number** |
| Test/e2e migration surface (3 hits, 0 needing migration) | `dashboard_live_test.exs:125` (data-attr, fine), `admin-spec-overview-phase194.spec.js:96` (PRESERVE class, fine), `region-tags.js:91` (the one real fix) | Re-ran the identical project-wide grep against current `test/` + `e2e/`: **exactly the same 3 hits, same line numbers, same verdicts** | **UNCHANGED** |
| Bundle-rebuild mechanics (mix task, storybook recipe) | `mix accrue_admin.assets.build` (tailwindcss@3.4.17 + esbuild@0.25.3, unchanged since 2026-06-15) | Confirmed the task file itself hasn't been touched since 2026-06-15 (pre-dates old research) | **UNCHANGED** |
| Committed `accrue_admin.css` bundle freshness (pre-existing state, informational) | N/A (not checked in original research) | **New finding this session:** the currently-committed `priv/static/accrue_admin.css` bundle IS already rebuilt-and-in-sync with the current `app.css` source (confirmed the CI-remediation `.ax-page{grid-template-columns:minmax(0,1fr)...}` and `.ax-detail-health-summary{...box-sizing:border-box...}` rules are present in the minified bundle) — the pre-Phase-211 baseline bundle is clean, so Plan 02's rebuild diff will cleanly reflect only the CSS deletions | Informational addition, no plan impact |
| Orphan/dangling guard script | Does not exist; no CI/script precedent | Re-surveyed `scripts/ci/*` and `accrue_admin/e2e/*.mjs` — still does not exist; no new script added by any of the 6 intervening commits | **UNCHANGED** |
| Environment tooling versions | Node v22.14.0, npx 11.1.0, Elixir 1.19.5/OTP 28, Playwright 1.59.1, ripgrep present | Node v22.14.0 (same), npx 11.1.0 (same), Elixir 1.19.5/OTP 28 (same), **Playwright 1.62.0** (bumped from 1.59.1), ripgrep present (same) | **Playwright version bumped only** (minor patch drift, no config/API impact expected) |

**New addition this session (not a "change" in verdict, a deeper pass over the same unchanged facts):** the original research's Pitfall 2 cited exactly one example of a comma-separated selector list mixing a dead class with live branches. This refresh ran a systematic scan for *every* such mixed-branch rule across all 92 dead classes and found **9 distinct comma-groups** (7 distinct rule locations, since the `:has()` rule is duplicated at two locations in the file) requiring branch-level (not block-level) deletion. All 9 are pre-existing (confirmed via `git blame` — the oldest dates to 2026-06-15/06-18/06-26, well before the 07-19 research), so this is a completeness improvement, not a regression. Full list is in the updated `## Common Pitfalls` → Pitfall 2 section.

**Conclusion for the orchestrator:** the 4 existing plans (211-01 Wave-0 orphan-guard baseline, 211-02 deletion, 211-03 storybook recompose, 211-04 region-tags fix + full-suite verification) can proceed **as planned, without re-planning**. The only recommended action is to have the Plan 02 executor consult this refreshed research's current line numbers (and the expanded Pitfall 2 table) rather than the plan's own inline stale ranges — the plans already instruct "read these ranges directly before editing" as a safety net, so this is advisory, not blocking.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS rule retirement (source) | Frontend Server (SSR component library) | — | `assets/css/app.css` is the Tailwind-processed source-of-truth for the `accrue_admin` LiveView package; it has no browser-tier or API-tier component. |
| Served CSS bundle | Frontend Server (SSR component library) | CDN/Static (served as an immutable, hashed, cache-control:max-age=31536000 asset via `AccrueAdmin.Assets` plug) | `priv/static/accrue_admin.css` is compiled at "build time" (a mix task, not deploy-time) and then served as a static, hash-named, browser-cacheable artifact — a hybrid of Frontend-Server-owned source and CDN-style immutable delivery. |
| Dev-only component kitchen / Storybook | Frontend Server (dev/test-only LiveView routes, `if Mix.env() != :prod`) | — | Never reachable in prod (`Code.ensure_loaded?` + env guards); purely a design/QA surface, no runtime/API tier involvement. |
| Ratchet `region-tags.js` selector map | Frontend Server (dev/test tooling, Node.js, off the deploy path) | — | Pure identity/selector-mapping metadata for the parked, maintainer-run v1.56 ratchet; never executes in the shipped admin app. |
| Test/e2e selector assertions | Frontend Server (LiveView unit tests) + Browser (Playwright e2e) | — | Split naturally between ExUnit/Floki (server-rendered HTML assertions) and Playwright (real browser DOM/CSS assertions). |

## Class Census

Methodology (unchanged from 2026-07-19, re-executed from scratch this session): for each of the 108 unique `.ax-*` class-selector names actually defined in `accrue_admin/assets/css/app.css` under the eight candidate prefixes (`ax-home-`, `ax-launcher`, `ax-attention`, `ax-health-summary`, `ax-subscriptions-`, `ax-subscription-row-`, `ax-subscription-setup`, plus the shared `ax-inline-worklist`/`ax-audit-summary-row`), an **exact-token** search was run with `rg -lP "(?<![\w-])CLASSNAME(?![\w-])"` across `accrue_admin/lib/`, `accrue_admin/test/`, `accrue_admin/e2e/`. This lookbehind/lookahead pattern excludes both partial-word matches (e.g. `ax-launcher` inside `ax-launchers`) and data-attribute false positives (e.g. `ax-launcher-primary` inside `data-ax-launcher-primary`) — see `## Common Pitfalls` Pitfall 1 for why a naive substring grep gives the wrong answer for 3 classes. **Result: 16 LIVE, 92 DEAD — identical to the 2026-07-19 verdicts, re-verified independently against the current repo state (post `9147ea02` + 4 CI-remediation commits).**

### PRESERVE (16 classes — live, do not delete)

| Class | Referenced by (current line numbers) | Reason |
|-------|---------------|--------|
| `ax-home` | `lib/accrue_admin/live/dashboard_live.ex:64` | Root section wrapper (`class="ax-page ax-home"`) — kept as Home's page-scope hook for the `.ax-home > .ax-page-header` etc. override rules (see Adjacent Findings below). |
| `ax-home-section` | `dashboard_live.ex` (×3, zone wrappers, e.g. line 137) | Kept as the generic zone-wrapper class for all 4 Home zones post-reign. |
| `ax-home-launcher-card` | `dashboard_live.ex` (×3, launcher tiles, line 180+) | Phase 210's **new** launcher tile primitive — explicitly documented in-CSS: "Tiles are now `.ax-card` primitives keyed off `data-ax-launcher-primary`; this layer does not touch any `.ax-launcher*` rule (Phase 211 retires those)." |
| `ax-home-launcher-icon` | `dashboard_live.ex` (×3) | Same Phase 210 launcher-tile primitive, icon slot. |
| `ax-home-launcher-action` | `dashboard_live.ex` (×3) | Same Phase 210 launcher-tile primitive, action-label slot. |
| `ax-launchers` | `dashboard_live.ex:179` (`class="ax-launchers ax-launchers-tri"`) | Grid wrapper for the 3-tile launcher grid — **not** the same class as the old bare `.ax-launcher` (singular) rule set, which is dead (see below). |
| `ax-launchers-tri` | `dashboard_live.ex:179` | 3-column grid modifier for the above. |
| `ax-attention` | `dashboard_live.ex:149` (`class="ax-card ax-attention"`) | Populated attention-rail wrapper. |
| `ax-attention-row` | `dashboard_live.ex:150` | Per-signal row inside the attention rail. |
| `ax-attention-text` | `dashboard_live.ex:156` | Text span inside each attention row. |
| `ax-attention-rail--empty` | `dashboard_live.ex:169` (EmptyState `class=`) + `e2e/admin-spec-overview-phase194.spec.js:96` (`.ax-attention-rail--empty` locator, the D-06 empty-rail gate) | Empty-state variant of the rail. Note this is the ONLY member of the `ax-attention*` family that is a compound/modifier name (`--empty`) rather than a hyphen-chain — do not confuse with the *bare* `ax-attention-rail` selector referenced by `region-tags.js`, which does not exist anywhere in the CSS (see `## Secondary Surfaces`). |
| `ax-subscription-setup-gap` | `lib/accrue_admin/live/subscriptions_live.ex:418` (`setup_gap_cell/2` helper, raw HTML span) | **Landmine.** Named inside the "ax-subscription-setup*" family the ROADMAP lists for retirement, but it is live — rendered by the Subscriptions LIST page's compact-cell idiom. Must be preserved. |
| `ax-inline-worklist` | `subscription_live.ex:304`, `component_kitchen_live.ex` (lines 141, 159, 183, 200) | Shared card-strip primitive; ROADMAP-documented as shared with the out-of-scope detail page. |
| `ax-inline-worklist-actions` | `component_kitchen_live.ex` (lines 149, 173, 193, 207) | Sibling of the above — only referenced by the kitchen today (not by `subscription_live.ex`), but still live. |
| `ax-inline-worklist-copy` | `subscription_live.ex:305`, `component_kitchen_live.ex` (lines 142, 160, 184, 201) | Sibling of the above; ROADMAP-named shared class. |
| `ax-audit-summary-row` | `dashboard_live.ex:311`, `subscription_live.ex:480`, `component_kitchen_live.ex` (lines 220, 974) | ROADMAP-named shared class; heaviest reuse of the 16 — 4 distinct call sites. |

**Every `.ex`-file line number in this table is byte-identical to the 2026-07-19 research.** None of `dashboard_live.ex`, `subscriptions_live.ex`, or `subscription_live.ex` have been touched by any commit since 07-19 in a way that shifts these lines (confirmed via targeted re-reads and re-greps this session).

### DELETE (92 classes — zero references, safe to remove)

**`ax-home-*` (12 dead of 17 total in family; current block: app.css lines 5639-5941):**
`ax-home-customer-search-cta`, `ax-home-customer-search-strip`, `ax-home-customer-search-strip-action`, `ax-home-header-health`, `ax-home-health-answer`, `ax-home-health-label`, `ax-home-health-metric`, `ax-home-health-metrics`, `ax-home-health-status`, `ax-home-primary-action`, `ax-home-search`, `ax-home-secondary-action`

(The CSS also nests descendant rules under the dead ancestors, e.g. `.ax-home-header-health .ax-status-badge`, `.ax-home-header-health strong`, `.ax-home-header-health span`, `.ax-home-health-metric strong, .ax-home-health-metric em` — these must be deleted too since their ancestor selector never matches.)

**`ax-launcher*` (bare/old family — 14 of 14 dead; this is the *entire* pre-Phase-210 launcher-tile rule set, explicitly flagged in-CSS as Phase 211's job; current main block: app.css lines 6230-6417, plus two small mixed-selector fragments at 7935-7954 and 8009-8019 — see Pitfall 2):**
`ax-launcher`, `ax-launcher-action`, `ax-launcher-action-button`, `ax-launcher-copy`, `ax-launcher-customer`, `ax-launcher-health`, `ax-launcher-icon`, `ax-launcher-meta`, `ax-launcher-meta-actions`, `ax-launcher-meta-warn`, `ax-launcher-primary`, `ax-launcher-recovery`, `ax-launcher-title`

(13 names listed above, plus the bare `ax-launcher` root itself = 14 dead selector names in the `ax-launcher` sub-family — `ax-launchers`/`ax-launchers-tri` are the separate, PRESERVE, plural grid-wrapper classes.)

**`ax-attention*` (15 of 19 total in family dead; current main block: app.css lines 5974-6191, plus mixed-selector fragments at 6096-6097, 6126-6127, and 8057-8077 — see Pitfall 2):**
`ax-attention-action`, `ax-attention-dot`, `ax-attention-dot-danger`, `ax-attention-dot-info`, `ax-attention-dot-warning`, `ax-attention-pill`, `ax-attention-pill-danger`, `ax-attention-pill-info`, `ax-attention-pill-warning`, `ax-attention-priority`, `ax-attention-priority-danger`, `ax-attention-priority-info`, `ax-attention-priority-warning`, `ax-attention-summary`, `ax-attention-summary-warning`

**`ax-health-summary*` (4 of 4 — entire family dead; current block: app.css lines 3030-3176; this was the pre-Phase-210 Home health-summary component, fully retired in markup already):**
`ax-health-summary`, `ax-health-summary-amber`, `ax-health-summary-moss`, `ax-health-summary-prominent`

**`ax-subscriptions-*` (31 of 31 — entire family dead; these are the five bespoke list bands Phase 209 already removed from markup; current main block: app.css lines 2909-4693; the `.ax-shell-content:has(> .ax-subscriptions-page)` mixed-selector branch additionally appears at lines 1090-1094 AND 6439-6443 — see Pitfall 2):**
`ax-subscriptions-at-risk-strip`, `ax-subscriptions-audit-strip`, `ax-subscriptions-customer-search-action`, `ax-subscriptions-customer-search-strip`, `ax-subscriptions-exposure`, `ax-subscriptions-header`, `ax-subscriptions-heading-metric`, `ax-subscriptions-heading-verdict`, `ax-subscriptions-health-hero`, `ax-subscriptions-health-line`, `ax-subscriptions-invoice-record`, `ax-subscriptions-invoice-record-empty`, `ax-subscriptions-invoice-record-list`, `ax-subscriptions-invoice-records`, `ax-subscriptions-invoice-strip`, `ax-subscriptions-invoice-strip-danger`, `ax-subscriptions-kpi-row`, `ax-subscriptions-page`, `ax-subscriptions-primary-action`, `ax-subscriptions-primary-workspace`, `ax-subscriptions-priority-actions`, `ax-subscriptions-priority-copy`, `ax-subscriptions-queue-shortcut`, `ax-subscriptions-route-line`, `ax-subscriptions-secondary-group`, `ax-subscriptions-secondary-group-primary`, `ax-subscriptions-secondary-link`, `ax-subscriptions-secondary-strips`, `ax-subscriptions-utility-strip`, `ax-subscriptions-webhook-strip`, `ax-subscriptions-webhook-workspace`

**`ax-subscription-row-*` (17 of 17 — entire family dead; the per-row bespoke cell markup Phase 209 replaced with the shared compact idiom; current block: app.css lines ~4144-4650 (interleaved with the subscriptions block above), plus a stray duplicate `.ax-subscription-row-webhook-action` rule at line 7348 — this second copy must ALSO be deleted):**
`ax-subscription-row-admin-chips`, `ax-subscription-row-audit`, `ax-subscription-row-audit-primary`, `ax-subscription-row-customer`, `ax-subscription-row-customer-scope`, `ax-subscription-row-id`, `ax-subscription-row-invoice-action`, `ax-subscription-row-invoice-controls`, `ax-subscription-row-invoice-primary`, `ax-subscription-row-invoices`, `ax-subscription-row-meta`, `ax-subscription-row-meta-grid`, `ax-subscription-row-primary-line`, `ax-subscription-row-signal-primary`, `ax-subscription-row-signal-secondary`, `ax-subscription-row-state`, `ax-subscription-row-webhook-action`

**`ax-subscription-setup*` (0 of 1 dead — the single member, `ax-subscription-setup-gap` at app.css lines 4518-4536, is PRESERVE; see above. Do not delete anything from this family.)**

### Rule-count vs. selector-count note

The 92 dead selector *names* above correspond to a considerably larger number of CSS *rule blocks* once media queries, pseudo-classes (`:hover`, `:focus-visible`), and multi-selector comma groups are counted — consistent with the ROADMAP's "~325 rules" figure. The planner/executor should still delete by **contiguous source region** per family where possible (the current regions are: `ax-launcher*` main block app.css 6230-6417; `ax-subscriptions-*`/`ax-subscription-row-*`/`ax-subscription-setup-gap` main block 2909-4693; `ax-attention*` main block 5974-6191; `ax-health-summary*` block 3030-3176; `ax-home-*` remnants block 5639-5941) but MUST additionally sweep the newly-enumerated scattered fragments (7935-7954, 8009-8019, 6096-6097, 6126-6127, 8057-8077, 1090-1094, 6439-6443, 7348) at **branch level, not block level** — see the expanded Pitfall 2 table below. Re-run the orphan guard (see `## Orphan/Dangling Guard`) after the contiguous-block pass to catch any stragglers among these fragments.

### Adjacent findings — dead CSS outside the 8 named families (bonus, not in REIGN-04's literal text)

Re-verified this session; all 5 are still dead, at updated line numbers:

| Selector | Current line | Status | Why |
|----------|------|--------|-----|
| `.ax-home .ax-page-header-compact { gap: 0.125rem; ... }` | 5766 | DEAD (orphan) | `dashboard_live.ex` no longer passes a `class="ax-page-header-compact"` variant to `PageHeader.page_header` (re-confirmed: `dashboard_live.ex:65-68` calls `PageHeader.page_header` with no `class=` override at all). The bare `.ax-page-header-compact` class is still alive globally (used by `component_kitchen_live.ex:74`'s own hand-rolled header), just never nested under `.ax-home` anymore. |
| `.ax-home .ax-page-actions { gap: 0.125rem; }` | 5909 | DEAD (orphan) | `PageHeader.page_header` renders `class="ax-page-header-actions" data-ax-page-actions` (confirmed via `lib/accrue_admin/components/page_header.ex:43`), not `ax-page-actions`. The bare `.ax-page-actions` class is alive elsewhere (`charge_live.ex:186`, `connect_account_live.ex:177`, `subscription_live.ex:344`, `invoice_live.ex:289`, `component_kitchen_live.ex:86` all still hand-roll `<div class="ax-page-actions">`), just never nested under `.ax-home`. |
| `.ax-home .ax-page-actions .ax-button-sm { min-height: 1.5rem; padding: ...; }` | 5913 | DEAD (orphan) | Same as above (compound of the dead ancestor). |
| `.ax-dashboard-title-row { display: flex; ... }` | 5730 | DEAD (orphan) | Zero references anywhere in `lib/`, `test/`, `e2e/`. Pre-210 hand-rolled-header remnant. |
| `.ax-dashboard-title-row .ax-display { width: auto; }` | 5737 | DEAD (orphan) | Same. |

**Confirmed LIVE and must stay** in the same block: `.ax-home { gap: var(--ax-space-md); }` (5707), `.ax-home > .ax-page-header { gap: 0; padding-block: 0; }` (5711), `.ax-home > .ax-page-header .ax-display` (5716) and `.ax-home > .ax-page-header .ax-page-copy` (5723), `.ax-home .ax-home-section { margin-block-start: 0; }` (5770), `.ax-home [data-ax-zone="attention-rail"] .ax-section-head .ax-heading { ... }` (5928), and `.ax-home [data-ax-zone="attention-rail"], .ax-home [data-ax-zone="task-launcher"], .ax-home [data-ax-zone="kpi-cluster"] { margin-block-start: 0; }` (5934-5936) — all match real `data-ax-zone` attributes in `dashboard_live.ex` (re-confirmed: `data-ax-zone="attention-rail"` at line 137, `data-ax-zone="task-launcher"` at line 173).

**Recommendation (unchanged):** fold these 5 extra dead rules into this phase's deletion pass — they are trivially safe, zero-reference-confirmed, and directly caused by the same Home reign this phase is cleaning up after. Not required by REIGN-04's literal wording, so flag the decision explicitly if the planner prefers strict scope discipline.

## Bundle Rebuild

**Command:** `cd accrue_admin && mix accrue_admin.assets.build` — unchanged since 2026-06-15 (pre-dates the original research; re-confirmed untouched this session).

**What it does** (from `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`, re-read in full this session — byte-identical to 2026-07-19):
1. Runs `npx --yes tailwindcss@3.4.17 --input assets/css/app.css --output priv/static/accrue_admin.css --minify`
2. Runs `npx --yes esbuild@0.25.3 assets/js/app.js --bundle --format=esm --minify --outfile=priv/static/accrue_admin.js`
3. Both tool versions are pinned inline in the task — `@tailwind_version "tailwindcss@3.4.17"`, `@esbuild_version "esbuild@0.25.3"`.
4. Output: exactly two files, `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js`, both **fixed filenames**.

**Determinism:** unchanged — given the same `app.css`/`app.js` source and the same pinned tool versions, output is deterministic. **New confirmation this session:** the currently-committed `priv/static/accrue_admin.css` is already rebuilt-and-fresh against the CURRENT (pre-retirement) `app.css` source — verified the CI-remediation `.ax-page{...grid-template-columns:minmax(0,1fr)...box-sizing:border-box}` and `.ax-detail-health-summary{...box-sizing:border-box...}` declarations are present in the minified bundle. This means Plan 02's eventual rebuild diff will cleanly and exclusively reflect the CSS deletions, with no unrelated pre-existing drift to account for.

**What must be committed:** unchanged — both `priv/static/accrue_admin.css` and `priv/static/accrue_admin.js` in the same commit as the `assets/css/app.css` source edit, because `AccrueAdmin.Assets` reads these files via `File.read!/1` into **compile-time module attributes**, hashed via `:crypto.hash(:md5, ...)`.

**Storybook CSS has NO automated rebuild task — unchanged.** Confirmed again via `mix.exs`/`package.json` (no storybook build alias exists; `phase200:storybook` only *tests* the bundle). `priv/static/storybook.css` is still a hand-composed 3-part concatenation: `(1) PhoenixStorybook sandbox CSS  (2) accrue_admin.css  (3) dark-mode shim`. **This file WAS edited on 2026-07-27** (commit `74a4c0be`), but only the dark-mode shim's 3 token declarations changed (`--ax-accent-readable`, `--ax-focus-ring`, `--ax-focus-shadow` — now verbatim-mirroring `theme.css`'s dark tokens, plus 2 new supporting custom properties `--ax-accent`/`--accrue-paper` defined locally in the shim); the PSB-CSS section and the embedded `accrue_admin.css` section are untouched, and the `/* === D-17 Spike B */` marker is still present at the same relative position (start of the shim tail). The recomposition recipe from 2026-07-19 is **unchanged and still correct**:

```bash
cd accrue_admin
mix accrue_admin.assets.build   # regenerates priv/static/accrue_admin.css (and .js, unchanged)

# Recompose storybook.css: PSB CSS + fresh accrue_admin.css + the UNCHANGED dark-mode shim tail.
# The shim tail starts at the "/* === D-17 Spike B" marker and must be preserved byte-for-byte
# (this now includes the 2026-07-27 token-mirroring fix — do not revert it).
awk '/\/\* === D-17 Spike B/{found=1} found' priv/static/storybook.css > /tmp/storybook-shim-tail.css

{
  printf '/* D-17 spike D recorded decision: Storybook CSS served via AccrueAdmin.Assets committed-bundle route; no Tailwind rebuild required */\n'
  printf '/* This bundle is committed to git and served by AccrueAdmin.Assets.asset(:storybook_css) */\n'
  printf '/* Composition: (1) PhoenixStorybook sandbox CSS  (2) accrue_admin.css  (3) dark-mode shim */\n\n'
  cat deps/phoenix_storybook/priv/static/css/phoenix_storybook.css
  printf '\n/* === accrue_admin.css bundle === */\n'
  cat priv/static/accrue_admin.css
  printf '\n'
  cat /tmp/storybook-shim-tail.css
} > priv/static/storybook.css
```

**Verification that storybook.css still needs a rebuild this phase (re-confirmed):** a grep of the current committed `priv/static/storybook.css` for the 8 candidate-family prefixes still finds `.ax-attention*`, `.ax-home`, `.ax-home-search`, `.ax-home-section`, `.ax-launcher*` present (still a byte-for-byte embed of the pre-retirement `accrue_admin.css`). None of these appear in any `storybook/` source `.story.exs` file (re-confirmed zero hits), so the fix is still a pure rebuild/recomposition, no story-source edits needed.

## Secondary Surfaces

### Component kitchen (`accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex`)

**Finding: unchanged — the kitchen renders NONE of the 92 dead classes today.** Re-ran a full-file grep for the 8 candidate prefixes — zero matches, same as 2026-07-19. **The file WAS touched on 2026-07-27** (commit `b79e89e4`, "restore drawer-form portal shell") — it wraps the drawer specimen in a `<DetailDrawer.detail_drawer>` component (moving Cancel/Save into a `:footer` slot) instead of a plain inline card. This edit only touches `ax-dev-group-drawer-*` and `ax-detail-drawer-footer`-adjacent classes, none of which are members of the 8 candidate families or the 2 shared-with-detail-page classes. The kitchen still uses the two PRESERVE shared families extensively and correctly: `ax-inline-worklist`/`ax-inline-worklist-copy`/`ax-inline-worklist-actions` (4 sections, lines 141-207) and `ax-audit-summary-row` (2 places, lines 220 and 974). **No markup changes are required in the kitchen for REIGN-04** — unchanged conclusion.

### Storybook (`priv/static/storybook.css` + `storybook/` sources)

Covered fully in `## Bundle Rebuild` above. Summary: rebuild-only, no story-source edits. The 2026-07-27 dark-shim-token fix does not change this conclusion (see delta table).

**Phase 200 storybook specs that must stay green** (re-checked, all unchanged since 2026-07-19):
- `test/accrue_admin/dev/storybook_coverage_test.exs` — asserts `ComponentRegistry` ↔ story coverage-row parity; zero coupling to CSS content. Safe by inspection.
- `test/accrue_admin/dev/storybook_asset_test.exs` — asserts the storybook CSS/JS assets are served byte-identically to the committed files; byte-equality computed dynamically at test time, safe against content change but WILL fail if `storybook.css` is not rebuilt/recomposed after `accrue_admin.css` changes.
- `test/accrue_admin/theme_test.exs` — asserts the storybook dark-mode shim mirrors every dark `--ax-*` token from `theme.css`. **This test's expectations changed underneath it on 2026-07-27** (the shim was edited specifically to satisfy this test's "verbatim mirroring" requirement per commit `74a4c0be`'s message — "theme_test storybook dark-shim drift" fix). Still unrelated to `.ax-home*`/`.ax-launcher*`/etc rule content; theme tokens untouched by Phase 211's retirement work. Safe, and now presumably green (was previously a known-red gap per user memory; the 07-27 fix targeted exactly this).
- `e2e/admin-storybook-a11y-phase200.spec.js` (via `npm run phase200:storybook`) — axe accessibility scan over storybook pages; unaffected by dashboard/subscriptions CSS retirement. Must run after `storybook.css` recomposition to avoid a stale/broken stylesheet.

`css_hash()`/`storybook_css_hash()` are still computed dynamically from file content at compile time; hash tests derive expected values from `AccrueAdmin.Assets.css_hash()` itself — unchanged, safe.

### Ratchet `region-tags.js` (`accrue_admin/e2e/ratchet/region-tags.js`)

**Finding: unchanged.** `REGION_SELECTORS["attention-rail"]` is still hardcoded to `"ax-attention-rail"` at **line 91** (file has been untouched since 2026-07-03, well before both the original research and this refresh) with the same `// TODO: confirm selector` comment. This selector still never existed as a real CSS class — the current `app.css` only has the `.ax-attention-rail--empty` modifier (three occurrences: 6178, 6182, 6185).

**Recommended replacement — unchanged:** `[data-ax-zone="attention-rail"]`, still confirmed live in `dashboard_live.ex:137` (`data-ax-zone="attention-rail"`), and still the selector the phase-199/210 Playwright ratchet guards were retargeted to (commit `22486e63`, unchanged history).

```js
// region-tags.js line 91, recommended fix (unchanged):
"attention-rail": "[data-ax-zone='attention-rail']", // fixed 2026: matches phase199 guard selector + dashboard_live.ex data-ax-zone
```

Other `REGION_SELECTORS` entries (`toolbar`, `tab-bar`, `kpi-row`, `detail-panel`, `related-panel`, `timeline`, `payload-viewer`, `content-body`, `layer`) still carry the same `// TODO: confirm selector` marker and remain out of scope for REIGN-04 — unchanged.

## Test/E2E Migration Surface

**Definitive finding: unchanged — zero migrations are needed.** Re-ran the identical project-wide grep of `accrue_admin/test/` and `accrue_admin/e2e/` for all 8 candidate prefixes — returns the exact same 3 hits as 2026-07-19, at the same line numbers:

| File | Line | Match | Verdict |
|------|------|-------|---------|
| `test/accrue_admin/live/dashboard_live_test.exs` | 125 | `assert html =~ "data-ax-launcher-primary"` | Not a CSS class at all — a `data-*` attribute, already correct. No action. |
| `e2e/admin-spec-overview-phase194.spec.js` | 96 | `page.locator(".ax-attention-rail--empty")` | PRESERVE class (see census). No action. |
| `e2e/ratchet/region-tags.js` | 91 | `"attention-rail": "ax-attention-rail"` | The one genuine fix — see `## Secondary Surfaces` above. Not a test assertion, so it doesn't affect any live gate, but it's the one line to change. |

This remains consistent with the 209-03 and 210-03 SUMMARY.md evidence: both prior phases migrated their own test/e2e selectors as part of their own success criteria. REIGN-04's migration clause is satisfied by verification, not new editing.

**How to run the relevant suites** (re-verified against current `accrue_admin/package.json` + `mix.exs` — all script names still present and unchanged):

| Gate | Command | Purpose |
|------|---------|---------|
| Full unit suite | `cd accrue_admin && mix test` | All ExUnit tests, including `dashboard_live_test.exs`, `subscriptions_live_test.exs`, storybook tests. |
| Home overview gate | `npm run e2e:phase194` | Includes the D-06 empty-rail check on `.ax-attention-rail--empty` (PRESERVE). |
| Interaction/overlay gate | `npm run e2e:phase199` | Focus-ring ratchet guards — already retargeted off dead classes. |
| Accessibility gate | `npm run e2e:a11y` | axe scan; expect pre-approved-deferred dark-mode contrast items and nothing new. |
| Storybook gate | `npm run phase200:storybook` | Chains 3 unit tests + the storybook a11y Playwright spec. |
| Subscriptions list/detail gates | `npm run e2e:phase196`, `npm run e2e:phase197` | Cover the Subscriptions list surface this phase's deletions touch. |
| Full e2e suite | `npm run e2e` | All specs × 2 projects (`chromium-desktop`, `chromium-mobile`). |

`copy_strings.json` regeneration is still **not required** this phase — unchanged.

## Orphan/Dangling Guard

**No existing script does this — re-confirmed.** Re-surveyed `scripts/ci/*.mjs`/`*.sh` and `accrue_admin/e2e/*.mjs` (including the newly-landed `e2e/ratchet/ratchet-live-uat.mjs` from the 2026-07-28 `d6636e4a` commit, which is a machine-UAT capture tool, unrelated to CSS liveness) — still none perform a CSS-selector-vs-source liveness census. The design recommendation is **unchanged from 2026-07-19**:

**Recommended design** (new, small, standalone script — e.g. `accrue_admin/e2e/verify-css-census.mjs`, following the existing `verify_*` naming convention):

1. **Extract** every `.ax-[a-zA-Z0-9_-]+` class-selector token from `accrue_admin/assets/css/app.css` (regex extraction on the source, not the minified bundle).
2. **Search** for each token, exact-match (the same `(?<![\w-])TOKEN(?![\w-])` lookaround pattern validated in this research) across `accrue_admin/lib/**/*.ex`, `accrue_admin/storybook/**/*.exs`, `accrue_admin/test/**/*.{ex,exs}`, `accrue_admin/e2e/**/*.js`.
3. **Report (a)** — orphan rules: CSS selectors with zero matches anywhere → candidates for deletion (generalizes beyond the 8 named families and will also surface the 5 "Adjacent findings" for free).
4. **Report (b)** — missing rules: literal `ax-*` class tokens found in source `class="..."`/`class={[...]}` with no matching CSS selector → lower-severity, informational.
5. **Allowlist mechanism for dynamic/interpolated classes** — e.g. `component_kitchen_live.ex` builds `class={"ax-foundation-status ax-foundation-status-#{status}"}`; verified this is NOT an issue for any of the 8 REIGN-04 families (re-checked this session — no `#{...}` interpolation touches any candidate-family class in `dashboard_live.ex`, `subscriptions_live.ex`, `subscription_live.ex`, or `component_kitchen_live.ex`).
6. **Self-test mode** (`--self-test`): hand-written fixture CSS + fixture source strings covering (i) a genuinely orphaned rule, (ii) a genuinely live rule, (iii) the exact-token boundary cases from Pitfall 1, and now additionally (iv) a branch-level fixture mirroring the newly-enumerated Pitfall 2 comma-group cases (one dead branch + one live branch in the same rule) — asserting the tool correctly flags only the dead branch, not the whole rule.
7. **Exit code:** non-zero if orphan rules are found, report stays advisory-friendly.

Keep this genuinely cheap: no browser, no build step, no network — pure regex extraction + `rg`/Node `fs.readFileSync` + string matching.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` (re-confirmed 2026-07-28, not absent, not false) — this section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir, `mix test`) + Playwright `^1.62.0` (Node, `accrue_admin/e2e/*.spec.js`) — **Playwright version bumped from 1.59.1 → 1.62.0 since 2026-07-19; no config/API-breaking changes expected, `playwright.config.js` untouched** |
| Config file | `accrue_admin/test/test_helper.exs` (ExUnit) + `accrue_admin/playwright.config.js` (Playwright, `testDir: "./e2e"`, `workers: 1`, two projects: `chromium-desktop`/`chromium-mobile`) — unchanged |
| Quick run command | `cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs` |
| Full suite command | `cd accrue_admin && mix test && npm run e2e` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REIGN-04 (SC1: zero-ref grep census) | Grep census over `lib/`, `test/`, `e2e/` for each candidate class | unit/script | `rg -lP "(?<![\w-])CLASS(?![\w-])" accrue_admin/lib accrue_admin/test accrue_admin/e2e` per class, or the new orphan guard (once built) | ✅ (ripgrep already present; orphan guard is Wave 0 new) |
| REIGN-04 (SC2: detail-page preservation) | `.ax-inline-worklist*`/`.ax-audit-summary-row` and any other `subscription_live.ex`-referenced class survive; detail page visually unbroken | e2e/manual_procedural | `npx playwright test e2e/admin-spec-detail-phase195.spec.js e2e/admin-spec-detail-phase198.spec.js` + PNG read | ✅ |
| REIGN-04 (SC3: bundle rebuild + orphan guard) | `accrue_admin.css`/`.js` rebuilt+committed; new orphan guard passes | unit/script | `mix accrue_admin.assets.build` (exit 0) + new guard script (exit 0) | ⚠️ orphan guard script is new — Wave 0 gap |
| REIGN-04 (SC4: kitchen/storybook/region-tags) | Kitchen renders no dead vocab (already true); storybook.css rebuilt; phase200 storybook specs green; `region-tags.js` fixed | unit/e2e | `npm run phase200:storybook` | ✅ |
| REIGN-04 (SC5: full suite green, no scope breach) | `mix test` + full e2e green across the phase boundary; diff touches no `accrue/lib`, no new nav room | unit/e2e/script | `mix test && npm run e2e`; `git diff --stat -- ../accrue/lib` (expect empty) | ✅ |

### Sampling Rate
- **Per task commit:** targeted unit test for the touched surface + the new orphan-guard script.
- **Per wave merge:** `mix test` (full accrue_admin unit suite) + the 3 named e2e gates (phase194, phase199, admin-a11y) + `npm run phase200:storybook`.
- **Phase gate:** full `mix test` + full `npm run e2e` (all specs × 2 projects) green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `accrue_admin/e2e/verify-css-census.mjs` — the orphan/dangling guard does not exist yet (re-confirmed unchanged) — must be authored this phase per success criterion 3. Include a `--self-test` mode per repo convention, now also covering the branch-level (Pitfall 2) case.
- [ ] Capture the **current** (pre-Phase-211) `mix test` pass/fail baseline as a Wave 0 step — measured against the actual starting point, not an assumed-clean baseline.
- [ ] No test-framework install gaps: ExUnit and Playwright are both already configured and passing (re-confirmed present and versioned this session).

## Security Domain

`security_enforcement` is absent from `.planning/config.json` (re-confirmed, treated as enabled per protocol), but this phase has **no security-relevant surface** — unchanged conclusion. Deletes unused CSS selectors and dev-tooling metadata; touches no auth/session/webhook/input-validation code; adds no new externally-reachable route or user input path.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | n/a — no auth code touched |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a |
| V5 Input Validation | no | n/a — no new user input surface |
| V6 Cryptography | no | n/a |

No STRIDE-relevant threat patterns apply to a CSS-source-file deletion + static-bundle-rebuild change.

## Package Legitimacy Audit

Not applicable — this phase installs **no new packages** — unchanged. `mix accrue_admin.assets.build` invokes two already-pinned, already-in-use tool versions via `npx` (`tailwindcss@3.4.17`, `esbuild@0.25.3`), both unchanged by this phase.

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Common Pitfalls

### Pitfall 1: Substring/attribute false positives in the liveness grep
**What goes wrong:** A naive `grep -l "ax-launcher"` (or `grep -l "ax-launcher-primary"`) reports the bare `ax-launcher`/`ax-launcher-primary` classes as "live" because `ax-launchers` and `data-ax-launcher-primary` contain them as substrings.
**Why it happens:** `\b` word-boundary regex treats `-` as a non-word character, so it fires at the same position whether the neighboring token is a hyphen-suffix continuation (`ax-launchers`) or an unrelated `data-` attribute prefix (`data-ax-launcher-primary`) — both look like valid boundaries to a naive `\b`-based check.
**How to avoid:** use the `(?<![\w-])TOKEN(?![\w-])` lookaround pattern validated in this research, or extract `class="..."`/`class={[...]}` attribute values and tokenize on whitespace before comparing.
**Warning signs:** a "live" class that never actually appears when you manually open the file and search for the literal `class="..."` string.

### Pitfall 2: Deleting a comma-grouped selector wholesale when only one branch is dead

**Re-verified and substantially expanded this session.** The original example still holds and now appears at TWO locations (the rule is duplicated in the source, once unconditional and once inside a media query):

```css
/* app.css line 1090-1094 (unconditional) AND again at line 6439-6443 (inside @media (min-width: 1024px)) */
.ax-shell-content:has(> .ax-subscriptions-page),   /* ← DEAD branch, delete only this line */
.ax-shell-content:has(> .ax-subscription-detail-page),  /* ← keep — out-of-scope detail page */
.ax-shell-content:has(> .ax-home) {                /* ← keep — Home is reigned/live */
  padding-top: 0;
}
```

**A systematic re-scan this session (a small script that groups comma-separated selector branches per rule and checks each branch independently for dead-class membership) found 9 total comma-groups requiring branch-level deletion, at 7 distinct rule locations** (the `:has()` rule above counts twice since it's duplicated in the source). All are pre-existing (confirmed via `git blame` — none introduced by the 07-19→07-28 commits), simply not individually enumerated in the original research beyond the one `:has()` example:

| Lines | Dead branch(es) to remove | Live branch(es) to keep |
|-------|---------------------------|--------------------------|
| 1090-1094 | `.ax-shell-content:has(> .ax-subscriptions-page)` | `.ax-shell-content:has(> .ax-subscription-detail-page)`, `.ax-shell-content:has(> .ax-home)` |
| 3014-3016 | `.ax-subscriptions-header .ax-button-sm` | `.ax-work-queue-actions .ax-button-sm` (a separate, pre-existing dead class outside the 8 named families — this whole rule is actually dead on BOTH branches; safe to delete the entire rule, but confirm `ax-work-queue-actions` truly has zero refs before doing so, since it is out of this phase's named scope) |
| 6096-6097 | `.ax-attention-row:first-child .ax-attention-action` | `.ax-attention-row:first-child .ax-attention-text strong` |
| 6126-6127 | `.ax-attention-pill-danger`, `.ax-attention-pill-warning` (as descendants of `.ax-attention`, which is itself PRESERVE) | n/a — this is `.ax-attention .ax-attention-pill-danger, .ax-attention .ax-attention-pill-warning { ... }`; since the ancestor `.ax-attention` is LIVE but the descendant pill classes are DEAD, the whole compound selector never matches once the pill classes are gone from markup — safe to delete both branches entirely |
| 6439-6443 | `.ax-shell-content:has(> .ax-subscriptions-page)` | `.ax-shell-content:has(> .ax-subscription-detail-page)`, `.ax-shell-content:has(> .ax-home)` (same rule as 1090-1094, duplicated inside a media query — both copies need the fix) |
| 7935-7954 | `.ax-launcher:focus-visible` (one branch inside an 18-branch global focus-ring utility rule) | all 17 other branches (`.ax-button`, `.ax-sidebar-link`, `.ax-attention-row`, `.ax-related-item`, etc. — all live, unrelated utility classes) |
| 8009-8019 | `.ax-launcher:hover` (one branch inside a 10-branch global hover utility rule) | all 9 other branches (same pattern as above) |
| 8057-8061 | `.ax-attention-pill-danger` (one branch inside a 5-branch danger-tone utility rule) | `.ax-status-badge-danger`, `.ax-badge-danger`, `.ax-flash-error`, `.ax-banner-danger` |
| 8067-8069 | `.ax-attention-pill-info` | `.ax-status-badge-cobalt`, `.ax-flash-info` |
| 8075-8077 | `.ax-attention-pill` | `.ax-status-badge-slate`, `.ax-badge` |

**Why it happens:** grep/`rg` matches the rule *block*, not the individual comma-branch, so a naive "this block mentions a dead class, delete the block" heuristic over-deletes — and the global focus/hover/status utility rules near the end of the file (7935-8090) are especially dense with this pattern since they consolidate dozens of unrelated component classes into shared interaction-state rules.
**How to avoid:** for every dead-class match inside a multi-selector comma list, remove only that comma-branch, keeping the rest of the rule intact. The new orphan-guard script's self-test (Wave 0) should include a fixture covering this exact pattern.
**Warning signs:** a shared layout/interaction-state rule (padding/margin/display/hover/focus-ring) silently regresses on an unrelated live component after deletion.

### Pitfall 3: Assuming "named family = fully dead"
**What goes wrong:** Treating `.ax-subscription-setup-gap` as dead because it's inside the "ax-subscription-setup*" family the ROADMAP names for retirement.
**Why it happens:** the ROADMAP/success-criteria prose names *families* (prefixes), but liveness is a per-selector fact, not a per-family one.
**How to avoid:** always grep every individual selector name, never bulk-delete by prefix match alone.
**Warning signs:** a rendering regression on the Subscriptions list's "setup gap" cell (missing border-left/warning-color treatment) after deletion.

### Pitfall 4: Forgetting `storybook.css` has no build task
**What goes wrong:** running only `mix accrue_admin.assets.build` and assuming all committed CSS artifacts are fresh; `storybook.css` silently keeps embedding the stale, pre-retirement `accrue_admin.css`.
**Why it happens:** `storybook.css` was authored as a one-time hand-composed commit in Phase 193 with no follow-up automation; there's no `mix storybook.assets.build` task to remind you. **Reconfirmed still true as of 2026-07-27** — even the recent dark-shim-token fix (`74a4c0be`) was a manual hand-edit of the committed file, not a rebuild.
**How to avoid:** always pair the `mix accrue_admin.assets.build` step with the manual/scripted `storybook.css` recomposition described in `## Bundle Rebuild` — and preserve the 2026-07-27 shim-tail token fix verbatim when recomposing (don't revert it by using a stale reference copy of the shim tail).
**Warning signs:** `npm run phase200:storybook` still passes (byte-equality is self-consistent), but the served storybook page visually/structurally still contains dead-class remnants if anyone inspects it.

### Pitfall 5: Compile-time asset caching masking a rebuild
**What goes wrong:** `AccrueAdmin.Assets` reads `priv/static/accrue_admin.css`/`storybook.css` into **module attributes at compile time**. If the host app (or `mix test`) doesn't recompile `accrue_admin` after the files change on disk, stale bytes keep being served in a long-running `iex`/dev session.
**Why it happens:** `@external_resource` is declared (so `mix compile` will detect the file changed), but a hot-reloading dev server or an already-booted BEAM node holding old compiled code won't automatically pick it up.
**How to avoid:** always run (or let CI run) a full `mix compile`/`mix test` after touching either CSS file.
**Warning signs:** `git diff` shows the CSS changed, but a manually-tested running dev server still renders the old styles.

## Runtime State Inventory

> Not applicable — this is a CSS retirement / dev-tooling cleanup phase, not a rename/refactor/migration phase. No renamed identifiers, no stored data, no OS-registered state, no secrets, no build-artifact rename is involved. Unchanged from 2026-07-19.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The recommended `region-tags.js` fix (`[data-ax-zone='attention-rail']`) is the "correct" non-dangling selector | Secondary Surfaces | Low — `REGION_SELECTORS` is documented as non-identity/never-crashes metadata; a wrong choice here has zero effect on the ratchet's actual behavior. |
| A2 | Folding the 5 "Adjacent findings" (outside the 8 named families) into this phase's deletion is a reasonable scope extension rather than scope creep | Class Census (Adjacent findings) | Low-Medium — independently zero-reference-verified dead rules, not literally named in REIGN-04's text; if the maintainer wants strict scope discipline, leave for a follow-up and note the decision explicitly. |
| A3 | Building a dedicated `mix accrue_admin.storybook.assets.build` task (rather than a one-off shell recipe) is worth the extra scope | Bundle Rebuild | Low — either approach achieves the phase's goal; flagged as a planner/maintainer judgment call, not a blocking risk. |
| A4 (new) | The `.ax-subscriptions-header .ax-button-sm, .ax-work-queue-actions .ax-button-sm` rule (lines 3014-3016) can be deleted in its entirety because BOTH branches are dead, including the out-of-named-scope `ax-work-queue-actions` | Common Pitfalls, Pitfall 2 table | Low — `ax-work-queue-actions`/`ax-work-queue-primary`/`ax-work-queue-secondary` are confirmed zero-referenced in `lib/`/`test/`/`e2e/` (pre-existing dead code from Phase 208, unrelated to REIGN-04's named families); if the executor prefers strict scope discipline, only delete the `.ax-subscriptions-header .ax-button-sm` branch and leave the `.ax-work-queue-actions .ax-button-sm` branch + its ancestor rules for a separate cleanup, since they are out of REIGN-04's literal text. |

**If this table is empty:** N/A — see entries above; none of these are compliance/security/retention-policy claims, all are low-blast-radius implementation-detail judgment calls appropriate for the planner to resolve.

## Open Questions

1. **Should the 5 "Adjacent findings" dead rules (outside the 8 named REIGN-04 families) be deleted in this phase or deferred?**
   - What we know: all 5 are zero-reference-confirmed dead, caused by the same Phase 210 PageHeader migration this phase is cleaning up after. Re-confirmed unchanged this session.
   - What's unclear: whether "grep-gated... the bespoke [8 named families]... sets (~325 rules) are removed" in the ROADMAP is meant as an exhaustive boundary or an illustrative one.
   - Recommendation: include them (trivially safe, same root cause, avoids a second invisible-dead-CSS round), but call out the decision explicitly in the plan rather than silently expanding scope.

2. **Should the general orphan/dangling guard be wired into CI as a blocking check, or left as a manually-run advisory script this phase?**
   - What we know: no existing CI workflow references any CSS-orphan check; still true as of 2026-07-28.
   - What's unclear: whether adding a new required CI check is itself a scope concern for a milestone whose guardrails say "no new deps, no CI required-check topology changes."
   - Recommendation: build the script and run it manually as part of this phase's own verification; leave CI-wiring as an explicit follow-up decision for the maintainer.

3. **Are the other `REGION_SELECTORS` `// TODO: confirm selector` entries in scope for "opportunistic" fixing alongside `attention-rail`?**
   - What we know: they carry the identical dangling-marker pattern and safety profile. Unchanged this session — file untouched since 07-03.
   - What's unclear: REIGN-04's text names only the `attention-rail` (`.ax-attention*`) family.
   - Recommendation: leave them untouched — unrelated, separately-scoped cleanup (v1.56 ratchet re-freeze territory).

4. **(New) Should `.ax-work-queue-actions`/`.ax-work-queue-primary`/`.ax-work-queue-secondary` (a pre-existing, unrelated dead-code pocket from Phase 208, discovered incidentally while tracing the comma-group at lines 3014-3016) be folded into this phase's cleanup?**
   - What we know: confirmed zero references anywhere in `lib/`/`test/`/`e2e/`; predates both this milestone and the 8 named REIGN-04 families; unrelated to the 209/210 reign.
   - What's unclear: this is genuinely outside REIGN-04's scope — it's leftover dead CSS from an entirely different, older phase (208, v1.56 ratchet era), not something the Home/Subscriptions reign caused.
   - Recommendation: **leave untouched** — unlike the 5 "Adjacent findings" (which are directly attributable to this phase's own Home reign), this is pre-existing, unrelated dead code and folding it in would be genuine scope creep. Only its `.ax-work-queue-actions .ax-button-sm` branch (paired with the dead `.ax-subscriptions-header .ax-button-sm` branch in the same rule) needs a decision — see Assumption A4.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | `npx` tool invocations inside `mix accrue_admin.assets.build`, Playwright e2e | ✓ | v22.14.0 (unchanged) | — |
| npx | Downloads/runs pinned `tailwindcss@3.4.17` / `esbuild@0.25.3` on demand | ✓ | 11.1.0 (unchanged) | — |
| Elixir/Mix | `mix test`, `mix accrue_admin.assets.build`, `mix accrue_admin.export_copy_strings` | ✓ | Elixir 1.19.5 / Mix 1.19.5 (OTP 28) (unchanged) | — |
| Playwright | Full e2e suite + storybook a11y spec | ✓ | **1.62.0 (bumped from 1.59.1 — no config/API-breaking changes expected; `playwright.config.js` untouched)** | — |
| ripgrep (`rg`) | Recommended for the exact-token census grep and the new orphan guard's shell-assisted verification | ✓ | present at `/opt/homebrew/bin/rg` (unchanged) | plain POSIX `grep -E` lacks lookaround; the Node-based orphan guard script (JS regex supports lookaround) is the portable fallback. |

**Missing dependencies with no fallback:** none — all required tooling is present and already used successfully by Phases 209/210/the 07-27/07-28 CI-remediation work in this exact environment.

## Sources

### Primary (HIGH confidence — direct codebase inspection this session, 2026-07-28)
- `accrue_admin/assets/css/app.css` (8326 lines, was 8091 at 07-19) — full selector re-extraction for all 8 candidate families, exact-token liveness re-grep, new systematic comma-branch scan, adjacent `.ax-home` block re-read (lines 5639-5941+).
- `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` (644 lines) — targeted re-reads confirming every PRESERVE line citation is unchanged.
- `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` (687 lines) — re-confirms `ax-subscription-setup-gap` at line 418 (unchanged).
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex` (2180 lines) — re-confirms detail-page-shared class usage at lines 304-305, 344, 480 (unchanged).
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` (1892 lines, was 1894) — re-confirms zero dead-vocabulary usage; reviewed the 07-27 `DetailDrawer` diff.
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — re-read, unchanged since 2026-06-15.
- `accrue_admin/lib/accrue_admin/assets.ex`, `accrue_admin/lib/accrue_admin/dev/storybook.ex`, `accrue_admin/lib/accrue_admin/components/page_header.ex` — re-read for hashed-path/compile-time-caching mechanics and PageHeader class-rendering confirmation.
- `accrue_admin/priv/static/storybook.css`, `accrue_admin/priv/static/accrue_admin.css` — re-read structure + spot-checked for CI-remediation rule presence (bundle freshness confirmation).
- `accrue_admin/e2e/ratchet/region-tags.js` (459 lines) — re-read, dangling `attention-rail` selector at line 91 unchanged since 2026-07-03.
- `accrue_admin/package.json`, `accrue_admin/mix.exs`, `accrue_admin/playwright.config.js` — re-read, all cited test/build entry points still present.
- `git log`/`git show`/`git blame` on all of the above files, plus `9147ea02`, `3d82e406`, `b79e89e4`, `1dce1262`, `bed032ff`, `55bb57b7`, `74a4c0be`, `d6636e4a` — used to establish exactly what changed since 2026-07-19 and confirm the 9 Pitfall-2 comma-groups pre-date this milestone.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/config.json` — re-read, phase scope/requirement text/`nyquist_validation` flag unchanged.
- Live environment probes: `node --version`, `npx --version`, `elixir --version`, `mix --version`, `npx playwright --version`, `rg` presence.

### Secondary (MEDIUM confidence)
- None — no external web/docs research was needed for this phase; entirely a same-repository grep/read exercise.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Class census (DELETE/PRESERVE): HIGH — re-derived from scratch this session via independent exact-token grep against the current repository state; produced an identical 92/16 split to the 2026-07-19 research, cross-validating both research passes.
- Bundle rebuild mechanics: HIGH — re-read the actual mix task source (unchanged file) and the actual `storybook.css` composition/marker structure (re-verified intact after the 07-27 shim-token edit).
- Secondary surfaces (kitchen/storybook/region-tags): HIGH — full-file reads and targeted diffs of every commit that touched these files since 07-19.
- Test/e2e migration surface: HIGH — exhaustive project-wide grep, identical result to 07-19, zero ambiguity.
- Orphan guard design: MEDIUM — unchanged design recommendation, still no existing precedent to directly verify against.
- New Pitfall-2 comma-branch findings: HIGH — derived via a deterministic branch-parsing script re-run against the current file and cross-checked with `git blame` to confirm none are newly introduced.

**Research date:** 2026-07-19 (original) / 2026-07-28 (this refresh)
**Valid until:** ~14 days from 2026-07-28 (fast-moving — tightly coupled to the exact current state of `app.css`/`dashboard_live.ex`/`subscriptions_live.ex`; any further commits to those files before Phase 211 executes should trigger a re-grep of the census, not a full re-research — this refresh demonstrates the re-grep is cheap and the census is stable across two rounds of unrelated intervening changes).
