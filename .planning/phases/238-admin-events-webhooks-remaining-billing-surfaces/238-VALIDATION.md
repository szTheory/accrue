---
phase: "238"
slug: "admin-events-webhooks-remaining-billing-surfaces"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-08"
---

# Phase 238 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView in `accrue_admin`; Playwright Test 1.59.1 in `examples/accrue_host` |
| **Config file** | Existing Mix test configuration; `examples/accrue_host/playwright.config.js` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/webhooks_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` |
| **Full package suite** | `cd accrue_admin && mix test --warnings-as-errors` |
| **Phase browser journey** | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` |
| **Merge-blocking home** | `.github/workflows/ci.yml` `host-integration` required deterministic gate and its Playwright shard |
| **Estimated runtime** | Focused ExUnit target under 30 seconds; adjacent Phase 237 served Playwright journey took about 9 seconds; record Phase 238 timings during Wave 0 |

---

## Sampling Rate

- **After each behavior task:** Run its focused ExUnit/LiveView command and the targeted browser check when that task changes a rendered journey.
- **After each plan wave:** Run `cd accrue_admin && mix test --warnings-as-errors`; run the Phase 238 served browser journey after browser-facing work.
- **Before phase verification:** Require the complete Admin package suite and Phase 238 served Playwright journey to pass in the existing required CI lane.
- **Max feedback latency:** Target under 5 minutes for focused checks; record actual times during execution.

---

## Per-Task Verification Map

Plan/task IDs are assigned by the Phase 238 planner; each planned behavior must map to one of these focused seams and receive an exact task row before execution.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Planner-assigned | Planner-assigned | 0/1 | ADM-07 | Planner-assigned | Re-resolve owner scope and current eligibility at action time; stale/foreign/ineligible IDs do not queue or receive a success audit. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` | Existing suites; add focused stale/mixed-state and mutation assertions | ⬜ pending |
| Planner-assigned | Planner-assigned | 0/1 | ADM-07 | Planner-assigned | Preserve per-row partial results through mid-batch failure; distinguish selected, eligible, attempted, queued, skipped, and failed; never equate queued with processed. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` | Existing suites; add deterministic injected requeue failure case | ⬜ pending |
| Planner-assigned | Planner-assigned | 1 | ADM-07 | Planner-assigned | Event/delivery history and related evidence stay owner-scoped; empty, unavailable, filters, payload disclosure, keyboard, theme, narrow layout, and replay outcomes are understandable. | Mounted Playwright | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | New phase-owned spec in Wave 0; required host Playwright shard | ⬜ pending |
| Planner-assigned | Planner-assigned | 0/1 | ADM-08 | Planner-assigned | Coupon/promotion-code surfaces remain inspection-only; provider-reported Connect facts stay separate from local fee-override state. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs test/accrue_admin/live/connect_accounts_live_test.exs test/accrue_admin/live/connect_account_live_test.exs` | Existing suites; extend only changed acceptance behavior | ⬜ pending |
| Planner-assigned | Planner-assigned | 1 | ADM-08 | Planner-assigned | Rendered billing inspection preserves read-only boundaries, unavailable states, scope, keyboard access, responsive/theme behavior, and distinct Connect/fee-override labeling. | Mounted Playwright | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | New phase-owned spec in Wave 0; required host Playwright shard | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Keep the existing targeted Admin ExUnit suites green and add counterexamples for stale/ineligible bulk replay selection, mixed eligibility, and a mid-batch requeue failure with accurate audit/result counts.
- [ ] Add or extend `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` for the mounted required host lane: selection, confirmation and step-up, queued-versus-processed and partial copy, scope/evidence links, billing inspection boundaries, keyboard, theme, and narrow layout.
- [ ] Confirm the Phase 238 browser spec is discovered by the recurring required `host-integration` Playwright shard in `ci.yml`.
- [ ] No new test framework, package, live-provider credential, or manual provider action is required.

---

## Manual-Only Verifications

All stable in-scope behavior has deterministic ExUnit/LiveView or mounted Playwright acceptance criteria. No human UAT is required for Phase 238. Test fixtures prove local application behavior and do not claim live-provider processing.

---

## Validation Sign-Off

- [ ] Every plan task has an automated verify command or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated feedback.
- [ ] Wave 0 covers all research-identified gaps and required browser discovery.
- [ ] No watch-mode flags.
- [ ] Feedback latency and suite results are recorded during execution.
- [ ] `nyquist_compliant: true` is set only after finalized coverage and passing evidence.

**Approval:** pending
