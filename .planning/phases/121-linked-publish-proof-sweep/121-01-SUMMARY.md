---
phase: 121-linked-publish-proof-sweep
plan: 01
subsystem: release
tags: [release, proof, pr-scope, ledger]

# Dependency graph
requires:
  - phase: 120-release-contract-audit
    provides: locked three-package release contract and CI scope verifier
provides:
  - Deterministic PR-scope verifier for the linked release contract
  - Canonical Phase 121 ledger keyed to one PR number and one target version
  - Verified three-package Release Please PR ready for merge review
affects: [121-02, release PR review, publish proof workflow]

# Tech tracking
tech-stack:
  added: []
  patterns: [gh-api-release-proof, marker-driven-ledger, grep-jq-shell-verifier]

key-files:
  created:
    - .planning/phases/121-linked-publish-proof-sweep/121-01-SUMMARY.md
    - scripts/ci/verify_release_pr_scope.sh
    - scripts/ci/capture_linked_release_proof.sh
  modified:
    - scripts/ci/README.md
    - .planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md

key-decisions:
  - "Treat the stale pair-only Release Please PR as invalid and block merge until the three-package verifier passes."
  - "Record Phase 121 execution against explicit ledger markers (`PR_NUMBER`, `TARGET_VERSION`, `RUN_ID`) rather than 'latest' GitHub state."
  - "Use the least-destructive refresh path first, but accept that GitHub-side state may need a stale PR replacement before the contract passes."

requirements-completed: [REL-10]

# Metrics
duration: ~1h
completed: 2026-05-08
---

# Phase 121 Plan 01: Make the release PR and proof tooling trustworthy

**Plan 01 turned Phase 120's three-package decision into an executable pre-merge gate and bound the phase to one exact release PR: `#21` targeting `1.1.0`.**

## Accomplishments
- Added `scripts/ci/verify_release_pr_scope.sh` to prove a Release Please PR updates the manifest, all three package `mix.exs` files, and all three package changelogs, with optional exact-version assertions.
- Added `scripts/ci/capture_linked_release_proof.sh` to append deterministic workflow, tag, release, and Hex API evidence into the Phase 121 ledger.
- Expanded `scripts/ci/README.md` with REL-10 and REL-11 triage guidance for the new scripts and the marker-driven ledger flow.
- Repaired the live GitHub release-PR state from stale pair-only PRs (`#18`, then `#19`) to a passing three-package PR (`#21`) and recorded `PR_NUMBER: 21` plus `TARGET_VERSION: 1.1.0` in `121-VERIFICATION.md`.

## Verification
- `bash scripts/ci/verify_release_pr_scope.sh --help`
- `bash scripts/ci/capture_linked_release_proof.sh --help`
- `bash scripts/ci/verify_release_pr_scope.sh --pr 21 --version 1.1.0`

## Self-Check: PASSED

---
*Phase: 121-linked-publish-proof-sweep*
*Completed: 2026-05-08*
