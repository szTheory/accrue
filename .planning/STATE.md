---
gsd_state_version: 1.0
milestone: v1.54
milestone_name: Admin UI Page-Level Streamlining & Storybook
status: verifying
stopped_at: Completed 197-07-PLAN.md
last_updated: "2026-06-28T18:47:27.927Z"
last_activity: 2026-06-28
progress:
  total_phases: 8
  completed_phases: 5
  total_plans: 29
  completed_plans: 29
  percent: 63
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-24 — v1.54 Admin UI Page-Level Streamlining & Storybook opened)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 197 — propagate-list

## Current Position

Phase: 197 (propagate-list) — EXECUTING
Plan: 7 of 7
Status: Phase complete — ready for verification
Last activity: 2026-06-28

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.54 Admin UI Page-Level Streamlining & Storybook is open as a quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` surface — not a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration; core `accrue` stays LiveView-runtime-free — PhoenixStorybook is `accrue_admin` dev/test-only). Reopen decision recorded in `PROJECT.md`. Justification class: explicit strategy change (page-level design quality of the flagship adopter-facing surface elevated to a strategic priority — same class as v1.50/v1.51/v1.52/v1.53) **plus firsthand-observed page-level usability defects** in the running demo (modal-behind-scrim, scroll traps, floating/mispositioned overlays, won't-dismiss, hover-on-non-interactive empty states, disabled-looks-enabled).

## Milestone Progress

### v1.54 Phase Summary (ACTIVE — Admin UI Page-Level Streamlining & Storybook; deps strictly linear 193→194→195→196→197→198→199→200)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 193 | Research, re-baseline & pattern lock | RES-01, RES-02, RES-03, RES-04, STY-01 | Complete (2026-06-25) |
| 194 | Exemplar A — Dashboard | EXE-01 | Complete (2026-06-26) |
| 195 | Exemplar B — Subscription detail | EXE-02, IXN-01 | Complete (2026-06-26) |
| 196 | Exemplar C — Subscriptions list + PageHeader | EXE-03, PGH-01 | Complete (2026-06-26) |
| 197 | Propagate LIST | PRP-01 | Not started |
| 198 | Propagate DETAIL + analytics | PRP-02 | Not started |
| 199 | Cross-cutting interaction/overlay correctness + fixture stress + microcopy | IXN-01, IXN-02, IXN-03, IXN-04, FIX-01, FIX-02, CPY-01 | Not started |
| 200 | Idempotent verification & sign-off | VER-01, VER-02, VER-03, STY-02, STY-03 | Not started |

Coverage: 23/23 v1.54 requirements mapped (each REQ-ID → exactly one phase). Per-phase counts: 193→5 · 194→1 · 195→2 · 196→2 · 197→1 · 198→1 · 199→7 · 200→4 = 23. Authoritative design source: `.planning/research/SUMMARY.md` (synthesizing FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md). Reuses v1.53's forward-only machinery: rubric `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md`, `baseline.cells.json`, defect ledger `defects.ndjson`, and the `regressions.ndjson` zero-regression gate.

**Note on IXN-01:** the canonical overlay primitive contract (IXN-01) is *instantiated* for the Subscription-detail side-drawer in Phase 195 (its action-menu/side-drawer groundwork) and is owned + fully swept across all pages in Phase 199. The single-phase mapping below assigns IXN-01 to **Phase 199** (its owning/sweep phase) for traceability; Phase 195 lists it as a cross-phase dependency in the roadmap detail, not a duplicate REQ assignment.

**Dependency shape:** strictly linear — 193 → 194 → 195 → 196 → 197 → 198 → 199 → 200. Foundations + the three locked pattern specs (193) precede the three exemplars (194 Dashboard / 195 Subscription detail / 196 Subscriptions list + PageHeader); exemplars lock the patterns propagation (197 LIST / 198 DETAIL) applies; cross-cutting overlay correctness + fixture stress + microcopy (199) and idempotent verification + sign-off (200) come last.

**Forward-only gate:** the Phase-187 scored-cell baseline is extended (Phase 193) with additive `surface_type:"page-flow"` cells over the ~20 admin routes; Phase 200 must score ≥ the union baseline on every component + group + page-flow cell with zero regressions. No pixel-diff (TOOL-02 stays deferred). PhoenixStorybook is the design lab (dev/test-only), not the regression engine.

### v1.53 Phase Summary (SHIPPED & ARCHIVED 2026-06-20 — Admin UI Design-System Hardening; deps strictly linear 187→188→189→190→191→192)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 187 | Audit & Baseline | VER-01 | Complete (2026-06-15) |
| 188 | Foundations hardening | FND-01, FND-02, FND-03, FND-04, FND-05, FND-06 | Complete (2026-06-17, approved) |
| 189 | Primitive & form components + component lab | CMP-01, CMP-02, CMP-03, CMP-04, CMP-05 | Complete (2026-06-18, verified) |
| 190 | Navigation, data-display & meta-component cohesion | GRP-01, GRP-02, GRP-03, GRP-04 | Complete — shift-left UAT automated (0 human steps) |
| 191 | Page & flow interaction pass + fixture stress + microcopy | IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02 | Complete (2026-06-19, verified) |
| 192 | Idempotent verification & sign-off | VER-02, VER-03, VER-04 | Complete (2026-06-20, approved) |

Coverage: 33/33 v1.53 requirements mapped (each REQ-ID → exactly one phase). Per-phase counts: 187→1 · 188→6 · 189→5 · 190→4 · 191→14 · 192→3 = 33. Authoritative scope source: the approved scoping plan; prior design source `.planning/research/v1.51-admin-ui-depth-design.md`.

**Dependency shape:** strictly linear — 187 → 188 → 189 → 190 → 191 → 192. Foundations (188) must precede component work (189–190); page/flow integration (191) follows group cohesion; 192 verifies everything against the Phase-187 baseline.

**Refreshed rubric:** the v1.51 10-dimension rubric extended with researched additions — interaction-integrity, layer/z-index, microcopy — scored across viewport × theme × state with live interaction testing. The Phase-187 severity-ranked defect ledger + scored baseline is the only-forward reference point; Phase 192 must score ≥ baseline on every dimension/cell with zero regressions.

**Execution model:** each phase executed research-backed and verified via the GSD UI workflow (`/gsd-ui-phase` design-contract + `/gsd-ui-review`), with an adversarial multi-lens judge (correctness, a11y, brand, interaction) and a maintainer screenshot checkpoint at every phase boundary. Final sign-off (Phase 192) closes v1.51's open photographic-sign-off tech-debt.

**Guardrails (out of scope):** no Tailwind migration (FND-04 resolves the inert config, not a migration); no new billing primitives or domain features; no breaking API/route changes (internal moves ship with redirects; component public APIs stay backward-compatible); no PhoenixStorybook dependency (extend the in-app `/dev/components` kitchen — TOOL-01 deferred); no demo/host chrome redesign (only seed/fixture data, SEED-01/02); no `accrue_portal` work; no re-churn of the v1.51 motion spec or v1.52 brand tokens absent a rubric regression or new interaction pattern.

### v1.52 Phase Summary (SHIPPED & ARCHIVED 2026-06-14 — Brand System; deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 180 | Brand Audit & DNA Lock | AUD-01, AUD-02, AUD-03 | Complete (2026-06-12) |
| 181 | SVG Pipeline + Tournament Round 1 — Divergent | LOGO-01, LOGO-02 | Complete (2026-06-12) |
| 182 | Tournament Convergent Refinement | LOGO-03 | Complete (2026-06-13) |
| 183 | Logo System Production | LOGO-04 | Complete (2026-06-13) |
| 184 | Design Tokens & Specimens | TOK-01, TOK-02, TOK-03 | Complete (2026-06-14) |
| 185 | Voice, Microcopy & Marketing Copy | COPY-01, COPY-02 | Complete (2026-06-14) |
| 186 | HTML Brand Book Assembly & Quality Gate | BOOK-01, BOOK-02 | Complete (2026-06-14) |

Coverage: 14/14 v1.52 requirements mapped (each REQ-ID → exactly one phase). Design source: `.planning/research/v1.52-brand-system-design.md`. Shipped, archived, and tagged `v1.52` on 2026-06-14.

### v1.51 Phase Summary (SHIPPED & ARCHIVED 2026-06-04 — Admin UI: Depth Pass; deps A→B→C→{D,E}→F; phase dirs in milestones/v1.51-phases/)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 174 | A — Design-System Gap Closure & Token Completeness | DSY-01, DSY-02, DSY-03 | Complete |
| 175 | B — Persona-Driven IA Spine | IA-01, IA-02, IA-03, IA-04, IA-05, IA-06, IA-07 | Complete |
| 176 | C — Systematic Per-Screen Rubric Uplift | SCR-01, SCR-02, SCR-03, SCR-04 | Complete |
| 177 | D — Motion & Micro-interaction Design | MOT-01, MOT-02, MOT-03 | Complete |
| 178 | E — Seed Expressiveness & State Coverage | SEED-01, SEED-02 | Complete |
| 179 | F — Screenshot-Driven Visual QA Loop & Sign-off | QA-01, QA-02, QA-03 | Complete |

Coverage: 22/22 v1.51 requirements mapped (each REQ-ID → exactly one phase). Design source: `.planning/research/v1.51-admin-ui-depth-design.md`.

### v1.50 Phase Summary (shipped 2026-06-02 via PR #32; archived 2026-06-03 — see milestones/v1.50-*)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 167 | Design Tokens & Motion Foundation | AUI-01 | Complete |
| 168 | Typography & Icon System | AUI-02 | Complete |
| 169 | Information Architecture — Home, Nav & Search | AUI-03 | Complete |
| 170 | Cross-Screen Threading & Microcopy | AUI-04 | Complete |
| 171 | Shared Detail Components & Screen Refactor | AUI-05 | Complete |
| 172 | Seed Enrichment & Component Kitchen | AUI-06 | Complete |
| 173 | Rubric Audit & Visual/A11y Coverage | AUI-07 | Complete |

### v1.49 Phase Summary

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 163 | Realistic Domain & Rich Seeds | EVD-01, EVD-02 | Complete |
| 164 | Docker DX & Optimized Caching | EVD-03, EVD-04 | Complete |
| 165 | E2E Automation & Shift-Left CI | E2E-01, E2E-02, E2E-03, E2E-04 | Complete |
| 166 | Adoption DX Docs | DOC-01, DOC-02, DOC-03 | Complete |

### Recently shipped milestones

**v1.53** (shipped & archived **2026-06-20**): 6 phases (**187–192**), 33 requirements. Theme: Admin UI Design-System Hardening. See `.planning/milestones/v1.53-ROADMAP.md`.

**v1.52** (shipped & archived **2026-06-14**): 7 phases (**180–186**), 14 requirements. Theme: Brand System. See `.planning/milestones/v1.52-ROADMAP.md`.

**v1.51** (shipped & archived **2026-06-04**): 6 phases (**174–179**), 22 requirements. Theme: Admin UI Depth Pass. Audit: `.planning/milestones/v1.51-MILESTONE-AUDIT.md`.

**v1.49** (shipped & archived **2026-06-02**): 4 phases (**163–166**), 11 requirements. Theme: Realistic Demo App & Adoption Evidence. Audit: `.planning/milestones/v1.49-MILESTONE-AUDIT.md`.

**v1.48** (shipped & archived **2026-06-01**): 4 phases (**159–162**), 9 requirements. Theme: Release Readiness + Stable Core Posture. Audit: `.planning/v1.48-v1.48-MILESTONE-AUDIT.md` (or equivalent closeout proof).

**v1.47** (shipped & archived **2026-05-31**): 5 phases (**154–158**), 11 requirements. Theme: ENT-10 Polish + Adopter-Proof Completeness. Audit: `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 146
- Average duration: 1m
- Total execution time: 1m

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 187 P01 | 4m 12s | 2 tasks | 3 files |
| Phase 187 P02 | 6m | 3 tasks | 8 files |
| Phase 187 P03 | 19m | 2 tasks | 1 files |
| Phase 187 P04 | 9m | 2 tasks | 4 files |
| Phase 188 P01 | 16 min | 2 tasks | 5 files |
| Phase 188 P02 | 6 min | 2 tasks | 2 files |
| Phase 188 P03 | 3 min | 2 tasks | 2 files |
| Phase 188 P04 | 5 min | 2 tasks | 5 files |
| Phase 188 P05 | 9 min | 2 tasks | 5 files |
| Phase 188 P06 | 38 min | 2 tasks | 3 files |
| Phase 189 P01 | 3 min | 2 tasks | 4 files |
| Phase 189 P02 | 3 min | 2 tasks | 8 files |
| Phase 189-primitive-form-components-component-lab P03 | 25min | 2 tasks | 3 files |
| Phase 189-primitive-form-components-component-lab P05 | 8min | 3 tasks | 1 files |
| Phase 190 P01 | 7 min | 3 tasks | 5 files |
| Phase 190 P02 | 11m32s | 3 tasks | 5 files |
| Phase 190 P03 | 10m32s | 3 tasks | 10 files |
| Phase 190 P04 | 6m28s | 3 tasks | 11 files |
| Phase 190 P05 | serial | 3 tasks | 5 files |
| Phase 190 P06 | 19min | 2 tasks | 3 files |
| Phase 191 P01 | 12 min | 3 tasks | 4 files |
| Phase 191 P02 | 7 min | 2 tasks | 3 files |
| Phase 191 P06 | 7 min | 2 tasks | 4 files |
| Phase 191 P03 | 16m | 2 tasks | 10 files |
| Phase 191 P04 | 29 min | 2 tasks | 19 files |
| Phase 191 P05 | 16m 34s | 2 tasks | 13 files |
| Phase 191 P07 | 12m | 2 tasks | 3 files |
| Phase 188 P08 | 68 | 3 tasks | 11 files |
| Phase 193 P01 | 15m | 2 tasks | 4 files |
| Phase 193 P02 | 2m | 1 tasks | 1 files |
| Phase 193 P03 | 15 | 1 tasks | 2 files |
| Phase 193 P04 | 526s | 2 tasks | 7 files |
| Phase 193 P05 | 558 | - tasks | - files |
| Phase 194 P01 | 322s | 3 tasks | 3 files |
| Phase 194 P02 | 191s | 2 tasks | 1 files |
| Phase 194 P03 | 234s | 2 tasks | 2 files |
| Phase 194 P04 | 624s | 3 tasks | 2 files |
| Phase 195 P01 | 9m 15s | 3 tasks | 4 files |
| Phase 195 P02 | 9m 50s | 3 tasks | 1 files |
| Phase 195 P03 | 10m 35s | 3 tasks | 8 files |
| Phase 195 P04 | 4m 10s | 3 tasks | 4 files |
| Phase 195 P05 | 6m 54s | 3 tasks | 3 files |
| Phase 195 P06 | 7m 52s | 3 tasks | 6 files |
| Phase 195 P07 | 21m | 3 tasks | 4 files |
| Phase 195 P08 | 10m 38s | 4 tasks | 7 files |
| Phase 196 P01 | 13min | 3 tasks | 6 files |
| Phase 196 P02 | 4min | 2 tasks | 2 files |
| Phase 196 P03 | 9min | 3 tasks | 4 files |
| Phase 196 P04 | 12m | 3 tasks | 4 files |
| Phase 196 P05 | 9m | 2 tasks | 6 files |
| Phase 197 P01 | 16min | 3 tasks | 4 files |
| Phase 197-propagate-list P02 | approximately 45 minutes | 3 tasks | 8 files |
| Phase 197 P03 | 9min | 3 tasks | 10 files |
| Phase 197 P04 | 14m | 3 tasks | 4 files |
| Phase 197 P05 | 9m 38s | 2 tasks | 4 files |
| Phase 197 P06 | 1044 | 3 tasks | 7 files |
| Phase 197 P07 | 12m32s | 3 tasks | 3 files |

