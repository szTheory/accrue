---
phase: 214
slug: docs-truth-reconciliation
status: ready
nyquist_compliant: true
wave_0_complete: true
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
| 214-01-01 | 01 | 1 | DOCS-01, DOCS-02 | T-214-01 | Current docs reject stale `lattice_stripe` pins and grant-authority drift | contract + focused fixture | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh` | ✅ extend | ⬜ pending |
| 214-01-02 | 01 | 1 | DOCS-02, DOCS-03 | T-214-01, T-214-03 | Adopter, support, and proof mirrors preserve observational-only authority | contract + isolation | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_entitlement_sync_isolation.sh` | ✅ extend | ⬜ pending |
| 214-01-03 | 01 | 1 | DOCS-03 | T-214-02 | Active planning mirrors reconcile without rewriting dated evidence | scoped planning audit | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query roadmap.get-phase 214 && rg -n '213|SYNC-0[1-5]|214|DOCS-0[1-3]' .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md` | ✅ existing | ⬜ pending |
| 214-02-01 | 02 | 2 | DOCS-03 | T-214-05, T-214-07, T-214-08 | Package-owned Unreleased and release-guide truth preserve ownership and grant boundaries | release contract + diff check | `bash scripts/ci/verify_release_notes_contract.sh && git diff --check -- accrue/CHANGELOG.md accrue_admin/CHANGELOG.md accrue_portal/CHANGELOG.md accrue/guides/release-notes.md` | ✅ extend | ⬜ pending |
| 214-02-02 | 02 | 2 | DOCS-03 | T-214-05, T-214-08 | Release-note discoverability regressions fail non-vacuously | focused fixture | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs && cd .. && bash scripts/ci/verify_release_notes_contract.sh` | ✅ extend | ⬜ pending |
| 214-02-03 | 02 | 2 | DOCS-03 | T-214-06 | Exactly the supported public contracts carry `since: "1.5.0"` | focused fixture + compile | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && mix compile --warnings-as-errors && cd .. && bash scripts/ci/verify_package_docs.sh` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Infrastructure

- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` exists and provides the ROOT_DIR-backed fixture scaffold that Tasks 214-01-01, 214-01-02, and 214-02-03 extend.
- [x] `accrue/test/accrue/docs/release_notes_contract_test.exs` exists and provides the release-note fixture scaffold that Task 214-02-02 extends.
- [x] `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_release_notes_contract.sh`, `scripts/ci/verify_processor_support_matrix.sh`, and `scripts/ci/verify_entitlement_sync_isolation.sh` exist and are directly exercised by task-level automation.
- [x] No task references a missing test file or unresolved Wave 0 dependency; behavior-specific red fixtures and verifier assertions are created test-first inside their owning tasks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Historical references remain intact while current surfaces tell one story | DOCS-01, DOCS-02, DOCS-03 | Repo-wide grep includes intentionally historical evidence | Classify every `lattice_stripe` and `entitlements sync` hit as current-contract or historical; confirm only historical surfaces retain old wording. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 infrastructure exists and every task verification target is present
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
