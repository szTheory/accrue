---
phase: 26
slug: hierarchy-and-pattern-alignment
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-20
---

# Phase 26 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix 1.8 (`Phoenix.LiveViewTest`) |
| **Config file** | `accrue_admin/config/config.exs` (test), `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/<module>_test.exs` |
| **Full suite command** | `cd accrue_admin && mix test` |
| **Estimated runtime** | ~60–120 seconds (package-local) |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the touched test file(s).
- **After every plan wave:** Run the full suite command for `accrue_admin`.
- **Before `/gsd-verify-work`:** Full `accrue_admin` suite must be green.
- **Max feedback latency:** Target under 3 minutes on CI-class hardware.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 26-01-01 | 01 | 1 | UX-01 | T-26-01 / — | N/A — markup only | LiveView | `mix test test/accrue_admin/live/customers_live_test.exs` | ✅ | ⬜ pending |
| 26-01-02 | 01 | 1 | UX-01 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/subscriptions_live_test.exs` | ✅ | ⬜ pending |
| 26-01-03 | 01 | 1 | UX-01 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/invoices_live_test.exs` | ✅ | ⬜ pending |
| 26-01-04 | 01 | 1 | UX-01 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/charges_live_test.exs` | ✅ | ⬜ pending |
| 26-02-01 | 02 | 2 | UX-02 | T-26-01 / — | N/A | LiveView + optional LazyHTML | `mix test test/accrue_admin/live/customer_live_test.exs` | ✅ | ⬜ pending |
| 26-02-02 | 02 | 2 | UX-02 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/subscription_live_test.exs` | ✅ | ⬜ pending |
| 26-02-03 | 02 | 2 | UX-02 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/invoice_live_test.exs` | ✅ | ⬜ pending |
| 26-02-04 | 02 | 2 | UX-02 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/charge_live_test.exs` | ✅ | ⬜ pending |
| 26-03-01 | 03 | 3 | UX-03 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/webhooks_live_test.exs` | ✅ | ⬜ pending |
| 26-03-02 | 03 | 3 | UX-03 | T-26-01 / — | N/A | LiveView | `mix test test/accrue_admin/live/webhook_live_test.exs` | ✅ | ⬜ pending |
| 26-04-01 | 04 | 4 | UX-04 | T-26-01 / — | N/A | mix test + grep | `cd accrue_admin && mix test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new framework install; optional LazyHTML assertions reuse `{:lazy_html, only: :test}` from `accrue_admin/mix.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None planned | — | — | All primary gates are automated in `accrue_admin` ExUnit. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency under target
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