## Accumulated Context

### Key Planning Decisions for v1.54

- **2026-06-24:** Opened v1.54 "Admin UI Page-Level Streamlining & Storybook" (Phases 193–200, continue-numbering from v1.53's Phase 192). Reopen decision: explicit strategy change (page-level design quality of the flagship adopter-facing surface elevated to strategic priority — same class as v1.50/v1.51/v1.52/v1.53) **plus firsthand-observed page-level usability defects** in the running demo (modal-behind-scrim, scroll traps, floating/mispositioned overlays, won't-dismiss, hover-on-non-interactive empty states, disabled-looks-enabled). No new billing primitives, no breaking API/route changes, no Tailwind migration, core stays LiveView-runtime-free. Recorded in `PROJECT.md`.
- **2026-06-25:** Roadmap created — 8 phases (193–200), 23/23 requirements mapped (each REQ-ID → exactly one phase), strictly linear deps 193→194→195→196→197→198→199→200. Roadmapper formalized success criteria + traceability from the approved 8-phase plan + research SUMMARY (did not invent a different breakdown).
- **2026-06-25:** The milestone backbone is structural, not cosmetic — the maintainer's reported defects are page-composition/runtime-interaction failures invisible to the existing source-text gates. Two-part backbone: (a) one canonical overlay primitive (body-level portal + ref-counted iOS-safe scroll-lock + `inert` background + single dismissal contract + origin-aware enter motion) every modal/drawer/popover routes through; (b) a rendered state-matrix gate — PhoenixStorybook (dev/test-only) + axe-core + Playwright interaction battery, folded into v1.53's forward-only cell-baseline as `surface_type:"page-flow"` cells under the unchanged `regressions.ndjson` rule. Prevention via source-lint where mechanical (3 new guards); rendered-detection in CI where compositional.
- **2026-06-25:** Reverses v1.53's TOOL-01 deferral — PhoenixStorybook is **adopted** `only: [:dev, :test]`, mounted via a `Code.ensure_loaded?`-guarded sibling-scope router wrap (Mailglass precedent) so adopters never carry it and a host dev compile exposes no storybook route. The in-app `/dev/components` kitchen stays as a second renderer (registry stays SSOT) backing the Phase-189/190 drift tests. TOOL-02 (pixel-diff VR) stays deferred — the scored-cell forward-only gate over real composed routes is the mechanism (pixel-diff would flag every intentional v1.54 improvement as a regression).
- **2026-06-25:** IXN-01 (canonical overlay primitive) is *instantiated* for the Subscription-detail side-drawer in Phase 195 (its action-menu/side-drawer groundwork is a cross-phase dependency) but is **owned/assigned to Phase 199** (the full cross-cutting sweep) for single-phase traceability — avoids a duplicate REQ assignment while making the dependency explicit in the roadmap detail. Page-design work is archetype-driven: lock three pattern specs (193), nail one exemplar per archetype (194 Dashboard / 195 Subscription detail / 196 Subscriptions list + PageHeader), then propagate (197 LIST / 198 DETAIL).

