---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: Tax + Organization Billing
current_phase: 19
current_phase_name: Tax Location and Rollout Safety
current_plan: "05"
status: ready_to_plan
stopped_at: Completed 19-05 rollout-safety and invalid-location recovery guidance
last_updated: "2026-04-17T18:37:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 5
  completed_plans: 5
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-17)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** v1.3 Tax + Organization Billing

## Current Position

Phase: 19
Plan: 05
**Current Phase:** 19
**Current Phase Name:** Tax Location and Rollout Safety
**Current Plan:** 05
**Status:** Ready to Plan
**Stopped At:** Completed 19-05 rollout-safety and invalid-location recovery guidance
**Resume File:** None
**Last Activity:** 2026-04-17

## Milestone Progress

**Milestone:** v1.3 Tax + Organization Billing
**Progress:** [██████████] 100%

| Phase | Status | Notes |
|-------|--------|-------|
| 18. Stripe Tax Core | Complete | `18-01` through `18-04` shipped; TAX-01 is complete |
| 19. Tax Location and Rollout Safety | Complete | `19-01` shipped sanitized processor tax-location validation; `19-02` shipped the public tax-location billing facade and focused TAX-02 coverage; `19-03` shipped local rollback observability and invoice failure reconciliation; `19-04` shipped admin tax-risk visibility plus the host repair path; `19-05` shipped rollout-safety and live Stripe recovery guidance for TAX-04 |
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
- Phase 18 stores only narrow automatic-tax observability fields on billing rows; full provider tax payloads remain in `data`.
- Invoice tax projection trusts only canonical processor tax fields (`tax` and `total_details.amount_tax`) and defaults to `0` only for enabled automatic-tax payloads with no amount yet.
- Stripe `customer_tax_location_invalid` now maps to a stable `%Accrue.APIError{}` with sanitized processor metadata only.
- Fake invalid-location coverage now distinguishes immediate customer validation failures from recurring automatic-tax rollback payloads.
- Public customer tax-location updates now go through `Accrue.Billing.update_customer_tax_location/2`, which persists only sanitized local customer projections and records a dedicated tax-location event.
- Tax-enabled subscription creation now fails at the billing boundary with `customer_tax_location_invalid` when automatic-tax payloads report `requires_location_inputs`.
- Recurring invalid-location rollback now persists `automatic_tax_disabled_reason` on local subscription and invoice rows instead of leaving the cause hidden in provider payloads.
- `invoice.updated` and `invoice.finalization_failed` now flow through the canonical invoice reducer so finalization error codes reconcile locally without storing raw provider messages.
- Admin tax-risk panels now render only local projected disabled reasons and finalization codes, without provider fetches or raw payload copy.
- The canonical host repair path must stay inside `AccrueHost.Billing` wrappers over public Accrue APIs.
- Tax rollout docs must explicitly warn that existing subscriptions, invoices, payment links, and pre-existing Checkout customers require deliberate migration settings before automatic tax rollout is safe.

## Next Action

Plan Phase 20: Organization Billing With Sigra.
