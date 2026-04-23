---
phase: 63
slug: p0-integrator-verify-docs
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 63 — Validation Strategy

> Per-phase validation for **INT-10** integrator / VERIFY / docs closure.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue` package) + bash verifiers |
| **Config file** | `accrue/mix.exs` (test paths); verifiers self-contained |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/v1_17_friction_research_contract_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_verify01_readme_contract.sh` (from repo root) |
| **Estimated runtime** | ~30–120 seconds (bash + ExUnit; host UAT minutes if run locally) |

---

## Sampling Rate

- **After every task commit:** Quick ExUnit pair above (when task touched docs verifiers or inventory).
- **After every plan wave:** Full bash verifier trio when any wave touched paths those scripts read.
- **Before `/gsd-verify-work`:** `verify_package_docs.sh` + `verify_v1_17_friction_research_contract.sh` green; add `verify_verify01_readme_contract.sh` if `examples/accrue_host/README.md` changed.
- **Max feedback latency:** 3 minutes for doc-only waves (CI local approximation).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 1 | INT-10 | T-63-01 | No secrets in markdown | bash + unit | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 63-01-02 | 01 | 1 | INT-10 | — | N/A | unit | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ | ⬜ pending |
| 63-02-01 | 02 | 1 | INT-10 | — | N/A | bash | `bash scripts/ci/accrue_host_uat.sh` (optional local) + `rg '\[host-integration\]' scripts/ci/accrue_host_verify_*.sh scripts/ci/accrue_host_uat.sh` after implementation | ✅ | ⬜ pending |
| 63-03-01 | 03 | 2 | INT-10 | T-63-02 | Signed notes only, no secrets | bash | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 63-03-02 | 03 | 2 | INT-10 | — | N/A | unit | `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new Wave-0 framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions log scan | INT-10 | Hosted runner only | Open failing **`host-integration`** run; confirm first visible failure line includes `[host-integration]` phase hint or `FAILED_GATE` banner per **63-02** acceptance |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual row above
- [ ] Sampling continuity maintained across waves
- [ ] No watch-mode flags introduced
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
