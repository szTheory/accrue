---
phase: 162
slug: close-gap-rel-01-rel-03-linked-release-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 162 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract verifiers + GitHub Actions workflow validation |
| **Config file** | `.github/workflows/release-please.yml` |
| **Quick run command** | `bash -n scripts/ci/capture_linked_release_proof.sh && bash -n scripts/ci/verify_release_pr_scope.sh` |
| **Full suite command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_release_notes_contract.sh` |
| **Estimated runtime** | ~60 seconds, excluding live Hex smoke and GitHub Actions artifact availability |

---

## Sampling Rate

- **After every task commit:** Run `bash -n scripts/ci/capture_linked_release_proof.sh && bash -n scripts/ci/verify_release_pr_scope.sh`
- **After every plan wave:** Run `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_release_notes_contract.sh`
- **Before `$gsd-verify-work`:** Canonical proof must exist in `159-VERIFICATION.md`, Phase 162 must point to it, and release mirrors must reconcile to the same PR/version/run evidence.
- **Max feedback latency:** 60 seconds for local contract checks; live publish proof is bounded by GitHub Actions and Hex propagation.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 162-01-01 | 01 | 1 | REL-01 | T-162-01 | Release PR evidence is tied to a real PR and target version greater than `1.3.0` | contract | `bash scripts/ci/verify_release_pr_scope.sh --pr <pr> --version <target>` | yes | pending |
| 162-01-02 | 01 | 1 | REL-03 | T-162-02 | Publish proof is bound to one exact PR/version/run and appended to canonical Phase 159 ledger | integration/contract | `bash scripts/ci/capture_linked_release_proof.sh --version <target> --run-id <run> --pr <pr> --output .planning/phases/159-linked-release-readiness-publish-proof/159-VERIFICATION.md` | yes | pending |
| 162-01-03 | 01 | 1 | REL-03 | T-162-03 | Public package install path and release-notes mirror corroborate canonical proof | integration/contract | `bash scripts/ci/accrue_host_hex_smoke.sh && bash scripts/ci/verify_release_notes_contract.sh` | yes | pending |
| 162-01-04 | 01 | 1 | REL-01, REL-03 | T-162-04 | Planning mirrors are reconciled without replacing the canonical ledger or fabricating proof | source/assertion | `rg "REL-01|REL-02|REL-03|Phase 162|159-VERIFICATION" .planning/ROADMAP.md .planning/STATE.md .planning/phases/162-close-gap-rel-01-rel-03-linked-release-proof/162-VERIFICATION.md` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the GitHub Actions `linked-release-proof.md` artifact URL is the canonical artifact for the same PR/version/run recorded in `159-VERIFICATION.md` | REL-03 | Artifact URL identity depends on the live GitHub run produced after publish | Open the recorded run URL and verify the artifact name, run id, target version, and PR number match the canonical ledger block. |
| Confirm no placeholder evidence remains in Phase 162 closeout | REL-01, REL-03 | Prevents false closure when live release proof is unavailable | Search `159-VERIFICATION.md`, `162-VERIFICATION.md`, `ROADMAP.md`, and `STATE.md` for placeholder words such as `TBD`, `<pr>`, `<target>`, `<run>`, or fabricated post-`1.3.0` evidence. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual verification for live artifact identity.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s for local contract checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-01
