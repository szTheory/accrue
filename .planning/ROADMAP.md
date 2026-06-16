# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass [SHIPPED 2026-06-04 — see milestones/v1.51-ROADMAP.md] (IA + Systematic Polish)** — Phases 174-179 (planning 2026-06-03; second, depth-oriented pass on the same `accrue_admin` surface; persona-driven IA reshape + token gap-closure + systematic rubric uplift + motion + seed expressiveness + screenshot-driven visual-QA; no new billing primitives)
- ✅ **v1.52 Brand System** — Phases 180-186 (shipped 2026-06-14; brand audit + DNA lock, SVG logo tournament, design tokens, voice/copy, standalone HTML brand book; no billing primitives) — [archive](milestones/v1.52-ROADMAP.md)
- 🟢 **v1.53 Admin UI Design-System Hardening** — Phases 187-192 (OPEN; planning 2026-06-14; fractal design-system audit foundations→primitives→groups→pages→flows + interaction-defect remediation + component-level systematization + idempotent only-forward verification on `accrue_admin`; no new billing primitives, no breaking API/route changes, no Tailwind migration) — **active inline section below**

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.53 Admin UI Design-System Hardening is open as a quality / design-system / interaction-correctness investment in the already-shipped `accrue_admin` surface. Reopen justification (recorded in `PROJECT.md`): explicit strategy change (design quality of the flagship adopter-facing surface elevated to a strategic priority — same class as v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo (concrete failure evidence). It adds no new billing primitives and does not reopen broad feature scope.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details open>
<summary>🟢 v1.53 Admin UI Design-System Hardening (Phases 187-192) — OPEN (deps strictly linear 187→188→189→190→191→192)</summary>

**Posture:** Quality / interaction-correctness / design-system investment in the already-shipped `accrue_admin` operator UI — **not** a broad feature milestone (no new billing primitives, no breaking API/route changes). Takes the admin UI from *considered* (v1.51) to *interaction-correct and component-systematic*: audit the design system fractally (foundations → primitives → component groups → pages → flows), catch and fix the behavioral defects screenshot scoring can't see (modal-behind-scrim, scroll traps, focus loss, overlay z-index, hover-on-empty-state, disabled-looks-enabled), formalize every component in isolation across its full state matrix, and lock it all behind an idempotent only-forward verification loop. Reopen decision recorded in `PROJECT.md`; justification class: explicit strategy change + firsthand-observed interaction defects.

**Differentiated value over v1.50–v1.52:** v1.51 audited *screens*, not *components in isolation* (only 7 of 28 components are formally specced); its sign-off was LLM-scored stills (logged `tech_debt`) blind to interaction bugs; component-*group* cohesion plus a few foundation gaps (typography bundles, z-index/layer formalization, inert-Tailwind decision) were left open. v1.53 closes all of these and discharges v1.51's open photographic-sign-off tech-debt.

**Guardrails (out of scope):** no Tailwind *migration* (custom `ax-*` CSS + tokens stay SSOT; FND-04 is a *resolution* of the inert config, not a migration); no new billing primitives or domain features; no breaking API/route changes (internal moves ship with redirects, component public APIs stay backward-compatible); no PhoenixStorybook dependency (extend the in-app `/dev/components` kitchen — deferred as TOOL-01); no demo/host chrome redesign (`examples/accrue_host` UI is not a design target — only its seed/fixture data, SEED-01/02); no `accrue_portal` work; no re-churn of the v1.51 motion spec or v1.52 brand tokens absent a rubric regression or new interaction pattern.

**Refreshed rubric:** the v1.51 10-dimension rubric extended with researched additions — **interaction-integrity**, **layer/z-index**, **microcopy** — and scored across viewport × theme × state with live interaction testing. The Phase-187 severity-ranked defect ledger + scored baseline is the only-forward reference point; Phase 192 must score ≥ baseline on every dimension/cell with zero regressions.

**Execution model:** each phase is executed research-backed and verified via the GSD UI workflow (`/gsd-ui-phase` design-contract + `/gsd-ui-review`), with an adversarial multi-lens judge (correctness, a11y, brand, interaction) and a **maintainer screenshot checkpoint at every phase boundary** (this is what closes v1.51's open photographic-sign-off tech-debt).

**Authoritative scope source:** the approved scoping plan; prior design source `.planning/research/v1.51-admin-ui-depth-design.md`.

### Phase Summary

- [x] **Phase 187: Audit & Baseline** — Refresh the rubric (adds interaction-integrity, layer/z-index, microcopy); run the full matrix (viewport × theme × state) + live interaction testing of the running admin UI; produce a severity-ranked defect ledger + scored baseline = the only-forward reference point. (completed 2026-06-15)
- [ ] **Phase 188: Foundations hardening** — Typography bundles, reading-measure application, formal z-index/layer system, motion-gap closure, inert-Tailwind resolution, and dark-mode role/focus/scrollbar/disabled completeness — root-level fixes.
- [ ] **Phase 189: Primitive & form components + component lab** — Every component in isolation × full state matrix × theme × viewport × a11y; root-level (DRY) fixes; grow `/dev/components` into the systematic gallery (no PhoenixStorybook dep).
- [ ] **Phase 190: Navigation, data-display & meta-component cohesion** — App shell / nav / tabs / pagination + tables / cards / detail / timeline / KPI + recurring component groups; spacing rhythm, hierarchy, responsive behavior, operator-stress states.
- [ ] **Phase 191: Page & flow interaction pass + fixture stress + microcopy** — Walk every page against its JTBD across all paths; fix the Phase-187 behavioral defects; expand `examples/accrue_host` seeds for missing matrix cells; on-brand microcopy pass.
- [ ] **Phase 192: Idempotent verification & sign-off** — Full re-run + adversarial multi-lens judge; only-forward scorecard ≥ baseline (zero regressions); regression guardrails in CI; maintainer screenshot UAT.

### Phase Details

### Phase 187: Audit & Baseline

**Goal:** Establish the only-forward baseline for the milestone — refresh the v1.51 10-dimension rubric with researched additions (interaction-integrity, layer/z-index, microcopy), then run the full matrix (viewport × theme × state) AND live interaction-test the running admin UI (open every modal/drawer/dropdown, scroll every container, keyboard-nav every flow, force empty/error/permission/disconnected states) to produce a severity-ranked defect ledger and a scored baseline that every later phase must beat.
**Depends on:** Nothing (first phase of milestone)
**Requirements:** VER-01
**Success Criteria** (what must be TRUE):

  1. The refreshed rubric is documented with its new interaction-integrity, layer/z-index, and microcopy dimensions defined and scored alongside the carried v1.51 dimensions, and a maintainer can read why each new dimension exists.
  2. A severity-ranked defect ledger exists in which every entry names the surface, the reproduction, the severity, and the rubric dimension it fails — covering both static-matrix findings (viewport × theme × state) and live-interaction findings (modal/scroll/focus/overlay/z-index/empty-state/disabled).
  3. A scored baseline captures every audited cell (component / group / page across viewport × theme × state) so it can be re-run idempotently and compared in Phase 192.
  4. The defect ledger and baseline are committed as the single only-forward reference point that Phases 188–191 remediate against and Phase 192 verifies ≥.

**Plans:** 5/5 plans complete
Plans:
**Wave 1**

- [x] 187-01-PLAN.md — Rubric and schema contract

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 187-02-PLAN.md — Manifest, artifact generator, and 12-dimension scorer pipeline

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 187-03-PLAN.md — Static matrix baseline capture
- [x] 187-04-PLAN.md — Live interaction probes and test-only state forcing

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 187-05-PLAN.md — Audit run and canonical baseline ledger

**UI hint**: yes

### Phase 188: Foundations hardening

**Goal:** Fix the design-system roots so every downstream component and page inherits correctness: introduce composed typography bundles, apply the reading-measure token to prose and dense surfaces, formalize and tokenize the z-index/layer system, close motion-token gaps, resolve the inert Tailwind config into one unambiguous styling SSOT, and make every semantic role correct in both light and dark (focus rings, scrollbars, disabled states included). Root-level fixes only — no per-page patching.
**Depends on:** Phase 187
**Requirements:** FND-01, FND-02, FND-03, FND-04, FND-05, FND-06
**Success Criteria** (what must be TRUE):

  1. Composed typography bundles exist as `ax-*` tokens (family + size + weight + line-height + tracking) and primitives consume the bundles instead of ad-hoc per-property utility soup.
  2. A maintainer can grep the admin CSS and find no ad-hoc z-index literals: a formal tokenized layer system (base → sticky → dropdown → popover → drawer → modal → toast) exists and every overlay and sticky element references it; the reading-measure token (`--ax-measure`) is applied so long prose and wide tables stay readable at every breakpoint.
  3. There is one unambiguous styling source of truth — the inert Tailwind config is removed or explicitly documented as reference-only — and motion-token coverage is complete for every animated surface with `prefers-reduced-motion` collapsing travel/overshoot while preserving crossfades.
  4. In dark mode, every semantic role — including focus rings, scrollbars, and disabled states — renders with a correct, contrast-passing value (no role renders wrong or invisible).

**Plans:** 7 plans
Plans:
**Wave 1**

- [x] 188-01-PLAN.md — Tailwind SSOT and package asset build contract
- [x] 188-02-PLAN.md — Typography bundles and reading-measure foundation

**Wave 2** *(blocked on Wave 1 CSS completion)*

- [ ] 188-03-PLAN.md — Semantic layer stack and motion-token closure

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 188-04-PLAN.md — Semantic role tokens, focus, scrollbars, and disabled behavior

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 188-05-PLAN.md — Foundation kitchen specimens and computed-style browser checks

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 188-06-PLAN.md — Static verifier guards and negative fixtures

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 188-07-PLAN.md — Full automated verification and maintainer foundation-kitchen checkpoint

Cross-cutting constraints:
- Composed type, layer, semantic role, motion, and Tailwind SSOT fixes stay at root `accrue_admin` design-system surfaces; no per-page patching.
- `/billing/dev/components` is the maintainer proof surface for foundation specimens in light and dark modes.
**UI hint**: yes

### Phase 189: Primitive & form components + component lab

**Goal:** Systematize every primitive and form component in isolation — exercise each across its full state matrix (default / hover / focus / active / pressed / disabled / loading / selected / empty / error / overflow) in both themes and across viewports, verify a11y (role, keyboard, focus, accessible name), fix every defect at the component root so it propagates to every consuming page, and grow `/dev/components` into the systematic gallery that proves it (no PhoenixStorybook dependency).
**Depends on:** Phase 188
**Requirements:** CMP-01, CMP-02, CMP-03, CMP-04, CMP-05
**Success Criteria** (what must be TRUE):

  1. Every component is exercised in the `/dev/components` lab across its full state matrix (default / hover / focus / active / pressed / disabled / loading / selected / empty / error / overflow) in both light and dark, and the lab is the systematic gallery proving it (extended in-app kitchen, no new dependency).
  2. Each component renders correctly with long/overflowing content (long IDs, names, URLs, module names) without clipping, overlap, or layout break.
  3. Each interactive component has the correct accessible role, full keyboard operation, visible focus, and accessible name; non-interactive elements expose no misleading affordances (e.g. no hover state on empty-state heroes).
  4. Disabled and read-only states are visually unmistakable (disabled looks disabled; enabled never looks disabled) and button text never collides with its background color.
  5. Every component-level visual/brand fix is made at the component root so it propagates to every consuming page (no per-page patching).

**Plans:** TBD
**UI hint**: yes

### Phase 190: Navigation, data-display & meta-component cohesion

**Goal:** Audit the recurring component *groups* as units — app shell / nav / tabs / pagination, plus tables / cards / detail / timeline / KPI, plus the recurring meta-component clusters (page-header + actions + breadcrumbs; toolbar + search + filters + sort; table + empty/loading/error/pagination; KPI + chart + table; detail-header + metadata + actions; modal-confirm; drawer + form; tabs + subviews) — for spacing rhythm, hierarchy, obvious next action, responsive degradation, and operator-stress states. Builds on the hardened foundations and systematized primitives.
**Depends on:** Phase 189
**Requirements:** GRP-01, GRP-02, GRP-03, GRP-04
**Success Criteria** (what must be TRUE):

  1. Each recurring component group (page-header + actions + breadcrumbs; toolbar + search + filters + sort; table + empty/loading/error/pagination; KPI + chart + table; detail-header + metadata + actions; modal-confirm; drawer + form; tabs + subviews) is audited as a unit for spacing rhythm, hierarchy, and obvious next action.
  2. Tables degrade to readable cards/lists (not squished columns) at narrow widths, and a list/card pattern is used wherever it fits the data better than a table.
  3. Nested containers do not read as an accidental "box prison," and stat/KPI cards are visually consistent across every screen.
  4. Pagination and similar affordances disappear or de-emphasize when there is nothing to paginate, and filter/sort/active/selected states are unmistakable.

**Plans:** TBD
**UI hint**: yes

### Phase 191: Page & flow interaction pass + fixture stress + microcopy

**Goal:** Walk every admin page against its primary persona/JTBD across all paths (happy, empty, loading, error, permission-denied, boundary, advanced, disconnected/reconnecting), fix the behavioral interaction defects recorded in the Phase-187 ledger (modal-behind-scrim, scroll traps, focus loss after LiveView patch, overlay z-index/position) and cover each with a regression test, expand `examples/accrue_host` seeds so every matrix cell is reachable in one click, and run an on-brand microcopy pass. This is the page/flow integration of the foundations, primitives, and groups hardened in 188–190.
**Depends on:** Phase 190
**Requirements:** IXN-01, IXN-02, IXN-03, IXN-04, IXN-05, PAGE-01, PAGE-02, PAGE-03, PAGE-04, CPY-01, CPY-02, CPY-03, SEED-01, SEED-02
**Success Criteria** (what must be TRUE):

  1. Every modal/drawer renders above its scrim, fully visible and interactive, traps focus, restores focus to its trigger on close, and dismisses via Escape and click-outside; scrolling works on every page/container with no traps or unreachable content; focus is never lost after a LiveView patch and keyboard-only operation completes every primary flow; floating elements (dropdowns, popovers, tooltips, toasts) position correctly and never obscure their controls — and each Phase-187 interaction defect is fixed and covered by a regression test so it cannot silently return.
  2. Every admin page is walked against its primary persona/JTBD across happy, empty, loading, error, permission-denied, boundary, and advanced paths and renders correctly in each; empty states explain the next useful action and distinguish "no data" from "data unavailable" from "permission denied."
  3. LiveView disconnected/reconnecting state is communicated to the operator and disables actions that cannot be performed while stale; every page is verified at 320 / 375 / 768 / 1024 / 1440 widths in light and dark with no layout break, clipping, or off-screen content.
  4. Microcopy is corrected across the surface: error messages state what happened and how to recover (no bare "oops / invalid / failed / forbidden"); destructive-action confirmations name the specific object and its consequence; domain vocabulary is consistent across headings, tabs, filters, buttons, and alerts.
  5. `examples/accrue_host` seeds reach every matrix cell in one click — null/missing optional fields, permission-denied, boundary pagination, high counts, non-ASCII names, disconnected/reconnecting state (in addition to existing long-name / multi-currency / dunning edges) — and the seed expansion is idempotent (re-runnable) and deterministic, consistent with the existing keyed-insert seed contract.

**Plans:** TBD
**UI hint**: yes

### Phase 192: Idempotent verification & sign-off

**Goal:** Prove the milestone is done and lock it forever-forward: re-run the full audit, score every level (component / group / page) with an adversarial multi-lens judge (correctness, a11y, brand, interaction), confirm the final scorecard is ≥ the Phase-187 baseline on every dimension/cell with zero regressions, wire regression guardrails (interaction e2e, axe a11y, reduced-motion, component-lab coverage) into CI so re-running the milestone only ever finds new gaps, and obtain the maintainer screenshot sign-off that closes v1.51's open photographic-sign-off tech-debt.
**Depends on:** Phase 191
**Requirements:** VER-02, VER-03, VER-04
**Success Criteria** (what must be TRUE):

  1. Each level (component / group / page) is scored by an adversarial multi-lens judge (correctness, a11y, brand, interaction), and the final scorecard is ≥ the Phase-187 baseline on every dimension/cell with zero regressions.
  2. Regression guardrails — interaction e2e, axe a11y, reduced-motion, and a component-lab coverage check — run in CI so re-running the milestone only ever finds new gaps.
  3. The maintainer signs off on screenshots at each phase boundary, and the milestone-final sign-off closes v1.51's open photographic-sign-off tech-debt.

**Plans:** TBD
**UI hint**: yes

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
| 188. Foundations hardening | v1.53 | 2/7 | In Progress|  |
| 189. Primitive & form components + component lab | v1.53 | 0/TBD | Not started | - |
| 190. Navigation, data-display & meta-component cohesion | v1.53 | 0/TBD | Not started | - |
| 191. Page & flow interaction pass + fixture stress + microcopy | v1.53 | 0/TBD | Not started | - |
| 192. Idempotent verification & sign-off | v1.53 | 0/TBD | Not started | - |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| TOOL-01 (PhoenixStorybook) | deferred (v1.53) | v1.53 extends the in-app `/dev/components` kitchen to avoid a shipped-lib dependency. | Component-lab tooling | concrete adopter/contributor failure where the in-app kitchen is insufficient, or explicit strategy change |
| TOOL-02 (pixel-diff visual-regression) | deferred (v1.53) | Percy/Applitools-style pixel-diff tooling deferred in favor of the screenshot + adversarial-judge loop. | Visual-regression tooling | flaky/insufficient screenshot+judge loop, or explicit strategy change |
| TOOL-03 (publish tokens.css distributable) | deferred (v1.53) | Standalone npm/CDN token distributable not needed for the admin hardening pass. | Brand/token distribution | external doc/marketing-site need for distributable tokens |
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
</content>
</invoke>
