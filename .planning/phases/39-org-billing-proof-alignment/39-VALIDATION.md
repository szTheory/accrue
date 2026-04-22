---
phase: 39
slug: org-billing-proof-alignment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (accrue package) + bash CI scripts |
| **Config file** | `accrue/config/config.exs` (host not required for doc tests) |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/` + `bash scripts/ci/verify_adoption_proof_matrix.sh` (repo root) |
| **Estimated runtime** | ~30–90 seconds (doc tests + bash) |

---

## Sampling Rate

- **After every task commit:** Run quick command + `bash scripts/ci/verify_adoption_proof_matrix.sh` from repo root when matrix or script touched
- **After every plan wave:** Full suite command family above + `bash scripts/ci/verify_verify01_readme_contract.sh` if README or VERIFY-01 script touched
- **Before `/gsd-verify-work`:** `host-integration` bash steps equivalent green locally
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | ORG-09 | T-39-01-01 / — | Public docs only; honest non-Sigra wording | bash + rg | `bash scripts/ci/verify_adoption_proof_matrix.sh` after script lands | ⬜ W0 | ⬜ pending |
| 39-02-01 | 02 | 2 | ORG-09 | T-39-02-01 | No secret logging in new bash | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ post W1 | ⬜ pending |
| 39-02-02 | 02 | 2 | ORG-09 | — | CI wiring only | rg | `rg -n verify_adoption_proof_matrix .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 39-03-01 | 03 | 2 | ORG-09 | — | Doc literals only | ExUnit | `cd accrue && mix test test/accrue/docs/organization_billing_guide_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_adoption_proof_matrix.sh` — created in Plan 02 (script must exist before matrix verifier column is meaningful in README)
- *Existing infrastructure covers ExUnit doc tests.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Matrix readability | ORG-09 | Editorial table flow | Spot-check rendered markdown in GitHub |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers script creation before blocking matrix claims
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
