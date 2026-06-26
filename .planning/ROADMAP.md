# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass [SHIPPED 2026-06-04 — see milestones/v1.51-ROADMAP.md] (IA + Systematic Polish)** — Phases 174-179 (planning 2026-06-03; second, depth-oriented pass on the same `accrue_admin` surface; persona-driven IA reshape + token gap-closure + systematic rubric uplift + motion + seed expressiveness + screenshot-driven visual-QA; no new billing primitives)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14; brand audit + DNA lock, SVG logo tournament, design tokens, voice/copy, standalone HTML brand book; no billing primitives) — [archive](milestones/v1.52-ROADMAP.md)
- ✅ **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (shipped 2026-06-20; fractal design-system audit foundations→primitives→groups→pages→flows + interaction-defect remediation + component-level systematization + idempotent only-forward verification on `accrue_admin`; no new billing primitives, no breaking API/route changes, no Tailwind migration) — [archive](milestones/v1.53-ROADMAP.md)
- 🔵 **v1.54 Admin UI Page-Level Streamlining & Storybook** — Phases 193-200 (opened 2026-06-24; page-level excellence on `accrue_admin` — lock 3 archetype pattern specs, nail one gold-standard exemplar per archetype then propagate, fix firsthand-observed page-composition usability defects via one canonical overlay primitive + a rendered state-matrix gate, adopt PhoenixStorybook dev/test-only; no new billing primitives, no breaking API/route changes, no Tailwind migration, core stays LiveView-runtime-free)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.54 Admin UI Page-Level Streamlining & Storybook is the currently-open milestone — a quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` operator UI (continues v1.53's design-system hardening). It is **not** a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration; core `accrue` stays LiveView-runtime-free — PhoenixStorybook is `accrue_admin` dev/test-only). Reopen justification (recorded in `PROJECT.md`): explicit strategy change (page-level design quality of the flagship adopter-facing surface elevated to a strategic priority — same class as v1.50/v1.51/v1.52/v1.53) **plus firsthand-observed page-level usability defects** in the running demo (modal-behind-scrim, scroll traps, floating/mispositioned overlays, won't-dismiss, hover-on-non-interactive empty states, disabled-looks-enabled — concrete failure evidence).

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

### v1.54 Admin UI Page-Level Streamlining & Storybook (Phases 193-200) — ACTIVE (deps strictly linear 193→194→195→196→197→198→199→200)

**Posture:** Quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` operator UI — **not** a broad feature milestone. Takes the surface from *interaction-correct building blocks* (v1.53) to *page-level excellence*: drive every page from its operator job-to-be-done, eliminate the "info dump" density, lock three archetype pattern specs (overview / list / detail), nail one gold-standard exemplar per archetype, then propagate the locked patterns across all ~20 pages. The structural backbone is two things: (a) one hardened canonical overlay primitive every modal/drawer/popover routes through; and (b) a rendered state-matrix gate — PhoenixStorybook (dev/test-only) + axe-core + a Playwright interaction battery, folded into v1.53's forward-only cell-baseline as new `surface_type:"page-flow"` cells under the unchanged `regressions.ndjson` zero-regression rule.

**Guardrails (honored):** scope is the `accrue_admin` operator UI only — no `accrue_portal` work; no new billing primitives, domain features, or breaking API/route changes (component public APIs stay backward-compatible; internal moves ship with redirects); no Tailwind migration (custom `ax-*` CSS + tokens stay SSOT); core `accrue` stays LiveView-runtime-free (PhoenixStorybook is `accrue_admin` dev/test-only and must not reach adopter runtime); no pixel-diff / SaaS visual-regression (TOOL-02 stays deferred — the scored-cell forward-only gate is the mechanism); the in-app `/dev/components` kitchen stays as a second renderer backing the Phase-189/190 drift tests.

