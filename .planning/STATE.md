---
gsd_state_version: 1.0
milestone: v1.53
milestone_name: Admin UI Design-System Hardening
current_phase: 53
status: Awaiting next milestone
stopped_at: Completed 188-08-PLAN.md
last_updated: "2026-06-20T15:24:38.192Z"
last_activity: 2026-06-20
last_activity_desc: Milestone v1.53 completed and archived
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 39
  completed_plans: 39
  percent: 100
current_phase_name: (none — v1.53 complete)
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-14 — v1.53 Admin UI Design-System Hardening opened)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Planning next milestone (v1.53 shipped & archived 2026-06-20; stable core / demand-driven posture)

## Current Position

Phase: Milestone v1.53 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-22 — Completed quick task 260622-fql: admin page headers — one consistent JTBD-oriented voice across every section. Every section page's h1 + subtitle had inconsistent voice + internal-jargon leakage, and Recovery had no subtitle. Rewrote all to the /admin/customers philosophy (plain-noun h1 = nav label + two-part job-oriented subtitle, implementation-hidden), added the Recovery subtitle, extracted 4 inline headers into copy.ex helpers. Copy + tiny markup only — no CSS/JS, bundles untouched. `--validate` plan-check PASS (caught a missed events test assertion) + verify PASS 7/7, 350 tests/0 failures. Closed/superseded todo 260622-admin-page-header-microcopy-audit. Browser-only: confirm all 11 headers read consistently on demo. Earlier reminder still open: examples/accrue_host/mix.lock is environmentally stale on main (clean deps-bump re-pin is a good future task; also unblocks the host admin_webhook_replay_test.exs).
Prior activity: 2026-06-22 — Completed quick task 260621-olr: admin list pages — compact metrics ("stat strip") + condensed instant-apply filter toolbar across all 9 list pages. Research-backed (2 design sweeps + brand/JTBD). NEW StatStrip `<dl>` component (chromeless, tone-on-value, dev-lab registered) replaces the ~200px KPI card grid (→~48-56px); filter form condensed to a single self-labeling toolbar (dropped redundant Apply button; `:select` `all_label`; Clear-when-active); 2-3-value selects → segmented toggles incl. owner_type dynamic ≤3⇒segmented (fixes the 2-value-dropdown complaint). KpiCard untouched on dashboard/recovery/detail. `--validate` plan-check PASS 1st iter (3 corrections folded in) + verify PASS 7/7, 350 tests/0 failures, css bundle rebuilt. 4 browser-only visuals to confirm. NEW TODO captured: 260622-admin-page-header-microcopy-audit (per-section h1+subtitle microcopy consistency, JTBD-oriented, modeled on /admin/customers; recovery page currently has no subtitle) — `.planning/todos/`. Earlier reminder still open: `examples/accrue_host/mix.lock` is environmentally stale on main (a clean deps-bump re-pin remains a good future task; also blocks re-running the host admin_webhook_replay_test.exs).
Prior activity: 2026-06-21 — Completed quick task 260621-nr8: admin nav — live navigation + visible loading stripe + remove sidebar collapse. One root cause for both complaints: sidebar links were plain `<a href>` → full page reloads (no `phx:page-loading-*` so the wired `topbar` stripe never fired; LiveView re-mount replayed the `SidebarCollapse` opacity flash). Fix = `<.link navigate>` (all admin pages share one `live_session`) → stripe fires + morphdom keeps the sidebar; topbar delay 300→120ms; collapse feature removed entirely (badges kept), `sidebar_collapse.js` deleted, bundles rebuilt. `--validate` plan-check PASS 1st iter + verify PASS 7/7, 348 tests/0 failures, spec-gap proven. 3 browser-only visuals to confirm on the demo (stripe on nav, no sidebar flash, badges still show). Reminder still open: `examples/accrue_host/mix.lock` is environmentally stale on main (published deps moved past pins) — a clean deps-bump re-pin is a good future task (also blocks re-running the host `admin_webhook_replay_test.exs`).

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.53 Admin UI Design-System Hardening is open as a quality / interaction-correctness / design-system investment in the already-shipped `accrue_admin` surface — not a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration). Reopen decision recorded in `PROJECT.md`. Justification class: explicit strategy change (design quality of the flagship adopter-facing surface elevated to a strategic priority — same class as v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo.

## Milestone Progress

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

**v1.52** (shipped & archived **2026-06-14**): 7 phases (**180–186**), 14 requirements. Theme: Brand System. See `.planning/milestones/v1.52-ROADMAP.md`.

**v1.51** (shipped & archived **2026-06-04**): 6 phases (**174–179**), 22 requirements. Theme: Admin UI Depth Pass. Audit: `.planning/milestones/v1.51-MILESTONE-AUDIT.md`.

**v1.49** (shipped & archived **2026-06-02**): 4 phases (**163–166**), 11 requirements. Theme: Realistic Demo App & Adoption Evidence. Audit: `.planning/milestones/v1.49-MILESTONE-AUDIT.md`.

**v1.48** (shipped & archived **2026-06-01**): 4 phases (**159–162**), 9 requirements. Theme: Release Readiness + Stable Core Posture. Audit: `.planning/v1.48-v1.48-MILESTONE-AUDIT.md` (or equivalent closeout proof).

**v1.47** (shipped & archived **2026-05-31**): 5 phases (**154–158**), 11 requirements. Theme: ENT-10 Polish + Adopter-Proof Completeness. Audit: `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 129
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

## Accumulated Context

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
- **v1.51 Admin UI Depth Design:** `.planning/research/v1.51-admin-ui-depth-design.md` (prior design source carried forward for v1.53)
- **v1.52 Brand System Design:** `.planning/research/v1.52-brand-system-design.md`

### Roadmap Evolution

- v1.48 shipped and archived 2026-06-01: Phases 159–162
- v1.49 shipped and archived 2026-06-02: Phases 163–166
- v1.50 shipped and archived 2026-06-03: Phases 167–173
- v1.51 shipped and archived 2026-06-04: Phases 174–179
- v1.52 shipped and archived 2026-06-14: Phases 180–186
- v1.53 opened 2026-06-14: Phases 187–192 (continue-numbering)

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

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

### Pending Todos

- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) — Capture follow-up from CohortFlow `/billing` UAT: make `accrue_portal` white-label friendly, align the demo portal with host brand colors, style the unstyled `/billing/subscriptions` `View details` link, and plan a broader portal UI component/design-system pass.
- **[RESOLVED 2026-06-18 via `/gsd-debug`] Phase-187 `Admin live interaction baseline` e2e times out (>300s).** Root cause was NOT DOM-size/per-node iteration (disproven — selectors resolve in 10–80ms): `probeAffordanceAndStates` called unbounded `await locator.hover()` on a disabled `.ax-button` (Phase 189 added disabled specimens to the kitchen); `.ax-button:disabled` has `pointer-events: none` (app.css:1332), so Playwright's hover actionability check never resolves and inherits the 180s test budget — ×2 serial projects → >300s. Fix: bound `hover()`/`focus()` with `{ timeout: 1_000 }` in `accrue_admin/e2e/admin-interactions.spec.js`. Re-verified: 2 passed (25.7s) both projects. Session: `.planning/debug/resolved/phase-187-baseline-timeout.md`.
- **[RESOLVED 2026-06-18 via `/gsd-quick` 260618-3pu] Component-lab family headers used `String.upcase(family)`** (rendered "BUTTON"/"FORM-FIELD"). Replaced with a `family_label/1` map in `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` covering all 16 `applicable_states` families with the approved Phase-189 UI-SPEC `####` copywriting labels + a humanizing catch-all for future families. `189-UI-REVIEW.md` WARNING discharged.

### Blockers/Concerns

- None. (Resolved/obsolete: the 190-05 `admin-baseline.spec.js` hang note was cleared 2026-06-21 — Phase 190 and the full v1.53 milestone subsequently shipped & verified, so the bounded-retry concern no longer applies.)

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
| 260620-qkx | De-duplicate admin orientation chrome (topbar → utility bar: search/menu/theme only; drop eyebrow + brand chip; remove redundant page-header eyebrows; promote each page hero to a single `<h1>`) + add a Turbo-style navigation loading bar (vendored MIT `topbar`, `--ax-accent`-colored, reduced-motion aware; no CSP weakening — CSSOM setters are style-src-exempt) | 2026-06-20 | c16eca09 | [260620-qkx-de-duplicate-admin-orientation-chrome-ut](./quick/260620-qkx-de-duplicate-admin-orientation-chrome-ut/) |
| 260621-h72 | Webhooks DLQ page — design-system tightening + selection-driven retry (`--validate`, 6 atomic commits): suppress UA focus ring on programmatic `main` focus (no dark-mode blue box); tidy `KpiCard` footer (no-wrap pill + `.ax-kpi-meta` caption) + define `--ax-accent-contrast`; emit `DataTable` selection to parent (`{:data_table_bulk_action, …}`) + plural footer "Showing N events" + flip `selectable` default to false (drops orphaned checkboxes on 8 pages); webhooks selection-driven Retry-selected + jargon-free confirm/audit; filter overhaul (Type `:datalist` autocomplete, Status counts+disabled, Live-mode `:segmented` primitive) + admin `distinct_types/1`+`status_counts/1` queries + `segmented` lab family. 329 tests/0 failures. Verify=Needs Review (3 browser-only visuals) | 2026-06-21 | 745462ec | [260621-h72-webhooks-dlq-design-system-tightening-an](./quick/260621-h72-webhooks-dlq-design-system-tightening-an/) |
| 260621-idn | Fix `/billing/events` crash (`FunctionClauseError` in `Cursor.encode/2`) — spec-driven (`--validate`, Part A of 3). Root cause: `Event` has an integer PK but `Cursor.encode/2` was guarded `is_binary(id)`, so pagination past the page limit (>25 rows) raised. Fix (cursor.ex only): widen `@type`/`encode`/`decode` to `is_binary(id) or is_integer(id)`; HMAC sign/verify + token guard untouched. Closed the coverage gap with 3 regression specs (integer-id cursor round-trip; events query 2-page pagination; events LiveView render + load-more) — verifier independently proved they fail pre-fix with the exact crash, pass post-fix. 332 tests/0 failures. Verify=Verified | 2026-06-21 | 4a937532 | [260621-idn-fix-admin-events-cursor-crash-integer-pk](./quick/260621-idn-fix-admin-events-cursor-crash-integer-pk/) |
| 260621-io6 | Shared DataTable UX + customers redesign (`--validate`, Part B of 3, 5 atomic commits; 2 plan-check iterations caught + fixed 2 correctness blockers). DataTable (shared, all 9 list pages): infinite scroll via `phx-viewport-bottom` sentinel (Load-more kept as a11y fallback) + SPA `push_patch` filters via new `AccrueAdmin.DataTableNav.patch_with_filters/3` (MERGES into existing query → single `?`, preserves `?org=`; per-page `data_table_filter` handlers) + filter-toolbar spacing. New shared click-to-copy `IdBadge` (REGISTERED per-element `Clipboard` LiveView hook so dynamically-rendered/scrolled rows bind — the old one-shot binder wouldn't) + `:copy` icon + lab `id-badge` family. Customers: jargon-free copy ("Customers" + plain description), lean find-and-open columns (name+email / Payment method / copy-id chip), dropped Owner-types KPI + always-"Off" Billing-signals column, owner-type dropdown from `distinct_owner_types/1`. 347 tests/0 failures. Verify=Needs Review (4 browser-only behaviors) | 2026-06-21 | 12e64d57 | [260621-io6-shared-datatable-infinite-scroll-spa-fil](./quick/260621-io6-shared-datatable-infinite-scroll-spa-fil/) |
| 260621-knk | Realistic fictional-SaaS demo seed data (`--validate`, Part C of 3, 2 atomic commits, data-only `examples/accrue_host`). The 26 `phase191` page customers get Faker company/person names + emails + varied `owner_type` (Organization/User/Team/Workspace, populating the new owner-type dropdown); 23/26 get a payment method on file (`pm_phase191_host_page_NN` + back-set `default_payment_method_id`); first 10 get a coherent linked subscription/invoice/charge graph with a realistic status mix (past_due+dunning anchor, trialing, JPY zero-decimal, active+paid) so detail pages/KPIs/signals populate. PRESERVED all `processor_id` prefixes, idempotency keys, primary customer 株式会社/Café + nil-PM, "Crème"/"ÉTÉ191", 26-boundary, 28-customer total; fixture counts updated in lockstep (subs 2→12, invoices 1→11, charges 1→11). Idempotent (seed evals twice, counts stable). Verify=Verified | 2026-06-21 | fdb6daee | [260621-knk-realistic-fictional-saas-demo-seed-data-](./quick/260621-knk-realistic-fictional-saas-demo-seed-data-/) |
| 260621-lzc | Repair host e2e test `admin_webhook_replay_test.exs` orphaned by 260621-h72 (`--validate`, test-only). h72's webhooks redesign removed the filter-driven `prepare-bulk-replay` button the host security test clicked; h72 only ran the accrue_admin suite so the host regression slipped through. Rewrote the bulk step to the new selection-driven contract WITHOUT weakening the security property: layer-1 (out-of-scope/ambiguous webhooks absent from the org-scoped list + empty-state, no bulk-action affordance) + layer-2 defense-in-depth (inject hostile ids via `send(pid, {:data_table_bulk_action,"retry_selected",ids})` → click `confirm-retry-selected` → `replay_blocked` warning, nothing requeued); asserts ZERO of BOTH `admin.webhook.replay.completed` AND the new `admin.webhook.bulk_replay.completed` audits. File 2/2 green; host `test/accrue_host_web/` 109/0. Verify=Verified | 2026-06-21 | 42b75764 | [260621-lzc-repair-host-admin-webhook-replay-test-to](./quick/260621-lzc-repair-host-admin-webhook-replay-test-to/) |
| 260621-mr6 | Admin webhooks DataTable polish — 4 fixes to the SHARED `DataTable` so all list pages benefit (`--validate`, plan-check PASS 1st iter, 4 atomic commits). (1) **Truthful empty state** (DataTable-owned, reusable, non-breaking opt-in): filtered-to-zero now shows "No webhook deliveries match these filters" not the truly-empty "…for this organization yet" lie — `assign_new(:filtered_empty_title/copy, nil)` + `resolve_empty_state/1` derives `resolved_empty_*` (filtered copy only when filters active AND supplied, else falls back → opt-out pages byte-identical); +4 `Copy` helpers (webhooks-specific + generic `data_table_filtered_empty_*`); only `webhooks_live.ex` opts in. (2) **Spacing**: new base `.ax-data-table{display:flex;flex-direction:column;gap:--ax-space-lg}` (none existed) — filters no longer flush against results/empty card. (3) **Filter toolbar → mobile-first grid**: `.ax-data-table-filters` flex→grid (1-col mobile; `@md` `repeat(auto-fit,minmax(12rem,1fr)) auto`, actions `justify-self:end`); tokens-only. (4) **Select buttons → native checkboxes** (reuse `.ax-checkbox`): per-row grid+card + single shared select-all are `<input type=checkbox>`, `<th>` label `ax-visually-hidden`; ALL pinned contracts preserved (`data-role`/`data-phase191-focus`/`data-row-id`/`aria-label`), exactly one `[data-role='toggle-all']`; select-all label reuses `.ax-field-inline` → no new class, zero registry churn. Rebuilt committed `accrue_admin.css` (js byte-identical). Spec-gap proven (filtered assertions fail pre-change, pass post). 348 tests/0 failures. Verify=Verified (host `admin_webhook_replay_test.exs` not re-run — needs `deps.get` on off-limits stale `mix.lock`; zero host files changed, contracts independently covered). Browser-only: 4 visuals to confirm on demo | 2026-06-21 | 9aa35ced | [260621-mr6-webhooks-datatable-polish](./quick/260621-mr6-webhooks-datatable-polish/) |
| 260621-nr8 | Admin nav — live navigation + visible loading stripe + remove sidebar collapse (`--validate`, plan-check PASS 1st iter, verify PASS 7/7, 3 atomic commits). **One root cause for both complaints**: sidebar links were plain `<a href>` (`sidebar.ex:76`) → every section nav was a FULL PAGE RELOAD, which never fired `phx:page-loading-*` (so the already-wired `topbar` stripe stayed dead) AND re-mounted the LiveView so the `SidebarCollapse` hook re-inited from localStorage + replayed its opacity transition (the "collapse/re-expand on every navigation" flash). All admin pages share one `live_session :accrue_admin`, so the fix is client-side live nav. (1) **Live nav + stripe**: `<a href>`→`<.link navigate>` (renders `href`+`data-phx-link="redirect"`) — topbar now fires AND morphdom preserves the sidebar DOM; `app.js` topbar show-delay 300→120ms (perceptible on fast local navs; reduced-motion still instant). No other plain internal `<a href>` existed (sweep = no-op). (2) **Collapse removed entirely** (user: "what is even the point… get rid of that"), **badges kept**: `<section>` lost `phx-hook`/`data-*`; `if collapsible <button> else <p>` → single static `<p class="ax-sidebar-group-label">` carrying the badge; deleted `group_initially_expanded?/1`, dropped `collapsible` from `grouped_items/1` meta + all 11 `nav.ex` maps; removed `SidebarCollapse` import/hook + `git rm` `sidebar_collapse.js`; CSS dropped `.ax-sidebar-group-toggle`/`-chevron`/`.ax-collapsed`/group-links opacity transition, merged badge flex/gap into `.ax-sidebar-group-label`; removed stale component-kitchen motion row. Rebuilt committed `accrue_admin.{css,js}` (bundles grep-clean of `SidebarCollapse`/`.ax-sidebar-group-toggle`). Spec-gap proven (`data-phx-link="redirect"` assert fails pre-change, passes post). Lone deviation: loosened `app_shell_test` exact href/class adjacency to single-tag regex (intent preserved). 348 tests/0 failures. Verify=Verified. Browser-only: confirm stripe + no-flash + badges on demo | 2026-06-21 | 76ea8393 | [260621-nr8-admin-nav-live-nav-no-collapse](./quick/260621-nr8-admin-nav-live-nav-no-collapse/) |
| 260621-olr | Admin list pages — compact metrics (stat strip) + condensed instant-apply filter toolbar, across all 9 list pages (`--validate`, plan-check PASS 1st iter w/ 3 corrections folded in, verify PASS 7/7, 5 atomic commits). Research-backed (2 design sweeps + brand/JTBD mining): oversized KPI cards + a tall label-stacked filter form pushed the table below the fold. **Part A — stat strip**: NEW `components/stat_strip.ex` chromeless `<dl class="ax-stat-strip">` + `:stat` slot (label/value/optional tone moss|cobalt|amber/href), tone colors VALUE only (no wash), hairline dividers, tokens-only CSS, stacks <30rem; dev-lab `stat-strip` family + dedicated `do_render_specimen` (guardrail 8/8). Migrated all 9 list pages (customers/subscriptions/invoices/charges/webhooks/events/coupons/promotion_codes/connect) from `ax-kpi-grid`+KpiCard → StatStrip, dropped `<:meta>` captions; cuts ~200px band → ~48-56px. KpiCard UNTOUCHED on dashboard/recovery/detail (frozen). **Part B — filter toolbar**: data_table.ex single flex toolbar (search grows; wraps <768px); per-field labels→`ax-visually-hidden`; DROPPED visible Apply button (instant `phx-change`; text debounced 300ms) but kept visually-hidden submit (preserves `filter-submit` anchor); context-only Clear gated by `any_filter_active?/1`; `:select` primitive gained `all_label` so default option names its dimension ("All owner types"). **Control-type reassignment**: 2-3-value `:select`s → `:segmented` (prepend `{"","All"}`): customers has_default_payment_method, invoices collection_method, charges fees_settled, coupons valid, promo active, connect type+charges_enabled+payouts_enabled+details_submitted+deauthorized (6 cats, plan-check-corrected, no livemode on connect). **owner_type** dynamic branch `length(options)<=3 → :segmented, else :select` → the 2-value Org/User case is now a toggle not a dropdown (the user's complaint). Webhooks keeps select+counts/datalist/segmented; subs/invoices status stay select. Rebuilt committed accrue_admin.css (js byte-unchanged). 350 tests/0 failures. Verify=Verified. Accepted deviation: did NOT flip webhook_live_test.exs:82 (`ax-kpi-grid`) — that's the DETAIL page (keeps KpiCard); plan-check misattributed detail-vs-list. Browser-only: 4 visuals to confirm on demo. Related follow-up: todo 260622-admin-page-header-microcopy-audit | 2026-06-21 | d127a7e0 | [260621-olr-list-page-stat-strip-filter-toolbar](./quick/260621-olr-list-page-stat-strip-filter-toolbar/) |
| 260622-fql | Admin page headers — one consistent JTBD-oriented voice across every section (`--validate`, plan-check PASS w/ corrections incl. a missed events test assertion, verify PASS 7/7, 3 atomic commits). Copy + tiny markup only — NO CSS/JS, bundles untouched (no rebuild). Fixed: every section page's `h1.ax-display` + `p.ax-body.ax-page-copy` subtitle had inconsistent voice + leaked internal jargon (facade/query layer/projections/audit seams/server-side/admin surface/Lifecycle-safe/dedicated admin surface), and **Recovery had NO subtitle**. Rewrote all to the `/admin/customers` philosophy: plain-noun h1 (= nav label) + two-part "[what this is, domain terms]. [how you navigate/act — search/filter/open]", brand voice (Measured/Exact/Native/Durable), domain-native but implementation-hidden, not boilerplate. Strings rewritten in place (no fn rename): copy/billing_event.ex (events→"Event log" org+global + append-only subtitles), copy/{invoice→"Invoices",coupon→"Coupons",promotion_code→"Promotion codes",connect→"Connected accounts"}.ex + new subtitles. 4 NEW helpers in copy.ex (subscriptions/charges/webhooks/recovery _index_heading+_subtitle); wired subscriptions/charges/webhooks_live (dropped inline literals) + recovery_live (h1→Copy + ADDED `<p ax-page-copy>` after .ax-heading-row, before WindowSelector). Dashboard+Customers unchanged (reference). Tests: 5 literal assertions repointed to Copy.<fn>() (incl. events_live_test:172 — the blocker first grep missed) + Recovery subtitle assertion added; copy_test CPY-03 + assets_test green. 350 tests/0 failures. Verify=Verified. Closes/supersedes todo 260622-admin-page-header-microcopy-audit (deleted). Browser-only: confirm all 11 section headers read consistently on demo | 2026-06-22 | 68fb8bc5 | [260622-fql-admin-header-microcopy-voice](./quick/260622-fql-admin-header-microcopy-voice/) |

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

### v1.53 deferrals (recorded at milestone open 2026-06-14)

| Category | Item | Status | Reason | Revisit trigger |
|----------|------|--------|--------|-----------------|
| tooling | TOOL-01 — adopt PhoenixStorybook | deferred | v1.53 extends the in-app `/dev/components` kitchen to avoid a shipped-lib dependency. | concrete adopter/contributor failure where the in-app kitchen is insufficient, or explicit strategy change |
| tooling | TOOL-02 — pixel-diff visual-regression (Percy/Applitools) | deferred | Screenshot + adversarial-judge loop preferred for now. | flaky/insufficient screenshot+judge loop, or explicit strategy change |
| tooling | TOOL-03 — publish `brandbook/tokens/tokens.css` as npm/CDN distributable | deferred | Not needed for the admin hardening pass. | external doc/marketing-site need for distributable tokens |

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

Last session: 2026-06-20T13:50:23.911Z
Stopped at: Completed 188-08-PLAN.md
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
