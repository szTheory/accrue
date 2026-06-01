---
phase: 161
slug: backlog-anchor-closure-pause-rule
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-01
---

# Phase 161 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash verifier scripts + GitHub Actions docs-contract lane |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_roadmap_hygiene.sh` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_v1_17_friction_research_contract.sh && bash scripts/ci/verify_roadmap_hygiene.sh` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_roadmap_hygiene.sh`
- **After every plan wave:** Run the full docs-contract bundle listed above
- **Before `$gsd-verify-work`:** Full docs-contract bundle must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 161-01-01 | 01 | 0 | BAK-01, BAK-02, PAU-01 | T-161-01 / T-161-02 | Roadmap hygiene verifier fails when historical/dormant/pause-rule wording drifts | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | No - Wave 0 | pending |
| 161-01-02 | 01 | 1 | BAK-01 | T-161-02 | Historical anchors remain traceable but cannot be interpreted as active broad-feature scope | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | No - Wave 0 | pending |
| 161-01-03 | 01 | 1 | BAK-01, PAU-01 | T-161-02 | Deferred seeds and ideas carry explicit trigger-bound dormant status | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | No - Wave 0 | pending |
| 161-01-04 | 01 | 1 | BAK-02, PAU-01 | T-161-01 / T-161-02 | PROJECT/ROADMAP/STATE mirrors preserve the reopen trigger set and reject feature-freeze wording | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` | No - Wave 0 | pending |
| 161-01-05 | 01 | 1 | BAK-02 | T-161-01 | CI shift-left lane runs the hygiene verifier with the other docs contracts | contract | `bash scripts/ci/verify_roadmap_hygiene.sh` plus docs-contract bundle | No - Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_roadmap_hygiene.sh` - contract stubs and initial failing assertions for BAK-01, BAK-02, and PAU-01
- [ ] `scripts/ci/README.md` - triage entry documenting the new roadmap hygiene verifier
- [ ] `.github/workflows/ci.yml` - `docs-contracts-shift-left` step wiring for the hygiene verifier

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Historical and dormant wording is maintainer-readable, not just grep-compatible | BAK-01, BAK-02 | Exact language quality affects future planning interpretation | Read `.planning/ROADMAP.md`, `.planning/PROJECT.md`, and `.planning/STATE.md`; confirm no active roadmap pointer implies broad feature work is currently active |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-01
