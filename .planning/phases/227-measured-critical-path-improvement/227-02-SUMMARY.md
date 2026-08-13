---
phase: 227
plan: "02"
subsystem: ci-evidence
tags: [github-actions, critical-path, blocked]
dependency_graph:
  requires: [227-01, phase-226-baseline]
  provides: [immutable-negative-control, failed-cohort-ledger]
  affects: [host-integration, playwright-e2e, annotation-sweep]
tech_stack:
  added: []
  patterns: [repository-bound-actions-evidence, fail-closed-cohort-admission]
key_files:
  created:
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md
    - .planning/phases/227-measured-critical-path-improvement/227-02-SUMMARY.md
  modified:
    - .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson
    - .github/workflows/ci.yml
    - scripts/ci/verify_ci_critical_path.mjs
decisions:
  - Preserve all failed candidate runs and require a new plan before any compatible event-class proof.
metrics:
  completed_date: 2026-08-13
  tasks_completed: 1
  tasks_total: 2
status: blocked
---

# Phase 227 Plan 02: Live Critical-Path Evidence Summary

The repository-bound live evidence attempt is blocked: the retained temporary-branch negative control is admissible, but no successful first-attempt `workflow_dispatch` candidate observations exist for the required three-run comparison.

## Outcome

- The temporary control [run 31660617339](https://github.com/szTheory/accrue/actions/runs/31660617339) recorded the intended test annotation while host integration and all Playwright shards succeeded. Its temporary branch and remote ref were removed after collection.
- All nine candidate observations across the three bounded cohorts are retained as exclusions in [227-CI-CRITICAL-PATH.ndjson](227-CI-CRITICAL-PATH.ndjson). The final permitted cohort is [31664055724](https://github.com/szTheory/accrue/actions/runs/31664055724), [31664057331](https://github.com/szTheory/accrue/actions/runs/31664057331), and [31664058949](https://github.com/szTheory/accrue/actions/runs/31664058949).
- The final cohort selected the required `live-stripe` provider lane, which failed; one run also had a host-integration failure. No further candidate runs were launched.
- D-04 requires three successful first-attempt, same-event-class candidate runs. That requirement is unmet, so the before/after comparison and keep decision cannot be made.

## Decision

`rollback_required` is recorded as a pending maintainer decision. Replan after choosing a compatible event class that does not require unavailable provider proof; do not treat this report as a comparison or a keep decision.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 2 - Missing live verifier]** Added fail-closed live Actions evidence collection and deterministic rendering support in `scripts/ci/verify_ci_critical_path.mjs`.
2. **[Rule 3 - Dispatch blocker]** Replaced invalid job-level `runner.temp` expressions with runtime `$RUNNER_TEMP` exports so the CI workflow could dispatch.
3. **[Rule 2 - Required finalizer]** Made `annotation-sweep` run with `always()` so a control annotation is collected even when its source job fails.
4. **[Rule 1 - Pre-existing formatting failure]** Formatted the Phase 226 live-proof fixture files that prevented candidate workflow success.
5. **[Rule 1 - Stale contract test]** Aligned the Phase 226 provider-guidance test with the existing advisory matrix policy before launching the final permitted cohort.

## Verification

- Passed: `node scripts/ci/verify_ci_critical_path.mjs --fixtures`
- Passed: `node scripts/ci/verify_provider_proof.mjs --fixtures`
- Passed: `bash scripts/ci/verify_ci_setup_diagnostics.sh`
- Passed: `cd accrue && mix format --check-formatted test/accrue/docs/release_guidance_test.exs && mix test test/accrue/docs/release_guidance_test.exs`
- Passed: `bash scripts/ci/verify_package_docs.sh`
- Not passed / intentionally not claimed: the plan's live three-success comparison verification. The retained final cohort has zero successful qualifying runs.

## Deferred Issues

- **Blocking evidence gap:** `workflow_dispatch` selects the required `live-stripe` provider lane, which makes each final candidate conclude `failure`; one final candidate also failed host integration. A different event-class design requires replanning and maintainer approval.

## Self-Check: PASSED

- Evidence ledger and readable report exist.
- Retained evidence commits are present, including `9f3fcff6` for the final cohort report.
