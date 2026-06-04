---
gsd_state_version: 1.0
milestone: v1.51
milestone_name: Admin UI Depth Pass
status: executing
last_updated: "2026-06-04T18:57:56.815Z"
last_activity: 2026-06-04
progress:
  total_phases: 6
  completed_phases: 3
  total_plans: 26
  completed_plans: 22
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-03 — v1.50 archived, v1.51 opened)

**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Current focus:** Phase 177 — D — Motion & Micro-interaction Design

## Current Position

Phase: 177 (D — Motion & Micro-interaction Design) — EXECUTING
Plan: 3 of 6
Status: Ready to execute
Last activity: 2026-06-04

## Post-v1.48 Pause Rule

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

v1.49 is an Adoption Evidence milestone focusing on realistic demo apps, DX, and shift-left automation, not broad new feature capabilities.

## Milestone Progress

### v1.51 Phase Summary (planning 2026-06-03 — Admin UI: Depth Pass; deps A→B→C→{D,E}→F)

| Phase | Name | Requirements | Status |
|-------|------|--------------|--------|
| 174 | A — Design-System Gap Closure & Token Completeness | DSY-01, DSY-02, DSY-03 | Not started |
| 175 | B — Persona-Driven IA Spine | IA-01, IA-02, IA-03, IA-04, IA-05, IA-06, IA-07 | Not started |
| 176 | C — Systematic Per-Screen Rubric Uplift | SCR-01, SCR-02, SCR-03, SCR-04 | Not started |
| 177 | D — Motion & Micro-interaction Design | MOT-01, MOT-02, MOT-03 | Not started |
| 178 | E — Seed Expressiveness & State Coverage | SEED-01, SEED-02 | Not started |
| 179 | F — Screenshot-Driven Visual QA Loop & Sign-off | QA-01, QA-02, QA-03 | Not started |

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

**v1.49** (shipped & archived **2026-06-02**): 4 phases (**163–166**), 11 requirements. Theme: Realistic Demo App & Adoption Evidence. Audit: `.planning/milestones/v1.49-MILESTONE-AUDIT.md`.

**v1.48** (shipped & archived **2026-06-01**): 4 phases (**159–162**), 9 requirements. Theme: Release Readiness + Stable Core Posture. Audit: `.planning/v1.48-v1.48-MILESTONE-AUDIT.md` (or equivalent closeout proof).

**v1.47** (shipped & archived **2026-05-31**): 5 phases (**154–158**), 11 requirements. Theme: ENT-10 Polish + Adopter-Proof Completeness. Audit: `.planning/milestones/v1.47-MILESTONE-AUDIT.md`.

**v1.46** (shipped & archived **2026-05-30**): 3 phases (**151–153**), 1 requirement (MNT-01). Theme: Maintenance & Closure — routine issue triage, dependency updates, @since annotation fixes, Three Zeros gate, Hex 1.3.0 publish, and audit trail closure. Audit: `.planning/v1.46-v1.46-MILESTONE-AUDIT.md`.

**v1.45** (shipped & archived **2026-05-29**): 2 phases (**149–150**), 4 requirements (BAN-01..BAN-04). Theme: Multi-channel Dunning (In-App Banners). Audit: `.planning/v1.45-v1.45-MILESTONE-AUDIT.md`.

## Performance Metrics

**Velocity:**

- Total plans completed: 89
- Average duration: 1m
- Total execution time: 1m

## Accumulated Context

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

### Roadmap Evolution

- v1.48 shipped and archived 2026-06-01: Phases 159–162
- v1.49 shipped and archived 2026-06-02: Phases 163–166

### Decisions

Decisions are logged in PROJECT.md. Recent decisions affecting current work:

- **2026-06-01:** Opened v1.49 "Realistic Demo App & Adoption Evidence". This explicitly does not open new broad feature scope, but rather provides realistic E2E coverage, rich fixtures, and Docker DX for the existing application to prove the value proposition and ease maintainer ramp-up.
- **2026-06-02:** Closed v1.49 after fresh audit passed 11/11 requirements and archived ROADMAP, REQUIREMENTS, MILESTONE-AUDIT, and phase artifacts under `.planning/milestones/`.
- [Phase ?]: AttentionCounts extracted into shared context fn; NavBadgeHook post-auth with DB-error rescue; Nav.items/3 backward-compat via default arg; SidebarCollapse localStorage key prefixed with mount_path
- [Phase ?]: URI.encode/1 applied to :id in RedirectController for path traversal prevention
- [Phase ?]: live('/events/:id') route stub in router.ex; EventLive ships in Wave 3; warning-not-error compile status confirmed
- [Phase ?]: EventLive not-found redirect omits put_flash (fetch_flash missing from accrue_admin_browser pipeline)
- [Phase ?]: motion.md is the authoritative justification record for Phase 177 — no entry means no animation permitted; all 9 surfaces catalogued with enter/exit asymmetry

### Pending Todos

- None open.

### Blockers/Concerns

- None open.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260602-6xv | Seamless multi-project Docker DX for examples/accrue_host | 2026-06-02 | 85477a1b | [260602-6xv-seamless-multi-project-docker-dx-for-exa](./quick/260602-6xv-seamless-multi-project-docker-dx-for-exa/) |
| 260604-3cg | Automate Phase 174 human-UAT items into CI (0 human verification) | 2026-06-04 | a228bda5 | [260604-3cg-automate-phase-174-human-uat-items-into-](./quick/260604-3cg-automate-phase-174-human-uat-items-into-/) |
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

### Milestone Intake Rules

- Default to maintenance/release-readiness unless new work has a sourced adopter, correctness, security, operational, or strategic reason.
- Do not create a milestone for polish-only work with a documented workaround.
- Any processor-surface change must update runtime behavior, support matrix, docs, examples/verifiers, and release notes together.

## Deferred Items

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

Last session: 2026-06-04T18:57:56.811Z
Stopped at: Phase 176 executed; SCORECARD 21/21 screens all dims >=2; verification human_needed (3 visual items deferred to Phase 179); code review clean (4 fixed); UI audit 20/24 (2 fixed)
Resume file: None

## Operator Next Steps

- Start the next milestone with `$gsd-new-milestone`.