### Key Planning Decisions for v1.53

- **2026-06-18 (Phase 189, post-execution):** Reversed locked decisions **D-05/D-07** — the `/billing/dev/components` lab now renders a **single state-matrix column following the global topbar theme toggle** instead of side-by-side light/dark columns. Rationale: dark-mode verification is redundant (`admin-a11y.spec.js` already scans every surface in both themes via the global toggle); the D-07 `.accrue-admin [data-theme="dark"]` sub-tree mechanism was bug-prone (dark-column contrast bug) and complex; two-column broke mobile (~195k px). Removed dark column, headers, the `themeColumnDeltaProbe` e2e, and the per-column `color` re-declaration; `theme.css` sub-tree block retained as harmless dead code (avoids frozen-foundation + FND-05 verifier churn). Recorded in 189-CONTEXT.md / 189-UI-SPEC.md.
- **2026-06-14:** Opened v1.53 "Admin UI Design-System Hardening" (Phases 187–192, continue-numbering from v1.52's Phase 186). Reopen decision: explicit strategy change (flagship adopter-facing surface design quality elevated to strategic priority — same class as v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo. No new billing primitives, no breaking API/route changes, no Tailwind migration. Recorded in `PROJECT.md`.
- **2026-06-14:** Six-phase structure approved via an ExitPlanMode-approved scoping plan; roadmapper formalized success criteria + traceability only (did not invent a different breakdown). Strictly linear deps 187→188→189→190→191→192.
- **2026-06-14:** Differentiated value over v1.51: v1.51 audited *screens*, not *components in isolation* (only 7 of 28 specced); its sign-off was LLM-scored stills (logged `tech_debt`) blind to interaction bugs; component-*group* cohesion + a few foundation gaps (typography bundles, z-index formalization, inert-Tailwind decision) left open. v1.53 closes all of these and discharges v1.51's photographic-sign-off tech-debt.
- **2026-06-14:** Refreshed rubric = v1.51's 10 dimensions + researched additions (interaction-integrity, layer/z-index, microcopy), scored across viewport × theme × state with live interaction testing. Phase-187 severity-ranked defect ledger + scored baseline is the only-forward reference; Phase 192 must be ≥ baseline with zero regressions.
- **2026-06-14:** Component lab = extend the in-app `/dev/components` kitchen (TOOL-01 PhoenixStorybook deferred). Sign-off = adversarial multi-lens judge + maintainer screenshot checkpoint at every phase boundary, executed via the GSD UI workflow (`/gsd-ui-phase` + `/gsd-ui-review`).

### Key Planning Decisions for v1.52

- **2026-06-11:** Opened v1.52 "Brand System". Reopen decision: brand/DX investment in adopter-facing presentation surfaces — same justification class as v1.50/v1.51; no billing primitives. Recorded in `PROJECT.md`.
- **2026-06-11:** User decisions ratified (via AskUserQuestion in design phase): full checkpoint set; round 1 = 12–16 concepts across 4 directions; seed latitude is evidence-gated (Geist + palette are defaults).
- **2026-06-11:** Hard logo constraints locked (binding on every candidate): no rect background/container shape; logotype optically close to mark; main lockup no subtitle (with-subtitle variant ships separately); fully-integrated custom typemark options required.
- **2026-06-11:** Admin `ax-*` tokens in `accrue_admin/assets/css/theme.css` stay SSOT and are untouched this milestone — brandbook documents the brand layer only.
- **2026-06-11:** Exploration artifacts (galleries, rejected candidates, TOURNAMENT.md) stay in `.planning/milestones/v1.52-phases/` — not in `brandbook/`.
- **2026-06-11:** `brandbook/` size budget ≤ 2 MB enforced at Phase 186 verification.

### Key Planning Decisions for v1.49

- **2026-06-01:** Focus on a highly realistic click-around demo for `examples/accrue_host` to serve as adoption evidence.
- **2026-06-01:** E2E Playwright tests must be deterministic, flake-free, and integrated into CI (shift-left devops mindset).
- **2026-06-01:** Docker DX must be seamless with optimized cache layers to allow maintainers and adopters to iterate quickly without redownloading dependencies (Tailwind, Hex deps).
- **2026-06-02:** Core onboarding and billing Playwright coverage is consolidated into a single serial spec because the Fake processor is shared process state; CI must preserve serial execution for sensitive subscription-mutating flows.
- **2026-06-02:** CI now enforces Phase 165 through native sharded Playwright E2E, Docker Compose boot smoke, and mandatory periodic live-Stripe parity.
- **2026-06-02:** v1.49 shipped and archived. Future milestones return to stable-core / demand-driven expansion posture unless reopened by concrete adopter, correctness, security, operational, or strategy evidence.

### Historical Research Assets

- **v1.17 Friction Inventory (FRG-01):** `.planning/research/v1.17-FRICTION-INVENTORY.md`
- **v1.17 North Star:** `.planning/research/v1.17-north-star.md` — stop rules S1–S5.
- **v1.47 Research:** `.planning/research/SUMMARY.md`
- **v1.51 Admin UI Depth Design:** `.planning/research/v1.51-admin-ui-depth-design.md` (prior design source carried forward for v1.53/v1.54)
- **v1.52 Brand System Design:** `.planning/research/v1.52-brand-system-design.md`
- **v1.54 Research (active):** `.planning/research/SUMMARY.md` (page-level streamlining + Storybook synthesis of FEATURES.md, ARCHITECTURE.md, PITFALLS.md, v1.54-storybook-and-forward-only-qa.md)

### Roadmap Evolution

- v1.48 shipped and archived 2026-06-01: Phases 159–162
- v1.49 shipped and archived 2026-06-02: Phases 163–166
- v1.50 shipped and archived 2026-06-03: Phases 167–173
- v1.51 shipped and archived 2026-06-04: Phases 174–179
- v1.52 shipped and archived 2026-06-14: Phases 180–186
- v1.53 shipped and archived 2026-06-20: Phases 187–192
- v1.54 opened 2026-06-24: Phases 193–200 (continue-numbering); roadmap created 2026-06-25

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-06-24:** Opened v1.54 "Admin UI Page-Level Streamlining & Storybook" (Phases 193–200). Quality / page-level-design / interaction-correctness investment in the already-shipped `accrue_admin` surface; no new billing primitives. Roadmap created with 8 phases, 23/23 requirements mapped.
- **2026-06-14:** Opened v1.53 "Admin UI Design-System Hardening" (Phases 187–192). Quality / interaction-correctness investment in the already-shipped `accrue_admin` surface; no new billing primitives. Roadmap created with 6 phases, 33/33 requirements mapped.
- **2026-06-11:** Opened v1.52 "Brand System". This explicitly does not open new broad feature scope, but rather invests in adopter-facing brand presentation surfaces (logo, brand book, design tokens, voice/copy). Roadmap created with 7 phases (180–186).
- **2026-06-02:** Closed v1.49 after fresh audit passed 11/11 requirements and archived ROADMAP, REQUIREMENTS, MILESTONE-AUDIT, and phase artifacts under `.planning/milestones/`.
- [Phase 187]: Layer/z-index is an overlay tag, not a thirteenth rubric dimension. — Plan 187-01 preserves the 12-dimension contract and keeps layer failures searchable without double-counting.
- [Phase 187]: Structured baseline and defect artifacts are canonical when markdown disagrees. — Plan 187-01 schemas make baseline.cells.json and defects.ndjson the Phase 192 comparison source of truth.
- [Phase 187]: Phase 187 defects route to owner phases 188, 189, 190, or 191. — Plan 187-01 fixed downstream remediation ownership before manifest and harness work.
- [Phase 187]: Phase 187 matrix identity is manifest-owned; model and raw evidence metadata are advisory. — Plan 187-02 uses the manifest as the source of truth for cell IDs and enrichment.
- [Phase 187]: Targeted breakpoint rows use mode targeted plus numeric viewport_width/breakpoint and targeted_label. — Plan 187-02 rejects legacy targeted-320 mode strings.
- [Phase 187]: Evidence artifacts stay under accrue_admin/test-results with checksums; committed planning artifacts store references only. — Plan 187-02 avoids committing screenshots, traces, or external artifacts.
- [Phase 187]: Static baseline component rows resolve manifest /dev/components to the actual /billing/dev/components route. — The admin dev component kitchen is mounted under the /billing admin scope, and resolving it in the harness keeps component/component-group evidence reachable without changing manifest identity.
- [Phase 187]: Permission-denied forcing stays inside E2E test support. — Plan 187-04 uses an explicit `member` token and `login-member` helper route without changing production admin auth.
- [Phase 187]: Live interaction probes record observations instead of corrected-behavior regressions. — Plan 187-04 writes trace-backed NDJSON rows for current behavior and leaves permanent regression tests to Phase 191 fixes.
- [Phase 189]: D-07 CSS gate: sub-tree .accrue-admin [data-theme='dark'] selector with FULL dark token set is the CSS prerequisite; browser-level color delta verified in Plan 06 themeColumnDeltaProbe
- [Phase 189]: Structural tests (e) and (f) are data-contract-only (no page mount); HTML mount assertions for data-ax-state and data-theme attributes are Plan 03 test (g)
- [Phase ?]: StatusBadge ink tone maps to neutral (not danger) — ax-status-badge-ink removed from Plan 04 danger grouping; ink is catch-all unknown status
- [Phase 190]: Plan 01 uses AccrueAdmin.Dev.ComponentRegistry.group_contracts/0 as the canonical Wave 0 group contract source.
- [Phase 190]: Plan 01 keeps the Playwright Wave 0 harness source-level only until later plans render data-component-group DOM specimens.
- [Phase 190]: Plan 01 records Phase 191 handoff tags in contracts and the ledger without implementing focus, Escape, click-outside, fixture, or microcopy behavior in Wave 0.
- [Phase 190]: 190-02: Component groups render from ComponentRegistry.group_contracts/0 rather than duplicated kitchen data. — Keeps the proof surface coupled to the authoritative registry from 190-01.
- [Phase 190]: 190-02: Drawer proof styling is contained in the kitchen specimen while Phase 191 owns full drawer interaction behavior. — Allows visual proof without expanding this plan into flow interaction work.
- [Phase 190]: 190-02: Mounted coverage uses Floki-scoped group-root assertions so unrelated page text cannot satisfy detail/table proof requirements. — Makes registry proof tests robust against incidental labels elsewhere in the kitchen.
- [Phase 190]: 190-03: DataTable selection controls derive aria labels from row content for contextual row actions. — Improves accessibility while preserving existing LiveComponent selection behavior.
- [Phase 190]: 190-03: AtRiskTable accepts optional amount fields and falls back when existing recovery rows omit money data. — Keeps the new component compatible with current call sites without widening query scope in this plan.
- [Phase 190]: 190-03: Detail sections are unframed while summary headers remain framed. — Avoids card-in-card page rhythm while keeping object identity headers visually grouped.
- [Phase 190-04]: Breadcrumbs remain breadcrumb-only; page-header/actions/breadcrumbs is a composed page-header proof surface. — The Breadcrumbs component owns orientation and current crumb semantics, not the full page-header/action band.
- [Phase 190-04]: DropdownMenu uses native disclosure semantics and does not claim menu/menuitem roles until true menu-button keyboard behavior is implemented. — The component is built on details/summary and Phase 191 owns true menu keyboard behavior if needed.
- [Phase 190-04]: Drawer/modal group contracts define structure, IDs, action order, sizing, scrollable bodies, and layer tokens while Phase 191 owns full trap/restore/dismissal behavior. — This keeps Phase 190 bounded to reusable group structure and tokenized layers.
- [Phase 190]: 190-05: Use grp190 proof roots rather than generic data-component-group selectors because nested reusable components also expose group locators. — Browser and ExUnit probes both found nested component group attributes; proof IDs are the stable root contract.
- [Phase 190]: 190-05: Keep validation pending-baseline-evidence until admin-baseline.spec.js completes. — All other automated gates passed, but baseline hung under bounded retry and cannot support approved validation status.
- [Phase 191]: Phase 191 page-flow inventory derives from baseline-manifest.js, not a second route list.
- [Phase 191]: High-severity owner_phase 191 AX187 rows must be directly cited in the Phase 191 spec; medium rows may be covered by AX187 ID or normalized overlay tag.
- [Phase 191]: Phase 191 matrix route records use static test-only UUIDs so reset plus reseed returns stable detail route IDs. — Plan 191-02 requires deterministic route IDs for page-flow fixtures.
- [Phase 191]: The phase191-matrix endpoint remains in test/support E2E plug routes only; no production router or auth paths changed. — T-191-04 mitigation requires fixture reachability without production forced-state routes or auth bypasses.
- [Phase 191-06]: Phase 191 host fixture rows use the phase191_host namespace, separate from browser-only e2e_phase191 forcing data. — Keeps local click-through seed data distinct from test-only E2E forcing rows.
- [Phase 191-06]: Host seed route IDs are deterministic for binary-id billing rows; append-only event reachability is keyed by idempotency_key. — Binary route records need stable local detail links while event rows preserve append-only semantics.
- [Phase 191-03]: FocusTrap stays package-local instead of adding a third-party focus-management dependency. — Avoids Phase 191 dependency scope while satisfying overlay focus integrity.
- [Phase 191-03]: Step-up modal Escape, outside click, and cancel all dismiss through step_up_dismiss while confirmation remains an explicit submit path. — Preserves the security boundary that destructive confirmation requires an explicit submit.
- [Phase 191-03]: The generated admin JS bundle is committed with the hook registration so served admin assets include FocusTrap. — Generated runtime assets must match app.js hook registration.
- [Phase 191]: Phase 191 focus verification uses data-phase191-focus anchors on shared components instead of brittle page-specific selectors. — Keeps patch-focus verification stable across routes and reusable components.
- [Phase 191]: Admin static JS/CSS bundles are committed with source hook and CSS changes so served admin assets match implementation. — The admin E2E server serves compiled assets, so generated bundles must track hook registration and CSS updates.
- [Phase 191]: Connection state is sourced from LiveView lifecycle events and expressed through a shared shell hook/status region. — Satisfies T-191-08 without adding manually clickable status state.
- [Phase 191]: Page-state and destructive-action copy belongs in AccrueAdmin.Copy modules, not inline LiveView strings. — Plan 191-05 centralizes CPY/PAGE microcopy contracts for reuse and browser verification.
- [Phase 191]: Visible action failures use recoverable resource-specific copy instead of raw inspect(reason). — Mitigates T-191-10 information disclosure while preserving operator recovery guidance.
- [Phase 191]: Browser copy assertions target mounted page-flow DOM states, avoiding auth redirects with unstable empty bodies. — Keeps Phase 191 DOM checks deterministic without changing auth routing in this plan.
- [Phase ?]: data-ax-force=focus detached DOM probe for headless Chromium focus-ring e2e
- [Phase ?]: Production copy fix in subscription.ex preferred over relaxing CPY-02 assertions
- [Phase ?]: Stale webhook test assertions aligned with current copy functions
- [Phase ?]: Three archetype spec guides (SPEC-OVERVIEW/LIST/DETAIL) authored as ExDoc guides with GOV.UK-style machine invariant tables; phoenix_storybook dep added as Plan 04 prerequisite
- [Phase ?]: 21 PAGE_FLOWS surfaces in baseline-manifest.js (not 22 as estimated); 9,072 p193-prefixed page-flow cells generated as additive sibling to baseline.cells.json for Phase 200 zero-regression gate
- [Phase ?]: D-01 portal-primary confirmed
- [Phase ?]: D-01 portal-primary confirmed by D-05 spike: body-level #ax-overlay-root escapes transform ancestors, survives LiveView navigation, hit-testable above scrim (RES-03 Spike A resolved)
- [Phase ?]: Proof 3 gutter-jump delta = 0px without ScrollLock hook — Phase 199 to enforce delta == 0
- [Phase ?]: D-17 spike B: CSS class shim (.psb-sandbox.accrue-admin.ax-theme-dark-shim) chosen over JS hook for Storybook dark-mode
- [Phase ?]: D-17 spike C: inert attribute chosen for background-suppression in overlays; browser floor (Chrome 102+/Firefox 112+/Safari 15.5+) satisfied by target audience
- [Phase ?]: D-17 spike D: Storybook CSS/JS served via AccrueAdmin.Assets committed-bundle route; no Tailwind rebuild required
- [Phase ?]: Code.ensure_loaded?(PhoenixStorybook.Router) mandatory in router wrap — host apps without the dep compile clean in dev and prod
- [Phase ?]: Fix violations before adding guards — Guard A spacing exceptions annotated with ax-spacing-exception comments, Guard B skip-link fixed to :focus-visible, Guard C min-width:0 added
- [Phase ?]: Planted CSS violations in PackageDocsVerifier tests use append+trailing-newline to preserve seeded app.css coverage for earlier guards
- [Phase ?]: Guard D (empty-rail non-interactivity source lint) bans cursor:pointer on .ax-attention-rail--empty; D-08 ExUnit mirror keeps guard and test suite coupled
- [Phase ?]: Phase 194 Plan 04: p193↔p187 scorecard pairing structural no-op — SC3 redefined as e2e:phase194 pass + source guards
- [Phase 195]: Plan 195-01 intentionally remains RED-only; implementation is owned by later Phase 195 plans. — The plan objective is Wave 0 RED validation coverage; later plans green the implementation.
- [Phase 195]: EXE-02 and IXN-01 remain pending after 195-01; this plan addresses them with RED coverage only. — The underlying Subscription detail conversion and full overlay implementation are split across later Phase 195 and Phase 199 plans.
- [Phase 195]: Plan 195-02 intentionally remains RED-only; implementation is owned by later Phase 195 plans. — The plan objective is Wave 0 RED LiveView validation coverage; later plans green the Subscription detail implementation.
- [Phase 195]: EXE-02 and IXN-01 remain pending after 195-02; this plan addresses them with RED coverage only. — The underlying Subscription detail conversion and overlay interaction implementation are split across later Phase 195 and Phase 199 plans.
- [Phase 195-03]: Use pinned LiveView .portal with #ax-overlay-root as the canonical overlay transport for modal/drawer/popover presentations.
- [Phase 195-03]: Keep IXN-01 requirement completion pending for Phase 199; 195-03 ships the prerequisite overlay API/root/wrapper slice.
- [Phase 195]: Phase 195-04: Overlay composes FocusTrap lifecycle and gates ScrollLock to modal/drawer presentations.
- [Phase 195]: Phase 195-04: IXN-01 remains pending for the Phase 199 cross-page overlay sweep; this plan ships the Phase 195 JS prerequisite.
- [Phase 195]: 195-05: Overlay CSS presentation layers use existing --ax-z-drawer, --ax-z-modal, and --ax-z-popover tokens; IXN-01 remains pending for Phase 199 sweep.
- [Phase 195]: 195-05: Drawer CSS is mobile-first bottom sheet below md and right-docked at min(34rem, 92vw) for md+ desktop geometry.
- [Phase 195-06]: Detail.summary_list/1 uses row maps for strings, rendered HTML values, and optional Change/View actions while detail_field_list/1 remains read-only drill UI. — Keeps header row actions separate from drill-section read-only fields for Phase 198 propagation.
- [Phase 195-06]: DropdownMenu.action_menu/1 stays non-modal details/menu UI; drawer and StepUp surfaces remain the overlay/modal boundary. — Matches D-04: action menus are lightweight disclosure menus and must not inherit scroll-lock, inert, or aria-modal behavior.
- [Phase 195-06]: EXE-02 and IXN-01 remain pending after prerequisite primitives; 195-07 owns the page conversion and Phase 199 owns the cross-page overlay sweep. — Prevents a prerequisite primitive plan from closing broader page-conversion and cross-page overlay requirements early.
- [Phase 195]: Subscription detail uses the six-band DETAIL spine with drawer-hosted actions and lazy Activity/JSON. — Plan 195-07 converted SubscriptionLive into the Phase 195 exemplar.
- [Phase 195]: Subscription drawer labels are routed through AccrueAdmin.Copy and exported for anti-drift checks. — Keeps LiveView and browser fixture labels aligned.
- [Phase 195-08]: Storybook coverage is additive and keeps `/dev/components` untouched.
- [Phase 195-08]: Subscription detail action-menu remains non-portaled in Phase 195; Phase 199 owns transformed-ancestor, overflow clipping, and stacking-context audit before any portal exception.
- [Phase 195-08]: Task 4 was verification-only because the final Phase 195 gate passed without additional code changes.
- [Phase 196]: 196-01 kept Wave 0 test-only: no PageHeader/DataTable/Subscriptions runtime behavior was implemented.
- [Phase 196]: 196-01 scoped propagation coverage to Subscriptions; broader LIST rollout remains Phase 197 work.
- [Phase 196]: 196-01 owner-scope clear-all is asserted in LiveView tests with an authorized organization session.
- [Phase 196]: PageHeader composes Breadcrumbs and renders caller-owned description, stat_strip, actions, and filter_toolbar slots without owning list/resource state. — Locks PGH-01 before Subscriptions adoption and Phase 197 propagation.
- [Phase 196]: Storybook coverage stays focused and static for the PageHeader contract; runtime page adoption remains deferred to later Phase 196 plans. — Keeps D-16 and D-17 propagation and Storybook boundaries intact.
- [Phase 196]: 196-03: DataTable keeps backward-compatible derived state defaults while allowing explicit list_state and empty_reason for LIST pages.
- [Phase 196]: 196-03: DataTable.filter_toolbar remains parent-targeted for data_table_filter so PageHeader can host filters without owning state.
- [Phase 196]: 196-03: FilterChipBar renders caller-supplied result counts and clear-all hrefs without mutating URLs.
- [Phase 196]: Phase 196 Plan 04 keeps PageHeader slot-only; SubscriptionsLive and DataTableNav own list state and filter mutation. — Preserves D-02 and D-10 by letting PageHeader host slots without owning list/filter state.
- [Phase 196]: Phase 196 Playwright contract remains scoped to Subscriptions LIST; Phase 197 propagation, overlay flows, portal UI, and Storybook-wide sweeps stay out of scope. — Preserves the 196-05 ownership boundary while proving EXE-03/PGH-01 on the exemplar.
- [Phase 196]: DataTable loading status supports page-specific copy through loading_label while preserving a generic default. — Browser validation required exact Subscriptions loading copy without breaking existing DataTable callers.
- [Phase 197]: Phase 197 Wave 0 remains validation-only: RED contracts define required LIST propagation behavior before runtime migrations. — 197-01 created test/support, ExUnit, and Playwright contracts only; runtime LIST changes are intentionally deferred to later Phase 197 plans.
- [Phase 197]: Phase 197 browser coverage is project-scoped instead of an exhaustive matrix. — Desktop all-page and representative deep checks run on chromium-desktop, while mobile all-page card smoke runs on chromium-mobile.
- [Phase 197-propagate-list]: 197-02 reused AccrueAdmin.ListContracts from 197-01 as the source of RED LiveView contract assertions. — Keeps route, list id, lens, state, and copy expectations aligned across ExUnit and browser validation.
- [Phase 197-propagate-list]: 197-02 remained test-only; runtime LIST propagation is intentionally left RED for follow-up implementation plans. — The plan objective was to lock LiveView contracts before runtime propagation work.
- [Phase 197]: Webhooks replay defaults decode through an allowlisted multi-status status param instead of atom conversion from raw URL text. — Prevents arbitrary existing atoms from URL input while preserving failed/dead replay queue semantics.
- [Phase 197]: Connect Needs attention is a query-owned OR lens; individual readiness filters remain explicit AND filters. — Default queue behavior now matches operator intent without changing explicit filter composition.
- [Phase 197]: Payments owner scope is enforced in Charges.list/1 and count_newer_than/1 through the joined customer owner relation. — Charges already joins Customers for list projection, matching the existing Invoices tenant-boundary pattern.
- [Phase 197]: 197-04: Customers stays all-default while exposing Missing payment method as a quick lens.
- [Phase 197]: 197-04: Coupons and Promotion codes use valid=true/active=true defaults with view=all as the all-records escape hatch.
- [Phase 197]: 197-04: PageHeader owns list filters while DataTable exposes list_status for FilterChipBar counts and chips.
- [Phase ?]: Kept payments backed by AccrueAdmin.Queries.Charges while presenting payment terminology in the LIST UI.
- [Phase ?]: Preserved organization scope through default queue redirects, clear-all links, row links, and summary counts for invoices and payments.
- [Phase 197]: Plan 197-06 keeps Webhooks replay page-local while making status=failed,dead the default Needs replay lens. — Replay selected IDs cross into DLQ.requeue side effects, so scoped selection/detail guards stayed in WebhooksLive instead of being generalized.
- [Phase 197]: Plan 197-06 keeps Events as an all-ledger default and exposes Admin changes via actor_type=admin. — Events is an append-only audit ledger, so bare /events must not manufacture a queue or hide rows.
- [Phase 197]: Plan 197-06 uses Connect needs_attention=true as the OR readiness lens instead of composing readiness filters. — The Plan 03 query seam owns the OR semantics for deauthorized, onboarding, charges, and payouts attention states.
- [Phase 197]: Phase 197 browser smoke waits for LiveView default URL push_patch before asserting queue params. — The final Playwright gate exposed a timing-only failure when URL params were sampled immediately after login.
- [Phase 197]: Phase 197 query contract tests assert filtered inclusion/exclusion instead of singleton global fixture lists. — The focused gate can run after E2E fixtures seed additional valid rows, so tests must prove semantics rather than database exclusivity.

### Pending Todos

- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) — Capture follow-up from CohortFlow `/billing` UAT: make `accrue_portal` white-label friendly, align the demo portal with host brand colors, style the unstyled `/billing/subscriptions` `View details` link, and plan a broader portal UI component/design-system pass.
- **[RESOLVED 2026-06-18 via `/gsd-debug`] Phase-187 `Admin live interaction baseline` e2e times out (>300s).** Root cause was NOT DOM-size/per-node iteration (disproven — selectors resolve in 10–80ms): `probeAffordanceAndStates` called unbounded `await locator.hover()` on a disabled `.ax-button` (Phase 189 added disabled specimens to the kitchen); `.ax-button:disabled` has `pointer-events: none` (app.css:1332), so Playwright's hover actionability check never resolves and inherits the 180s test budget — ×2 serial projects → >300s. Fix: bound `hover()`/`focus()` with `{ timeout: 1_000 }` in `accrue_admin/e2e/admin-interactions.spec.js`. Re-verified: 2 passed (25.7s) both projects. Session: `.planning/debug/resolved/phase-187-baseline-timeout.md`.
- **[RESOLVED 2026-06-18 via `/gsd-quick` 260618-3pu] Component-lab family headers used `String.upcase(family)`** (rendered "BUTTON"/"FORM-FIELD"). Replaced with a `family_label/1` map in `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` covering all 16 `applicable_states` families with the approved Phase-189 UI-SPEC `####` copywriting labels + a humanizing catch-all for future families. `189-UI-REVIEW.md` WARNING discharged.

