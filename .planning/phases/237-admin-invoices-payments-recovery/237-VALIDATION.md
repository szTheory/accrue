---
phase: "237"
slug: "admin-invoices-payments-recovery"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-08"
---

# Phase 237 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit and Phoenix LiveView tests in accrue_admin; Playwright Test in examples/accrue_host |
| Config file | Existing Mix configuration; examples/accrue_host/playwright.config.js |
| Quick run command | cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charges_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs |
| Full suite command | cd accrue_admin && mix test --warnings-as-errors |
| Served browser seam | Existing host integration Playwright lane via scripts/ci/accrue_host_uat.sh and .github/workflows/ci.yml |
| Estimated runtime | Not measured in planning; measure focused and full runs during execution |

## Sampling Rate

- After every behavior task: run the focused ExUnit/LiveView or Playwright check assigned to that task.
- After every plan wave: run cd accrue_admin && mix test --warnings-as-errors; run the affected served browser contract after browser-facing changes.
- Before phase verification: full Admin package suite and the representative phase-owned served browser journey must pass.
- Max feedback latency: target under 5 minutes for focused checks; record actual suite times during execution.

## Per-Task Verification Map

The planner must replace “Assigned by plan” with concrete plan/task/wave IDs and threat references, and record execution status in the owning plan summary.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assigned by plan | Assigned by plan | Assigned by plan | ADM-02 | Assigned by plan | Stored state stays distinct from overdue; missing date and currency precision are truthful | ExUnit + LiveView | cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs | Existing; add focused boundary cases as needed | pending |
| Assigned by plan | Assigned by plan | Assigned by plan | ADM-05 | Assigned by plan | Exact scoped action and consequence are reviewed; dispatch and result copy reflect current evidence | LiveView + action contract | cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs | Existing; add action/result boundary cases as needed | pending |
| Assigned by plan | Assigned by plan | Assigned by plan | ADM-06 | Assigned by plan | Recovery retains owner/window/currency and return context; historical failures do not replace current state | Query/LiveView + served navigation | cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs; host integration lane for representative browser navigation | Existing; add empty/nil-currency and round-trip assertions as needed | pending |

## Wave 0 Requirements

- [ ] Add focused cases for overdue date boundaries, missing due dates, zero amounts, and zero-/three-decimal currencies.
- [ ] Add scoped action cases that change owner, eligibility, or action-relevant amount between review/step-up and dispatch, and cover accepted, requires-action, failed, completed, and ambiguous outcomes supported by current contracts.
- [ ] Add recovery cases for empty/missing currency data, owner and time-window retention, historical/current separation, and linked-record return context.
- [ ] Add or extend one representative served Admin browser journey only where it proves a browser-specific gap; use the existing blocking host CI lane. Do not multiply all routes by all themes and viewports.
- [ ] No new test framework or provider credential setup is required.

## Manual-Only Verifications

All stable in-scope acceptance behavior should have automated ExUnit/LiveView or served-browser evidence; human UAT is not required for phase acceptance. Deterministic Fake/provider fixtures do not prove live-provider parity. Do not make a live-provider appearance or remote outcome claim without its existing independent evidence.

## Validation Sign-Off

- [ ] Every plan task has an automated verify command or an explicit Wave 0 dependency.
- [ ] No three consecutive tasks lack automated feedback.
- [ ] Wave 0 covers each research-identified coverage gap.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency and test results are recorded during execution.
- [ ] nyquist_compliant is set true only after finalized coverage and passing evidence.

Approval: pending planning and execution evidence.

