---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Ecosystem stability + demo visuals
current_phase: 23
current_phase_name: Ecosystem stability + demo visuals
current_plan: null
status: idle
stopped_at: v1.4 Phase 23 complete (STAB-01, UX-DEMO-01); choose next milestone when ready.
last_updated: "2026-04-17T19:20:00Z"
last_activity: 2026-04-17
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-17)

**Core value:** A Phoenix developer can install Accrue + accrue_admin and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic, with tamper-evident audit and zero breaking-change pain through v1.x.
**Current focus:** v1.4 — **Ecosystem stability + demo visuals** (Phase 23) — **complete** (2026-04-17)

## Current Position

Phase: **23** (Ecosystem stability + demo visuals)  
Plan: *`23-01-PLAN.md` + `23-02-PLAN.md` executed*  
**Current Phase Name:** Ecosystem stability + demo visuals  
**Status:** Complete  
**Stopped At:** STAB-01 + UX-DEMO-01 delivered; committed admin static bundle + host verify + `e2e:visuals` green.  
**Resume File:** `.planning/phases/23-ecosystem-stability-and-demo-visuals/`  
**Last Activity:** 2026-04-17

## Milestone Progress

**Milestone:** v1.4 Ecosystem stability + demo visuals — **COMPLETE** (2026-04-17)

| Phase | Status | Notes |
|-------|--------|-------|
| 23. Ecosystem stability + demo visuals | Complete | STAB-01, UX-DEMO-01 |

**Milestone:** v1.3 Tax + Organization Billing — **COMPLETE** (archived)

| Phase | Status | Notes |
|-------|--------|-------|
| 18–22 | Complete | See `.planning/milestones/v1.3-ROADMAP.md` |

## Current Planning Artifacts

- `.planning/PROJECT.md` — active v1.4 milestone goals and project context.
- `.planning/REQUIREMENTS.md` — active v1.4 requirements (STAB-01, UX-DEMO-01).
- `.planning/ROADMAP.md` — active roadmap including Phase 23.
- `.planning/phases/21-admin-and-host-ux-proof/21-UAT.md` — VERIFY-01 **CI automation manifest** (Phase 21 executable half).
- `.planning/milestones/v1.3-REQUIREMENTS.md` — closed v1.3 requirements snapshot.

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
- Organization billing stays on Accrue's existing `owner_type` and `owner_id` contract; the example host now proves organization ownership without core billing schema changes.
- The example host resolves Sigra from `../../../sigra` by path unless `ACCRUE_HOST_HEX_RELEASE=1` selects the versioned Hex dependency branch.
- Organization fixtures create orgs through Sigra with `Scope.for_user/1`, and owner membership creation is treated as idempotent because Sigra inserts the initial owner row atomically.
- The host billing page now resolves the active organization through `Sigra.Scope.Hydration` and clears stale active-org pointers fail-closed.
- Host billing mutations now derive ownership from `current_scope.active_organization` only and ignore browser-supplied organization ids.
- The admin package now forwards a fixed owner-scope session contract (`active_organization_id`, `active_organization_slug`, `admin_organization_ids`, `active_organization_name`) alongside host-specified session keys.
- Owner scope now resolves once during `AccrueAdmin.AuthHook.on_mount/4`, and downstream admin work should read `current_owner_scope` instead of re-parsing session state.
- Admin query modules now enforce ORG-03 row proof directly: customer, subscription, and invoice loaders join back to organization-owned customer rows before returning data.
- Webhook loaders now distinguish `{:ok, row}`, `:not_found`, and `{:ambiguous, proof_context}`, and scoped bulk replay counts derive from those proofed loaders instead of global DLQ totals.
- Customer and subscription detail routes now treat out-of-scope owner-aware loader misses as redirects to the scoped index with the exact denial flash copy.
- Shared admin list queries now receive `current_owner_scope`, and event-feed owner proof compares billing UUIDs as text so active-organization event pages fail closed instead of leaking or crashing.
- Webhook detail and replay now consume owner-aware proof outcomes directly, re-check replay authorization at action time, and emit replay-success audits only for in-scope organization rows.
- v1.4: committed `accrue_admin` `priv/static/accrue_admin.js` must be real esbuild output (Phoenix + LiveView). A placeholder line parsed as `generated` + invalid `by` in the browser and broke admin `phx-click` until the bundle was rebuilt and committed; `mix verify.full` browser gate now runs `mix accrue_admin.assets.build` + `mix deps.compile accrue_admin --force` before Playwright.

## Next Action

1. **Plan the next milestone** (post–v1.4) in `PROJECT.md` / `ROADMAP.md` when priorities are set.
2. Optional: **`/gsd-pr-branch`** on a feature branch if planning commits should stay out of a code-only PR (see **Repo hygiene**).

## Deferred Items

Items acknowledged at **v1.3 milestone close** (2026-04-17) from `gsd-tools audit-open` and quick-task hygiene:

| Category | Item | Status |
|----------|------|--------|
| quick_task | `260413-jri-bump-lattice-stripe-to-1-0-and-unblock-p` | deferred — restore or delete quick-task dir |
| quick_task | `260414-l9q-automate-phase-3-human-verification-item` | deferred — restore or delete quick-task dir |
| tooling | GSD `audit-open` Phase 21 UAT line | acknowledged — VERIFY-01 is **CI-backed**; see `21-UAT.md` |

## Repo hygiene

`/gsd-pr-branch` rebuilds a review-friendly branch by cherry-picking **non**-`.planning/phases/**` commits. Use it from a **feature branch** that is **ahead of `main`**. It does not replace normal git hygiene on `main` (commit WIP, or branch before large planning dumps).

## Session Continuity

v1.3 closed: Phase 22 plans `22-01`–`22-02` executed; `v1.3` git tag; milestones `v1.3-*` written; active `REQUIREMENTS.md` reset to v1.4 placeholder.
