---
phase: "235"
slug: "customer-plan-selection-checkout"
status: draft
nyquist_compliant: false
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
| **Estimated runtime** | Not measured during research; record actual CI/runtime evidence when the phase runs |

---

## Sampling Rate

- **After every task commit:** Run the focused Elixir tests for the changed checkout path.
- **After every plan wave:** Run all focused checkout ExUnit tests; include the Braintree browser lane when hook, markup, return, CSS, or served assets change.
- **Before phase verification:** Run the focused Elixir suite and the merge-blocking `playwright-e2e` Braintree checkout lane.
- **Max feedback latency:** Use focused ExUnit tests for per-task feedback; the browser lane is a wave-level check. Runtime is not yet measured.

---

## Per-Task Verification Map

This draft maps each requirement to executable evidence. The planner must replace the planning-assignment labels with the actual plan/task/wave IDs when it decomposes the work.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assign from plan | Assign from plan | Assign from plan | CKO-01 | Assign from plan | Visible Hosted Fields form tokenizes and submits; valid, invalid, provider-failure, cancellation, and fresh-retry outcomes are truthful | LiveView + browser integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/live/checkout_live_discount_test.exs`; `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ infrastructure exists; assertions to extend | ⬜ pending |
| Assign from plan | Assign from plan | Assign from plan | CKO-02 | Assign from plan | Hosted-provider redirect and mounted checkout stay capability-specific; return navigation alone never proves payment | ExUnit + browser integration | `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ infrastructure exists; assertions to extend | ⬜ pending |
| Assign from plan | Assign from plan | Assign from plan | CKO-03 | Assign from plan | Both submission transports revalidate session, expiry, promotion, and replay state; uncertain outcomes never auto-replay or claim success | ExUnit + browser integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/live/checkout_live_discount_test.exs test/accrue_portal/checkout_context_test.exs` | ✅ infrastructure exists; assertions to extend | ⬜ pending |
| Assign from plan | Assign from plan | Assign from plan | CKO-04 | Assign from plan | Selected plan survives sign-in/return; trusted terms render; missing terms and ambiguous outcomes recover safely | Host integration + browser | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs test/accrue_portal/checkout_context_test.exs`; `cd examples/accrue_host && npm run e2e:braintree-checkout` | ✅ infrastructure exists; assertions to extend | ⬜ pending |

---

## Wave 0 Requirements

Existing test frameworks, fixtures, and browser CI lane cover the phase; no infrastructure-install Wave 0 is needed. The visible-form submission and outcome assertions are implementation tasks, not missing-framework setup.

---

## Manual-Only Verifications

All acceptance behaviors have automated verification paths. Do not require confirmation-only UAT when the focused ExUnit and merge-blocking browser evidence passes. A real-provider credential or irreversible external transaction is not a routine CI/UAT prerequisite; report an unavailable provider-fidelity claim as unavailable rather than implying parity.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for focused checks; full browser lane is wave-level
- [ ] `nyquist_compliant: true` set in frontmatter after plan/task mapping and execution evidence

**Approval:** pending
