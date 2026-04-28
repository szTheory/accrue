---
phase: 093
slug: hyg-mirror-inv-tag
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 093 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Repo bash contract scripts + manual git/grep closeout checks |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` |
| **Full suite command** | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -n '1\\.0\\.0|v1\\.30|shipped|Phase 93' .planning/PROJECT.md .planning/MILESTONES.md .planning/STATE.md && git tag --list 'v1.30' && git rev-parse v1.30` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_v1_17_friction_research_contract.sh` after any inventory edit.
- **After every plan wave:** Run `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -n '1\.0\.0|v1\.30|shipped|Phase 93' .planning/PROJECT.md .planning/MILESTONES.md .planning/STATE.md`
- **Before `$gsd-verify-work`:** Full suite must be green and `git rev-parse v1.30` must resolve to the close commit.
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 093-01-01 | 01 | 1 | HYG-02 | T-93-01 | `PROJECT.md` and `MILESTONES.md` mirror the published `1.0.0` pair and shipped v1.30 posture without touching public docs. | grep | `rg -F 'Current focus: **v1.30 closeout (2026-04-28)**' .planning/PROJECT.md && rg -F '## v1.30 \`1.0.0\` Declaration (Spine A)' .planning/MILESTONES.md` | ✅ | ⬜ pending |
| 093-01-02 | 01 | 1 | HYG-02 | T-93-01 | `STATE.md` reflects that Phase 93 remains the active closeout slice after Phase 92 proof completion. | grep | `rg -F 'Phase: 93 Post-publish HYG mirror + INV-07 + tag — next' .planning/STATE.md && rg -F 'Phase 93 closeout remains' .planning/STATE.md` | ✅ | ⬜ pending |
| 093-02-01 | 02 | 1 | INV-07 | T-93-04 | Inventory remains path-(b), row counts unchanged, and verifier contract stays green after the dated pass is appended. | shell contract | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 093-02-02 | 02 | 1 | INV-07 | T-93-05 | `093-VERIFICATION.md` reuses `092-VERIFICATION.md` and captures only the fresh inventory transcript. | grep | `rg -F '092-VERIFICATION.md' .planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md && rg -F 'verify_v1_17_friction_research_contract: OK' .planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md` | ✅ | ⬜ pending |
| 093-03-01 | 03 | 2 | HYG-02, INV-07 | T-93-07 | `093-VERIFICATION.md` records HYG mirror review and `.planning/REQUIREMENTS.md` closes only HYG-02 and INV-07 before the tag exists. | grep | `rg -F '## HYG-02 mirror review' .planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md && rg -F -- '- [ ] **REL-08**' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 093-03-02 | 03 | 2 | REL-08 | T-93-08 / T-93-09 | `v1.30` exists on the close commit, `STATE.md` flips to the final closed posture, and REL-08 closes only after the tag proof lands. | git metadata + grep | `git tag --list 'v1.30' && git rev-parse v1.30 && rg -F 'Phase: v1.30 closed — next milestone pending' .planning/STATE.md && rg -F -- '- [x] **REL-08**' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review final mirror wording in `PROJECT.md`, `MILESTONES.md`, and `STATE.md` against `092-VERIFICATION.md` and `ROADMAP.md`. | HYG-02 | The repo has no single script that semantically validates milestone prose. | Read the three files plus `092-VERIFICATION.md`; confirm they cite `accrue` / `accrue_admin` `1.0.0`, mark v1.30 as shipped/closed, and do not claim extra scope beyond HYG-02 / INV-07 / REL-08. |
| Confirm the closing commit SHA recorded in `093-VERIFICATION.md` matches the tag target and final docs state. | REL-08 | The tag proof is metadata plus human closeout review. | Run `git rev-parse HEAD` on the close commit, `git rev-parse v1.30`, and compare both values to the SHA recorded in `093-VERIFICATION.md`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28