**Dependency shape:** strictly **linear** — 193 → 194 → 195 → 196 → 197 → 198 → 199 → 200. Foundations + the three locked pattern specs (193) must precede exemplar work; the three exemplars (194 Dashboard / 195 Subscription detail / 196 Subscriptions list + PageHeader) lock the patterns that propagation (197 LIST / 198 DETAIL) applies; cross-cutting overlay correctness + fixture stress + microcopy (199) and idempotent verification + sign-off (200) come last. **Cross-phase primitive dependency:** the canonical overlay primitive is decided as a spike in 193 (portal-vs-`<dialog>`, `inert` floor, theming bridge) and the action-menu/side-drawer action-hosting groundwork is built in 195 to serve the detail exemplar; the **full** cross-cutting overlay sweep (scroll-lock, portal, `inert`, dismissal contract, drawer geometry, origin-aware popovers, transformed-ancestor audit) lands in 199 and is verified in 200.

- [x] **Phase 193: Research, re-baseline & pattern lock** — Lock the three archetype pattern specs (SPEC-OVERVIEW/LIST/DETAIL) as design contracts, extend the Phase-187 baseline with `surface_type:"page-flow"` cells, stand up PhoenixStorybook (dev/test-only) + run the four spikes, add the three new CSS source guards. (completed 2026-06-25)
- [x] **Phase 194: Exemplar A — Dashboard** — Refine the four-zone overview (refine-not-rebuild) and re-grammar Recovery analytics to `hero metric pair → at-risk work-queue → trend`. (completed 2026-06-26)
- [x] **Phase 195: Exemplar B — Subscription detail** — Convert the worst info-dump (~25 always-visible zones → ~6 bands) to summary-then-drill + ≤2 primary actions + an overflow action-menu hosting actions in a side-drawer; build the action-menu primitive + side-drawer action hosting. (completed 2026-06-26)
- [ ] **Phase 196: Exemplar C — Subscriptions list + PageHeader** — Convert the Subscriptions list to the table-first list spec (chips + count + clear-all, work-queue default, four distinct states) and extract + lock the shared `PageHeader` component slot contract.
- [ ] **Phase 197: Propagate LIST** — Conform all 8 remaining list pages to SPEC-LIST, adopt `PageHeader`, with per-page JTBD microcopy + four-state coverage.
- [ ] **Phase 198: Propagate DETAIL + analytics** — Conform all remaining detail/analytics pages to SPEC-DETAIL / the overview spec.
- [ ] **Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy** — Land the canonical overlay primitive (scroll-lock, portal, `inert`, dismissal, geometry, origin-aware popovers, transformed-ancestor audit), exercise multi-step + edge fixtures, and run the full brand-voice microcopy sweep.
- [ ] **Phase 200: Idempotent verification & sign-off** — Re-score all cells (component + group + page-flow) viewport × theme × state with zero regressions; complete + verify Storybook story coverage and theming; axe-core + no-FOUC/persistence/system-emulation checks; adversarial multi-lens judge + maintainer sign-off.

Coverage: 23/23 requirements mapped (each REQ-ID → exactly one phase). Per-phase counts: 193→5 · 194→1 · 195→2 · 196→2 · 197→1 · 198→1 · 199→7 · 200→4 = 23. Design source: `.planning/research/SUMMARY.md` (synthesizing FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md). Reuses v1.53's forward-only machinery (rubric `187-RUBRIC.md`, `baseline.cells.json`, `regressions.ndjson` zero-regression gate).

## Phase Details

### Phase 193: Research, re-baseline & pattern lock

