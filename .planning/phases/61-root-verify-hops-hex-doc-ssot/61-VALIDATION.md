---
phase: 61
slug: root-verify-hops-hex-doc-ssot
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for doc/bash/ExUnit work (**no** new runtime billing features).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) + bash scripts |
| **Config file** | `accrue/mix.exs` (test paths only) |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every task commit:** `bash scripts/ci/verify_package_docs.sh`
- **After tasks touching host README:** also `bash scripts/ci/verify_verify01_readme_contract.sh`
- **After edits to `package_docs_verifier_test.exs` or `verify_package_docs.sh`:** `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs`
- **Before `/gsd-verify-work`:** both bash gates + ExUnit file above exit 0
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | INT-08 | — | N/A (docs) | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 61-01-02 | 01 | 1 | INT-08 | — | N/A | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 61-02-01 | 02 | 1 | INT-09 | — | N/A | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing **ExUnit** + **`verify_package_docs`** infrastructure covers this phase (**no** new framework).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README hop readability for a human evaluator | INT-08 | Subjective “buried or not” | Open root `README.md`; confirm **Proof path** visible without excessive scroll on a laptop viewport; if not, apply D-02 micro hop map |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or bash gates listed above
- [ ] Sampling continuity: doc tasks chained through `verify_package_docs`
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
