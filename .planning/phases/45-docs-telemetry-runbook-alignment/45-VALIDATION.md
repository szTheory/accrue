---
phase: 45
slug: docs-telemetry-runbook-alignment
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 45 — Validation Strategy

> Doc-only phase: validation emphasizes **published docs build**, **grep contracts**, and **link integrity** — not new ExUnit coverage.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (unchanged baseline); primary gate is **ExDoc** |
| **Config file** | `accrue/mix.exs` (`docs` task) |
| **Quick run command** | `cd accrue && mix docs` |
| **Full suite command** | `cd accrue && mix docs && mix test --warnings-as-errors` (optional confidence; doc edits should not break compile) |
| **Estimated runtime** | ~30–90s for `mix docs` |

---

## Sampling Rate

- **After every task touching guides or `@doc`:** `cd accrue && mix docs`
- **After wave 1 and wave 2:** full quick command + requirement greps listed in plans
- **Before `/gsd-verify-work`:** `mix docs` green; README/guide links manually spot-checked if stretch tasks ran

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | MTR-07 | T-45-01 | No secrets/PII in doc examples | docs | `cd accrue && mix docs` | ✅ | ⬜ pending |
| 45-01-02 | 01 | 1 | MTR-07 | T-45-01 | Same | grep | `rg -n 'guides/metering.md' accrue/lib/accrue/billing.ex` (if task claims link) | ✅ | ⬜ pending |
| 45-02-01 | 02 | 1 | MTR-08 | T-45-01 | Same | docs+grep | `mix docs` + plan greps | ✅ | ⬜ pending |
| 45-03-01 | 03 | 2 | MTR-08 | T-45-01 | No raw webhook payloads in examples | docs+grep | `mix docs` + forbidden-table grep | ✅ | ⬜ pending |
| 45-04-01 | 04 | 2 | MTR-07/08 stretch | — | N/A | grep | plan-specific | ✅ | ⬜ pending |

*T-45-01: Documentation must not introduce copy-pastable API keys or customer PII in examples.*

---

## Wave 0 Requirements

- [x] Existing infrastructure — **no** new Wave 0. Doc validation uses `mix docs` + `rg`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Readability | MTR-07/MTR-08 | Tone / non-contradiction with Phase 44 | Maintainer reads diff for `metering.md`, new `telemetry.md` subsection, runbook branches |

---

## Validation Sign-Off

- [ ] All tasks include doc build or grep in `<verify>`
- [ ] No duplicate ops catalog tables outside `telemetry.md`
- [ ] `nyquist_compliant: true` after execution completes

**Approval:** pending
