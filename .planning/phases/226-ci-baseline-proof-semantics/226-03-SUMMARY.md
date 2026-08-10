---
phase: 226-ci-baseline-proof-semantics
plan: 03
subsystem: ci-baseline-contract
tags: [github-actions, ci, proof-semantics, ownership, bash]
requires: [226-01, 226-02]
provides:
  - "Command-first CI versus host setup ownership runbook"
  - "Fail-closed topology, proof, privacy, and Phase 227 selection contract"
  - "Shift-left CI invocation without proof-topology drift"
affects: [docs-contracts-shift-left, host-integration, playwright-e2e, phase-227]
tech-stack:
  added: []
  patterns:
    - "Extract YAML job bodies with the Phase 192 boundary parser and assert stable semantics."
    - "Use self-test mutations to prove ownership, privacy, and topology assertions fail closed."
key-files:
  created:
    - .planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-03-SUMMARY.md
  modified:
    - scripts/ci/README.md
    - scripts/ci/verify_ci_baseline_contract.sh
    - .github/workflows/ci.yml
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
key-decisions:
  - "Repository proof taxonomy is distinct from provider-enforced checks, which remain sourced only from the effective-rules and classic-protection snapshot."
  - "The baseline contract runs once in docs-contracts-shift-left; job topology is asserted rather than rewritten."
metrics:
  duration: "~25m"
  completed: 2026-08-10
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 226 Plan 03: CI Baseline Proof Semantics Summary

**A command-first host ownership runbook and a fail-closed CI baseline contract now protect proof semantics in the existing shift-left job.**

## Accomplishments

- Published CI-versus-host responsibility, diagnostics, expected signals, and safe next actions for Node/npm, Playwright/Chromium, PostgreSQL, fixtures, ports, Phoenix lifecycle, cleanup, and artifacts.
- Added concise baseline and setup triage to `scripts/ci/README.md`, pointing maintainers to existing owner scripts instead of a new bootstrap path.
- Extended the baseline verifier to lock the release critical chain, required/advisory matrix policy, Phase 192 artifact identities, ownership commands, metadata-only privacy fields, provider snapshot semantics, and Phase 227 measured-selection fields.
- Added exactly one contract invocation to the existing non-scheduled `docs-contracts-shift-left` job. The workflow diff contains no job, dependency, policy, event, or artifact change.
- Marked the Phase 226 validation Wave 0 complete and Nyquist compliant with the executed automated gates.

## Task Commits

1. **Task 1: Publish CI-versus-host setup ownership and command-first diagnostics** — `ee3df1ca` (`docs`)
2. **Task 2 RED: Enforce the baseline contract in the existing shift-left topology** — `8d7cfbda` (`test`)
3. **Task 2 GREEN: Gate baseline semantics without topology drift** — `dba3633b` (`ci`)

## Verification

- `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` — passed, including expected negative-control failures for unsafe metadata, query URLs, renamed job, missing ownership command, and missing privacy field.
- `bash scripts/ci/verify_phase192_ci_contract.sh` — passed.
- `git diff --check` — passed.
- Workflow diff from the Task 1 base confirms one added `CI baseline proof semantics contract` step under `docs-contracts-shift-left` only.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the ownership runbook and baseline contract script exist.
- Confirmed all three task/TDD commits exist in git history.
- Confirmed the final workflow diff adds only the planned shift-left step.
