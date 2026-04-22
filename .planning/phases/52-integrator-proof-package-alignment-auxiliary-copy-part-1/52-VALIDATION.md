---
phase: 52
slug: integrator-proof-package-alignment-auxiliary-copy-part-1
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-22
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for Phase **52** (docs gates + **`accrue_admin`** copy + tests). **Wave 0** = existing repo tooling (no new framework install).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) + bash CI contract scripts |
| **Config file** | `accrue_admin/config/config.exs` (test), `accrue/mix.exs` |
| **Quick run command** | `cd accrue_admin && mix test test/accrue_admin/live/coupon_promotion_copy_test.exs` *(path after tests exist)* OR `cd accrue_admin && mix test --only line:…` scoped to touched tests |
| **Full suite command** | `mix test` from repo root per monorepo convention **or** `cd accrue_admin && mix test` after admin changes |
| **Estimated runtime** | ~60–180 seconds (admin subset); full suite longer |

---

## Sampling Rate

- **After every task commit:** Run the **smallest** relevant check (`mix test` on touched test file, or one bash verifier if task touched only docs).
- **After every plan wave:** `cd accrue_admin && mix test` + **`bash scripts/ci/verify_package_docs.sh`** when any install doc or `mix.exs` changed.
- **Before `/gsd-verify-work`:** `bash scripts/ci/verify_package_docs.sh` + `bash scripts/ci/verify_verify01_readme_contract.sh` + `bash scripts/ci/verify_adoption_proof_matrix.sh` (all **0** exit) + **`mix test`** green for touched packages.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | INT-04 | — | Docs use placeholders only | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 52-01-02 | 01 | 1 | INT-04 | — | Matrix needles aligned | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 52-02-01 | 02 | 1 | INT-05 | — | No secrets in README edits | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 52-03-01 | 03 | 1 | AUX-01 | — | N/A | mix | `cd accrue_admin && mix test path/to/coupon_tests.exs` | ❌ W0 → created in execution | ⬜ pending |
| 52-03-02 | 03 | 1 | AUX-02 | — | N/A | mix | `cd accrue_admin && mix test path/to/promo_tests.exs` | ❌ W0 → created in execution | ⬜ pending |

---

## Wave 0 Requirements

- [x] Existing **`mix test`** + **`scripts/ci/verify_*.sh`** cover Phase 52 — **no** new pytest/jest install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evaluator reads walkthrough aloud | INT-04 | Human voice check | Spot-check **`evaluator-walkthrough-script.md`** against README commands after edits. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