### Blockers/Concerns

- (Resolved/obsolete: the 190-05 `admin-baseline.spec.js` hang note was cleared 2026-06-21 — Phase 190 and the full v1.53 milestone subsequently shipped & verified, so the bounded-retry concern no longer applies.)
- Phase 196 final full-suite gate: cd accrue_admin && mix test --warnings-as-errors fails outside Phase 196 in dashboard_live_test.exs:91 (missing $42.50) and webhooks_live_test.exs:106 (audit count expected 1, observed 2). Focused Phase 196 tests, package docs, assets, and e2e:phase196 pass.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260618-3pu | Component-lab family-label map (replace `String.upcase(family)` with UI-SPEC labels) | 2026-06-18 | b5cf3527 | [260618-3pu-component-lab-family-label-map](./quick/260618-3pu-component-lab-family-label-map/) |
| 260620-gmv | Green main CI — format test file + harden CMP-05 xargs guards (GNU-vs-BSD portability) | 2026-06-20 | 0ce75413 | [260620-gmv-fix-ci-format-xargs](./quick/260620-gmv-fix-ci-format-xargs/) |
| 260620-lie | Fix host login 500 — validate stale `active_organization_id` against live memberships before session insert (FK crash) | 2026-06-20 | 69867bb9 | [260620-lie-fix-stale-active-org-login](./quick/260620-lie-fix-stale-active-org-login/) |
| 260620-luy | Use the real Accrue brand mark in admin chrome (sidebar + favicon), theme-aware; white-label `logo_url` still overrides | 2026-06-20 | d307f091 | [260620-luy-admin-brand-mark](./quick/260620-luy-admin-brand-mark/) |
| 260620-mfh | Host dev DX — hot-reload sibling Accrue libs (`reloadable_apps` + live_reload `dirs`/patterns), no `restart web`; CSS still needs `assets.build` | 2026-06-20 | 60920f46 | [260620-mfh-host-sibling-hot-reload](./quick/260620-mfh-host-sibling-hot-reload/) |
| 260620-mn0 | Admin sidebar — render combined Accrue logo lockup (one theme-aware SVG), drop duplicated `app_name`/`Accrue Admin` brand text | 2026-06-20 | 54163ace | [260620-mn0-admin-sidebar-logo-lockup](./quick/260620-mn0-admin-sidebar-logo-lockup/) |
| 260620-n4q | Redesign theme picker as on-brand segmented control (icon+text, radiogroup+arrow-keys); extract `ThemePicker` component + register in component lab | 2026-06-20 | ec45880e | [260620-n4q-theme-picker-segmented](./quick/260620-n4q-theme-picker-segmented/) |
| 260620-ps2 | Elevate Timeline into a proper on-brand timeline — continuous vertical rail + threaded-feed entries (borderless, hover surface), reuse `StatusBadge` (tone passthrough), `<time>` tabular figures, dedicated empty state; register `timeline` family in component lab | 2026-06-20 | f6cda082 | [260620-ps2-elevate-the-timeline-component-into-a-pr](./quick/260620-ps2-elevate-the-timeline-component-into-a-pr/) |
| 260621-h72 | Webhooks DLQ page — design-system tightening + selection-driven retry | 2026-06-21 | 745462ec | [260621-h72-webhooks-dlq-design-system-tightening-an](./quick/260621-h72-webhooks-dlq-design-system-tightening-an/) |
| 260622-nob | Finish host Playwright e2e CI green-up (spec-drift realigns + stale committed copy_strings.json regen) | 2026-06-22 | 0a2f25ba | [260622-nob-fix-two-host-playwright-e2e-spec-drift-a](./quick/260622-nob-fix-two-host-playwright-e2e-spec-drift-a/) |
| 260621-idn | Fix `/billing/events` crash (`FunctionClauseError` in `Cursor.encode/2`) — widen cursor to integer PKs + 3 regression specs | 2026-06-21 | 4a937532 | [260621-idn-fix-admin-events-cursor-crash-integer-pk](./quick/260621-idn-fix-admin-events-cursor-crash-integer-pk/) |
| 260621-io6 | Shared DataTable UX + customers redesign (infinite scroll, SPA filters, click-to-copy IdBadge) | 2026-06-21 | 12e64d57 | [260621-io6-shared-datatable-infinite-scroll-spa-fil](./quick/260621-io6-shared-datatable-infinite-scroll-spa-fil/) |
| 260621-knk | Realistic fictional-SaaS demo seed data (data-only `examples/accrue_host`, idempotent) | 2026-06-21 | fdb6daee | [260621-knk-realistic-fictional-saas-demo-seed-data-](./quick/260621-knk-realistic-fictional-saas-demo-seed-data-/) |
| 260621-lzc | Repair host e2e test `admin_webhook_replay_test.exs` orphaned by 260621-h72 (security property preserved) | 2026-06-21 | 42b75764 | [260621-lzc-repair-host-admin-webhook-replay-test-to](./quick/260621-lzc-repair-host-admin-webhook-replay-test-to/) |
| 260621-mr6 | Admin webhooks DataTable polish — truthful filtered-empty state, spacing, mobile-first filter grid, native checkboxes | 2026-06-21 | 9aa35ced | [260621-mr6-webhooks-datatable-polish](./quick/260621-mr6-webhooks-datatable-polish/) |
| 260621-nr8 | Admin nav — live navigation + visible loading stripe + remove sidebar collapse | 2026-06-21 | 76ea8393 | [260621-nr8-admin-nav-live-nav-no-collapse](./quick/260621-nr8-admin-nav-live-nav-no-collapse/) |
| 260621-olr | Admin list pages — compact stat strip + condensed instant-apply filter toolbar across all 9 list pages | 2026-06-21 | d127a7e0 | [260621-olr-list-page-stat-strip-filter-toolbar](./quick/260621-olr-list-page-stat-strip-filter-toolbar/) |
| 260622-fql | Admin page headers — one consistent JTBD-oriented voice across every section | 2026-06-22 | 68fb8bc5 | [260622-fql-admin-header-microcopy-voice](./quick/260622-fql-admin-header-microcopy-voice/) |
| 260622-h7h | Green the package-docs CI gate — app.css doc-contract violations (DSY-01 media annotation + FND-01/02 fixes) | 2026-06-22 | 60fb1c06 | [260622-h7h-dsy01-theme-picker-media-annotation](./quick/260622-h7h-dsy01-theme-picker-media-annotation/) |
| 260622-i2c | Green the accrue_admin Playwright browser UAT — 8 spec-drift realigns + 1 responsive `.ax-kpi-delta` fix | 2026-06-22 | 90952f5f | [260622-i2c-admin-uat-green-up](./quick/260622-i2c-admin-uat-green-up/) |

