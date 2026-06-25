# Project Research Summary — v1.54

**Project:** Accrue — `accrue_admin` operator UI (page-level streamlining + Storybook)
**Milestone:** v1.54 — Admin UI Page-Level Streamlining & Storybook (Phases 193–200)
**Domain:** Dense operator/admin tooling for an Elixir/Phoenix billing library; token-based design system (`ax-*`), forward-only visual-QA machinery
**Researched:** 2026-06-24
**Confidence:** HIGH

> Single synthesis of four v1.54 research files. The roadmapper and REQUIREMENTS step read **this** file; the four sources are cited inline for detail:
> - **FEATURES.md** — page archetypes, IA, progressive disclosure (SPEC-OVERVIEW / SPEC-LIST / SPEC-DETAIL)
> - **ARCHITECTURE.md** — micro-animation & interaction-motion (Emil Kowalski K1–K15, overlay/scroll/portal fixes, IXN acceptance criteria 1–12)
> - **PITFALLS.md** — 9 maintainer bug classes → root cause → prevention → guard/AC → gap-vs-existing-gate
> - **v1.54-storybook-and-forward-only-qa.md** — PhoenixStorybook adoption + forward-only page-flow baseline extension
>
> (`.planning/research/STACK.md` is the **canonical project-wide stack**, unchanged — NOT v1.54 research.)

---

## Executive Summary — the cross-cutting linchpin

**The one finding that unifies all four docs: the maintainer's reported defects are STRUCTURAL, not cosmetic, and the existing CI gates structurally cannot see them.** Modal-behind-scrim, awkward/trapping scroll, floating/mispositioned overlays, won't-dismiss, hover-on-non-interactive empty states, disabled-looks-enabled — these are *page-composition / runtime-interaction* failures: overlay layering, a **completely missing body scroll-lock** (`grep` confirms none exists in the repo), `position:fixed` shells **trapped by a transformed/filtered ancestor** stacking context, a **non-inert** background behind the scrim, and a **geometrically-wrong drawer** (full-viewport bottom sheet on every breakpoint with a wrong-axis `translateX` enter). Every existing gate (`verify_package_docs.sh`, FND-05 contrast, z-index literal ban, motion guards) operates on **token + CSS source text** — none observe a *composed, rendered page* across viewport × theme × state. The maintainer's entire bug list lives precisely in the blind spot.

**Therefore the milestone's backbone is two things:** (a) **one hardened, canonical overlay primitive** that every modal/drawer/popover routes through — body-level portal/`<dialog>` top-layer + ref-counted iOS-safe body scroll-lock + `inert` background + single dismissal contract + origin-aware enter motion; and (b) **a rendered state-matrix gate** — PhoenixStorybook (dev/test-only) + axe-core + a Playwright interaction battery, folded into v1.53's forward-only cell-baseline as new `surface_type:"page-flow"` cells under the unchanged `regressions.ndjson` zero-regression rule. **Prevention via source-lint where mechanical (3 cheap new guards); rendered-detection in CI where compositional (the real prevention surface).** Do not try to lint taste.

On top of that structural backbone, the *page-design* work is **archetype-driven**: lock three pattern specs (overview / list / detail) as design contracts, nail one gold-standard exemplar per archetype (Dashboard / Subscription-detail / Subscriptions-list), then propagate. The center of gravity is the **object-detail archetype** — `subscription_live.ex` at 1,234 LOC renders ~25 flat-stacked zones with **ten permanently-expanded inline action forms** (the textbook "info dump"), to be converted to **summary-then-drill + a single action menu + side-drawer + lazy plumbing** (~25 zones → ~6 bands). The motion-token vocabulary is already Kowalski-aligned and **stays as-is** — the budget goes to structural correctness, not new curves.

---

## Key Findings

### Storybook adoption + forward-only QA (`v1.54-storybook-and-forward-only-qa.md`)

