---
phase: 80
slug: checkout-session-on-accrue-billing
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 80 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (BIL-06).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `accrue/config/test.exs` (transitive) |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/checkout_session_facade_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~2–5 minutes (facade-only quick path ~10s) |

---

## Sampling Rate

- **After every task commit:** Run the **quick run command**
- **After every plan wave:** Run **`mix test test/accrue/billing/`** from **`accrue/`**
- **Before `/gsd-verify-work`:** Full **`mix test`** green in **`accrue/`**
- **Max feedback latency:** 300 seconds (full suite ceiling)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 80-01-01 | 01 | 1 | BIL-06 | T-80-01 | No secrets in span metadata | unit | `cd accrue && mix test test/accrue/billing/checkout_session_facade_test.exs` | ✅ | ⬜ pending |
| 80-01-02 | 01 | 1 | BIL-06 | T-80-02 | NimbleOptions rejects unknown attrs at facade | unit | same | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing **ExUnit** + **`Accrue.BillingCase`** — no new framework

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | BIL-06 | All behaviors covered by **`checkout_session_facade_test.exs`** | — |

---

## Validation Sign-Off

- [ ] All tasks have grep-verifiable acceptance criteria
- [ ] Sampling: quick test path after **`billing.ex`** / test edits
- [ ] No watch-mode flags
- [ ] **`nyquist_compliant: true`** set when phase evidence is complete

**Approval:** pending