**Goal**: The three archetype pattern specs are locked as design contracts, the forward-only baseline can see composed pages, PhoenixStorybook is stood up dev/test-only with the four spike decisions recorded, and the three new source guards are merge-blocking.
**Depends on**: Nothing (first phase of v1.54; builds on shipped v1.53 baseline)
**Requirements**: RES-01, RES-02, RES-03, RES-04, STY-01
**Success Criteria** (what must be TRUE):

  1. A maintainer can open and read three locked archetype pattern specs (SPEC-OVERVIEW / SPEC-LIST / SPEC-DETAIL) and use each as the design contract every page is built or conformed against.
  2. The forward-only zero-regression gate now scores `surface_type:"page-flow"` cells over the ~20 admin routes (additive sibling `baseline.page-flow.cells.json`), reusing the Phase-191 page-flow Playwright driver and the 12-dimension rubric.
  3. A host dev compile of `examples/accrue_host` succeeds with `phoenix_storybook` absent and exposes no `/dev/storybook` route, proving the `Code.ensure_loaded?`-guarded sibling-scope mount has zero adopter-runtime leak.
  4. Each of the four Phase-193 spikes (overlay portal-vs-`<dialog>` with a Playwright hit-test; Storybook `data-theme` dark-mode shim; `inert` vs `aria-hidden` browser-floor; Storybook asset-serving without a Tailwind rebuild) is resolved with a recorded decision.
  5. Three new CSS source guards (spacing-literal ban, `:focus-visible` enforcement, truncation-without-`min-width:0`) ship in `verify_package_docs.sh`/CI and fail on a planted violation.

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 193-01-PLAN.md — Three archetype spec guides (spec-overview/list/detail) + mix.exs wiring (dep, elixirc_paths, extras, groups)
- [x] 193-02-PLAN.md — Forward-only baseline extension: additive sibling baseline.page-flow.cells.json (~9,504 page-flow cells)
- [x] 193-03-PLAN.md — Overlay portal spike: four D-05 Playwright proofs + recorded decision (RES-03 Spike A)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 193-04-PLAN.md — Storybook scaffold: storybook.ex backend + router wrap + assets.ex extension + RegistryStory + button.story.exs + committed bundles + D-17 spike decisions
- [x] 193-05-PLAN.md — CSS source guards (3) + spec doc-needles (6) + PackageDocsVerifierTest seed_tmp_dir! extension + 3 negative guard tests

**UI hint**: yes

### Phase 194: Exemplar A — Dashboard

**Goal**: The Dashboard is the locked gold-standard for the overview archetype, and Recovery analytics reads as a work-queue, not a chart wall.
**Depends on**: Phase 193 (SPEC-OVERVIEW locked; page-flow baseline in place)
**Requirements**: EXE-01
**Success Criteria** (what must be TRUE):

  1. An operator landing on the Dashboard sees the locked four-zone overview grammar — attention-rail (exceptions-only, prominent healthy empty-state) → verb task-launchers (visible ⌘K) → demoted clickable KPIs → recent activity — refined, not rebuilt.
  2. The Recovery analytics page is re-grammared to `hero metric pair → at-risk work-queue table → supporting trend` and surfaces at-risk work first rather than a wall of charts.
  3. Both pages score ≥ their page-flow baseline cells across viewport × theme × state with zero regressions.

**Plans**: 4 plans
**Wave 1**

- [x] 194-01-PLAN.md — Dashboard additive data-ax-* markers + non-interactive empty-rail hero + light KPI demotion CSS + rebuilt bundle
- [x] 194-02-PLAN.md — Recovery re-grammar (AtRiskTable above FunnelChart) + honest zone markers
- [x] 194-03-PLAN.md — Empty-rail non-interactivity source guard (Guard D) + D-08 ExUnit mirror

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 194-04-PLAN.md — SPEC-OVERVIEW invariant assertion e2e spec + SC3 scoring confirmation (Open Q-B)

**UI hint**: yes

### Phase 195: Exemplar B — Subscription detail

