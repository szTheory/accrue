---
phase: 226-ci-baseline-proof-semantics
plan: "19"
subsystem: ci-provider-evidence
tags: [exunit, node, github-actions, stripe-test-mode, privacy]
requires:
  - phase: 226-18
    provides: frozen comparable-run evidence and preservation contracts
provides:
  - aggregate-only formatter evidence that ignores unselected ExUnit outcomes
  - real tagged-only provider manifest promotion to literal proved evidence
  - accurate required scheduled/manual provider-proof guidance
affects: [phase-226-validation, live-stripe-workflow, phase-227-critical-path]
tech_stack:
  added: []
  patterns: [explicit-event-classification, subprocess-proof-integration, atomic-redacted-manifest]
key_files:
  created: []
  modified:
    - accrue/test/support/live_proof_formatter.ex
    - accrue/test/accrue/live_proof_formatter_test.exs
    - guides/testing-live-stripe.md
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
decisions:
  - "Excluded ExUnit events are unselected outcomes and leave all aggregate provider-manifest counters unchanged."
  - "Formatter timestamps are truncated to milliseconds so real manifests satisfy production finalizer validation."
  - "Scheduled and manual live-Stripe selections use required policy, separate from Fake-backed push/PR merge proof."
metrics:
  duration: "~4 minutes"
  completed: "2026-08-12"
  tasks_completed: 2
  files_modified: 4
status: complete
---

# Phase 226 Plan 19: CI Baseline Proof Semantics Summary

Real tagged-only live-provider execution now emits a privacy-safe, manifest-backed `proved` result while documentation states the selected scheduled/manual lane's required policy.

## Completed Tasks

1. Added RED regressions for direct ExUnit excluded events and a genuine `mix test --only live_stripe` subprocess; the test finalizes its manifest through the production provider CLI.
2. Corrected the formatter to ignore exclusions and emit millisecond ISO timestamps accepted by the finalizer, then reconciled the maintainer guide and Phase 226 validation ledger.

## Verification

- `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors` — PASS (4 tests)
- `node scripts/ci/verify_provider_proof.mjs --fixtures` — PASS
- `node scripts/ci/verify_ci_baseline.mjs --fixtures` — PASS
- `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path` — PASS
- `bash scripts/ci/verify_ci_setup_diagnostics.sh` — PASS
- `bash scripts/ci/verify_phase225_required_lane_evidence.sh` — PASS
- Planned guide-policy assertion and `test -s .planning/phases/226-ci-baseline-proof-semantics/COVERAGE.md` — PASS

## Decisions Made

- Preserve aggregate-only privacy semantics: excluded event reasons and fixture names never enter the manifest.
- Require the production finalizer, not a raw green job status, to establish `proved` evidence.
- Keep selected live-provider policy distinct from push/PR Fake-backed merge proof.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Normalized runtime formatter timestamps to milliseconds
- **Found during:** Task 1
- **Issue:** Actual `DateTime.utc_now/0` values serialized with microseconds, which the production manifest validator correctly rejected.
- **Fix:** Truncate started and finished timestamps to milliseconds before ISO-8601 serialization.
- **Files modified:** `accrue/test/support/live_proof_formatter.ex`
- **Verification:** Real tagged-only subprocess manifest finalized as `proved`.
- **Commit:** `218283c7`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Restores the real formatter-to-finalizer seam without relaxing validation.

## Known Stubs

None.

## Self-Check: PASSED

- All four modified plan artifacts exist.
- Task commits `a8b88e57`, `218283c7`, and `64afe717` exist.
- No canonical baseline, workflow, coverage declaration, setup script, or required-lane evidence file was modified.
