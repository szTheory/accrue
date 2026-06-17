---
gsd_state_version: 1.0
milestone: v1.53
milestone_name: Admin UI Design-System Hardening
status: executing
last_updated: "2026-06-17T00:00:00.000Z"
last_activity: 2026-06-17
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 12
  completed_plans: 12
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-14 — v1.53 Admin UI Design-System Hardening opened)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 189 — primitive & form components + component lab (next to plan)

## Current Position

Phase: 188 (foundations-hardening) — COMPLETE (2026-06-17, human_review: approved)
Plan: 7 of 7 complete
Status: Phase 189 not started — ready to plan (`/gsd-plan-phase 189` via `/gsd-ui-phase`)
Last activity: 2026-06-17

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.53 Admin UI Design-System Hardening is open as a quality / interaction-correctness / design-system investment in the already-shipped `accrue_admin` surface — not a broad feature milestone (no new billing primitives, no breaking API/route changes, no Tailwind migration). Reopen decision recorded in `PROJECT.md`. Justification class: explicit strategy change (design quality of the flagship adopter-facing surface elevated to a strategic priority — same class as v1.50/v1.51/v1.52) **plus firsthand-observed interaction defects** in the running demo.

## Milestone Progress

### v1.53 Phase Summary (OPEN — Admin UI Design-System Hardening; deps strictly linear 187→188→189→190→191→192)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 187 | Audit & Baseline | VER-01 | Complete (2026-06-15) |
| 188 | Foundations hardening | FND-01, FND-02, FND-03, FND-04, FND-05, FND-06 | Complete (2026-06-17, approved) |
| 189 | Primitive & form components + component lab | CMP-01, CMP-02, CMP-03, CMP-04, CMP-05 | Not started |
| 190 | Navigation, data-display & meta-component cohesion | GRP-01, GRP-02, GRP-03, GRP-04 | Not started |
| 191 | Page & flow interaction pass + fixture stress + microcopy | IXN-01..05, PAGE-01..04, CPY-01..03, SEED-01..02 | Not started |
| 192 | Idempotent verification & sign-off | VER-02, VER-03, VER-04 | Not started |

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

- Total plans completed: 121
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

## Accumulated Context

### Key Planning Decisions for v1.53

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

### Pending Todos

- None open.

### Blockers/Concerns

- None open.

### Milestone Intake Rules

- Default to maintenance/release-readiness unless new work has a sourced adopter, correctness, security, operational, or strategic reason.
- Do not create a milestone for polish-only work with a documented workaround.
- Any processor-surface change must update runtime behavior, support matrix, docs, examples/verifiers, and release notes together.

## Deferred Items

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

Last session: 2026-06-16T03:31:11.714Z
Stopped at: Completed 188-06-PLAN.md
Resume file: None

## Operator Next Steps

- v1.53 Admin UI Design-System Hardening is **open** with a created roadmap (Phases 187–192, strictly linear).
- Phase 187 is complete and verified; next gate is Phase 188 planning.
- Each phase is executed research-backed and verified via the GSD UI workflow (`/gsd-ui-phase` design-contract + `/gsd-ui-review`), with an adversarial multi-lens judge and a maintainer screenshot checkpoint at every phase boundary.

</content>
