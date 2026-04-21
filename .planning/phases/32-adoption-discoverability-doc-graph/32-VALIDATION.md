---
phase: 32
slug: adoption-discoverability-doc-graph
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash doc-contract scripts (no ExUnit for primary gate) |
| **Config file** | `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh` |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Full suite command** | Same as quick |
| **Estimated runtime** | ~5–15 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick command from repository root.
- **After every plan wave:** Run the quick command again before merging plan branch.
- **Before `/gsd-verify-work`:** Both scripts must exit 0.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | ADOPT-02 | T-doc-01 | No misleading merge-blocking claims | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | ADOPT-02 | T-doc-01 | VERIFY-01 awk still guards sk_live | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 32-02-01 | 02 | 2 | ADOPT-01 | T-doc-01 | Root hop count / link validity | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 32-03-01 | 03 | 2 | ADOPT-03 | T-doc-01 | Cross-guide one-liner parity | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — doc-contract scripts already run in CI.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Two-hop discoverability | ADOPT-01 | Human judgment on README flow | From root `README.md`, follow links; count hops to a runnable VERIFY-01 / `mix verify` / Playwright instruction block. |
| No contradictory primary command | Roadmap criterion 3 | Requires reading prose holistically | Read linked set: root README, host Proof H2, `accrue/guides/testing.md`, `guides/testing-live-stripe.md`; confirm `mix verify` is never “CI-complete” without qualifier. |

---

## Validation Sign-Off

- [x] All tasks have automated verify via doc scripts or documented manual steps
- [x] Sampling continuity: doc scripts after each wave
- [x] Wave 0 covers all MISSING references — N/A (no Wave 0 install)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution green