**Goal**: The worst info-dump page becomes the gold-standard for the object-detail archetype, and the reusable action-menu + side-drawer action-hosting primitives exist for propagation.
**Depends on**: Phase 194 (overview exemplar shipped; SPEC-DETAIL locked in 193)
**Requirements**: EXE-02, IXN-01
**Success Criteria** (what must be TRUE):

  1. The Subscription detail page is converted from ~25 always-visible flat zones to ~6 bands: a GOV.UK summary-list header with row-level "Change", ≤2 primary actions plus an overflow action-menu, collapsible drill sections (most-relevant open), one related-resources strip, and lazy activity/raw-JSON.
  2. Operator actions open in a side-drawer (destructive actions hand off to a step-up modal) hosted by the canonical overlay primitive — never reintroducing modal-behind-scrim — and the action-menu + side-drawer primitives land in Storybook.
  3. The duplicate related-resources card is deleted and card-in-card double-border nesting is flattened.
  4. The overlay primitive backing the side-drawer demonstrably scroll-locks, portals to a body-level root so it is never painted behind its scrim, marks the background `inert`, and dismisses cleanly on backdrop-click + Escape (the IXN-01 contract, instantiated here for the detail exemplar and swept across all pages in Phase 199).

**Plans**: 8 plans
**Wave 0 — validation scaffolding**

- [x] 195-01-PLAN.md — Overlay/action-hosting RED coverage: component tests, scroll-lock JS tests, and Phase 195 Playwright script
- [x] 195-02-PLAN.md — Subscription detail RED coverage: six-band LiveView contract, provider gating, copy fixture, and StepUp preservation

**Wave 1**

- [x] 195-03-PLAN.md — Canonical Overlay component API, body-level `#ax-overlay-root`, and drawer/modal wrapper migration

**Wave 2**

- [x] 195-04-PLAN.md — Overlay JS behavior: ref-counted scroll lock, inert background, FocusTrap composition, and committed JS bundle

**Wave 3**

- [x] 195-05-PLAN.md — Overlay CSS geometry: tokenized layers, desktop drawer, mobile bottom sheet, and committed CSS bundle

**Wave 4**

- [x] 195-06-PLAN.md — Reusable DETAIL primitives: `Detail.summary_list/1`, `DropdownMenu.action_menu/1`, primitive CSS, and component coverage

**Wave 5**

- [x] 195-07-PLAN.md — Subscription detail conversion: six bands, drawer-hosted action forms, copy relabels, one related strip, and lazy Activity/JSON

**Wave 6**

- [x] 195-08-PLAN.md — Storybook stories for primitives/exemplar and final Phase 195 Playwright/page-flow gate

**UI hint**: yes

### Phase 196: Exemplar C — Subscriptions list + PageHeader

**Goal**: The Subscriptions list is the locked gold-standard for the list archetype, and the shared `PageHeader` slot contract is extracted and locked before any propagation.
**Depends on**: Phase 195 (detail exemplar shipped; SPEC-LIST locked in 193)
**Requirements**: EXE-03, PGH-01
**Success Criteria** (what must be TRUE):

  1. The Subscriptions list is table-first with row→card mobile degradation, persistent filter chips + result count + clear-all, a work-queue default ("All" one chip away), and four visually-distinct states (populated / first-run-empty / filtered-empty / loading-skeleton).
  2. A shared `AccrueAdmin.Components.PageHeader` (breadcrumb + title + stat-strip + actions + filter-toolbar slots) is extracted with its slot contract locked, proven on the Subscriptions list, and rendering exactly one `<h1>` per page.
  3. Identity·state·money·time columns are prioritized with plumbing IDs de-emphasized, and truncation uses `min-width:0` discipline (the new guard passes).

**Plans**: TBD
**UI hint**: yes

### Phase 197: Propagate LIST

**Goal**: Every remaining list page is internally consistent with the locked list spec and adopts the shared `PageHeader`.
**Depends on**: Phase 196 (SPEC-LIST exemplar + `PageHeader` slot contract locked)
**Requirements**: PRP-01
**Success Criteria** (what must be TRUE):

  1. All 8 remaining list pages (customers · invoices · payments · coupons · promotion-codes · webhooks · events · connect) conform to SPEC-LIST — table-first, chips + count + clear-all, work-queue default, row→card degradation.
  2. Every one of those pages adopts `PageHeader` and renders exactly one `<h1>`.
  3. Each page carries per-page JTBD microcopy and covers all four list states (populated / first-run-empty / filtered-empty / loading).

