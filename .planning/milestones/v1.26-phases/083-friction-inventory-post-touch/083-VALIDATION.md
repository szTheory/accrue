---
phase: 83-friction-inventory-post-touch
slug: friction-inventory-post-touch
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-24
---

# Phase 83 — Validation Strategy

> Bash-first verification; no application runtime or secrets.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash CI scripts (shift-left) |
| **Config file** | none |
| **Quick run command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` |
| **Full suite command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Estimated runtime** | ~60 seconds |

## Sampling Rate

- **After inventory or script edits:** Quick run command
- **Before marking `083-VERIFICATION.md` complete:** Full suite command
- **Max feedback latency:** N/A (manual maintainer pass)

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 83-01-01 | 01 | 1 | INV-04 | T-83-01 / T-83-03 | N/A — docs only | bash | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 83-01-02 | 01 | 1 | INV-04 | T-83-01 | N/A | bash | same | ✅ | ⬜ pending |
| 83-01-03 | 01 | 1 | INV-04 | T-83-02 | N/A | bash | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 83-01-04 | 01 | 1 | INV-04 | T-83-01 | N/A | bash | full suite | ✅ | ⬜ pending |
| 83-01-05 | 01 | 1 | INV-04 | T-83-01 | N/A | manual | CI URL or workflow cite | ✅ | ⬜ pending |
| 83-01-06 | 01 | 1 | INV-04 | — | N/A | bash + grep | `rg` contracts in plan | ✅ | ⬜ pending |

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements** — no new test stubs.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| GitHub Actions green on reviewed SHA | INV-04 | CI is remote | Open `github.com` Actions for the cited merge SHA; confirm `docs-contracts-shift-left` and `host-integration` succeeded |

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual CI evidence
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] `083-RESEARCH.md` references Validation Architecture

**Approval:** pending
