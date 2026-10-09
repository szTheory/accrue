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

Phase 238 plan/task IDs below bind each behavior to its focused seam before execution.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 238-01-T1 | 238-01 | 0 | ADM-07 | T-238-01 | One eligible row needs confirmation and fresh step-up before local queue acceptance. | ExUnit / LiveView + mounted browser | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` | Existing ExUnit; new phase browser spec in Wave 0 | ⬜ pending |
| 238-01-T2 | 238-01 | 0 | ADM-07 | T-238-02, T-238-03 | Fresh scope/status, duplicate/stale/mixed selection, mid-batch continuation, and exact audit/result counts. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` | Existing suites; add focused regressions | ⬜ pending |
| 238-02-T1 | 238-02 | 1 | ADM-07 | T-238-04 | Event history and exact related evidence stay scoped; empty, no-match, and unavailable differ. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Existing suites | ⬜ pending |
| 238-02-T2 | 238-02 | 1 | ADM-07 | T-238-05 | Delivery attempts and single replay retain current owner/status and step-up. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` | Existing suites | ⬜ pending |
| 238-02-T3 | 238-02 | 1 | ADM-07 | T-238-04, T-238-05 | Local list/summary/detail read failures remain unavailable and retryable without being reported as empty or not-found. | DataTable + LiveView | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs` | Existing suites; add deterministic error/retry seam | ⬜ pending |
| 238-03-T1 | 238-03 | 1 | ADM-08 | T-238-06 | Exact scoped coupon and related code facts, with distinct unavailable state. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs` | Existing suites | ⬜ pending |
| 238-03-T2 | 238-03 | 1 | ADM-08 | T-238-07 | Exact scoped promotion code, restrictions, and parent coupon; inspection only. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Existing suites | ⬜ pending |
| 238-04-T1 | 238-04 | 1 | ADM-08 | T-238-09, T-238-10 | Connect list preserves separate provider and local facts and scoped identities. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs` | Existing suite | ⬜ pending |
| 238-04-T2 | 238-04 | 1 | ADM-08 | T-238-08 | Local override save revalidates target and step-up without remote mutation. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/connect_account_live_test.exs` | Existing suite | ⬜ pending |
| 238-05-T1 | 238-05 | 2 | ADM-07, ADM-08 | T-238-11, T-238-12 | Mounted journeys assert scoped links, partial outcomes, inspection boundaries, and error/pending routes. | Mounted Playwright | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | New phase-owned spec created in Wave 0 | ⬜ pending |
| 238-05-T2 | 238-05 | 2 | ADM-07, ADM-08 | T-238-13 | Keyboard, responsive, theme, long-text, axe, and required-shard discovery. | Mounted Playwright | `cd examples/accrue_host && npx playwright test --list e2e/phase238-admin-events-webhooks.spec.js` | New spec; existing required Playwright shard | ⬜ pending |

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
