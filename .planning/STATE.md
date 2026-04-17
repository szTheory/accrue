---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Tax + Organization Billing
current_phase: null
current_phase_name: null
current_plan: Not started
status: ready_to_plan_phase
stopped_at: Roadmap created for v1.3
last_updated: "2026-04-17T17:05:00.000Z"
last_activity: 2026-04-17
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-17)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** v1.3 Tax + Organization Billing

## Current Position

Phase: Not started (defining requirements)
Plan: —
**Current Phase:** Not started
**Current Phase Name:** —
**Current Plan:** —
**Status:** Ready to plan Phase 18
**Stopped At:** Roadmap created for v1.3
**Resume File:** None
**Last Activity:** 2026-04-17 — Milestone v1.3 started

## Milestone Progress

**Milestone:** v1.3 Tax + Organization Billing
**Progress:** [░░░░░░░░░░] 0%

| Phase | Status | Notes |
|-------|--------|-------|
| 18. Stripe Tax Core | Pending | Tax enablement and projection work |
| 19. Tax Location and Rollout Safety | Pending | Location validation and legacy recurring-item migration work |
| 20. Organization Billing With Sigra | Pending | Sigra-first org billing and tenant-boundary proof |
| 21. Admin and Host UX Proof | Pending | Browser/admin proof for tax and org billing states |
| 22. Finance Handoff and Milestone Verification | Pending | Stripe-native finance handoff and closure verification |

## Current Planning Artifacts

- `.planning/PROJECT.md` — active v1.3 milestone goals and project context.
- `.planning/REQUIREMENTS.md` — active v1.3 requirements.
- `.planning/ROADMAP.md` — active v1.3 phase roadmap.
- `.planning/milestones/v1.2-ROADMAP.md` — archived v1.2 roadmap details.
- `.planning/milestones/v1.2-REQUIREMENTS.md` — archived v1.2 requirements.
- `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — archived v1.2 milestone audit.
- `.planning/STATE-ARCHIVE.md` — archived pre-cleanup state history and legacy metrics.

## Recent Decisions

- v1.3 uses the layered expansion shape: Stripe Tax plus Sigra-first organization billing, with finance as Stripe-native handoff only.
- Stripe Tax remains the safest first expansion because it deepens the existing Stripe-first billing model without changing processor strategy.
- Organization billing is now ready to plan because local Sigra ships organizations, memberships, active organization scope/session hydration, org-aware admin, impersonation, and audit/export foundations.
- Accrue keeps generic host-owned billables as the public model: `owner_type` and `owner_id` remain the billing ownership contract.
- Sigra-first means the canonical host proof should use Sigra org scope and membership boundaries, while non-Sigra hosts continue through `Accrue.Billable`.
- Finance work must not become a revenue-recognition engine; v1.3 should document Stripe Revenue Recognition, Sigma scheduled queries, and Data Pipeline handoff points.
- Preserve `tax rollout correctness`, `cross-tenant billing leakage`, and `wrong-audience finance exports` as explicit milestone risks.
- Official second processor adapter remains a planted seed outside v1.3.
- v1.3 phases are ordered tax core -> tax rollout safety -> org billing -> host/admin proof -> finance handoff and verification.

## Next Action

Plan Phase 18: Stripe Tax Core.
