---
phase: 51
slug: integrator-golden-path-docs
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for documentation execution (no new Wave 0 test framework).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract scripts + host Mix aliases |
| **Config file** | `examples/accrue_host/mix.exs` (verify / verify.full aliases) |
| **Quick run command** | `cd examples/accrue_host && mix verify` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` |
| **Contract script** | `bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Estimated runtime** | verify ~minutes; verify.full longer; contract script ~1s |

---

## Sampling Rate

- **After tasks touching `examples/accrue_host/README.md` proof / VERIFY-01 prose:** `bash scripts/ci/verify_verify01_readme_contract.sh`
- **After tasks touching root `README.md` Proof path block:** same script if VERIFY-01 strings mirrored; otherwise manual diff against `verify_verify01_readme_contract.sh` expectations for host README consistency
- **After wave 1 (plans 01–02):** run contract script at least once
- **Before `/gsd-verify-work`:** `mix verify` green from `examples/accrue_host` (or executor documents waiver for pure index wording with no command changes)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | INT-01 | — | No secrets in markdown | manual+rg | `rg -n 'sk_live|sk_test_' accrue/guides/first_hour.md` (expect no live key patterns) | ✅ | ⬜ |
| 51-01-02 | 01 | 1 | INT-01 | — | Same | rg | `rg -n 'Capsule|capsule' accrue/guides/first_hour.md` | ✅ | ⬜ |
| 51-02-01 | 02 | 1 | INT-02 | — | No false merge claims | script | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ |
| 51-03-01 | 03 | 2 | INT-03 | — | Anchors only, no PII | rg | `rg -n '#accrue-dx-webhook-raw-body' accrue/guides/webhooks.md` | ✅ | ⬜ |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new test stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reader flow | INT-01 | Subjective reading order | Diff `first_hour.md` vs `examples/accrue_host/README.md` step order; confirm capsules + spine match **51-CONTEXT D-01–D-04**. |

---

## Validation Sign-Off

- [ ] Contract script green after README proof edits
- [ ] No `sk_live` / credential examples in touched guides
- [ ] `nyquist_compliant: true` set when execution completes

**Approval:** pending
