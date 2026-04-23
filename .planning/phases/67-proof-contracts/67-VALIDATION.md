---
phase: 67
slug: proof-contracts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 67 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (accrue) + bash shift-left |
| **Config file** | `accrue/mix.exs` (test env) |
| **Quick run command** | `bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Full suite command** | `bash scripts/ci/verify_adoption_proof_matrix.sh` && `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_adoption_proof_matrix.sh` from repo root
- **After every plan wave:** Run quick command plus targeted `mix test` for touched doc tests
- **Before `/gsd-verify-work`:** `docs-contracts-shift-left` equivalents green locally
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-01-01 | 01 | 1 | PRF-01 | T-67-01 / — | N/A (docs integrity) | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 67-01-02 | 01 | 1 | PRF-01 | — | N/A | mix | `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` | ✅ | ⬜ pending |
| 67-01-03 | 01 | 1 | PRF-02 | — | N/A | grep | `grep -Fq 'adoption-proof-matrix.md' scripts/ci/README.md` (after edits) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — no new test stubs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README readability | PRF-02 | Subjective flow | Skim `### Triage: verify_adoption_proof_matrix.sh` for SSOT path + co-update rule |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or N/A documented
- [ ] Sampling continuity: bash gate after script edits
- [ ] No watch-mode flags
- [ ] Feedback latency under budget
- [ ] `nyquist_compliant: true` set in frontmatter when phase closes

**Approval:** pending
