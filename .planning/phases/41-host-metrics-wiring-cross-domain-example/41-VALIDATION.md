---
phase: 41
slug: host-metrics-wiring-cross-domain-example
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `accrue/config/config.exs` + `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/telemetry/` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~2–5 minutes (project size dependent) |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/telemetry/`
- **After every plan wave:** Run `cd accrue && mix test test/accrue/telemetry/` + `cd examples/accrue_host && mix compile` when host files touched
- **Before `/gsd-verify-work`:** Full `cd accrue && mix test` must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | TEL-01 | T-41-01-01 / — | No PII in test fixtures | unit | `cd accrue && mix test test/accrue/telemetry/metrics_ops_parity_test.exs` (uses `TelemetryOpsInventory`) | ⬜ W0 | ⬜ pending |
| 41-01-02 | 01 | 1 | TEL-01 | T-41-01-02 / — | Allowlist stays internal to test/support | unit | `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs` | ✅ | ⬜ pending |
| 41-02-01 | 02 | 2 | OBS-02 | T-41-02-01 / — | Snippets use public modules only | doc+compile | `rg -n 'Cross-domain' accrue/guides/telemetry.md && cd examples/accrue_host && mix compile` | ⬜ W0 | ⬜ pending |
| 41-03-01 | 03 | 3 | D-18 | — | N/A | grep | `rg -n 'OBS-02|TEL-01' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + `test/support` compile path covers new inventory module and parity test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide readability | OBS-02 | Subjective flow | Read new subsection end-to-end in GitHub preview |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