### Milestone Intake Rules

- Default to maintenance/release-readiness unless new work has a sourced adopter, correctness, security, operational, or strategic reason.
- Do not create a milestone for polish-only work with a documented workaround.
- Any processor-surface change must update runtime behavior, support matrix, docs, examples/verifiers, and release notes together.

## Deferred Items

### Acknowledged at v1.53 milestone close (2026-06-20)

9 open artifacts acknowledged and deferred at milestone close — all carryover from earlier milestones or future-roadmap work, none v1.53-scoped:

| Category | Item | Status |
|----------|------|--------|
| quick_task | admin-shared-detail-components (20260602) | missing (v1.50-era; superseded by shipped shared detail components) |
| quick_task | 260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p | unknown (historical) |
| quick_task | 260414-l9q-automate-phase-3-human-verification-item | unknown (historical) |
| quick_task | 260602-6xv-seamless-multi-project-docker-dx-for-exa | unknown (v1.49/v1.50 Docker DX; shipped) |
| quick_task | 260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem | unknown (Docker DX; shipped) |
| quick_task | 260605-dkx-docker-native-boot-shared-traefik-proxy | unknown (Docker DX; shipped, committed main 260605-dkx) |
| quick_task | 260605-gys-add-dedicated-admin-example-com-billing- | unknown (historical) |
| todo | 2026-06-19-brandbook-use-accrue-favicon.md | pending (brandbook follow-up) |
| todo | 2026-06-19-white-label-billing-portal-design-system.md | pending (future portal design-system pass) |

