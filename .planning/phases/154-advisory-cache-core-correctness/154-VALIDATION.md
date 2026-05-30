---
phase: 154
slug: advisory-cache-core-correctness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 154 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| **Full suite command** | `mix test` (from `accrue/` directory) |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs`
- **After every plan wave:** Run `mix test` from `accrue/` directory
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| ADV-02 nil-ts | 01 | 0 | ADV-02 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 | ⬜ pending |
| ADV-03 stale | 01 | 0 | ADV-03 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 | ⬜ pending |
| POL-01 processor | 01 | 0 | POL-01 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 | ⬜ pending |
| POL-02 livemode | 01 | 0 | POL-02 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ Wave 0 | ⬜ pending |
| ADV-04 concurrent | 01 | 0 | ADV-04 | — | N/A | integration | `mix test test/accrue/webhook/wr05_concurrency_test.exs` | ✅ exists (needs allow/3) | ⬜ pending |
| ADV-01 OCC removal | 01 | 1 | ADV-01 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for ADV-02 (nil `last_stripe_event_ts` event updates the row, not a silent no-op)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for ADV-03 (DB-level stale skip: write newer then concurrent older → `{:ok, :stale}` + `result: :unchanged` telemetry + no ledger event)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for POL-01 (non-Stripe processor event writes correct `:processor` field, not global config default)
- [ ] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — add test for POL-02 (follow-up event with absent `livemode` carries forward prior row's livemode)
- [ ] `test/accrue/webhook/wr05_concurrency_test.exs` OR `default_handler_entitlement_summary_test.exs` — ADV-04 concurrent test with `Ecto.Adapters.SQL.Sandbox.allow/3` (not `:shared` mode)

*Wave 0 must complete before Wave 1 implementation tasks can be verified.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
