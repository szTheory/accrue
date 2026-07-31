---
phase: 214
slug: docs-truth-reconciliation
status: validated
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
| 214-01-01 | 01 | 1 | DOCS-01, DOCS-02 | T-214-01 | Current docs reject stale `lattice_stripe` pins and grant-authority drift | contract + focused fixture | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh` | ✅ | ✅ green |
| 214-01-02 | 01 | 1 | DOCS-02, DOCS-03 | T-214-01, T-214-03 | Adopter, support, and proof mirrors preserve observational-only authority | contract + isolation | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_entitlement_sync_isolation.sh` | ✅ | ✅ green |
| 214-01-03 | 01 | 1 | DOCS-03 | T-214-02 | Active planning mirrors reconcile without rewriting dated evidence | verifier + scoped assertions | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query roadmap.get-phase 214 --raw` | ✅ | ✅ green |
| 214-02-01 | 02 | 2 | DOCS-03 | T-214-05, T-214-07, T-214-08 | Package-owned Unreleased truth preserves ownership, grant boundaries, and the Release Please boundary | release contract + focused fixture + diff check | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs && cd .. && bash scripts/ci/verify_release_notes_contract.sh` | ✅ | ✅ green |
| 214-02-02 | 02 | 2 | DOCS-03 | T-214-05, T-214-08 | Release-note discoverability regressions fail non-vacuously | focused fixture | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs && cd .. && bash scripts/ci/verify_release_notes_contract.sh` | ✅ | ✅ green |
| 214-02-03 | 02 | 2 | DOCS-03 | T-214-06 | Exactly the supported public contracts carry `since: "1.5.0"` | focused fixture + compile | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs && mix compile --warnings-as-errors && cd .. && bash scripts/ci/verify_package_docs.sh` | ✅ | ✅ green |
| 214-03-01 | 03 | 3 | DOCS-03 | T-214-09..13 | Current, aligned 1.5.0, and future aligned candidates traverse the production release verifier | generated repository fixtures | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs` | ✅ | ✅ green |
| 214-03-02 | 03 | 3 | DOCS-03 | T-214-09..14 | Invalid linked release states fail safely with bounded diagnostics | negative contract fixtures | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs && cd .. && bash scripts/ci/verify_release_notes_contract.sh` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Infrastructure

- [x] `accrue/test/accrue/docs/package_docs_verifier_test.exs` exists and provides the ROOT_DIR-backed fixture scaffold that Tasks 214-01-01, 214-01-02, and 214-02-03 extend.
- [x] `accrue/test/accrue/docs/release_notes_contract_test.exs` exists and provides the release-note fixture scaffold that Task 214-02-02 extends.
- [x] `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_release_notes_contract.sh`, `scripts/ci/verify_processor_support_matrix.sh`, and `scripts/ci/verify_entitlement_sync_isolation.sh` exist and are directly exercised by task-level automation.
- [x] No task references a missing test file or unresolved Wave 0 dependency; behavior-specific red fixtures and verifier assertions are created test-first inside their owning tasks.

---

## Manual-Only Verifications

All phase behaviors have automated verification. The phase verifier's scoped current-surface scan distinguishes current contract text from dated historical evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 infrastructure exists and every task verification target is present
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-31

## Validation Audit 2026-07-31

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All requirements are covered by executable ExUnit fixtures and production CI verifier scripts; no manual-only verification remains.