**Plans**: TBD
**UI hint**: yes

### Phase 198: Propagate DETAIL + analytics

**Goal**: Every remaining detail and analytics page is internally consistent with the locked detail/overview specs.
**Depends on**: Phase 197 (LIST propagation complete; SPEC-DETAIL exemplar locked in 195)
**Requirements**: PRP-02
**Success Criteria** (what must be TRUE):

  1. All remaining detail pages (customer · invoice · charge · coupon · promotion-code · connect-account · webhook · event) conform to SPEC-DETAIL — summary-then-drill, ≤2 primary + overflow menu, side-drawer actions, one related strip, lazy timeline/JSON.
  2. The Recovery and Campaign analytics pages conform to the locked overview spec (work-queue first, no chart wall).
  3. Tabs appear only for peer record-sets (e.g. Customer-360 Subscriptions/Invoices/Payments), never hiding primary state or critical actions behind a horizontal tab.

**Plans**: TBD
**UI hint**: yes

### Phase 199: Cross-cutting interaction/overlay correctness + fixture stress + microcopy

**Goal**: One canonical overlay primitive backs every modal/drawer/popover across all pages with structurally-correct behavior, edge fixtures surface no squish/clipping/overflow, and all page-level copy speaks one brand voice.
**Depends on**: Phase 198 (all pages conformed; overlay primitive groundwork from 195)
**Requirements**: IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01
**Success Criteria** (what must be TRUE):

  1. Every modal/drawer routes through the single canonical overlay primitive — ref-counted iOS-safe body scroll-lock (no scrollbar-gutter jump), body-level portal so an overlay is never painted behind its scrim and is always hit-testable, `inert`/`aria-hidden` background, and a unified backdrop+Escape dismissal that settles cleanly on rapid double-toggle (IXN-01).
  2. Overlay motion is geometry-correct — drawer edge-docks on desktop (translateX from the right), is a bottom-sheet on mobile (translateY), popovers are origin-aware, focus moves into/traps/restores with an instant focus ring, the ≤240ms band holds, and reduced-motion is preserved (extending `reduced-motion.spec.js`) (IXN-02); non-interactive empty-state heroes carry no hover/cursor, disabled looks disabled, absent affordances are hidden, floats stay in viewport bounds, and theme switching has no flash-of-wrong-theme with correct persistence + system emulation (IXN-03); and a transformed/filtered/`contain` ancestor audit confirms no LiveView page wrapper re-roots a `position:fixed` shell (IXN-04).
  3. Deterministic multi-step workflow fixtures (list → detail → nested detail → drill-down → back) exercise focus and scroll integrity across every transition (FIX-01), and long-content/boundary fixtures (zero-decimal currency, past-due dunning, very long names, overflow) surface no squish/clipping/overflow on real seeded data and remain idempotent (FIX-02).
  4. A full brand-voice microcopy sweep covers all page-level copy with distinct first-run-empty vs filtered-empty messages and action/"Change" labels carrying visually-hidden context that names the object and the next useful action (CPY-01).

**Plans**: TBD
**UI hint**: yes

### Phase 200: Idempotent verification & sign-off