### v1.54 tooling note (recorded at milestone open 2026-06-24)

| Category | Item | Status | Note |
|----------|------|--------|------|
| tooling | TOOL-01 — adopt PhoenixStorybook | **adopted (v1.54)** | v1.53 extended the in-app `/dev/components` kitchen and deferred TOOL-01; v1.54 reverses that deferral — `phoenix_storybook` `only: [:dev, :test]` (STY-01..03). Kitchen stays as a second renderer (registry SSOT) backing Phase-189/190 drift tests. |
| tooling | TOOL-02 — pixel-diff visual-regression (Percy/Applitools) | deferred (continued) | Scored-cell forward-only gate over real composed routes is the mechanism; pixel-diff would flag every intentional v1.54 improvement as a regression. |
| tooling | TOOL-03 — publish `brandbook/tokens/tokens.css` as npm/CDN distributable | deferred | Not needed for the admin streamlining pass. |

### Known CI issue — nightly live-stripe canary red (deferred 2026-06-14)

The scheduled `live-stripe` job (`.github/workflows/ci.yml`, "Stripe test-mode parity (mandatory periodic)", 06:00 UTC cron + manual dispatch) fails every night. **Not merge-blocking** — it never runs on push/PR, so the main matrix stays green; this is the only red on the repo.

