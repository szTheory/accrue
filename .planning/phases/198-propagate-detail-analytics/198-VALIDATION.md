---
phase: 198
slug: propagate-detail-analytics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 198 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix plus Playwright `@playwright/test` |
| **Config file** | `accrue_admin/test/test_helper.exs`, `accrue_admin/config/test.exs`, `accrue_admin/package.json` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs -x` |
| **Full suite command** | `cd accrue_admin && mix test && npm run e2e:phase198` |
| **Estimated runtime** | ~90 seconds targeted, project-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run the targeted `mix test` command for the touched LiveView/component/test files.
- **After every plan wave:** Run `cd accrue_admin && mix test` plus the relevant Phase 198 Playwright smoke.
- **Before `/gsd:verify-work`:** `cd accrue_admin && mix test && npm run e2e:phase198 && npm run e2e:phase194 && npm run e2e:phase195` must be green.
- **Max feedback latency:** Keep targeted task feedback under 120 seconds where feasible.

---

## Per-Task Verification Map

Exact task IDs are assigned by `198-PLAN.md`. The planner must preserve these verification targets when splitting work into plans.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 198-W0-01 | TBD | 0 | PRP-02 | T-198-01 / T-198-02 | Detail action contracts are testable before page rewrites start. | e2e | `cd accrue_admin && npm run e2e:phase198` | No: `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` | pending |
| 198-W0-02 | TBD | 0 | PRP-02 | T-198-01 / T-198-02 | Targeted LiveView tests assert drawer/step-up behavior server-side. | integration | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs -x` | Yes: target files exist | pending |
| 198-DTL-01 | TBD | TBD | PRP-02 | T-198-01 / T-198-03 | Detail pages keep primary state above fold and raw/timeline sections lazy. | integration + e2e | `cd accrue_admin && mix test test/accrue_admin/live/*_live_test.exs -x && npm run e2e:phase198` | Partial | pending |
| 198-CUS-01 | TBD | TBD | PRP-02 | T-198-03 | Customer tabs expose only peer record-sets and do not hide critical state/actions. | integration + e2e | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs -x && npm run e2e:phase198` | Partial | pending |
| 198-ACT-01 | TBD | TBD | PRP-02 | T-198-02 / T-198-04 | Refund, invoice destructive actions, webhook replay, and connect override stay server-owned and step-up gated. | integration + e2e | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/charge_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/connect_account_live_test.exs -x && npm run e2e:phase198` | Partial | pending |
| 198-ANA-01 | TBD | TBD | PRP-02 | N/A | Recovery and Campaign analytics follow work-queue-first overview/detail contracts, not chart-wall layouts. | integration + e2e | `cd accrue_admin && mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/analytics/campaign_live_test.exs -x && npm run e2e:phase194 && npm run e2e:phase198` | Partial | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` - Phase 198 detail/analytics smoke covering target pages, summary/drill structure, related strip, lazy raw/timeline sections, and representative drawer/step-up flows.
- [ ] `accrue_admin/package.json` - script `e2e:phase198` mirroring existing phase e2e script shape.
- [ ] Extend target LiveView tests with failing assertions for summary rows, action counts, overflow/drawer affordances, related-strip markers, lazy sections, and Customer tab policy before implementing page rewrites.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual density and first-scan hierarchy across all target pages | PRP-02 | Automated tests can assert structure and markers, but final scan quality needs human review. | Start Phoenix, visit each target page at desktop and mobile widths, confirm the page opens with summary-first state, no hidden critical action, no chart wall, and no overlap/truncation. |
| Sensitive action risk posture for webhook replay and connect override | PRP-02 | Product/security judgment may be needed if any action is argued lower-risk than step-up gated. | Review the relevant plan and implementation notes; any non-step-up exception must include a written lower-risk rationale and server-side guard tests. |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing Phase 198 Playwright and targeted LiveView assertions.
- [ ] No watch-mode flags.
- [ ] Feedback latency target under 120 seconds for targeted task checks.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 and task maps are complete.

**Approval:** pending