**Goal**: The whole surface is proven forward-only ≥ baseline with zero regressions, Storybook story coverage and theming are complete and verified, accessibility/no-FOUC checks are green, and the milestone has explicit ACCEPT sign-off.
**Depends on**: Phase 199 (all correctness + copy work landed)
**Requirements**: VER-01, VER-02, VER-03, STY-02, STY-03
**Success Criteria** (what must be TRUE):

  1. The merged `regressions.ndjson` shows zero regressions versus the union baseline (component + group + page-flow cells) across viewport × theme × state — every inherited cell scores ≥ its baseline (VER-01).
  2. Every `ComponentRegistry` family and all 8 group contracts have a generated (registry-driven) story with the registry staying SSOT and the `/dev/components` kitchen + Phase-189/190 drift tests green (STY-02), and stories render correctly in both color modes against the shipped committed `ax-*` bundle with the `html.accrue-admin[data-theme]` scoping bridged into Storybook's sandbox (STY-03). (Storybook is scaffolded in Phase 193; story completeness + theming are completed/verified here.)
  3. axe-core color-contrast + name/role passes over rendered stories and page-flow routes; no-FOUC/persistence/system-emulation checks are green; and the reduced-motion + group-contract + a11y guardrail suites pass in CI (VER-02).
  4. An adversarial multi-lens judge (correctness · a11y · brand · interaction) plus a maintainer photographic/interaction checkpoint sign off ACCEPT at the final boundary (VER-03).

**Plans**: TBD
**UI hint**: yes

<details>
<summary>✅ v1.53 Admin UI Design-System Hardening (Phases 187-192) — SHIPPED 2026-06-20 (deps strictly linear 187→188→189→190→191→192)</summary>

**Posture:** Quality / interaction-correctness / design-system investment in the already-shipped `accrue_admin` operator UI — **not** a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration). Took the admin UI from *considered* (v1.51) to *interaction-correct and component-systematic*: fractal design-system audit (foundations → primitives → groups → pages → flows), behavioral interaction-defect remediation, component-level systematization, and an idempotent only-forward verification loop. Discharged v1.51's open photographic-sign-off tech-debt.

- [x] Phase 187: Audit & Baseline (5/5 plans) — completed 2026-06-15 (VER-01)
- [x] Phase 188: Foundations hardening (8/8 plans) — completed 2026-06-20 (FND-01..06)
- [x] Phase 189: Primitive & form components + component lab (7/7 plans) — completed 2026-06-18 (CMP-01..05)
- [x] Phase 190: Navigation, data-display & meta-component cohesion (6/6 plans) — completed 2026-06-18 (GRP-01..04)
- [x] Phase 191: Page & flow interaction pass + fixture stress + microcopy (7/7 plans) — completed 2026-06-19 (IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02)
- [x] Phase 192: Idempotent verification & sign-off (6/6 plans) — completed 2026-06-20 (VER-02..04)

Coverage: 33/33 requirements. Final scorecard ≥ Phase-187 baseline across 21,276 cells with 0 regressions; maintainer sign-off ACCEPT.

Full details: [v1.53 roadmap archive](milestones/v1.53-ROADMAP.md)

</details>

<details>
<summary>✅ v1.52 Brand System (Phases 180-186) — SHIPPED 2026-06-14 (deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)</summary>

**Posture:** Brand/DX investment in adopter-facing presentation surfaces (README, Hex.pm, HexDocs, social previews, admin UI identity) — **not** a broad feature milestone (no new billing primitives). Reopen decision recorded in `PROJECT.md`; justification class same as v1.50/v1.51.

- [x] Phase 180: Brand Audit & DNA Lock (4/4 plans) — completed 2026-06-12 (AUD-01..03)
- [x] Phase 181: SVG Pipeline + Tournament Round 1 — Divergent (7/7 plans) — completed 2026-06-13 (LOGO-01, LOGO-02)
- [x] Phase 182: Tournament Convergent Refinement (3/3 plans) — completed 2026-06-13 (LOGO-03); winner locked: R2-7 two-tone
- [x] Phase 183: Logo System Production (4/4 plans) — completed 2026-06-13 (LOGO-04)
- [x] Phase 184: Design Tokens & Specimens (5/5 plans) — completed 2026-06-14 (TOK-01..03)
- [x] Phase 185: Voice, Microcopy & Marketing Copy (3/3 plans) — completed 2026-06-14 (COPY-01, COPY-02)
- [x] Phase 186: HTML Brand Book Assembly & Quality Gate (3/3 plans) — completed 2026-06-14 (BOOK-01, BOOK-02)

