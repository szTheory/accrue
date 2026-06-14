---
gsd_state_version: 1.0
milestone: v1.52
milestone_name: Brand System
status: milestone_complete
last_updated: 2026-06-14T15:30:00.000Z
last_activity: 2026-06-14 -- v1.52 Brand System archived (ROADMAP+REQUIREMENTS snapshots, MILESTONES.md + RETROSPECTIVE.md entries, PROJECT.md evolution, git tag v1.52)
progress:
  total_phases: 7
  completed_phases: 7
  total_plans: 29
  completed_plans: 29
  percent: 100
stopped_at: Milestone complete (Phase 186 was final phase)
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-14 — v1.52 Brand System shipped & archived)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** No milestone open — stable-core / demand-driven expansion posture (post-v1.48 pause rule)

## Current Position

Phase: 186
Plan: Not started
Status: Milestone complete
Last activity: 2026-06-14

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.52 is a brand/DX investment in adopter-facing presentation surfaces (README, Hex.pm, HexDocs, social previews, admin UI identity) — not a broad feature milestone (no new billing primitives). Reopen decision recorded in `PROJECT.md`. Justification class: same as v1.50/v1.51.

## Milestone Progress

### v1.52 Phase Summary (OPEN — Brand System; deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 180 | Brand Audit & DNA Lock | AUD-01, AUD-02, AUD-03 | Complete (2026-06-12) |
| 181 | SVG Pipeline + Tournament Round 1 — Divergent | LOGO-01, LOGO-02 | Complete (2026-06-12) |
| 182 | Tournament Convergent Refinement | LOGO-03 | Complete (2026-06-13) |
| 183 | Logo System Production | LOGO-04 | Complete (2026-06-13) |
| 184 | Design Tokens & Specimens | TOK-01, TOK-02, TOK-03 | Complete (2026-06-14) |
| 185 | Voice, Microcopy & Marketing Copy | COPY-01, COPY-02 | Complete (2026-06-14) |
| 186 | HTML Brand Book Assembly & Quality Gate | BOOK-01, BOOK-02 | Complete (2026-06-14) |

Coverage: 14/14 v1.52 requirements mapped (each REQ-ID → exactly one phase). Design source: `.planning/research/v1.52-brand-system-design.md`.

**Hard logo constraints (binding on every candidate):** no rectangular background/container shape behind the logomark; logotype sits optically close to the mark; main lockup carries no subtitle (with-subtitle variant ships separately); fully-integrated custom typemark options required. **Seed latitude is evidence-gated:** Geist + existing palette are defaults; changes require a cited failure (contrast, distinctiveness, 16px rendering) and user ratification at Phase 180 checkpoint.

**Dependency shape:** 180 → 181 → 182 → 183 → 186, with 180 → {184, 185} → 186 as parallel side-rails (tokens and copy can execute while tournament rounds await user verdicts).

**Human checkpoints:** Phase 180 (audit verdicts + DNA ratification + logo brief), Phase 181 (round-1 winner picks), Phase 182 (looping — one checkpoint per refinement round until winner locked), Phase 183 (light: derivative-sheet eyeball), Phase 185 (light: batch copy review), Phase 186 (final UAT).

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

**v1.51** (shipped & archived **2026-06-04**): 6 phases (**174–179**), 22 requirements. Theme: Admin UI Depth Pass. Audit: `.planning/milestones/v1.51-MILESTONE-AUDIT.md`.

**v1.49** (shipped & archived **2026-06-02**): 4 phases (**163–166**), 11 requirements. Theme: Realistic Demo App & Adoption Evidence. Audit: `.planning/milestones/v1.49-MILESTONE-AUDIT.md`.

**v1.48** (shipped & archived **2026-06-01**): 4 phases (**159–162**), 9 requirements. Theme: Release Readiness + Stable Core Posture. Audit: `.planning/v1.48-v1.48-MILESTONE-AUDIT.md` (or equivalent closeout proof).

