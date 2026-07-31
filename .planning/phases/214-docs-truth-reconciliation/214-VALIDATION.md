---
phase: 214
slug: docs-truth-reconciliation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-30
---

# Phase 214 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix 1.19.5 plus Bash CI verifiers |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/release_notes_contract_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_release_notes_contract.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_entitlement_sync_isolation.sh` |
| **Estimated runtime** | Under 60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the relevant CI verifier plus the focused docs ExUnit file.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Full suite and scoped acceptance grep must be green.
- **Max feedback latency:** 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 214-01-01 | 01 | 1 | DOCS-01 | T-214-01 | Current docs reject stale `lattice_stripe` pins | contract | `bash scripts/ci/verify_package_docs.sh` | ✅ extend | ⬜ pending |
| 214-01-02 | 01 | 1 | DOCS-02 | T-214-01 | Sync remains observational and never grant-authoritative | contract | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ extend | ⬜ pending |
| 214-02-01 | 02 | 2 | DOCS-03 | T-214-02 | Release notes and public API metadata agree | contract | `bash scripts/ci/verify_release_notes_contract.sh` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `accrue/test/accrue/docs/package_docs_verifier_test.exs` with stale `lattice_stripe` and deferred-sync red paths.
- [ ] Extend `accrue/test/accrue/docs/release_notes_contract_test.exs` with missing portal changelog link and missing next-release story red paths.
- [ ] Add verifier assertions for `since: "1.5.0"` on Phase 213 public contracts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Historical references remain intact while current surfaces tell one story | DOCS-01, DOCS-02, DOCS-03 | Repo-wide grep includes intentionally historical evidence | Classify every `lattice_stripe` and `entitlements sync` hit as current-contract or historical; confirm only historical surfaces retain old wording. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
