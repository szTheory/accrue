---
phase: 160
slug: stable-core-public-positioning
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 160 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract scripts executed by GitHub Actions |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_release_notes_contract.sh` |
| **Full suite command** | CI required jobs including `docs-contracts-shift-left`, `release-manifest-ssot`, `release-gate`, and `host-integration` |
| **Estimated runtime** | ~60 seconds locally for docs contract scripts; full CI runtime varies |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_stable_core_posture.sh`
- **After every plan wave:** Run local docs-contract equivalent including the stable-core posture verifier, release-notes verifier, package-doc verifier, processor-support-matrix verifier, and adoption-proof verifier
- **Before `$gsd-verify-work`:** Full required CI jobs must be green
- **Max feedback latency:** 120 seconds for docs-contract feedback after each task commit

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 160-01-01 | 01 | 1 | POS-01 | T-160-01 | Public stable-core posture cannot drift silently | contract | `bash scripts/ci/verify_stable_core_posture.sh` | No - Wave 0 creates it | pending |
| 160-01-02 | 01 | 1 | POS-02 | T-160-02 | Adopter-facing support and ownership boundaries remain explicit | contract | `bash scripts/ci/verify_stable_core_posture.sh` | No - Wave 0 creates it | pending |
| 160-01-03 | 01 | 1 | POS-03 | T-160-03 | Mirrors stay aligned across public docs, release notes, planning mirrors, and proof docs | contract | `bash scripts/ci/verify_stable_core_posture.sh && bash scripts/ci/verify_release_notes_contract.sh` | Partially - release-notes verifier exists | pending |

---

## Wave 0 Requirements

- [ ] `scripts/ci/verify_stable_core_posture.sh` - new posture contract gate for POS-01, POS-02, and POS-03.
- [ ] `.github/workflows/ci.yml` - add the stable-core posture step under `docs-contracts-shift-left`.
- [ ] `scripts/ci/README.md` - add triage and requirement mapping entry for POS-01, POS-02, and POS-03.

---

## Manual-Only Verifications

All phase behaviors have automated verification through Bash docs-contract scripts and required CI jobs.

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for docs-contract checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
