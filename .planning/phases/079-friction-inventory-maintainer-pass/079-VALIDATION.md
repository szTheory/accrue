---
phase: 79
slug: friction-inventory-maintainer-pass
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 79 — Validation Strategy

> Doc + bash-contract phase; no new application test harness.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash CI scripts (shift-left); optional **`mix test`** only if executor touches ExUnit-bearing paths |
| **Config file** | none |
| **Quick run command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` |
| **Full suite command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Estimated runtime** | ~2–15 minutes (package docs slower) |

---

## Sampling Rate

- **After every task commit:** `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- **After inventory or `verify_v1_17_friction_research_contract.sh` edits:** Full suite command above
- **Before `/gsd-verify-work`:** Full suite green on cited SHA
- **Max feedback latency:** Bounded by longest script (dominated by **`verify_package_docs.sh`**)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | INV-03 | T-79-01 / — | N/A (docs) | bash | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 79-01-02 | 01 | 1 | INV-03 | T-79-02 / — | N/A | bash | same + inventory grep | ✅ | ⬜ pending |
| 79-01-03 | 01 | 1 | INV-03 | T-79-03 / — | N/A | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 79-01-04 | 01 | 1 | INV-03 | — | N/A | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 79-01-05 | 01 | 1 | INV-03 | — | N/A | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 79-01-06 | 01 | 1 | INV-03 | — | N/A | manual | host-integration / CI pointer | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — reuse **`scripts/ci/*.sh`**; no new stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| **host-integration** green on cited SHA | INV-03 | Full job may require CI secrets / Playwright | In **`079-VERIFICATION.md`**, record **GitHub Actions** run URL or job id + merge SHA; if run locally, document partial vs full |

---

## Validation Sign-Off

- [ ] All tasks have bash verify or documented CI equivalent
- [ ] No 3 consecutive tasks without **`verify_v1_17_friction_research_contract.sh`** after inventory touches
- [ ] `nyquist_compliant: true` set in frontmatter when phase executes

**Approval:** pending
