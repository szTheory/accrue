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
- **After every plan wave:** Run `cd accrue_portal && mix test.ci` and the Phase 236 served-browser spec when that wave changes rendered Portal behavior.
- **Before phase verification:** Run the full package command and Phase 236 served-browser spec; both must be green.
- **Max feedback latency:** Target under 5 minutes for focused checks; measure and record actual suite times during execution.

---

## Per-Task Verification Map

The planner must replace “Assigned by plan” with actual plan/task/wave IDs and update commands if the implementation chooses a narrower reliable test seam.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assigned by plan | Assigned by plan | Assigned by plan | POR-01 | — | Branded customer routes render at supported viewport sizes | LiveView + served browser | `cd accrue_portal && mix test`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing route tests; phase spec planned | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-02 | Assigned by plan | Every mutation re-resolves and authorizes the exact customer-owned target | LiveView/controller | `cd accrue_portal && mix test` | Existing suites; extend as needed | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-03 | Assigned by plan | Invoice access remains customer-scoped; failed reads are not empty results | LiveView/controller | `cd accrue_portal && mix test` | Existing suites; failure injection planned | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-04 | Assigned by plan | Displayed outcomes reflect provider/result state and uncertainty | LiveView/controller | `cd accrue_portal && mix test` | Existing suites; failure assertions planned | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-05 | Assigned by plan | Payment fields stay provider-hosted; app only receives a nonce | LiveView + served browser | `cd accrue_portal && mix test`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing fixture; extend served-route coverage | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-06 | Assigned by plan | Known and unknown lifecycle states use truthful labels and claims | ExUnit + LiveView | `cd accrue_portal && mix test` | Existing copy and LiveView tests; extend cases | ⬜ pending |
| Assigned by plan | Assigned by plan | Assigned by plan | POR-07 | Assigned by plan | Return destinations are validated; query strings do not establish success | Controller + served browser | `cd accrue_portal && mix test`; `cd examples/accrue_host && npm run e2e -- e2e/phase236-portal-self-service.spec.js` | Existing context/controller suites; extend rejection cases | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Add failure injection for invoice and payment-method reads; assert visible unavailable states differ from successful empty results.
- [ ] Add the Phase 236 served-host Playwright spec for route/action states required by the approved UI-SPEC and include it in the recurring CI Playwright run.
- [ ] Add deterministic provider/result failure assertions for user-visible outcome copy where current fixtures do not already cover them.
- [ ] Planner maps each POR requirement to concrete plan task IDs and automated commands before marking this strategy Nyquist-compliant.

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
- [ ] `nyquist_compliant: true` set in frontmatter after the plan/task map is complete

**Approval:** pending plan and validation-map reconciliation
