---
phase: "236"
slug: "portal-billing-self-service"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-08"
---

# Phase 236 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit and Phoenix LiveViewTest in `accrue_portal`; Playwright Test in `examples/accrue_host` |
| **Config file** | Existing Mix configuration and `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd accrue_portal && mix test` |
| **Full package command** | `cd accrue_portal && mix test.ci` |
| **Served browser command** | `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` |
| **Estimated runtime** | To measure on the first focused run; keep per-task feedback under 5 minutes where practical |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit/LiveView/controller or Playwright command listed for that task.
- **After every plan wave:** Run `cd accrue_portal && mix test.ci`; run the Phase 236 served-browser spec after wave 4 when it exists and covers the changed routes.
- **Before phase verification:** Run the full package command and Phase 236 served-browser spec; both must be green.
- **Max feedback latency:** Target under 5 minutes for focused checks; measure and record actual suite times during execution.

---

## Per-Task Verification Map

The planner must replace “Assigned by plan” with actual plan/task/wave IDs and update commands if the implementation chooses a narrower reliable test seam.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 236-01-T1, 236-05-T2 | 236-01, 236-05 | 1, 4 | POR-01 | T-236-01, T-236-11 | Billed entity and seven branded routes retain owner scope | LiveView + served browser | `cd accrue_portal && mix test test/accrue_portal/live/invoices_live_test.exs test/accrue_portal/live/invoices_wrong_tenant_test.exs`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing route tests; phase spec planned | ⬜ pending |
| 236-02-T1, 236-03-T1 | 236-02, 236-03 | 2, 3 | POR-02 | T-236-03, T-236-06 | Every mutation re-resolves and authorizes the exact customer-owned target | LiveView/controller | `cd accrue_portal && mix test test/accrue_portal/live/payment_methods_live_test.exs test/accrue_portal/context_post_test.exs`; `cd accrue_portal && mix test test/accrue_portal/live/subscriptions_live_test.exs test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/context_live_test.exs` | Existing suites; extend parity/denial cases | ⬜ pending |
| 236-01-T1, 236-01-T2 | 236-01 | 1 | POR-03 | T-236-01, T-236-02 | Invoice access remains customer-scoped; failed reads are not empty results | LiveView/controller | `cd accrue_portal && mix test test/accrue_portal/live/invoices_live_test.exs test/accrue_portal/live/invoices_wrong_tenant_test.exs`; `cd accrue_portal && mix test test/accrue_portal/live/invoices_live_test.exs` | Existing suites; failure injection planned | ⬜ pending |
| 236-01-T2, 236-02-T1, 236-03-T1, 236-04-T1 | 236-01, 236-02, 236-03, 236-04 | 1, 2, 3 | POR-04 | T-236-05, T-236-07, T-236-10 | Displayed outcomes reflect provider/result state and uncertainty | LiveView/controller | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/checkout_context_test.exs` | Existing suites; failure assertions planned | ⬜ pending |
| 236-02-T2, 236-05-T2 | 236-02, 236-05 | 2, 4 | POR-05 | T-236-04 | Payment fields stay provider-hosted; app only receives a nonce | LiveView + served browser | `cd accrue_portal && mix test test/accrue_portal/live/add_payment_method_live_test.exs`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing fixture; served-route coverage planned | ⬜ pending |
| 236-03-T2, 236-05-T2 | 236-03, 236-05 | 3, 4 | POR-06 | T-236-07 | Known and unknown lifecycle states use truthful labels and claims | ExUnit + served browser | `cd accrue_portal && mix test test/accrue_portal/live/subscriptions_live_test.exs test/accrue_portal/live/subscription_live_test.exs`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing suites; extend cases | ⬜ pending |
| 236-04-T1, 236-04-T2 | 236-04 | 2 | POR-07 | T-236-08, T-236-09 | Return destinations are validated; query strings do not establish success | Controller + LiveView | `cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs test/accrue_portal/live/checkout_live_test.exs` | Existing suites; rejection cases planned | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Add failure injection for invoice and payment-method reads; assert visible unavailable states differ from successful empty results.
- [ ] Add the Phase 236 served-host Playwright spec for route/action states required by the approved UI-SPEC and include it in the recurring CI Playwright run.
- [ ] Add deterministic provider/result failure assertions for user-visible outcome copy where current fixtures do not already cover them.
- [x] Planner mapped each POR requirement to concrete plan/task/wave IDs and automated commands. Compliance remains false until execution records passing evidence.

---

## Manual-Only Verifications

All in-scope acceptance behaviors should have automated ExUnit/LiveView or served-browser verification. No manual-only UAT is planned. A provider-only fidelity claim may be handed off only if deterministic fixtures cannot prove it and the exact external limitation is recorded under D-08.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify commands or explicit Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Focused feedback latency measured and documented
- [ ] `nyquist_compliant: true` set only after validation-phase records passing evidence

**Approval:** pending plan and validation-map reconciliation
