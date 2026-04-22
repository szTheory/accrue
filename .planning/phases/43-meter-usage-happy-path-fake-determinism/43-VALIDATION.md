---
phase: 43
slug: meter-usage-happy-path-fake-determinism
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for ExUnit feedback during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `accrue/config/test.exs` (host TestRepo + Fake) |
| **Quick run command** | `mix test test/accrue/billing/meter_event_actions_test.exs` |
| **Full suite command** | `mix test test/accrue/billing/meter_event_actions_test.exs test/accrue/processor/fake_meter_event_test.exs` |
| **Estimated runtime** | \< 15 seconds |

---

## Sampling Rate

- **After every task commit:** Run the **quick** command for the files touched in that plan.
- **After every plan wave:** Run the **full suite command** above (extend glob if Plan 03 adds `*_meter*test.exs`).
- **Before `/gsd-verify-work`:** `mix test` for `accrue` package green.
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-T1 | 01 | 1 | MTR-01 | T-doc-01 | No live API keys in ExDoc examples | doc grep | `rg '@doc' accrue/lib/accrue/billing.ex` | ✅ | ⬜ pending |
| 43-02-T1 | 02 | 1 | MTR-01, MTR-02 | T-doc-01 | Link-only; no duplicate Nimble table | doc grep | `rg 'report_usage|meter' accrue/guides/testing.md` | ✅ | ⬜ pending |
| 43-03-T1 | 03 | 2 | MTR-02, MTR-03 | T-test-01 | Non-Fake raises; no private-module imports in new tests | unit | `mix test test/accrue/billing/meter_event_actions_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `Accrue.BillingCase` + `Accrue.TestRepo` — existing infrastructure covers Phase 43.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| *None* | — | All MTR-01..MTR-03 behaviors are Fake + DB observable in CI | — |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no three consecutive tasks without `mix test`
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency \< 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
