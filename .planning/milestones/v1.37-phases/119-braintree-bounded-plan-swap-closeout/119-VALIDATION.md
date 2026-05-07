---
phase: 119
slug: braintree-bounded-plan-swap-closeout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for closing `SCM-06` by hardening the bounded
> Braintree plan-swap story across runtime, docs, host guidance, and
> merge-blocking support-contract verifiers.

## Coverage Audit

| Source | Item | Covered By |
|--------|------|------------|
| GOAL | Bounded Braintree plan-swap closeout and coherent public mirrors | Plans `119-01`, `119-02`, `119-03` |
| REQ | `SCM-06` coherent support matrix, lifecycle/First Hour/production-readiness docs, host guidance, and drift gates | Plans `119-02`, `119-03` |
| ROADMAP | Braintree swap documented and surfaced only within the `:plan_resolver` contract | Plans `119-01`, `119-02` |
| ROADMAP | Unsupported Braintree quantity/item semantics fail clearly in runtime, docs, and touched UI | Plans `119-01`, `119-02` |
| ROADMAP | Support-matrix verifiers, package-facing docs, and example-host guidance point back to one contract | Plans `119-02`, `119-03` |
| RESEARCH | runtime and touched UI already mostly encode the bounded story | Plan `119-01` |
| RESEARCH | docs and verifier bundle are the highest-leverage remaining gaps | Plans `119-02`, `119-03` |
| CONTEXT | support matrix remains SSOT and mirrors should stay thin | Plan `119-02` |
| CONTEXT | contributor co-update rules must block parity creep and setup-contract erosion | Plan `119-03` |

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit suites plus bash verifier bundle |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/processor/capabilities_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/processor/capabilities_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs && cd ../.. && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Estimated runtime** | under 5 minutes |

## Sampling Rate

- After every task commit: run that task's automated verification command.
- After Plan 01: rerun the bounded runtime and touched-UI proof bundle before
  broad docs edits.
- After Plan 02: rerun all four bash verifier scripts before touching their
  needles in Plan 03 to distinguish doc drift from verifier drift.
- After Plan 03: rerun the full support-contract bundle plus targeted ExUnit
  suites so runtime, docs, and drift gates close together.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Automated Command | Status |
|---------|------|------|-------------|-------------------|--------|
| 119-01-01 | 01 | 1 | `SCM-06` | `cd accrue && mix test test/accrue/billing/subscription_actions_test.exs test/accrue/processor/capabilities_test.exs` | ⬜ pending |
| 119-01-02 | 01 | 1 | `SCM-06` | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs && cd ../accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs && cd ../examples/accrue_host && mix test test/accrue_host_web/live/subscription_live_test.exs` | ⬜ pending |
| 119-02-01 | 02 | 2 | `SCM-06` | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh` | ⬜ pending |
| 119-02-02 | 02 | 2 | `SCM-06` | `bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | ⬜ pending |
| 119-03-01 | 03 | 3 | `SCM-06` | `rg -n "Support-contract mirror parity\|Support-contract bundle\|plan_resolver\|verify_processor_support_matrix\\.sh\|verify_package_docs\\.sh\|verify_verify01_readme_contract\\.sh\|verify_adoption_proof_matrix\\.sh" scripts/ci/README.md && bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | ⬜ pending |

## Wave 0 Requirements

- [x] `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/processor-support-matrix.md` exist.
- [x] `accrue/lib/accrue/billing.ex`, `subscription_actions.ex`, and
  `capabilities.ex` exist.
- [x] Admin, portal, and example-host wording proof files exist.
- [x] Support-contract verifier scripts exist under `scripts/ci/`.

## Manual-Only Verifications

No manual-only gate is required. `scripts/ci/README.md` is covered through a
bounded `rg` assertion in Plan 03 alongside the shell verifier bundle it
documents.

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] No watch-mode steps
- [x] Wave 0 covers every referenced proof lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
