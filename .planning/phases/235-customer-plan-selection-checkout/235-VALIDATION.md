---
phase: "235"
slug: "customer-plan-selection-checkout"
status: validated
nyquist_compliant: true
wave_0_complete: false
created: "2026-10-08"
---

# Phase 235 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests; Playwright Test for browser journeys |
| **Config file** | `accrue_portal/mix.exs`; `examples/accrue_host/playwright.braintree.config.js` |
| **Quick run command** | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/live/checkout_live_discount_test.exs test/accrue_portal/checkout_context_test.exs` |
| **Full suite command** | `cd accrue_portal && mix test`; `cd examples/accrue_host && npm run e2e:braintree-checkout` |
| **Estimated runtime** | Focused Portal suite: 2.84s in local run (26 tests); browser lane runs at wave level (12/12 passed) |

---

## Sampling Rate

- **After every task commit:** Run the focused Elixir tests for the changed checkout path.
- **After every plan wave:** Run all focused checkout ExUnit tests; include the Braintree browser lane when hook, markup, return, CSS, or served assets change.
- **Before phase verification:** Run the focused Elixir suite and the merge-blocking `playwright-e2e` Braintree checkout lane.
- **Max feedback latency:** Use focused ExUnit tests for per-task feedback; the browser lane is a wave-level check. Runtime is not yet measured.

---

## Per-Task Verification Map

The mapping uses executable plan/task/wave IDs. The browser command is the existing Braintree-configured lane in merge-blocking `playwright-e2e`; its injected SDK proves the form integration path, not live-provider parity.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 235-01 Task 1 | 235-01 | 1 | CKO-01, CKO-02 | T-235-01 | Visible official Hosted Fields path tokenizes and sends one nonce through actual transport; denied context has no form | Browser integration | `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ spec exists; assertions pass | ✅ green |
| 235-01 Task 2 | 235-01 | 1 | CKO-01 | T-235-02 | Duplicate click, SDK failure, cancellation and uncertain response never replay nonce; fresh retry resets fields | Browser integration | `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ spec exists; assertions pass | ✅ green |
| 235-02 Task 1 | 235-02 | 2 | CKO-04 | T-235-03 | Exact host offer/customer/billable/processor survive sign-in and duplicate return, with fresh host authorization | Host LiveView + browser | `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs && npm run e2e:braintree-checkout` | ✅ files exist; assertions pass | ✅ green |
| 235-02 Task 2 | 235-02 | 2 | CKO-03, CKO-04 | T-235-04 | Trusted exact terms render; unknown/ambiguous terms fail closed without zero-price guess | Portal LiveView | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs` | ✅ file exists; assertions pass | ✅ green |
| 235-03 Task 1 | 235-03 | 3 | CKO-03 | T-235-05, T-235-06, T-235-07 | POST reauthorizes, claims one operation and reports accepted-but-unconfirmed action honestly | LocalSession + controller ExUnit | `cd accrue && mix test test/accrue/checkout/local_session_test.exs && cd ../accrue_portal && mix test test/accrue_portal/checkout_context_test.exs` | ✅ files exist; assertions pass | ✅ green |
| 235-03 Task 2 | 235-03 | 3 | CKO-01, CKO-03 | T-235-05, T-235-06, T-235-07 | LiveView shares expiry, promotion, concurrency and uncertain-outcome rules with POST | Portal LiveView + context ExUnit | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/live/checkout_live_discount_test.exs test/accrue_portal/checkout_context_test.exs` | ✅ files exist; assertions pass | ✅ green |
| 235-04 Task 1 | 235-04 | 4 | CKO-02 | T-235-08, T-235-09 | Stripe hosted return refetches provider evidence; Braintree stays mounted; duplicate returns are idempotent | Facade + host ExUnit | `cd accrue && mix test test/accrue/checkout_test.exs test/accrue/billing/checkout_session_facade_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` | ✅ files exist; assertions pass | ✅ green |
| 235-04 Task 2 | 235-04 | 4 | CKO-01, CKO-02, CKO-03, CKO-04 | T-235-10 | Served assets, all 16 UI states, 320 CSS px, 400% zoom, keyboard/focus/live status and host theme stay usable | Browser integration + existing required CI job | `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ lane exists; assertions pass | ✅ green |
| 235-05 Task 1 | 235-05 | 5 | CKO-01, CKO-03, CKO-04 | T-235-11 | Explicit trusted zero amount completes through actual POST once; missing, negative, mismatched amounts and replay do not bill | Controller integration | `cd accrue_portal && mix test test/accrue_portal/checkout_context_test.exs` | ✅ actual POST, persisted completed status, gateway nonce and replay assertions | ✅ green |
| 235-05 Task 2 | 235-05 | 5 | CKO-03, CKO-04 | T-235-12 | Expired checkout uses validated recovery URL (unsafe URL falls back to `/billing`), shows no payment forms/actions, and served recovery reaches host billing | Portal LiveView + browser integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs`; `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ exact safe link/no-form assertions and browser follow/no-tokenize/no-POST assertions | ✅ green |
| 235-06 Task 1 | 235-06 | 6 | CKO-01, CKO-02, CKO-03, CKO-04 | T-235-13, T-235-14 | Only the exact completed LocalSession for the current authorized Braintree Customer/billable/plan/selection completes; pending, foreign and forged locators remain non-complete; Stripe still requires fetched paid evidence | Host LiveView integration | `cd examples/accrue_host && ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs`; `cd examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` | ✅ scoped completed/repeated read, pending states, foreign/forged scope, and Stripe fetch assertions | ✅ green |
| 235-06 Task 2 | 235-06 | 6 | CKO-01, CKO-02 | T-235-14 | Served Braintree checkout sends one mocked nonce POST; fixture-backed completed return resolves persisted state; pending/forged returns cannot claim completion | Browser integration | `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ served journey and completed/pending/forged fixture assertions | ✅ green |

---

## Wave 0 Requirements

Existing test frameworks, fixtures, and browser CI lane cover the phase; no infrastructure-install Wave 0 is needed. The visible-form submission and outcome assertions are implementation tasks, not missing-framework setup.

---

## Manual-Only Verifications

All acceptance behaviors have automated verification paths. Do not require confirmation-only UAT when the focused ExUnit and merge-blocking browser evidence passes. A real-provider credential or irreversible external transaction is not a routine CI/UAT prerequisite; report an unavailable provider-fidelity claim as unavailable rather than implying parity.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused checks (documented quick run measured 2.84s); full browser lane is wave-level
- [x] `nyquist_compliant: true` set in frontmatter after plan/task mapping and execution

**Approval:** approved 2026-10-08 (automated acceptance; no manual UAT)

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
