# Requirements: Accrue

Standing, posture-level requirements that persist between milestones. Milestone-specific
requirements are added here when a milestone is opened (see `.planning/ROADMAP.md`).
Accrue is in **stable core / demand-driven expansion** posture; broad feature milestones
remain closed by default per the post-v1.48 pause rule.

## Stable-Core Positioning

- [x] **POS-01**: Developer evaluating Accrue can read the public docs and package READMEs and understand that Accrue is stable-core / demand-driven expansion, not a broad feature-chasing billing product.
- [x] **POS-02**: Developer adopting Accrue can see the complete supported SaaS billing loop, processor support boundaries, and package ownership boundaries without reading planning internals.
- [x] **POS-03**: Maintainer can verify that release notes, package docs, support matrix, adoption proof docs, and planning mirrors all describe the same stable-core posture.

## Milestone v1.50 Requirements — Admin UI Foundation (shipped 2026-06-02; archived 2026-06-03)

Shipped 7/7 (AUI-01..07). Archived to `.planning/milestones/v1.50-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.51 Requirements — Admin UI: Depth Pass (shipped & archived 2026-06-04)

Shipped 22/22 (DSY-01..03, IA-01..07, SCR-01..04, MOT-01..03, SEED-01..02, QA-01..03).
Archived to `.planning/milestones/v1.51-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.52 Requirements — Brand System (shipped & archived 2026-06-14)

Shipped 14/14 (AUD-01..03, LOGO-01..04, TOK-01..03, COPY-01..02, BOOK-01..02) across Phases
180–186. Archived to `.planning/milestones/v1.52-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.53 Requirements — Admin UI Design-System Hardening (shipped & archived 2026-06-20)

Shipped 33/33 (FND-01..06, CMP-01..05, GRP-01..04, IXN-01..05, PAGE-01..04, CPY-01..03,
SEED-01..02, VER-01..04) across Phases 187–192. Archived to
`.planning/milestones/v1.53-REQUIREMENTS.md`; validated summary in `PROJECT.md`.

## Milestone v1.54 Requirements — Admin UI Page-Level Streamlining & Storybook (complete, accepted 2026-06-30)

Page-level pass on `accrue_admin`: drive every page from operator JTBD, eliminate "info dump"
density, fix the structural usability defects (overlay/scroll/focus/contrast), adopt
PhoenixStorybook (dev/test-only), and gate it all forward-only on v1.53's baseline + rubric.
Research source: `.planning/research/SUMMARY.md` (+ FEATURES/ARCHITECTURE/PITFALLS/
v1.54-storybook-and-forward-only-qa). Phases 193–200.

### RES — Research, baseline & foundation

- [x] **RES-01**: Maintainer can read three locked archetype pattern specs (SPEC-OVERVIEW / SPEC-LIST / SPEC-DETAIL) that serve as the design contracts every page is built or conformed against.
- [x] **RES-02**: The Phase-187 scored cell baseline is extended with `surface_type:"page-flow"` cells over the ~20 admin routes (additive sibling `baseline.page-flow.cells.json`), wired into the forward-only zero-regression gate.
- [x] **RES-03**: The four Phase-193 spikes are resolved with recorded decisions: overlay portal-vs-native-`<dialog>` (+ Playwright hit-test), `data-theme` dark-mode shim for Storybook color-mode, `inert` vs `aria-hidden` browser-floor, and Storybook asset-serving without a Tailwind rebuild.
- [x] **RES-04**: Three new CSS source guards ship in `verify_package_docs.sh`/CI — spacing-literal ban (no raw px on padding/margin/gap outside allowlist), `:focus-visible` enforcement, and truncation-without-`min-width:0` — mirroring the proven FND-01/MOT-01 guard shape.

### STY — PhoenixStorybook (dev/test-only)

- [x] **STY-01**: `phoenix_storybook` is added `only: [:dev, :test]` and mounted via a sibling-scope router wrap guarded by `Code.ensure_loaded?/1`, so `examples/accrue_host` compiles in `:dev` and `:prod` with the dep absent and exposes no storybook route (proves zero adopter-runtime leak).
- [x] **STY-02**: Every `ComponentRegistry` family and all 8 group contracts have a generated (registry-driven) story — the registry stays the single source of truth; the in-app `/dev/components` kitchen and the Phase-189/190 drift tests stay green.
- [x] **STY-03**: Stories render correctly in both color modes against the shipped committed `ax-*` bundle (not a Tailwind rebuild), with the `html.accrue-admin[data-theme]` scoping bridged into Storybook's sandbox.

### EXE — Gold-standard exemplars (one per archetype)

- [x] **EXE-01**: The Dashboard is refined to the locked four-zone overview spec (refine-not-rebuild) and the Recovery analytics page is re-grammared to `hero metric pair → at-risk work-queue → trend`.
- [x] **EXE-02**: The Subscription detail page is converted to summary-then-drill (~25 always-visible zones → ~6 bands): GOV.UK summary-list header, ≤2 primary actions + an overflow action-menu, action forms hosted in a side-drawer with step-up handoff, the duplicate related-resources card deleted, and card-in-card nesting flattened.
- [x] **EXE-03**: The Subscriptions list is converted to the locked list spec: table-first with row→card mobile degradation, persistent filter chips + result count + clear-all, work-queue default, and four distinct states (populated / first-run-empty / filtered-empty / loading).

### PGH — Shared PageHeader component

- [x] **PGH-01**: A shared `AccrueAdmin.Components.PageHeader` (breadcrumb + title + stat-strip + actions + filter-toolbar slots) is extracted with its slot contract locked before propagation, proven on the Subscriptions list, and preserving exactly one `<h1>` per page.

### PRP — Propagation across all pages

- [x] **PRP-01**: All 8 remaining list pages (customers · invoices · payments · coupons · promotion-codes · webhooks · events · connect) conform to SPEC-LIST, adopt `PageHeader`, and carry per-page JTBD microcopy + four-state coverage.
- [x] **PRP-02**: All remaining detail/analytics pages (customer · invoice · charge · coupon · promotion-code · connect-account · webhook · event detail + Recovery + Campaign) conform to SPEC-DETAIL / the overview spec.

### IXN — Interaction & overlay correctness

- [x] **IXN-01**: A single canonical overlay primitive backs every modal/drawer — ref-counted iOS-safe body scroll-lock (no scrollbar-gutter jump), a body-level portal/stacking model so an overlay is never painted behind its scrim and is always hit-testable, an `inert`/`aria-hidden` background, and a unified backdrop+Escape dismissal that settles cleanly on rapid double-toggle.
- [x] **IXN-02**: Overlay motion is geometry-correct — drawer edge-docks on desktop (translateX from the right) and is a bottom-sheet on mobile (translateY), popovers are origin-aware, focus moves into the panel / traps / restores with an instant focus ring, the ≤240ms duration band is held, and reduced-motion behavior is preserved (extending `reduced-motion.spec.js`).
- [x] **IXN-03**: Non-interactive elements carry no hover/cursor affordance (empty-state heroes), disabled controls look disabled, absent affordances are hidden (no empty pagination), floating elements stay within viewport bounds, and theme switching has no flash-of-wrong-theme with correct persistence and system emulation.
- [x] **IXN-04**: A transformed/filtered/`contain` ancestor audit confirms no LiveView page wrapper re-roots a `position:fixed` overlay shell (the root cause of modal-behind-scrim).

### FIX — Fixture stress for real flows

- [x] **FIX-01**: Deterministic multi-step workflow fixtures (list → detail → nested detail → drill-down → back) exercise focus and scroll integrity across every transition.
- [x] **FIX-02**: Long-content / boundary / edge fixtures (zero-decimal currency, past-due dunning, very long names, overflow) surface squish/clipping/overflow on real seeded data and remain idempotent.

### CPY — Microcopy

- [x] **CPY-01**: A full brand-voice microcopy sweep covers all page-level copy — distinct first-run-empty vs filtered-empty messages, and action/"Change" labels with visually-hidden context that name the affected object and give the next useful action.

### VER — Forward-only verification & sign-off

- [x] **VER-01**: The merged `regressions.ndjson` shows zero regressions versus the union baseline (component + group + page-flow cells) across viewport × theme × state — every inherited cell scores ≥ its baseline.
- [x] **VER-02**: axe-core color-contrast + name/role passes over rendered stories and page-flow routes; no-FOUC/persistence/system-emulation checks are green; and the reduced-motion + group-contract + a11y guardrail suites pass in CI.
- [x] **VER-03**: An adversarial multi-lens judge (correctness · a11y · brand · interaction) plus a maintainer photographic/interaction checkpoint sign off ACCEPT at each phase boundary and at final sign-off.

### Traceability (v1.54)

REQ-ID → phase mapping (each REQ-ID maps to exactly one phase; 23/23 mapped, no orphans, no duplicates):

| Requirement | Phase | Status |
|-------------|-------|--------|
| RES-01 | Phase 193 | Complete |
| RES-02 | Phase 193 | Complete |
| RES-03 | Phase 193 | Complete |
| RES-04 | Phase 193 | Complete |
| STY-01 | Phase 193 | Complete |
| EXE-01 | Phase 194 | Complete |
| EXE-02 | Phase 195 | Complete |
| PGH-01 | Phase 196 | Complete |
| EXE-03 | Phase 196 | Complete |
| PRP-01 | Phase 197 | Complete |
| PRP-02 | Phase 198 | Complete |
| IXN-01 | Phase 199 | Complete |
| IXN-02 | Phase 199 | Complete |
| IXN-03 | Phase 199 | Complete |
| IXN-04 | Phase 199 | Complete |
| FIX-01 | Phase 199 | Complete |
| FIX-02 | Phase 199 | Complete |
| CPY-01 | Phase 199 | Complete |
| VER-01 | Phase 200 | Complete |
| VER-02 | Phase 200 | Complete |
| VER-03 | Phase 200 | Complete |
| STY-02 | Phase 200 | Complete |
| STY-03 | Phase 200 | Complete |

**Notes on mapping decisions:**

- **IXN-01 (canonical overlay primitive)** is *instantiated* for the Subscription-detail side-drawer in Phase 195 (its action-menu/side-drawer action-hosting groundwork is a cross-phase dependency) but is **owned/assigned to Phase 199** — the full cross-cutting overlay sweep across all pages. Single-phase assignment is Phase 199 to avoid a duplicate REQ; the Phase 195 dependency is recorded in the ROADMAP.md phase detail and STATE.md.
- **STY-02 / STY-03 (Storybook story-completeness + theming)** are scaffolded in Phase 193 (STY-01 stands up the dependency, sibling-scope mount, registry generator, and asset serving). Story *completeness* (all families + 8 group contracts) and *theming verification* (both color modes against the shipped `ax-*` bundle) are **delivered and verified in Phase 200** alongside the final forward-only re-score — so STY-02/STY-03 map to Phase 200, with the Phase 193 scaffold as the verification touchpoint.

## Out of Scope

Broad feature milestones remain closed by default unless reopened by a concrete adopter
failure mode, correctness/security/data-loss risk, repeated support issue, operational
failure, or explicit strategy change. Historical backlog anchors and deferred seeds are
tracked as non-active planning context in `.planning/ROADMAP.md`.

**v1.52-specific exclusions:** no admin `ax-*` token changes (admin `theme.css` stays SSOT;
brandbook documents the brand layer); no PDF brand book; no website/landing-page build (copy
blocks only); no binary-heavy assets beyond platform-required PNG/.ico; exploration artifacts
(galleries, rejected candidates, tournament ledger) stay in `.planning/`, not `brandbook/`;
no new billing primitives; no breaking changes.

**v1.53-specific exclusions:** no Tailwind *migration* (custom `ax-*` CSS + tokens stay SSOT;
FND-04 is a *resolution* of the inert config, not a migration); no new billing primitives or
domain features (no new package code expected); no breaking API/route changes (internal moves
ship with redirects, component public APIs stay backward-compatible); no PhoenixStorybook
dependency (extend the in-app `/dev/components` kitchen — deferred as TOOL-01); no demo/host
chrome redesign (`examples/accrue_host` UI is not a design target — only its seed/fixture data,
SEED-01/02); no `accrue_portal` work (separate package); no re-churn of the v1.51 motion spec or
v1.52 brand tokens absent a rubric regression or new interaction pattern.

**v1.54-specific exclusions:** scope is the `accrue_admin` operator UI only — no `accrue_portal`
(customer-facing) work (tracked separately as the white-label portal todo); no new billing
primitives, domain features, or breaking API/route changes (component public APIs stay
backward-compatible; internal moves ship with redirects); no Tailwind migration (custom `ax-*`
CSS + tokens stay SSOT); core `accrue` stays LiveView-runtime-free (PhoenixStorybook is
`accrue_admin` dev/test-only and must not reach adopter runtime); no pixel-diff / SaaS
visual-regression (TOOL-02 stays deferred — the scored-cell forward-only gate is the mechanism);
no replacement of the in-app `/dev/components` kitchen (it stays as a second renderer backing the
Phase-189/190 drift tests); no demo/host chrome redesign beyond the seed/fixture data needed to
stress page-level flows (FIX-01/02).