**v1.47** (shipped & archived **2026-05-31**): 5 phases (**154–158**), 11 requirements. Theme: ENT-10 Polish + Adopter-Proof Completeness. Audit: `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 115
- Average duration: 1m
- Total execution time: 1m

## Accumulated Context

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
- **v1.52 Brand System Design:** `.planning/research/v1.52-brand-system-design.md` (authoritative design source)

### Roadmap Evolution

- v1.48 shipped and archived 2026-06-01: Phases 159–162
- v1.49 shipped and archived 2026-06-02: Phases 163–166
- v1.50 shipped and archived 2026-06-03: Phases 167–173
- v1.51 shipped and archived 2026-06-04: Phases 174–179
- v1.52 opened 2026-06-11: Phases 180–186

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-06-11:** Opened v1.52 "Brand System". This explicitly does not open new broad feature scope, but rather invests in adopter-facing brand presentation surfaces (logo, brand book, design tokens, voice/copy). Roadmap created with 7 phases (180–186).
- **2026-06-02:** Closed v1.49 after fresh audit passed 11/11 requirements and archived ROADMAP, REQUIREMENTS, MILESTONE-AUDIT, and phase artifacts under `.planning/milestones/`.
- [Phase ?]: AttentionCounts extracted into shared context fn; NavBadgeHook post-auth with DB-error rescue; Nav.items/3 backward-compat via default arg; SidebarCollapse localStorage key prefixed with mount_path
- [Phase ?]: URI.encode/1 applied to :id in RedirectController for path traversal prevention
- [Phase ?]: live('/events/:id') route stub in router.ex; EventLive ships in Wave 3; warning-not-error compile status confirmed
- [Phase ?]: EventLive not-found redirect omits put_flash (fetch_flash missing from accrue_admin_browser pipeline)
- [Phase ?]: motion.md is the authoritative justification record for Phase 177 — no entry means no animation permitted; all 9 surfaces catalogued with enter/exit asymmetry
- [Phase ?]: SIGN-OFF.md photographic gate uses [PENDING] placeholders; before-column sourced from 176-SCORECARD after-scores (21/21 ≥2)
- [Phase ?]: contrast.js uses WCAG 2.0 normative threshold 0.03928; 21-pair table committed as canonical evidence for all Phase 180 palette audit verdicts
- **2026-06-12 (180-02):** All palette verdicts in BRAND-AUDIT.md §1–§8 are TIGHTEN (usage-rule restrictions) — no REWORK; no hex changes proposed; --accrue-fog and --accrue-cobalt are brand-only tokens with no current --ax-* semantic binding; §8 four hard logo constraints authored verbatim with four Phase 181 conceptual directions
- [Phase ?]: 2026-06-12 (180-04): ADD-6 (§4.23 VS Code extension icon) flipped ADD → KEEP: VS Code extension out of scope for v1.52; all other Phase 180 verdicts accepted as written; BRAND-DNA.md, logo-brief.md, quality-gate-checklist.md ratified; Phase 181 unblocked
- **2026-06-12 (181-05):** lint.mjs CLI main() must be guarded by import.meta direct-exec check — raw `await main()` at module bottom runs as import side-effect; generate.mjs import triggers lint CLI otherwise
- **2026-06-12 (181-05):** assembleLockup palette.ink must be #181818 (greyscale, sat=0) — default #111418 has HSV sat=0.29 which fails lintMonochromeDeriv; all lockup SVGs in pipeline use greyscale fills
- **2026-06-12 (181-05):** Full pipeline produces 19 raw → 16 gallery; D2/D3/D4 gallery-size culled (excess beyond 16 cap); D1 is the only Direction D candidate in final gallery
- **2026-06-12 (181-06, SUPERSEDED by Fix 3):** 16px legibility CR threshold was tuned 3.0 → 1.75 to explain "thin marks" — root cause was actually coordinate-space bugs rendering all candidates near-blank. After the fix, threshold reverted to 3.0 and all 19 raw candidates pass (CR ≈ 17). Lesson: visually inspect renders before tuning thresholds; blank-render guard added to render-matrix.mjs.
- **2026-06-12 (181-06, RESOLVED by Fixes 1–3):** Direction D floor — final gallery is 16 candidates at 4/4/4/4 (direction-balanced cull moved after legibility cull); D-05 floor satisfied for all directions.
- **2026-06-12 (181-07):** Round 1 verdict recorded in TOURNAMENT.md: Winners B4 (primary) + B1 (runner-up); A/C/D killed. Constraints R1-C1 (direction B locked), R1-C2 (preserve "stepping up toward the type" gesture), R1-C3 (Geist logotype locked), R1-C4 (Round 2 shows real color, monochrome-derivable). Verdict arrived conversationally; transcribed verbatim.
- **2026-06-13 (181 review):** Code review CR-01 (Critical, advisory): Direction C arcs rendered fill-not-stroke — `markGroupSvg` contract never consumed by assembleLockup; user judged "solid domes," not intended stroked arcs. Doesn't invalidate the verdict (user affirmatively chose B) but Phase 182 harness work must not inherit the unused-contract pattern.
- **2026-06-13 (183-04):** Human-verify checkpoint (Task 3) approved — orchestrator QA of 29 screenshot tiles and brandbook docs found NO defects; user confirmed "approved"; Phase 183 Logo System Production complete.
- [Phase ?]: generate-tokens-css.mjs imports flattenTokens from lib.mjs (D-03 ≤60 lines)
- [Phase ?]: README mints zero --accrue-scale-* tokens (D-11 compliance)
- [Phase ?]: verify-tokens.mjs accepts CSS_PATH_OVERRIDE env var for TDD negative check
- [Phase ?]: Voice system D-07 surface dispatch rule: tagline leads on-page; descriptor leads out-of-context/search-indexed
- [Phase ?]: Tone slider anchors: Formal-Casual=3, Precise-Evocative=4 per D-08

### Pending Todos

- None open.

### Blockers/Concerns

- None open.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260602-6xv | Seamless multi-project Docker DX for examples/accrue_host | 2026-06-02 | 85477a1b | [260602-6xv-seamless-multi-project-docker-dx-for-exa](./quick/260602-6xv-seamless-multi-project-docker-dx-for-exa/) |
| 260604-3cg | Automate Phase 174 human-UAT items into CI (0 human verification) | 2026-06-04 | a228bda5 | [260604-3cg-automate-phase-174-human-uat-items-into-](./quick/260604-3cg-automate-phase-174-human-uat-items-into-/) |
| 260604-tjz | Docker DX for accrue_host admin UI: ephemeral ports, launch banner, lean entrypoint+caches, docs | 2026-06-05 | 9f435936 | [260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem](./quick/260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem/) |
| 260605-dkx | Native Docker boot (Apple Silicon: native arch + Rust-built harfbuzz NIF) + accrue_host joins shared dev_proxy Traefik (stable accrue.localhost, zero port conflicts); docs/docker-dx.md | 2026-06-05 | 38f5e29d | [260605-dkx-docker-native-boot-shared-traefik-proxy](./quick/260605-dkx-docker-native-boot-shared-traefik-proxy/) |
| 260605-gys | Add admin@example.com billing-admin operator seed — /admin now structurally reachable; ensure_demo_admin/1 helper, OPERATOR/CUSTOMERS banner split, hero_accounts_test persona assertions locked | 2026-06-05 | 730d9dd9 | [260605-gys-add-dedicated-admin-example-com-billing-](./quick/260605-gys-add-dedicated-admin-example-com-billing-/) |
| fast | Bump rendro dep to ~> 1.0 (1.0.0) across accrue/accrue_admin/accrue_portal locks; host stays on 0.3.0 (published accrue 1.4.0 floor); compile clean + 63 PDF/renderer tests green | 2026-06-05 | 6fdd0059 | (inline /gsd-fast) |
| Phase 174 P02 | 15m | 4 tasks | 6 files |
| Phase 174 P04 | 5m | 1 tasks | 1 files |
| Phase 174 P05 | 8 | 2 tasks | 2 files |
| Phase 175 P01 | 4m | 2 tasks | 6 files |
| Phase 175 P02 | 18min | 2 tasks | 11 files |
| Phase 175 P03 | 4 | 2 tasks | 6 files |
| Phase 175 P04 | 15m | 2 tasks | 10 files |
| Phase 175 P05 | 62 | 2 tasks | 4 files |
| Phase 175 P06 | 15min | 2 tasks | 6 files |
| Phase 175 P07 | 8min | 2 tasks | 13 files |
| Phase 176 P02 | 10m | 2 tasks | 2 files |
| Phase 176-c P03 | 8m | 2 tasks | 5 files |
| Phase 177 P177-01 | 2m | 2 tasks | 2 files |
| Phase 177 P177-03 | 2m | 2 tasks | 6 files |
| Phase 178 P178-01 | 7min | 2 tasks | 2 files |
| Phase 178 P02 | 12 | 2 tasks | 2 files |
| Phase 179 P03 | 15min | 2 tasks | 2 files |
| Phase 180 P01 | 2m | 2 tasks | 2 files |
| Phase 180 P02 | 5m | 2 tasks | 1 files |
| Phase 180 P03 | 7m | 2 tasks | 4 files |
| Phase 180 P04 | 15min | 3 tasks | 3 files |
| Phase 181-svg-pipeline-tournament-round-1-divergent P01 | 3 | 1 tasks | 3 files |
| Phase 181 P04 | 4min | 1 tasks | 1 files |
| Phase 181-svg-pipeline-tournament-round-1-divergent P05 | 6 | 2 tasks | 37 files |
| Phase 181 P06 | 35min | 2 tasks | 112 files |
| Phase 182-tournament-convergent-refinement P01 | 6m | 3 tasks | 6 files |
| Phase 183 P183-02 | 35 | 2 tasks | 3 files |
| Phase 183 P04 | 12min | 2 tasks | 3 files |
| Phase 184-design-tokens-specimens P02 | 20 | 3 tasks | 6 files |
| Phase 184 P03 | 20m | 2 tasks | 1 files |
| Phase 184-design-tokens-specimens P05 | 87 | 1 tasks | 1 files |
| Phase 185 P01 | 94 | 1 tasks | 1 files |
| Phase 185 P02 | 119 | 1 tasks | 1 files |

### Milestone Intake Rules

- Default to maintenance/release-readiness unless new work has a sourced adopter, correctness, security, operational, or strategic reason.
- Do not create a milestone for polish-only work with a documented workaround.
- Any processor-surface change must update runtime behavior, support matrix, docs, examples/verifiers, and release notes together.

## Deferred Items

### Acknowledged at v1.52 milestone close (2026-06-14)

8 open artifact-audit items were acknowledged and deferred when closing v1.52 (maintainer chose "archive now" over resolving). All benign:

| Category | Item | Status |
|----------|------|--------|
| quick_task | admin-shared-detail-components | done (scanner can't locate SUMMARY) |
| quick_task | 260602-6xv-seamless-multi-project-docker-dx-for-exa | done (logged in Quick Tasks Completed) |
| quick_task | 260604-3cg-automate-phase-174-human-uat-items-into- | done (logged) |
| quick_task | 260604-tjz-docker-dx-for-accrue-host-admin-ui-ephem | done (logged) |
| quick_task | 260605-dkx-docker-native-boot-shared-traefik-proxy | done (logged) |
| quick_task | 260605-gys-add-dedicated-admin-example-com-billing- | done (logged) |
| uat_gap | 182-HUMAN-UAT.md | partial — de facto satisfied by user's R2-7 lock; confirmed transitively by 183/186 checkpoints |
| verification_gap | 182-VERIFICATION.md | human_needed — same; downstream phases passed their human gates |

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
| scope | Per-step funnel breakdown in recovery dashboard | out of scope v1.44; deferred to v1.45+ if demanded | Recovery dashboard shipped the core recovered/lost MRR story; per-step analytics lacked immediate adopter demand. | Analytics enhancement | concrete adopter failure or repeated support issue requiring per-step funnel diagnosis | 2026-05-27 |
| scope | MRR-at-risk column on at-risk table | out of scope v1.44; requires extracting `calculate_mrr_cents/1` from `DefaultHandler` | Useful polish, but the existing dashboard can operate without exposing at-risk MRR in that table. | Analytics enhancement | concrete adopter failure or operational failure proving at-risk prioritization needs this column | 2026-05-27 |
| scope | Compensating-event backfill of pre-v1.44 events without `mrr_value_cents` | out of scope v1.44; cutoff-date label is the v1.44 honest answer | Historical event gaps are honestly labeled and do not affect new lifecycle capture. | Analytics data repair | correctness/data-loss risk or explicit strategy change requiring historical normalized MRR backfill | 2026-05-27 |
| scope | Real-time PubSub-driven dashboard refresh | out of scope v1.44; coupled to multi-channel dunning v1.45+ | Poll/manual refresh is sufficient for the current operator workflow. | Admin analytics UX | concrete adopter failure or repeated support issue requiring real-time recovery monitoring | 2026-05-27 |
| strategy_non_goal | FIN-03 finance exports · MRR/ARR product · MoR processors · Hyperwallet | explicit standing non-goals | Accrue is a billing/subscription library, not an accounting, merchant-of-record, or payout product. | Strategy non-goal | explicit strategy change or correctness/security/data-loss risk that cannot be handled by host-owned exports | carried |
| seed | SEED-002-ecosystem-integrations — Chimeway/Mailglass ecosystem integrations | backlogged; future-roadmap seed, not a closeout blocker | Ecosystem blueprints are dormant future-roadmap material and do not open milestone scope by themselves. | Future roadmap / ecosystem integrations | concrete adopter failure requiring an integration, repeated support issue, or explicit strategy change | 2026-05-31 |

## Session Continuity

Last session: 2026-06-14T00:00:00.000Z
Stopped at: Phase 186 Plan 03 complete — v1.52 Brand System milestone closed
Resume file: None

## Operator Next Steps

- v1.52 Brand System is **shipped & archived** (2026-06-14). No milestone is open.
- Planning git tag `v1.52` created; push with `git push origin v1.52` if/when desired.
- To start the next milestone: `/clear` then `/gsd-new-milestone` — but only with a sourced reason (release-readiness, maintenance, doc truth, verifier hardening, adopter-proof closure, or a concrete adopter/correctness/security/operational failure mode), per the post-v1.48 pause rule.
- Optional hygiene: add a gitignore rule for the untracked harness `node_modules` under `brandbook/logo/` and `brandbook/tokens/` (~375M on disk, not committed).
