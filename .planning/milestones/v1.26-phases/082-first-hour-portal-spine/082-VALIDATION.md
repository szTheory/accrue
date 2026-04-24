---
phase: 82
slug: first-hour-portal-spine
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-24
---

# Phase 82 — Validation Strategy

> Per-phase validation contract for doc + CI substring work (**INT-13**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit (existing) + bash shift-left verifiers |
| **Config file** | `accrue/config/config.exs` (unchanged) |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` (integrator smoke; advisory vs full merge contract) |
| **Estimated runtime** | ~2–15 minutes depending on host suite |

---

## Sampling Rate

- **After every task commit:** Run quick verifier command(s) named in that task’s `<acceptance_criteria>`.
- **After wave 2 (CI scripts):** Run both **`verify_package_docs.sh`** and **`verify_adoption_proof_matrix.sh`** from repository root.
- **Before `/gsd-verify-work`:** Quick verifiers green; record transcripts in **`082-VERIFICATION.md`**.
- **Max feedback latency:** 120s for bash gates alone.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 82-01-01 | 01 | 1 | INT-13 | T-82-01 | Docs do not introduce secret-bearing URLs in prose beyond existing checkout pattern | manual+grep | `rg -n 'create_billing_portal_session'` in targets | ⬜ | ⬜ pending |
| 82-01-02 | 01 | 1 | INT-13 | — | N/A | grep | `rg -n 'billing-billing-portal-create' accrue/guides/telemetry.md` | ⬜ | ⬜ pending |
| 82-01-03 | 01 | 1 | INT-13 | — | N/A | grep | `rg -n 'billing_portal_session_facade_test' examples/accrue_host/docs/adoption-proof-matrix.md` | ⬜ | ⬜ pending |
| 82-01-05 | 01 | 1 | INT-13 | T-82-01 | Pointer only; no new secrets in prose | awk+rg | `awk '/## Proof and verification/,/### Verification modes/' examples/accrue_host/README.md \| rg first_hour` | ⬜ | ⬜ pending |
| 82-02-01 | 02 | 1 | INT-13 | — | N/A | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 82-02-02 | 02 | 1 | INT-13 | — | N/A | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| 82-02-03 | 02 | 1 | INT-13 | — | N/A | file | `test -f .planning/milestones/v1.26-phases/082-first-hour-portal-spine/082-VERIFICATION.md` | ⬜ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — no new framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README anchor resolves in browser | INT-13 | Link targets depend on HexDocs host | Open built docs or raw GitHub view; confirm `#billing-billing-portal-create` fragment exists on telemetry page. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual step
- [ ] Sampling continuity: bash gates after script edits
- [ ] `082-VERIFICATION.md` lists SHA + verifier output snippets
- [ ] `nyquist_compliant: true` set in frontmatter when phase evidence is complete

**Approval:** pending