Adopt **`{:phoenix_storybook, "~> 1.2", only: [:dev, :test]}`** (1.2.0, 2026-06-11; deps already satisfied; new transitive `makeup_*`/`mdex` never reach a host runtime).

- **Leak-proof mount** = copy the in-repo **Mailglass sibling-scope precedent** (`AccrueAdmin.Router`): Storybook emits its own `live_session`, so mount as a sibling scope, never nested. Backend module wrapped in `if Mix.env() != :prod`.
- **The critical library-vs-app gotcha:** a host pulling `accrue_admin` from Hex never downloads its `:dev,:test` deps, yet `dev_routes?` defaults true → a bare `import PhoenixStorybook.Router` would **fail the host's dev compile**. **Mandatory fix:** guard the router wrap on `Code.ensure_loaded?(PhoenixStorybook.Router)`. Encode as a hard AC: a host dev compile of `examples/accrue_host` succeeds with the dep absent and exposes **no** `/dev/storybook` route.
- **Registry-driven stories:** `variations/0` is an ordinary function → generate it from `AccrueAdmin.Dev.ComponentRegistry` (`entries/0` specimens/states → `%Variation{}`/`%VariationGroup{}`; `group_contracts/0` → group stories). One compiled generator + ~14 family shims + ~8 group shims. **Registry stays SSOT; Storybook is a second renderer.**
- **Keep the kitchen** (`/dev/components`) — its `data-ax-family`/`data-ax-state`/`data-component-group` locators back the Phase-189/190 drift/coverage tests; deleting it = churn against the zero-regression gate for no upside.
- **Theming bridge (the one real wrinkle, MEDIUM-confidence spike):** Storybook color-mode toggles a **class**; accrue_admin scopes dark via the **attribute** `html.accrue-admin[data-theme="dark"]`. Resolve with a thin sandbox-scoped CSS dark-shim (`color_mode_sandbox_dark_class`). **Asset deviation:** accrue_admin has **no Tailwind** and ships a committed CSS bundle — serve Storybook's CSS/JS from the existing `AccrueAdmin.Assets` controller, NOT the official Tailwind recipe, so the lab renders *shipped* styles (heed the "editing app.css ships nothing until rebuilt+committed" lesson).
- **Forward-only page QA = EXTEND the baseline, no SaaS.** Add `surface_type:"page-flow"` cells over the ~20 real routes (reuse Phase-191's page-flow Playwright driver), score with the same 12-dim rubric + adversarial judge, gate with the unchanged `regressions.ndjson`. **No pixel-diff gate** (it would flag every intentional v1.54 improvement as a regression). Storybook is the design lab, **not** the visual-regression engine — the page gate runs over real composed routes.

### Page archetypes & information architecture (`FEATURES.md`)

Three repeatable archetypes, each with a chosen direction (counterposition argued then rejected):

- **Overview (Dashboard + Recovery):** *refine, don't rebuild.* Keep the four-zone grammar — `attention-rail (exceptions-only, prominent healthy empty-state) → verb task-launchers (+ visible ⌘K) → demoted clickable KPIs → recent activity`. Recovery analytics adopts the **same** grammar (`hero metric pair → at-risk work-queue table → supporting trend`), **not** a chart wall. Rejected: KPI-first headline (becomes wallpaper).
- **List (9 pages):** **table-first + `PageHeader`.** `PageHeader(breadcrumb, title, stat-strip, actions, filter-toolbar) → filter chips + result count + clear-all → table (identity·state·money·time prioritized; plumbing deferred) → row→card stacking below breakpoint → server pagination`. Work-queue default, "All" one chip away. Four **distinct** states: first-run-empty ≠ filtered-empty ≠ loading-skeleton ≠ error-retry. Extract the shared **`PageHeader`** (the pending todo — highest-leverage list DRY win). Rejected: cards-everywhere (loses for scan/compare), infinite scroll (destroys position memory + back-nav on a queue).
- **Detail (10+ pages; worst = Subscription @ 1,234 LOC):** **summary-then-drill, NOT tabs-first, NOT everything-at-once.** `breadcrumbs → summary-list header (GOV.UK key/value rows + row-level "Change") → ≤2 primary buttons + overflow action menu (actions open in a side-drawer; destructive → step-up modal; swap-plan preview in drawer) → collapsible drill sections (most-relevant open) → ONE related-resources strip (bidirectional threading; delete the duplicate) → lazy activity timeline + lazy raw JSON`. Never a 2-column form wall. **Tabs allowed only for peer record-sets** (Customer-360 Subscriptions/Invoices/Payments). Rejected: tabs-for-primary-state (27–43% of users miss horizontal tabs vs 8% for collapsed sections; billing labels resist 1–2 words); everything-visible (Linear's speed comes from *findability + muscle memory*, not simultaneous exposure — ten near-identical open forms are *slower*).
- **Pure-subtraction wins** (no disclosure mechanism needed): delete the duplicate related card; flatten card-in-card double borders; kill redundant eyebrow==heading; de-emphasize plumbing IDs to mono-small; padding discipline (compact rows, generous only for cards).

### Micro-animation & interaction-motion (`ARCHITECTURE.md`)

The motion system is **already mostly Kowalski-correct** (120–240ms band, composite-only properties, enter-gentle/exit-snappy asymmetry, single earned overshoot, reduced-motion for free). **Keep the token vocabulary; spend the budget on overlay correctness.**

- **K1–K15 audit:** mostly ✅. Gaps: **K10 origin-aware transforms** (drawer enters on wrong axis; dropdowns lack `transform-origin` toward trigger), **K8 interruptibility** (rapid open→close→open can leave stale enter/exit classes).
- **Adversarially-held position:** do **not** raise the 240ms ceiling to match Vaul/Sonner (~500ms) — those are low-frequency consumer surfaces; K11 localizes operator tooling *down* to 180–250ms/none. (Footgun F7.)
- **Overlay structural fixes** (the bug class): **R-1 body scroll-lock** (highest-value single fix; ref-counted, iOS-safe `position:fixed`+restore, `overscroll-behavior:contain`, `scrollbar-gutter:stable`); **F2 portal to a body-level `#ax-overlay-root`** (no transformed/filtered/`contain` ancestor may wrap a `position:fixed` shell); **R-5 `inert` background** while overlay open; **R-2 single dismissal contract** (backdrop click + Escape → same close event, idempotent); **R-3 drawer geometry** (desktop edge-docked right panel on `translateX`; mobile bottom sheet on `translateY`); **R-4 origin-aware popovers**; **R-6 no hover/cursor on non-interactive empty-state heroes**.
- **List/stream motion:** first-load whole-body crossfade only (**no per-row stagger**, F6); new stream rows flash via `--ax-transition-colors`, never a height/translate list shift; View Transitions **deferred** (candidate spike, not v1.54).
- **Token decision:** **no new motion tokens** (one possible `--ax-dur-sheet` held pending mobile-sheet UAT, must be ≤300ms). New non-motion primitives: `[data-ax-scroll-locked]` rule + `ScrollLock` hook + `inert` toggle.

### Usability footguns & prevention (`PITFALLS.md`)

Nine maintainer bug classes, each mapped root-cause → prevention → AC/guard → gap-vs-gate. The **structural gap**: all existing gates are source-text; the bugs are rendered-composition.

| # | Bug class | Canonical prevention | Gate status |
|---|-----------|----------------------|-------------|
| 1 | Modal-behind-scrim | Body-level portal / native `<dialog>` top-layer; scrim one rung below in **same** context | ✅ z-literal ban; 🆕 rendered hit-test + portal rule |
| 2 | Awkward/trapped scroll | scrollbar-gutter-stable lock + iOS fixed-restore + internal scroll + `overscroll:contain` | 🆕 before/after layout-box AC; ⚠️ scrollbar-token consumption |
| 3 | Mispositioned floats | Anchor-to-trigger + collision flip + top-layer/root portal | ✅ z-rung; 🆕 viewport-bounds AC |
| 4 | Misalignment / asymmetric padding | EightShapes inset/stack/inline tokens; no per-side magic px | 🆕 **spacing-literal guard** (mirror FND-01) |
| 5 | Card-in-card over-boxing / flush spacing | One elevation step; sunken/hairline not nested borders; margin>padding | ⚠️ judgment → archetype spec + rubric |
| 6 | Disabled-looks-enabled / focus / contrast | Distinct disabled token set (not opacity); `:focus-visible` ≥3:1; on-solid text token; per-theme retune | ✅ tokens presence; 🆕 **`:focus-visible` guard** + axe over rendered stories |
| 7 | Tabs no active state / dead pagination / empty-state hover | ARIA-bound selected; conditional affordances (`pages>1`); non-interactive heroes | ✅ selected consumption; 🆕 conditional-affordance ACs |
| 8 | Squished columns / table overuse / stat-card drift | `min-width:0`+`minmax(0,1fr)`; declared per-table degradation; one `KpiCard` | 🆕 **truncation-without-`min-width:0` guard**; ⚠️ per-page intentionality |
| 9 | No tri-state theme / FOUC | Tri-state (✅ shipped); server-rendered `data-theme` before first paint | ✅ structure; 🆕 no-FOUC + persistence + system-emulation Playwright AC |

**Three new cheap source guards:** spacing-literal · `:focus-visible` · truncation-without-`min-width:0`. **The real prevention surface:** PhoenixStorybook state-matrix stories + axe-core over rendered stories + the Playwright interaction/overlay battery + the per-page rubric.

---

## Adversarial synthesis — agreements & resolved tensions

**Where all four agree (high-confidence convergence):**
- The defects are **structural/compositional**, invisible to source-lint → the milestone needs a **rendered state-matrix gate** (FEATURES rubric + PITFALLS harness + ARCHITECTURE IXN ACs + Storybook doc all land on this).
- **Body scroll-lock is missing and is the single highest-value fix** (ARCHITECTURE R-1 ≡ PITFALLS Pitfall-2).
- **One canonical overlay primitive**, body-level portal, `inert` background, single dismissal contract (ARCHITECTURE 2.1–2.3 ≡ PITFALLS 1/3).
- **No hover on non-interactive empty states** (ARCHITECTURE R-6 ≡ PITFALLS Pitfall-7 ≡ FEATURES detail anti-patterns).
- **Reuse over rebuild:** keep the motion tokens, keep the kitchen, keep the four-zone dashboard, extend (not replace) the v1.53 baseline.

**Tensions, with the chosen direction (each adversarially judged):**

| Tension | Chosen direction | Why the alternative was rejected |
|---------|------------------|----------------------------------|
| **Native `<dialog>`+top-layer vs custom portal** | PITFALLS prefers native `<dialog showModal()>` as *structurally immune* (top layer escapes all stacking contexts); ARCHITECTURE describes a custom `#ax-overlay-root` body-level portal that reuses the existing isolated z-scale + FocusTrap. **Resolve in Phase 193 spike → default to the body-level portal that reuses the shipped FocusTrap/z-scale, treating `<dialog>` top-layer as the fallback if a transformed-ancestor audit (Phase 199) finds re-rooting we can't remove.** Either way: **prove it with a Playwright hit-test**, never "just bump z-index." | "Bump the modal z-index" cannot escape a trapped context — the exact non-fix that perpetuates the bug. |
| **New tokens vs reuse** | **Reuse.** No new motion tokens (CI already forces any new duration to be a token ≤300ms); one possible `--ax-dur-sheet` held pending mobile-sheet UAT only. Spacing uses existing `--ax-space-*`. | Speculative tokens dilute the disciplined vocabulary; the gap is correctness, not curves. |
| **Duration: match Vaul/Sonner 500ms?** | **No — hold the 120–240ms band.** | Vaul/Sonner are low-frequency consumer surfaces; K11 localizes high-frequency operator tooling down. |
| **Tabs vs summary-then-drill for detail** | **Summary-then-drill primary; tabs only for peer record-sets** (Customer-360). | 27–43% miss horizontal tabs; primary state / critical action behind a tab is an anti-pattern; billing labels resist 1–2 words. |
| **Storybook as the visual-regression gate?** | **No.** Storybook = design lab; the page-flow Playwright cell-baseline = gate (real composed routes). | Chromatic/Percy are SaaS (TOOL-02 deferred); story pixel-diff misses page-level info-dump/scroll/overlay defects. |
| **Pixel-diff vs scored-cell gate** | **Scored dimensions, not pixels.** | Pixel-diff flags every intentional v1.54 improvement as a regression — opposite of forward-only uplift. |
| **Force all tables → cards on mobile?** | **No — declared per-table degradation** (card | horizontal-scroll-with-frozen-identity-column); `min-width:0` universal. | Operators often want the dense scrollable grid; over-correction. |
| **Replace the kitchen with Storybook?** | **Keep both** (registry SSOT, two renderers). | Re-homing Phase-189/190 drift tests = churn + regression risk for zero upside. |

---

## Implications for Roadmap

### Phase-mapped findings (Phases 193–200)

| Phase | Lands these findings |
|-------|----------------------|
| **193** Research, re-baseline & pattern lock | Adopt the **three pattern specs** (SPEC-OVERVIEW/LIST/DETAIL) verbatim as design contracts. Stand up **PhoenixStorybook** (dep + env-guarded backend + `Code.ensure_loaded?`-guarded sibling-scope wrap + registry generator + asset serving). Extend Phase-187 baseline with `surface_type:"page-flow"` cells. Add the **3 new source guards**. Run the **spikes** (overlay portal-vs-`<dialog>`, `data-theme` dark-shim, `inert` browser-floor). |
| **194** Exemplar A — Dashboard | *Refine, don't rebuild* the four-zone overview; apply the same grammar to Recovery (`hero pair → at-risk queue → trend`). |
| **195** Exemplar B — Subscription detail | Instantiate **summary-then-drill + ≤2 primary + overflow action menu + side-drawer + lazy plumbing**; delete the duplicate related card; flatten card-in-card; build the **action-menu primitive** + side-drawer action hosting. ~25 zones → ~6 bands. |
| **196** Exemplar C — Subscriptions list + `PageHeader` | Table-first, chips+count+clear-all, work-queue default, row→card mobile degradation; **extract shared `PageHeader`**; truncation/`min-width:0` discipline. |
| **197** Propagate LIST | Apply locked list spec + `PageHeader` to the 8 other list pages (customers · invoices · payments · coupons · promotion-codes · webhooks · events · connect). |
| **198** Propagate DETAIL + overview | Apply summary-then-drill to the 8 other detail pages + Recovery/Campaign. |
| **199** Cross-cutting interaction/overlay correctness | The **canonical overlay primitive**: scroll-lock, portal, `inert`, dismissal contract, drawer geometry, origin-aware popovers, no-hover-on-non-interactive. Multi-step **fixture stress**. Full **brand-voice microcopy** sweep. Audit transformed/filtered ancestors that re-root `position:fixed`. |
| **200** Idempotent verification & sign-off | Re-score all cells (component + group + page-flow) viewport × theme × state; forward-only ≥ baseline, **zero regressions**; **axe-core** over rendered stories; Storybook complete (all families + 8 groups); no-FOUC/persistence/system-emulation checks; adversarial multi-lens judge + maintainer photographic/interaction sign-off. |

### Candidate acceptance criteria by requirement category

(Categories named in PROJECT.md / the v1.54 plan.)

- **RES (research/baseline):** three archetype pattern specs locked as design contracts; Phase-187 baseline extended with `surface_type:"page-flow"` cells over ~20 routes (additive sibling `baseline.page-flow.cells.json` recommended for provenance).
- **STY (Storybook):** `phoenix_storybook` is `only:[:dev,:test]`; host `:prod` **and** host `:dev` compile of `examples/accrue_host` succeeds with the dep absent and exposes no `/dev/storybook` route (proves the `Code.ensure_loaded?` guard); every registry family + all 8 group contracts have a generated story; stories render in both color modes against the **shipped `ax-*` bundle** (not a Tailwind rebuild); kitchen + Phase-189/190 drift tests stay green.
- **STY/source guards:** spacing-literal guard (no raw px on padding/margin/gap outside allowlist); `:focus-visible` guard (focus styling targets `:focus-visible`); truncation-without-`min-width:0` guard.
- **EXE (exemplars):** Dashboard refined to the four-zone spec + Recovery re-grammared; Subscription detail = summary-then-drill ~6 bands (duplicate card deleted, card-in-card flattened); Subscriptions list = table-first + `PageHeader` + 4 distinct states.
- **PGH (`PageHeader`):** one shared `PageHeader(breadcrumb, title, stat-strip, actions, filter-toolbar)` adopted by all list pages; slot contract locked **before** Phase-197 propagation (avoid 8-page re-churn).
- **PRP (propagation):** all 8 remaining list pages conform to SPEC-LIST; all remaining detail/analytics pages conform to SPEC-DETAIL.
- **IXN (interaction/overlay):** the 12 ARCHITECTURE ACs — (1) scroll-lock ref-counted + iOS + no gutter jump; (2) portal/stacking, never painted behind scrim, always hit-testable; (3) dismissal backdrop+Escape same event, double-toggle settles; (4) `inert` background; (5) drawer desktop-edge-dock / mobile-sheet correct axis; (6) origin-aware popovers; (7) no hover/cursor on non-interactive; (8) focus into-panel/trap/restore, instant focus ring; (9) duration band ≤240ms held; (10) reduced-motion preserved (extend `reduced-motion.spec.js`); (11) no new motion tokens unless justified ≤300ms; (12) list first-load crossfade only, no per-row stagger. Plus floating-in-viewport-bounds + conditional-affordance + theme-no-FOUC checks.
- **FIX (fixture-stress):** multi-step workflows + long-content/edge fixtures surface squish, clipping, overflow on real seeded (deterministic) data.
- **CPY (copy):** full brand-voice microcopy sweep; distinct first-run-empty vs filtered-empty copy; "Change"/action labels with visually-hidden context.
- **VER (verification):** merged `regressions.ndjson` shows **zero regressions** vs the union baseline across component + group + page-flow cells; axe color-contrast + name/role pass over rendered stories; maintainer sign-off ACCEPT.

### Research flags

- **Needs spike (Phase 193):** overlay portal-vs-native-`<dialog>` decision (+ Playwright hit-test); `data-theme` dark-shim selector specificity vs `.psb-sandbox` (color-mode bridge, MEDIUM); Storybook asset-serving without Tailwind (MEDIUM); `inert` vs `aria-hidden`+focusguard given the browser floor.
- **Standard / well-documented (lighter touch):** Dashboard refinement (194 — keep existing grammar); LIST/DETAIL **propagation** phases (197/198 — apply already-locked specs); the 3 new source guards (mechanical, mirror proven FND-01/MOT-01 shape).

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Storybook adoption (pin, leak-proof mount, registry generator) | HIGH | hex.pm/mix.exs verified; in-repo Mailglass precedent near-identical; `variations/0` is an ordinary function |
| Color-mode `data-theme` bridge + no-Tailwind asset serving | MEDIUM | `color_mode` documented; class→attribute shim is known-good CSS but unexercised here — budget a Phase-193 spike |
| Overlay failure-mode root causes (scroll-lock, transformed ancestor, inert) | HIGH | Cross-checked jayfreestone/Ben Frain/CSS-Tricks/Stripe-army + first-hand repo reading (no scroll-lock confirmed by grep; drawer geometry confirmed) |
| Motion principles (Kowalski enter/easing/duration/composite/reduced-motion) | HIGH | Multiple primary sources incl. his own article already cited in `motion.md` |
| Kowalski exact constants (velocity 0.11, 500ms Vaul, origin values) | MEDIUM | Course digests/skill refs — directional, treat as guidance not law |
| Page-archetype IA (overview/list/detail disclosure) | HIGH | Converging NN/g + Baymard + Smashing + PatternFly + GOV.UK; matches shipped v1.51 decisions |
| Forward-only page-flow QA extension | HIGH | Extends an already-shipped in-repo harness; `surface_type` discriminator already present |
| Per-persona emphasis / user loves-hates | MEDIUM | Personas well-defined (v1.51); ordering claims reasoned not user-tested; HN/Reddit threads thin |

**Overall confidence:** HIGH.

### Gaps to Address

- **Side-drawer + action-menu primitives:** no overflow/dropdown action-menu primitive is confirmed in the read set; confirm `detail_drawer.ex` can host action forms + step-up handoff without re-introducing modal-behind-scrim. Build in Phase 195, land in Storybook. (Phase 195/199.)
- **`PageHeader` slot contract:** lock exact slots before Phase-197 propagation. (Phase 196.)
- **Overlay primitive decision** (portal vs `<dialog>`) + theming-bridge + `inert`-floor: resolve via Phase-193 spikes before exemplar work.
- **Transformed-ancestor audit:** confirm no LiveView page wrapper applies `transform`/`filter`/`contain` that re-roots `position:fixed` shells. (Phase 199.)
- **Baseline storage:** additive sibling `baseline.page-flow.cells.json` (recommended) vs in-place extension — decide in Phase 193.
- **Empirical loves/hates:** optional targeted HN/Reddit pull to harden the MEDIUM feedback section.

## Sources

### Primary (HIGH confidence)
- **In-repo first-hand:** `subscription_live.ex` (1,234-LOC info-dump), `dashboard_live.ex` (exemplary overview), `nav.ex`, `router.ex` (Mailglass sibling-scope precedent), `dev/component_registry.ex`, `dev/component_kitchen_live.ex`, `guides/motion.md`, `assets/css/theme.css` + `app.css`, `assets/js/hooks/focus_trap.js`, `detail_drawer.ex`, `step_up_auth_modal.ex`, `playwright.config.js` + `e2e/admin-page-flow-phase191.spec.js`, `baseline.cells.json` (no body scroll-lock confirmed by grep; drawer geometry + cell schema confirmed)
- hex.pm / hexdocs phoenix_storybook 1.2.0 (version, deps, `color_modes`, story shape)
- Emil Kowalski — "Great animations" (emilkowal.ski/ui/great-animations), Vaul/Sonner, design-eng skill
- GOV.UK Design System (summary-list, task-list, one-thing-per-page); NN/g (tabs, accordions, mobile tables); Baymard (avoid horizontal tabs); Smashing (modal-vs-page decision tree); PatternFly (toolbar/overflow menu)
- iOS body scroll-lock (jayfreestone, Ben Frain, CSS-Tricks, Stripe-army); CSS stacking-context (freecodecamp, playfulprogramming); flex/grid squish (CSS-Tricks, bigbinary)

### Secondary (MEDIUM confidence)
- EightShapes spacing model; Atlassian/Carbon spacing; datatables/uxpatterns responsive tables; Sara Soueidan focus indicators; disabled-button contrast (design-bootcamp); dark-mode a11y (accessibilitychecker, DubBot); Eleken/Stripe/Linear operator-UX commentary; Storybook visual+a11y testing docs

### Tertiary (LOW confidence)
- Wildnet / Tableau / GridRebels / raw.studio / databox / excited.agency dashboard-UX writeups (synthesized, validate against rubric)

---
*Research completed: 2026-06-24*
*Ready for roadmap: yes*