Full details: [v1.52 roadmap archive](milestones/v1.52-ROADMAP.md)

</details>

<details>
<summary>✅ v1.51 Admin UI: Depth Pass (Phases 174-179) — SHIPPED 2026-06-04 (deps A→B→C→{D,E}→F)</summary>

**Posture:** Quality / adopter-facing operator-DX investment in the already-shipped `accrue_admin` surface — **not** a broad feature milestone (no new billing primitives). The second, depth-oriented pass on v1.50's foundation: re-map IA from entity-shaped to job/persona-shaped, close design-token gaps, lift the under-iterated screen tail to one rubric baseline, add restrained motion, make seed data express every state, and prove it with a screenshot-driven visual-QA loop.

Full details: [v1.51 roadmap archive](milestones/v1.51-ROADMAP.md)

</details>

<details>
<summary>✅ v1.50 Admin UI Foundation (Phases 167-173) — SHIPPED 2026-06-02 (PR #32; archived 2026-06-03)</summary>

- [x] Phase 167: Design Tokens & Motion Foundation — completed 2026-06-02 (AUI-01)
- [x] Phase 168: Typography & Icon System — completed 2026-06-02 (AUI-02)
- [x] Phase 169: IA — Home, Nav & Search — completed 2026-06-02 (AUI-03)
- [x] Phase 170: Cross-Screen Threading & Microcopy — completed 2026-06-02 (AUI-04)
- [x] Phase 171: Shared Detail Components & Refactor — completed 2026-06-02 (AUI-05)
- [x] Phase 172: Seed Enrichment & Component Kitchen — completed 2026-06-02 (AUI-06)
- [x] Phase 173: Rubric Audit & Visual/A11y Coverage — completed 2026-06-02 (AUI-07)

Full details: [v1.50 roadmap archive](milestones/v1.50-ROADMAP.md)

</details>

<details>
<summary>✅ v1.49 Realistic Demo App & Adoption Evidence (Phases 163-166) — SHIPPED 2026-06-02</summary>

- [x] Phase 163: Realistic Domain & Rich Seeds (1/1 plan) — completed 2026-06-01
- [x] Phase 164: Docker DX & Optimized Caching (2/2 plans) — completed 2026-06-01
- [x] Phase 165: E2E Automation & Shift-Left CI (4/4 plans) — completed 2026-06-02
- [x] Phase 166: Adoption DX Docs (3/3 plans) — completed 2026-06-02

Full details: [v1.49 roadmap archive](milestones/v1.49-ROADMAP.md)

</details>

<details>
<summary>✅ v1.48 Release Readiness + Stable Core Posture (Phases 159-162) — SHIPPED 2026-06-01</summary>

- [x] Phase 159: Linked Release Readiness + Publish Proof (2/2 plans) — completed 2026-06-01
- [x] Phase 160: Stable-Core Public Positioning (3/3 plans) — completed 2026-05-31
- [x] Phase 161: Backlog Anchor Closure + Pause Rule (1/1 plan) — completed 2026-06-01
- [x] Phase 162: Close gap: REL-01/REL-03 — linked release proof (4/4 plans) — completed 2026-06-01

Full details: [v1.48 roadmap archive](milestones/v1.48-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 167. Design Tokens & Motion Foundation | v1.50 | ✓ | Complete | 2026-06-02 |
| 168. Typography & Icon System | v1.50 | ✓ | Complete | 2026-06-02 |
| 169. IA — Home, Nav & Search | v1.50 | ✓ | Complete | 2026-06-02 |
| 170. Cross-Screen Threading & Microcopy | v1.50 | ✓ | Complete | 2026-06-02 |
| 171. Shared Detail Components & Refactor | v1.50 | ✓ | Complete | 2026-06-02 |
| 172. Seed Enrichment & Component Kitchen | v1.50 | ✓ | Complete | 2026-06-02 |
| 173. Rubric Audit & Visual/A11y Coverage | v1.50 | ✓ | Complete | 2026-06-02 |
| 174. A — Design-System Gap Closure & Token Completeness | v1.51 | 7/7 | Complete | 2026-06-04 |
| 175. B — Persona-Driven IA Spine | v1.51 | 7/7 | Complete | 2026-06-04 |
| 176. C — Systematic Per-Screen Rubric Uplift | v1.51 | 6/6 | Complete | 2026-06-04 |
| 177. D — Motion & Micro-interaction Design | v1.51 | 6/6 | Complete | 2026-06-04 |
| 178. E — Seed Expressiveness & State Coverage | v1.51 | 4/4 | Complete | 2026-06-04 |
| 179. F — Screenshot-Driven Visual QA Loop & Sign-off | v1.51 | 3/3 | Complete | 2026-06-05 |
| 180. Brand Audit & DNA Lock | v1.52 | 4/4 | Complete | 2026-06-12 |
| 181. SVG Pipeline + Tournament Round 1 — Divergent | v1.52 | 7/7 | Complete | 2026-06-13 |
| 182. Tournament Convergent Refinement | v1.52 | 3/3 | Complete | 2026-06-13 |
| 183. Logo System Production | v1.52 | 4/4 | Complete | 2026-06-13 |
| 184. Design Tokens & Specimens | v1.52 | 5/5 | Complete | 2026-06-14 |
| 185. Voice, Microcopy & Marketing Copy | v1.52 | 3/3 | Complete | 2026-06-14 |
| 186. HTML Brand Book Assembly & Quality Gate | v1.52 | 3/3 | Complete | 2026-06-14 |
| 187. Audit & Baseline | v1.53 | 5/5 | Complete    | 2026-06-15 |
| 188. Foundations hardening | v1.53 | 8/8 | Complete    | 2026-06-20 |
| 189. Primitive & form components + component lab | v1.53 | 7/7 | Complete   | 2026-06-18 |
| 190. Navigation, data-display & meta-component cohesion | v1.53 | 6/6 | Complete | 2026-06-18 |
| 191. Page & flow interaction pass + fixture stress + microcopy | v1.53 | 7/7 | Complete | 2026-06-19 |
| 192. Idempotent verification & sign-off | v1.53 | 6/6 | Complete   | 2026-06-20 |
| 193. Research, re-baseline & pattern lock | v1.54 | 5/5 | Complete    | 2026-06-25 |
| 194. Exemplar A — Dashboard | v1.54 | 4/4 | Complete    | 2026-06-26 |
| 195. Exemplar B — Subscription detail | v1.54 | 8/8 | Complete    | 2026-06-26 |
| 196. Exemplar C — Subscriptions list + PageHeader | v1.54 | 0/? | Not started | - |
| 197. Propagate LIST | v1.54 | 0/? | Not started | - |
| 198. Propagate DETAIL + analytics | v1.54 | 0/? | Not started | - |
| 199. Cross-cutting interaction/overlay correctness + fixture stress + microcopy | v1.54 | 0/? | Not started | - |
| 200. Idempotent verification & sign-off | v1.54 | 0/? | Not started | - |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| TOOL-01 (PhoenixStorybook) | adopted (v1.54) | v1.53 deferred it; v1.54 reverses the deferral — PhoenixStorybook is adopted `only: [:dev, :test]` (STY-01..03) so adopters never carry it. | Component-lab tooling | n/a — adopted |
| TOOL-02 (pixel-diff visual-regression) | deferred (v1.53/v1.54) | Percy/Applitools-style pixel-diff tooling deferred in favor of the scored-cell forward-only gate over real composed routes (it would flag every intentional v1.54 improvement as a regression). | Visual-regression tooling | flaky/insufficient scored-cell + judge loop, or explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin hardening/streamlining passes. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