- **Root cause:** the job's `env:` block sets only PG + `STRIPE_TEST_SECRET_KEY` + `ACCRUE_LIVE_*`. With the Stripe secret absent the tests are *supposed* to skip cleanly, but the `accrue` app crashes earlier at boot — `** (Accrue.ConfigError) ACCRUE-DX-WEBHOOK-SECRET-MISSING` from `Accrue.Application.start/2` — because the job omits the webhook signing secret env the rest of the test matrix supplies. So `mix test.live` exits 1 before any test can skip.
- **Fix shape (when picked up):** add the webhook-secret env var to the `live-stripe` job, mirroring how the green matrix jobs provide it; then re-run via `gh workflow run` / dispatch to confirm green. Small, isolated CI-config change — good `/gsd-quick` or `/gsd-debug` candidate.
- **revisit_trigger:** wanting an all-green CI dashboard, or before relying on the live-Stripe parity canary to catch upstream Stripe API drift.

### Standing scope deferrals

| Category | Item | Status | Reason | Future owner/category | revisit_trigger | Deferred At |
|----------|------|--------|--------|-----------------------|-----------------|-------------|
| scope | Rich metered/tiered/range entitlement math (beyond seat counts) | out of scope v1.39 | Current entitlement support intentionally covers local plan and seat-style quantities without a sourced adopter contract for richer math. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math | 2026-05-22 |
| scope | Atomic seat enforcement / membership management | host-owned; documented recipe, not core API | Membership ownership remains app-specific and Accrue does not own host user/team schemas. | Host integration recipe | concrete adopter failure showing documented host-owned enforcement is insufficient | 2026-05-22 |
| scope | Typed upstream Stripe Entitlements resources + live API reads | deferred to `lattice_stripe >= 1.2` | Local entitlement truth is canonical; typed upstream reads wait on dependency capability. | Stripe advisory overlay | correctness/security/data-loss risk in advisory cache truth or explicit dependency capability change | 2026-05-22 |
| scope | Multi-channel (SMS/push) dunning via Chimeway | out of scope v1.45; deferred | In-app and email dunning closed the current story without adding extra compliance and channel-delivery scope. | Dunning ecosystem integration | repeated support issue or concrete adopter failure requiring SMS/push orchestration | 2026-05-28 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | Accrue is a billing/subscription library, not an accounting, merchant-of-record, or payout product. | Strategy non-goal | explicit strategy change or correctness/security/data-loss risk that cannot be handled by host-owned exports | carried |
| seed | SEED-002-ecosystem-integrations — Chimeway/Mailglass ecosystem integrations | backlogged; future-roadmap seed, not a closeout blocker | Ecosystem blueprints are dormant future-roadmap material and do not open milestone scope by themselves. | Future roadmap / ecosystem integrations | concrete adopter failure requiring an integration, repeated support issue, or explicit strategy change | 2026-05-31 |

## Session Continuity

Last session: 2026-06-28T18:47:27.921Z
Stopped at: Completed 197-07-PLAN.md
Resume file: None

## Operator Next Steps

- Plan the first phase with `/gsd-plan-phase 193`
