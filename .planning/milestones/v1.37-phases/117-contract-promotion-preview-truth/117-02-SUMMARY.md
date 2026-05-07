---
phase: 117-contract-promotion-preview-truth
plan: 02
subsystem: docs-contract
tags: [docs, support-matrix, package-docs, host-docs]

# Dependency graph
requires:
  - plan: 117-01
    provides: promoted runtime contract and capability wording
provides:
  - Canonical docs spine for swap/preview semantics
  - Thin package and host mirrors aligned to the same contract
  - Updated support matrix rows for swap and preview
affects: [phase-117-03, docs-contracts-shift-left, host proof docs]

# Tech tracking
tech-stack:
  added: []
  patterns: [canonical-docs-spine, thin-mirror-docs, provider-honest-wording]

key-files:
  created: []
  modified:
    - .planning/processor-support-matrix.md
    - accrue/guides/lifecycle_semantics.md
    - accrue/README.md
    - accrue/guides/first_hour.md
    - examples/accrue_host/README.md
    - examples/accrue_host/docs/adoption-proof-matrix.md

key-decisions:
  - "Make `lifecycle_semantics.md` + `processor-support-matrix.md` the explicit two-part canonical spine for subscription changes."
  - "Describe preview as the canonical path where supported before commit, not as an implied cross-provider guarantee."
  - "Keep package and host docs thin: they repeat the contract and point back to the canonical sources."

requirements-completed: [SCM-01, SCM-02]

# Metrics
duration: ~50m
completed: 2026-05-07
---

# Phase 117 Plan 02: Align the canonical docs spine and mirrors

**The docs spine now matches the code truth: the support matrix includes dedicated swap/preview rows, lifecycle semantics defines preview-before-commit explicitly, and package/host mirrors repeat the same bounded Braintree story without becoming competing SSOTs.**

## Accomplishments
- Added dedicated `subscription.swap_plan` and `invoice.preview_upcoming_invoice` rows to `.planning/processor-support-matrix.md`.
- Reframed `accrue/guides/lifecycle_semantics.md` around the official active-subscription-change contract and added explicit preview semantics.
- Updated `accrue/README.md`, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md` to mirror the same swap/preview contract with provider-honest wording.
- Removed stale preview-parity phrasing so Braintree is described as bounded swap support plus explicit no-preview support.

## Verification
- `cd accrue && mix test test/accrue/docs/processor_support_matrix_test.exs test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors`
- `bash scripts/ci/verify_processor_support_matrix.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`

## Task Commits

No phase-local commits were created in this run because the workspace already contained overlapping user changes in the Phase 117 file set; the implementation was applied and verified inline instead.

## Self-Check: PASSED
