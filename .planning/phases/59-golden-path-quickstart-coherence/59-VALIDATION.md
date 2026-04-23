---
phase: 59
slug: golden-path-quickstart-coherence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + bash contract scripts |
| **Config file** | `accrue/mix.exs` (test env inherits host app deps for `accrue` package tests) |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` (from repo root with `MIX_ENV=test` where applicable) |
| **Estimated runtime** | ~2–6 minutes (depends on cold compile) |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_package_docs.sh`
- **After verifier / ExUnit plan wave:** Run the **full suite command**
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~360 seconds for full suite on cold CI

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | INT-06 | — | Docs only — no real secrets | manual+rg | `rg -n 'Trust boundary|auth_adapters' accrue/guides/first_hour.md` | ✅ | ⬜ pending |
| 59-01-02 | 01 | 1 | INT-06 | — | N/A | rg | `rg -n 'Sigra|demo' accrue/guides/first_hour.md` | ✅ | ⬜ pending |
| 59-01-03 | 01 | 1 | INT-06 | — | N/A | rg | `rg -n 'auth_adapters' accrue/guides/quickstart.md` | ✅ | ⬜ pending |
| 59-01-04 | 01 | 1 | INT-06 | — | N/A | rg | `rg -n 'verify_package_docs|verify_verify01|verify_adoption_proof' CONTRIBUTING.md` | ✅ | ⬜ pending |
| 59-02-01 | 02 | 2 | INT-06 | — | N/A | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 59-02-02 | 02 | 2 | INT-06 | — | N/A | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 59-02-03 | 02 | 2 | INT-06 | — | N/A | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 59-02-04 | 02 | 2 | INT-06 | — | N/A | mix | `mix test accrue/test/accrue/docs/package_docs_verifier_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- **Existing infrastructure covers all phase requirements.** No new test framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| “No contradictory messaging vs v1.15” narrative | INT-06 | Script checks literals/structure, not rhetorical contradictions | Maintainer read: First Hour ↔ host README ↔ quickstart after edits. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or documented manual checks
- [ ] Sampling continuity: doc tasks run `verify_package_docs.sh` after each commit
- [ ] Wave 0 covers all MISSING references — N/A (no W0)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable for CI
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
