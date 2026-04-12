---
phase: 2
slug: schemas-webhook-plumbing
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17, OTP 27) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test --stale` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~20 seconds (Wave 0), ~60 seconds (full phase) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test` (full suite in `accrue/`)
- **Before `/gsd-verify-work`:** Full suite must be green with `mix test && mix credo --strict && mix dialyzer`
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Filled by planner during PLAN.md generation. Each task row must reference its requirement ID and automated command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/support/fake_processor.ex` — Fake processor driver for PROC-04/PROC-06 end-to-end
- [ ] `accrue/test/support/webhook_fixtures.ex` — signed payload generator wrapping `LatticeStripe.Webhook.generate_test_signature/3`
- [ ] `accrue/test/support/data_case.ex` — `Accrue.DataCase` with `Ecto.Adapters.SQL.Sandbox` checkout
- [ ] `accrue/test/support/conn_case.ex` — `Accrue.ConnCase` for webhook plug tests
- [ ] `accrue/test/accrue/billable_test.exs` — stubs for BILL-01, BILL-02
- [ ] `accrue/test/accrue/webhook/plug_test.exs` — stubs for WH-01..WH-07, WH-10..WH-12, WH-14
- [ ] `accrue/test/accrue/billing/events_transaction_test.exs` — stubs for EVT-04
- [ ] `accrue/test/accrue/processor/fake_test.exs` — stubs for PROC-04, PROC-06
- [ ] `accrue/test/property/money_property_test.exs` — StreamData property test scaffold (TEST-09 coverage hook)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None identified | — | Phase 2 is pure library code with no UI | All behaviors automatable via ExUnit |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (9 support files listed above)
- [ ] No watch-mode flags (`mix test --stale` is one-shot)
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter after planner fills task rows

**Approval:** pending
