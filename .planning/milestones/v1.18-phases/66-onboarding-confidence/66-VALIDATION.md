---
phase: 66
slug: onboarding-confidence
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-04-23"
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (docs + bash contracts; no standalone test DB for `.planning/` work).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue`) + bash `scripts/ci/verify_*.sh` |
| **Config file** | `accrue/mix.exs` (test paths under `test/accrue/docs/`) |
| **Quick run command** | From repo root: `bash scripts/ci/verify_package_docs.sh; bash scripts/ci/verify_v1_17_friction_research_contract.sh; bash scripts/ci/verify_verify01_readme_contract.sh; bash scripts/ci/verify_adoption_proof_matrix.sh; bash scripts/ci/verify_core_admin_invoice_verify_ids.sh` |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/v1_17_friction_research_contract_test.exs test/accrue/docs/organization_billing_org09_matrix_test.exs` (extend paths if new mirrors land) |
| **Estimated runtime** | ~2–5 minutes for doc-contract slice; full `mix test` much longer |

---

## Sampling Rate

- **After every task commit:** Run the **quick** bash bundle rows that the task touched (see **Per-Task Verification Map**).
- **After every plan wave:** Run **quick** bundle in full + targeted `mix test` paths for touched ExUnit mirrors.
- **Before `/gsd-verify-work`:** `docs-contracts-shift-left` equivalents green locally; PR sees same jobs on GitHub **CI** / **`docs-contracts-shift-left`**.
- **Max feedback latency:** ~5 minutes for doc-only waves.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | UAT-01..UAT-05 ledger | T-66-01 / — | No secrets in `.planning/` proof text | manual+script | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` | ✅ | ⬜ pending |
| 66-02-01 | 02 | 2 | UAT-02, STATE | T-66-01 | No PII in STATE edits | script | same + `rg "v1\\.17-FRICTION-INVENTORY" .planning/STATE.md` | ✅ | ⬜ pending |
| 66-02-02 | 02 | 2 | UAT-04 (optional) | — | N/A | script | `test -f .planning/milestones/v1.17-REQUIREMENTS.md` (after script lands) | ⬜ W0 | ⬜ pending |
| 66-03-01 | 03 | 3 | PROOF-01 | T-66-01 | No live keys in host README | script | `bash scripts/ci/verify_adoption_proof_matrix.sh`; `cd accrue && mix test test/accrue/docs/organization_billing_org09_matrix_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Existing infrastructure covers all phase requirements** — no new Elixir app or DB for `.planning/` closure; optional **one** new `verify_*.sh` line only if UAT-04 file-presence is added per **66-RESEARCH.md**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| **66-VERIFICATION.md** maintainer sign-off cells | UAT-01..UAT-05 | Scenario judgment + inventory spot-check beyond bash | Fill **Closure** column; paste **Evidence** paths; date + initials policy per **66-CONTEXT.md** D-02a |
| **PROOF-01** semantic read | PROOF-01 | Matrix vs walkthrough vs README narrative cannot be fully encoded | Single sitting: read `adoption-proof-matrix.md`, `evaluator-walkthrough-script.md`, host README adoption/VERIFY hops; note contradictions in verification spot-check section |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under 5 minutes for doc waves
- [ ] `nyquist_compliant: true` set in frontmatter when phase verification completes

**Approval:** pending
