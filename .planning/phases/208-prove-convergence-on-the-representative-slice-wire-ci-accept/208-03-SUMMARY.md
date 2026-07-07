---
phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept
plan: 03
subsystem: ci
tags: [admin-ui-ratchet, github-actions, ci-contract, package-scripts, node]
requires:
  - phase: 208-plan-01
    provides: frozen ratchet ledger verifier and red-path self-tests
  - phase: 208-plan-02
    provides: UI ratchet sign-off verifier and ACCEPT contract
provides:
  - Dedicated Node-only `admin-ui-ratchet-guardrails` GitHub Actions job
  - Workflow contract checker for deterministic ratchet CI boundaries
  - Package aliases for frozen-ledger, sign-off, and CI-contract checks
affects: [phase-208, github-actions, admin-ui-ratchet, package-scripts]
tech-stack:
  added: []
  patterns:
    - Shell CI contract checker using extracted job-body validation
    - Node-only CI job that delegates to deterministic npm aliases
key-files:
  created:
    - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
  modified:
    - .github/workflows/ci.yml
    - accrue_admin/package.json
key-decisions:
  - "The admin-ui-ratchet-guardrails job is Node-only and excludes BEAM, Postgres, Playwright/browser setup, live ui.round/ui.fix commands, LLM commands, and --freeze."
  - "The workflow job depends on the existing Phase 192 and Phase 200 admin guardrail jobs so its PASS readback for existing UI gates is only emitted after those sibling gates succeed."
  - "Package aliases are deterministic wrappers only; the explicit local --freeze command remains outside all CI-oriented scripts."
patterns-established:
  - "Workflow contract checks sanitize the required no-key status copy while still rejecting any other ANTHROPIC_API_KEY reference in the ratchet job."
  - "Annotation-sweep membership is contract-checked across folded YAML command lines."
requirements-completed: [CONV-03, CONV-05, CONV-06]
duration: 55 min
completed: 2026-07-07
status: complete
---

# Phase 208 Plan 03: Deterministic Ratchet CI Summary

**Node-only admin UI ratchet CI job, contract checker, and package command aliases**

## Performance

- **Duration:** 55 min
- **Started:** 2026-07-07T21:27:00Z
- **Completed:** 2026-07-07T22:22:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` to validate the `admin-ui-ratchet-guardrails` workflow job, forbidden command/key usage, required status copy, artifact upload, and annotation-sweep wiring.
- Wired `.github/workflows/ci.yml` with a dedicated `admin-ui-ratchet-guardrails` job using checkout, Node 22, `npm ci`, ledger self-tests, read-only frozen verification, sign-off verification, the CI contract alias, status summary copy, and Phase 208 evidence upload.
- Added `admin-ui-ratchet-guardrails` to the stable job-id comments, merge-blocking comments, annotation-sweep `needs`, and annotation-sweep argument list.
- Added deterministic package aliases in `accrue_admin/package.json`: `ratchet:ledger:verify-frozen`, `ratchet:signoff:self-test`, `ratchet:signoff`, and `ratchet:ci-contract`.
- Preserved the pre-existing Phase 207 live-UAT `package.json` edits in the working tree without staging them into the Phase 208 package-script commit.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CI contract verifier** - `787386ea` (feat)
2. **Task 1 correction: Keep contract scoped to workflow wiring** - `b6baf83c` (fix)
3. **Task 2: Wire Node-only ratchet guardrail job** - `737c07f5` (feat)
4. **Task 3: Add deterministic package scripts** - `cb9a4d5d` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` - New workflow contract checker for the deterministic ratchet CI job.
- `.github/workflows/ci.yml` - Adds `admin-ui-ratchet-guardrails`, artifact upload, status summary, stable job comments, and annotation-sweep wiring.
- `accrue_admin/package.json` - Adds deterministic Phase 208 npm aliases.

## Decisions Made

- The workflow uses package aliases for the deterministic commands so local and CI command names stay aligned.
- The CI contract checks the workflow boundary only; Task 3 validates package-script contents separately so Task 2 can be verified before package aliases exist.
- The no-key copy containing `ANTHROPIC_API_KEY` is allowed only as the exact required status line; all other occurrences in the ratchet job are rejected.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first contract version checked package scripts too early for the plan order. It was narrowed to workflow-boundary validation, with package-script validation handled in Task 3.
- The real CI job includes `ratchet:ledger:verify-frozen` and `ratchet:signoff`; those commands are expected to fail until Plans 04 and 05 create the frozen baseline and final sign-off artifact.

## Verification

- `bash -n scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` - passed.
- `bash scripts/ci/verify_admin_ui_ratchet_ci_contract.sh` - passed.
- `cd accrue_admin && npm run ratchet:signoff:self-test` - passed.
- `cd accrue_admin && npm run ratchet:ci-contract` - passed.
- Focused `package.json` script-value check - passed.

## Self-Check: PASSED

- Contract rejects secrets, live ratchet commands, browser capture, broad Playwright usage, advisory failure semantics, and `--freeze` in the ratchet job.
- Package aliases resolve from `accrue_admin` and contain no live/mutating commands.

## User Setup Required

None.

## Next Phase Readiness

Plan 04 can now produce the actual convergence/freeze evidence that the new CI job and package aliases verify read-only.

---
*Phase: 208-prove-convergence-on-the-representative-slice-wire-ci-accept*
*Completed: 2026-07-07*
