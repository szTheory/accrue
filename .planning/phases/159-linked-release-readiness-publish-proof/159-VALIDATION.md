---
phase: 159
slug: linked-release-readiness-publish-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 159 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + bash contract scripts + GitHub Actions job gates |
| **Config file** | `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh` |
| **Full suite command** | GitHub Actions required jobs: `release-manifest-ssot`, `docs-contracts-shift-left`, `release-gate`, `phase18-tax-gate`, `admin-drift-docs`, `host-integration`, `annotation-sweep` |
| **Estimated runtime** | CI-dependent |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh`
- **After every plan wave:** Run the required CI gate bundle or its documented local equivalents.
- **Before `$gsd-verify-work`:** Full release proof must be green or explicitly documented with external blockers.
- **Max feedback latency:** CI-dependent

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 159-01-01 | 01 | 1 | REL-01 | — | Release-truth inputs cannot silently disagree across package versions, manifest, changelogs, tags, and runbook instructions. | contract | `bash scripts/ci/verify_release_pr_scope.sh --pr <n> --version <v>` | ✅ | ⬜ pending |
| 159-01-02 | 01 | 1 | REL-02 | — | Deterministic release gates produce one documented pass/fail artifact for all three packages. | integration + contract | required CI job bundle plus release proof append into `159-VERIFICATION.md` | ✅ | ⬜ pending |
| 159-01-03 | 01 | 1 | REL-03 | — | Ordered publish proof reconciles workflow, tags, GitHub releases, Hex, HexDocs, changelogs, and release notes. | workflow + post-publish capture | `bash scripts/ci/capture_linked_release_proof.sh --version <v> --run-id <id> --pr <n> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` — scaffold fixed schema for script-appended release proof.
- [ ] `scripts/ci/verify_release_manifest_alignment.sh` — verify whether it should be expanded in place for first-class `accrue_portal` coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex publish completion and public registry state | REL-03 | Actual publish depends on maintainer credentials, release PR merge timing, GitHub Actions run id, and Hex public availability. | Record PR number, target version, release workflow run id, Hex package URLs, HexDocs URLs, Git tags, and GitHub releases in `159-VERIFICATION.md`; run the post-publish capture script where credentials/network permit. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is acceptable for release workflow gates
- [ ] `nyquist_compliant: true` set in frontmatter when plan checker confirms coverage

**Approval:** pending
