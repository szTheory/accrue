---
phase: 118
slug: admin-portal-change-flows
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 118 — Validation Strategy

> Per-phase validation contract for closing `SCM-03`, `SCM-04`, and `SCM-05`
> by promoting official active-subscription-change support truth, deepening
> admin/operator change flows, and adding bounded portal self-serve plan-change
> proof without widening into pause/resume or schedule semantics.

## Coverage Audit

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Expose supported subscription-change bundle coherently across facade, admin, and portal | Plans `118-01`, `118-02`, `118-03` |
| REQ | `SCM-03` quantity/item support truth + explicit Braintree unsupported semantics | Plans `118-01`, `118-02` |
| REQ | `SCM-04` admin supported actions, preview states, and setup gates | Plan `118-02` |
| REQ | `SCM-05` portal self-serve plan-change preview/commit with provider-honest wording | Plan `118-03` |
| RESEARCH | contract promotion must precede touched UX | Plan `118-01` |
| RESEARCH | admin already has best staging pattern for richer change flows | Plan `118-02` |
| RESEARCH | portal should stay bounded to plan-change preview/commit, not broad item editing | Plan `118-03` |
| CONTEXT | Braintree remains swap-only + no preview/quantity/item parity | Plans `118-01`, `118-02`, `118-03` |
| CONTEXT | preview-before-commit default where supported | Plans `118-02`, `118-03` |
| CONTEXT | host seams stay thin and provider-neutral where possible | Plan `118-03` |

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit suites across `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs` |
| **Estimated runtime** | under 5 minutes |

## Sampling Rate

- After every task commit: run that task's automated verification command.
- After Plan 01: rerun the full `accrue` core proof bundle before touching UI.
- After Plan 02: rerun `accrue_admin` targeted tests plus at least one core
  mutation suite if the admin flow changed shared runtime assumptions.
- After Plan 03: rerun portal and example-host lanes together so customer-facing
  wording and host seams stay aligned.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Automated Command | Status |
|---------|------|------|-------------|-------------------|--------|
| 118-01-01 | 01 | 1 | `SCM-03` | `cd accrue && mix test test/accrue/processor/capabilities_test.exs` | ⬜ pending |
| 118-01-02 | 01 | 1 | `SCM-03` | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/billing/subscription_items_test.exs test/accrue/billing/upcoming_invoice_test.exs test/accrue/billing/proration_roundtrip_test.exs` | ⬜ pending |
| 118-02-01 | 02 | 2 | `SCM-04` | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | ⬜ pending |
| 118-02-02 | 02 | 2 | `SCM-04` | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | ⬜ pending |
| 118-03-01 | 03 | 3 | `SCM-05` | `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs` | ⬜ pending |
| 118-03-02 | 03 | 3 | `SCM-05` | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs` | ⬜ pending |

## Wave 0 Requirements

- [x] `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/processor-support-matrix.md` exist.
- [x] `accrue/lib/accrue/billing.ex`, `subscription_actions.ex`, and `subscription_items.ex` exist.
- [x] `accrue_admin` subscription detail LiveView and tests exist.
- [x] `accrue_portal` subscription detail/list LiveViews and tests exist.
- [x] example-host billing facade and subscription LiveView tests exist.

## Manual-Only Verifications

All planned work has automated verification. No manual-only gate is required.

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] No watch-mode steps
- [x] Wave 0 covers every referenced proof lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
