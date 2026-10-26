---
phase: "238"
slug: "admin-events-webhooks-remaining-billing-surfaces"
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| 238-01-T1 | 238-01 | 0 | ADM-07 | T-238-01 | One eligible row needs confirmation and fresh step-up before local queue acceptance. | ExUnit / LiveView + mounted browser | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs` | Existing ExUnit; new phase browser spec in Wave 0 | ✅ pass (replay tests; Admin 610/610) |
| 238-01-T2 | 238-01 | 0 | ADM-07 | T-238-02, T-238-03 | Fresh scope/status, duplicate/stale/mixed selection, mid-batch continuation, and exact audit/result counts. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` | Existing suites; add focused regressions | ✅ pass (replay tests; core 2,077/2,077) |
| 238-02-T1 | 238-02 | 1 | ADM-07 | T-238-04 | Event history and exact related evidence stay scoped; empty, no-match, and unavailable differ. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs` | Existing suites | ✅ pass (Admin 610/610) |
| 238-02-T2 | 238-02 | 1 | ADM-07 | T-238-05 | Delivery attempts and single replay retain current owner/status and step-up. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs test/accrue_admin/live/webhook_replay_test.exs` | Existing suites | ✅ pass (Admin 610/610) |
| 238-02-T3 | 238-02 | 1 | ADM-07 | T-238-04, T-238-05 | Local list/summary/detail read failures remain unavailable and retryable without being reported as empty or not-found. | DataTable + LiveView | `cd accrue_admin && mix test test/accrue_admin/components/data_table_test.exs test/accrue_admin/live/events_live_test.exs test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs` | Existing suites; add deterministic error/retry seam | ✅ pass (Admin 610/610) |
| 238-03-T1 | 238-03 | 1 | ADM-08 | T-238-06 | Exact scoped coupon and related code facts, with distinct unavailable state. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/coupons_live_test.exs test/accrue_admin/live/coupon_live_test.exs` | Existing suites | ✅ pass (Admin 610/610; unknown currency regression included) |
| 238-03-T2 | 238-03 | 1 | ADM-08 | T-238-07 | Exact scoped promotion code, restrictions, and parent coupon; inspection only. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/promotion_codes_live_test.exs test/accrue_admin/live/promotion_code_live_test.exs` | Existing suites | ✅ pass (Admin 610/610) |
| 238-04-T1 | 238-04 | 1 | ADM-08 | T-238-09, T-238-10 | Connect list preserves separate provider and local facts and scoped identities. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/connect_accounts_live_test.exs` | Existing suite | ✅ pass (Admin 610/610; snapshot filter regressions included) |
| 238-04-T2 | 238-04 | 1 | ADM-08 | T-238-08 | Local override save revalidates target and step-up without remote mutation. | ExUnit / LiveView | `cd accrue_admin && mix test test/accrue_admin/live/connect_account_live_test.exs` | Existing suite | ✅ pass (Admin 610/610) |
| 238-05-T1 | 238-05 | 2 | ADM-07, ADM-08 | T-238-11, T-238-12 | Seeded mounted journeys assert exact links, route/result states, inspection boundaries, and rejected-step-up correction. | Mounted Playwright | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` | Phase-owned spec + deterministic seed fixtures; ExUnit retains read-failure and mixed-outcome seams | ✅ pass (2/2, final code) |
| 238-05-T2 | 238-05 | 2 | ADM-07, ADM-08 | T-238-13 | Keyboard, responsive, operator/host theme, long-text, axe, and required-shard discovery. | Mounted Playwright | `cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop` plus the host-forced dark-theme lane | Phase spec in the default and dark-theme CI lane | ✅ pass (3 tests discovered; default 2/2; forced-theme lane 2 passed, 1 expected skip) |
| 238-05-T3 | 238-05 | 2 | ADM-07 | T-238-11 | Legacy copy regression assertion matches the explicit Phase 238 replay wording. | ExUnit | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs` | Existing copy contract | ✅ pass (13 tests) |

---

## Wave 0 Requirements

- [x] Keep the existing targeted Admin ExUnit suites green and add counterexamples for stale/ineligible bulk replay selection, mixed eligibility, and a mid-batch requeue failure with accurate audit/result counts.
- [x] Add or extend the Phase 238 host E2E fixture and spec for seeded selection, confirmation and step-up, queued-versus-processed copy, scope/evidence links, billing inspection boundaries, keyboard, theme, and narrow layout. Keep detailed DB failures and mixed outcome permutations at the lower-cost ExUnit seam.
- [x] Confirm the Phase 238 browser spec is discovered by the recurring required `host-integration` Playwright shard in `ci.yml`.
- [x] No new test framework, package, live-provider credential, or manual provider action is required.

---

## Manual-Only Verifications

All stable in-scope behavior has deterministic ExUnit/LiveView or mounted Playwright acceptance criteria. No human UAT is required for Phase 238. Test fixtures prove local application behavior and do not claim live-provider processing.

---

## Validation Sign-Off

- [x] Every plan task has an automated verify command or an explicit Wave 0 dependency.
- [x] Sampling continuity: no three consecutive tasks without automated feedback.
- [x] Wave 0 covers all research-identified gaps and required browser discovery.
- [x] No watch-mode flags.
- [x] Feedback latency and suite results are recorded during execution.
- [x] `nyquist_compliant: true` is set only after finalized coverage and passing evidence.

### Phase 238-05 Execution Evidence (2026-10-09)

This records the plan-time run before the goal-verifier gap-closure addendum below; the final CI wiring and counts are recorded there.

- Focused mounted browser command: 2 tests passed, Chromium desktop; local fixtures prove application behavior only.
- At plan time, default `playwright --list` listed both phase tests. No remote CI or branch-protection claim was made.
- Focused copy suite: 13 tests passed.
- Full Admin suite: `mix test --warnings-as-errors` passed, 601 tests, exit code 0 after removing two warnings that otherwise caused this required command to abort.
- Read failures and mixed replay outcomes remain verified at the ExUnit seam. No production fault-injection hook was added.

### Phase 238 Final Post-Fix Evidence (2026-10-09)

This was the final evidence before the subsequent goal-backward coverage audit; the later gap-closure addendum supersedes these counts and records the additional required lane.

- Core package regression: `cd accrue && mix test` — 2,077 tests, 0 failures (11 excluded by configured tags).
- Admin package regression: `cd accrue_admin && mix test --warnings-as-errors` — 610 tests, 0 failures.
- Final Phase 238 mounted browser run: 2/2 tests passed; CI discovery lists both tests in the existing unrestricted shard.
- Code review findings: 10 finding instances across two review passes were fixed; the final standard-depth review is clean. The review and per-finding disposition are recorded in `238-REVIEW.md` and `238-REVIEW-DISPOSITION.md`.
- Routine human UAT: none; all stable in-scope behaviors have deterministic automated evidence. No remote CI or branch-protection state was invoked or claimed.

**Validation:** complete; phase goal verification remains in progress.

## Validation Audit 2026-10-09

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Automated Verification Gap Closure (2026-10-09)

The goal-backward verifier found two deterministic browser evidence gaps after the original Phase 238 plans had been marked complete. Both were closed in code, mounted browser assertions, and the recurring required CI lane; no human UAT or live-provider action was needed.

- Keyboard path now activates bulk replay, confirmation dismissal, fresh step-up, rejected-code correction, StepUp dismissal, and Connect fee-override drawer/save by keyboard. Assertions cover initial focus, Tab containment, dismissal return focus, and nested modal-to-drawer focus restoration.
- The re-verification lane exposed a timing race: Phoenix `JS.focus` repeated confirmation focus after two animation frames and could steal focus from the next Tab. The inline confirmation now uses a one-time initial-focus action from `FocusTrap`; focus stays with the keyboard user after opening.
- Host Admin branding now supports `theme: :system | :light | :dark`; light/dark lock the mounted Admin theme and hide the theme picker. The browser case seeds a conflicting light preference and verifies the host-forced dark theme, accessible status, enabled filter, and axe-clean state.
- `.github/workflows/ci.yml` runs the phase browser spec in the ordinary shard and adds a host-forced dark-theme run on shard 1. Default `playwright --list` lists 2 tests and forced-dark `playwright --list` lists 3. The ordinary run passed 2/2; the forced-theme run passed 2 tests with the preference-picker test intentionally skipped. The forced run uses `ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1`; rerunning it after the mutating default lane against the same fixture database passed, confirming each test's SQL Sandbox transaction rolls back its writes.
- Final post-focus-fix browser evidence: default lane 2/2; forced-dark lane passed 2 with 1 expected skip in 3 consecutive full-lane runs after the default lane, with the same database and global seeding skipped.
- Core regression: `cd accrue && mix test` — 2,078 tests passed, 11 excluded, 0 failures.
- Admin regression: `cd accrue_admin && mix test --warnings-as-errors` — 612 tests, 0 failures.
- No remote CI run was triggered or claimed. Routine human UAT remains none.

**Final verification inputs:** all five plan summaries, source/test paths in the verifier's covered-file set, and this addendum. The verifier is being rerun after the post-verification focus fix.

## Validation Audit 2026-10-09

| Metric | Count |
|---|---|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |
