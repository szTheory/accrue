---
phase: 56
slug: billing-stripe-depth-telemetry-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `accrue/config/test.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/payment_method_list_test.exs test/accrue/telemetry/billing_span_coverage_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~2–5 minutes (project-dependent) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command** above (billing list + span coverage).
- **After every plan wave:** Run **`cd accrue && mix test`**.
- **Before `/gsd-verify-work`:** Full `accrue` test suite green.
- **Max feedback latency:** 300 seconds (CI budget)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | BIL-01 | — | Read-only; no PAN in logs | unit | `cd accrue && mix test test/accrue/billing/payment_method_list_test.exs` | ✅ | ⬜ pending |
| 56-01-02 | 01 | 1 | BIL-01 | — | Span metadata low-cardinality | unit | `cd accrue && mix test test/accrue/telemetry/billing_span_coverage_test.exs` | ✅ | ⬜ pending |
| 56-02-01 | 02 | 2 | BIL-02 | — | Doc truth vs code | manual grep | `rg -n "payment_method.*list|billing\\.payment_method" accrue/guides/telemetry.md` | ✅ | ⬜ pending |
| 56-02-02 | 02 | 2 | BIL-02 | — | Changelog | grep | `rg -n "list_payment_method" accrue/CHANGELOG.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] **Existing infrastructure covers all phase requirements** — `BillingCase`, `Accrue.Processor.Fake`, ExUnit.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional live Stripe | BIL-01 | Tagged off CI | `cd accrue && mix test --only live_stripe` when keys present |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under CI cap
- [ ] `nyquist_compliant: true` set in frontmatter when phase executes

**Approval:** pending
