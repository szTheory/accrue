---
phase: 163
slug: realistic-domain-rich-seeds
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 163 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `examples/accrue_host/mix.exs` |
| **Quick run command** | `cd examples/accrue_host && mix test {test_file}` |
| **Full suite command** | `cd examples/accrue_host && mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && mix test {test_file}`
- **After every plan wave:** Run `cd examples/accrue_host && mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Task 2 | 01 | 1 | EVD-01 | — | N/A | smoke | `cd examples/accrue_host && mix test test/accrue_host/hero_accounts_test.exs` | ✅ | ✅ green |
| Task 3 | 01 | 1 | EVD-02 | — | N/A | smoke | `cd examples/accrue_host && mix test test/accrue_host/background_data_test.exs` | ✅ | ✅ green |
| Task 4 | 01 | 1 | EVD-02 | — | N/A | smoke | `cd examples/accrue_host && mix test test/accrue_host/background_data_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/accrue_host/test/accrue_host/hero_accounts_test.exs`
- [x] `examples/accrue_host/test/accrue_host/background_data_test.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | N/A | N/A | All phase behaviors have automated verification. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-01

---

## Validation Audit 2026-06-01
| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |
