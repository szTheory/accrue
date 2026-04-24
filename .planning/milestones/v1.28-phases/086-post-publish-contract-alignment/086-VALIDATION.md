---
phase: 86
slug: post-publish-contract-alignment
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 86 — Validation Strategy

> Doc/version contract phase: merge-blocking bash gates + optional ExUnit mirror. No application runtime under test.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Primary** | Bash scripts under **`scripts/ci/`** (see **`.github/workflows/ci.yml`** job **`docs-contracts-shift-left`**) |
| **Mirror** | **`mix test test/accrue/docs/package_docs_verifier_test.exs`** from **`accrue/`** (Postgres-backed) |
| **Quick run** | `bash scripts/ci/verify_package_docs.sh` |
| **Full doc contract** | Run all six steps in **`docs-contracts-shift-left`** order (see RESEARCH.md) |
| **Estimated runtime** | ~2–5 minutes local (bash only); full matrix on CI |

---

## Sampling Rate

- **After integrator doc or script edits:** `bash scripts/ci/verify_package_docs.sh` + `bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Before marking phase complete:** Full **`docs-contracts-shift-left`** script list + ExUnit **`package_docs_verifier_test.exs`**
- **Before `/gsd-verify-work`:** **`086-VERIFICATION.md`** checklist filled with merge SHA

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 86-01-01 | 01 | 1 | PPX-05..08 | T-86-01 | N/A — public SemVer strings only | bash | `bash scripts/ci/verify_package_docs.sh` | ⬜ |
| 86-01-02 | 01 | 1 | PPX-05 | T-86-01 | N/A | ex_unit | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ⬜ |
| 86-01-03 | 01 | 1 | PPX-06 | T-86-02 | N/A | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ⬜ |
| 86-01-04 | 01 | 1 | PPX-07 | T-86-01 | N/A | bash | Six scripts in CI job order | ⬜ |
| 86-01-05 | 01 | 1 | PPX-08 | T-86-03 | N/A | manual+grep | Planning mirror grep vs Hex; inventory pointer lines | ⬜ |

---

## Wave 0 Requirements

- [x] Existing **`scripts/ci/`** + **`ci.yml`** define contracts — no new test framework.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex published versions match **`@version`** | PPX-05 | Registry is external | Read **`hex.pm`** (or mix hex.info) for **`accrue`** and **`accrue_admin`**; values must match **`mix.exs`** on merge SHA; paste one line into **`086-VERIFICATION.md`** Preconditions. |

---

## Validation Sign-Off

- [ ] All tasks have grep- or exit-code-verifiable acceptance
- [ ] Full **`docs-contracts-shift-left`** bundle recorded for PPX-07
- [ ] `nyquist_compliant: true` set in frontmatter when phase executes

**Approval:** pending
