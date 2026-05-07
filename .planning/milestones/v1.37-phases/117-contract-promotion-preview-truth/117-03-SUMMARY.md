---
phase: 117-contract-promotion-preview-truth
plan: 03
subsystem: drift-gates
tags: [admin, ci, verifier-bundle, drift-prevention]

# Dependency graph
requires:
  - plan: 117-02
    provides: canonical docs wording and thin-mirror contract text
provides:
  - Provider-honest admin copy for bounded Braintree swap/no-preview guidance
  - Updated support-contract verifier bundle for swap/preview drift
  - Contributor-map guidance for same-PR co-updates
affects: [phase-118, docs-contracts-shift-left, admin subscription UX]

# Tech tracking
tech-stack:
  added: []
  patterns: [shift-left-docs-contracts, provider-aware-admin-copy, same-pr-drift-gates]

key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/copy/subscription.ex
    - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
    - scripts/ci/README.md
    - scripts/ci/verify_processor_support_matrix.sh
    - scripts/ci/verify_package_docs.sh
    - scripts/ci/verify_verify01_readme_contract.sh
    - scripts/ci/verify_adoption_proof_matrix.sh

key-decisions:
  - "Keep Phase 117's admin touch narrow: remove contradictions and clarify Braintree limits instead of expanding the full Phase 118 UX."
  - "Make swap/preview wording merge-blocking through the existing docs-contracts-shift-left bundle."
  - "Document same-PR update rules for canonical docs, thin mirrors, and CI needles in one contributor map."

requirements-completed: [SCM-01, SCM-02]

# Metrics
duration: ~40m
completed: 2026-05-07
---

# Phase 117 Plan 03: Close drift gates and contradiction-prone admin seams

**Phase 117 now closes with guardrails, not just wording: admin copy no longer implies Braintree preview support, the shift-left scripts pin the new swap/preview contract, and `scripts/ci/README.md` tells contributors exactly which files must move together.**

## Accomplishments
- Updated admin subscription guidance so Braintree explicitly says preview is unavailable for this provider while keeping swap setup guidance tied to `:plan_resolver`.
- Extended the docs-contract verifier scripts to require the new swap/preview rows and to reject stale out-of-slice or pseudo-preview wording.
- Updated `scripts/ci/README.md` so the same-PR co-update rule explicitly covers the official active-subscription-change contract.
- Re-ran the full support-contract bundle plus the phase validation sweep to prove future drift is blocked automatically.

## Verification
- `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs --warnings-as-errors`
- `bash scripts/ci/verify_processor_support_matrix.sh`
- `bash scripts/ci/verify_package_docs.sh`
- `bash scripts/ci/verify_verify01_readme_contract.sh`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`

## Task Commits

No phase-local commits were created in this run because the workspace already contained overlapping user changes in the Phase 117 file set; the implementation was applied and verified inline instead.

## Self-Check: PASSED
