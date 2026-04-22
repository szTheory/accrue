---
phase: 40
slug: telemetry-catalog-guide-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 40 — Validation Strategy

> Documentation truth + telemetry ops catalog contracts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue`) |
| **Config file** | `accrue/config/config.exs` (default test env) |
| **Quick run command** | `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~2–8 minutes (host-dependent; core package only) |

---

## Sampling Rate

- **After every task commit:** `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs`
- **After every plan wave:** `cd accrue && mix test test/accrue/telemetry/`
- **Before `/gsd-verify-work`:** `cd accrue && mix test` (full package suite)
- **Max feedback latency:** 600 seconds (CI upper bound; local usually faster)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | OBS-01 | T-40-01-01 | Doc tables stay PII-example-free per existing guide rules | manual+grep | `rg -n 'Ops event catalog|Primary owner' accrue/guides/telemetry.md` | ⬜ W1 | ⬜ pending |
| 40-01-02 | 01 | 1 | OBS-03 | T-40-01-02 | No new secrets or env values in docs | grep | `rg -n 'Firehose|firehose|Namespace split' accrue/guides/telemetry.md` | ⬜ W1 | ⬜ pending |
| 40-02-01 | 02 | 1 | OBS-01 / OBS-03 | T-40-02-01 | OTel examples remain PII-free; aspirational spans clearly labeled | unit | `cd accrue && mix test test/accrue/telemetry/billing_span_coverage_test.exs` | ✅ | ⬜ pending |
| 40-03-01 | 03 | 2 | OBS-04 | T-40-03-01 | Audit supersession text references public guide, not secrets | grep | `rg -n 'SUPERSEDED|gap audit' .planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` | ⬜ W2 | ⬜ pending |
| 40-03-02 | 03 | 2 | OBS-01 | T-40-03-02 | Contract allowlist ⊆ public ops namespace | unit | `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs` | ⬜ W2 | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing ExUnit + `mix test` cover billing span coverage — no new framework install.

*Wave 0 satisfied by current `accrue` test harness.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Operator readability | OBS-01 | Subjective flow in rendered Markdown | Open `accrue/guides/telemetry.md` on GitHub preview; confirm single ops table reads top-to-bottom without duplicate competing catalogs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual row above
- [ ] Sampling continuity: contract test run after telemetry doc edits
- [ ] No watch-mode flags in verification commands
- [ ] `nyquist_compliant: true` set in frontmatter after execution waves green

**Approval:** pending
