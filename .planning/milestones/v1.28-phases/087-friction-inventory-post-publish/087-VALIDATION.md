---
phase: 87
slug: friction-inventory-post-publish
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 87 — Validation Strategy

> Doc and planning SSOT phase — verification is **bash CI contracts** + **GitHub Actions** job green, not ExUnit for deliverables.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash verifier scripts + GitHub Actions (`docs-contracts-shift-left`, `host-integration`) |
| **Config file** | `.github/workflows/ci.yml` (normative job membership @ reviewed SHA) |
| **Quick run command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` |
| **Full bundle command** | Run the six `bash scripts/ci/*.sh` steps under job `docs-contracts-shift-left` sequentially from repo root (see `087-RESEARCH.md`) |
| **Estimated runtime** | ~2–5 minutes local (shift-left only); host-integration longer in CI |

---

## Sampling Rate

- **After friction inventory subsection append:** `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- **After `087-VERIFICATION.md` finalized:** Full **shift-left** bundle on reviewed SHA (or cite existing **CI** run proving same membership)
- **Before `/gsd-verify-work`:** **`verify_v1_17_friction_research_contract.sh`** must exit **0** on final tree

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 87-01-01 | 01 | 1 | INV-06 | T-87-01 | N/A — attestation hygiene | bash | `rg -n 'docs-contracts-shift-left' .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 87-01-02 | 01 | 1 | INV-06 | T-87-02 | N/A | bash | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 87-01-03 | 01 | 1 | INV-06 | T-87-01 | N/A | bash | Full shift-left bundle @ SHA (see plan) | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new test stubs; **`accrue`** test suite unchanged unless a prior phase left **main** red (out of scope for **87**).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Path **(b)** maintainer conclusion | INV-06 | Human judgment vs **FRG-01** / **FRG-02** **S1**/**S5** | Read ranked friction evidence on reviewed SHA; write dated subsection voice consistently |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented CI replay
- [ ] `087-VERIFICATION.md` SHA matches `ci.yml` bundle enumeration
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
