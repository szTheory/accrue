---
phase: 17-milestone-closure-cleanup
plan: 01
subsystem: testing
tags: [planning, docs-contract, host-fixture, cleanup, trust-lanes]
requires:
  - phase: 13-canonical-demo-tutorial
    provides: canonical local demo verification path and host browser seed usage
  - phase: 14-adoption-front-door
    provides: release guidance and docs-contract structure for trust-lane wording
  - phase: 15-trust-hardening
    provides: host-integration trust lane and trust review invariants
  - phase: 16-expansion-discovery
    provides: final v1.2 planning records that should remain unchanged except for milestone closure bookkeeping
provides:
  - canonical-demo bookkeeping aligned between PROJECT and ROADMAP
  - fixture-owned host browser seed cleanup proven against unrelated shared DB history
  - release, provider-parity, and contributor docs locked to current trust lanes and browser UAT path
affects: [milestone closure, host integration, docs verification, release process]
tech-stack:
  added: []
  patterns:
    - narrow destructive test cleanup to fixture-owned identifiers before deleting shared ledger rows
    - pair prose changes in release docs with ExUnit and shell drift contracts
key-files:
  created:
    - .planning/phases/17-milestone-closure-cleanup/17-01-SUMMARY.md
    - examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs
  modified:
    - .planning/PROJECT.md
    - scripts/ci/accrue_host_seed_e2e.exs
    - RELEASING.md
    - guides/testing-live-stripe.md
    - CONTRIBUTING.md
    - accrue/test/accrue/docs/release_guidance_test.exs
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - scripts/ci/verify_package_docs.sh
key-decisions:
  - "The browser seed cleanup now keys destructive event deletion to fixture actor ids, webhook ids, and subscription ids instead of deleting by event type alone."
  - "The seed script exposes a reusable AccrueHostSeedE2E.run!/1 entrypoint so the regression test can execute the real cleanup path without diverging from mix run behavior."
  - "Release and contributor docs now name only the current workflow surfaces: release-gate, host-integration, live-stripe, and examples/accrue_host."
patterns-established:
  - "When docs define trust-lane semantics, keep a prose contract in ExUnit and fixed-string/forbidden-string checks in verify_package_docs.sh."
  - "Shared test databases require fixture identity in delete predicates before disabling immutable ledger triggers."
requirements-completed: [audit-tech-debt]
duration: 46min
completed: 2026-04-17
---

# Phase 17 Plan 01: Milestone Closure Cleanup Summary

**Canonical-demo bookkeeping is closed, host browser seed cleanup is fixture-scoped, and release/contributor docs now track the current trust lanes only**

## Performance

- **Duration:** 46 min
- **Started:** 2026-04-17T14:42:00Z
- **Completed:** 2026-04-17T15:27:51Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Marked the v1.2 canonical-demo checklist item complete in `.planning/PROJECT.md` so it matches the already-complete Phase 13 roadmap record.
- Reworked `scripts/ci/accrue_host_seed_e2e.exs` to delete only fixture-owned events, webhooks, subscriptions, and customers, then added a focused regression test that proves unrelated replay and payment-failed rows survive reruns.
- Removed stale release and contributor wording, then locked the updated `release-gate`, `host-integration`, and `examples/accrue_host` references with ExUnit and shell verifier coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Close the Phase 13 and canonical-demo bookkeeping drift** - `dcb5222` (`docs`)
2. **Task 2: Narrow browser seed cleanup to fixture-owned rows and add a preservation regression test** - `2d16854` (`test`), `80d019b` (`feat`)
3. **Task 3: Remove stale release and contributor references, then lock them with docs contracts** - `75139a1` (`docs`)

**Plan metadata:** pending

## Files Created/Modified

- `.planning/PROJECT.md` - Checks off the canonical-demo milestone outcome without changing other v1.2 notes.
- `scripts/ci/accrue_host_seed_e2e.exs` - Wraps the seed flow in `AccrueHostSeedE2E.run!/1` and scopes cleanup deletes to fixture ownership.
- `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` - Exercises the real seed rerun path and proves unrelated event history survives.
- `RELEASING.md` - Replaces the stale Phase 9 reference with current `release-gate` wording.
- `guides/testing-live-stripe.md` - References `release-gate` and `host-integration` instead of a non-existent primary test job.
- `CONTRIBUTING.md` - Points the browser UAT prerequisite to `examples/accrue_host`.
- `accrue/test/accrue/docs/release_guidance_test.exs` - Adds positive and negative assertions for the refreshed trust-lane wording.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Extends shell-verifier coverage for stale workflow and contributor wording drift.
- `scripts/ci/verify_package_docs.sh` - Enforces the new fixed strings and forbidden stale strings.

## Decisions Made

- Kept `.planning/ROADMAP.md` unchanged because it was already the canonical correct Phase 13 record; only the stale `PROJECT.md` checklist line needed to move.
- Used seeded fixture ids already present in the browser seed script as the cleanup boundary, which satisfies the threat-model mitigation without broadening the test database delete surface.
- Locked the stale doc phrases as negative assertions in ExUnit and forbidden regexes in the shell verifier so future wording drift fails fast.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated docs-verifier temp fixtures for the new contributor invariant**
- **Found during:** Task 3 (Remove stale release and contributor references, then lock them with docs contracts)
- **Issue:** The new `CONTRIBUTING.md` invariant caused existing temp-tree verifier tests to fail before they reached the intended drift assertion.
- **Fix:** Copied `CONTRIBUTING.md` into the temp fixtures and adjusted the stale-wording test to fail on the new `host-integration` invariant instead of an unrelated missing file.
- **Files modified:** `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- **Verification:** `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace`
- **Committed in:** `75139a1` (part of Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** The fix stayed inside the new docs-contract coverage and did not expand feature scope.

## Issues Encountered

- The plan acceptance text listed stale phrases across both docs and the contract files that intentionally mention them in negative assertions. Execution kept the phrases out of user-facing docs while preserving them in tests and verifier rules where they are required to detect regressions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- v1.2 planning, host-fixture cleanup, and trust-lane docs are aligned for milestone archival.
- The host UAT wrapper, focused regression test, docs contracts, and shell verifier all passed after the cleanup, so there is no remaining verification debt for this plan.

## Self-Check: PASSED

- Found `.planning/phases/17-milestone-closure-cleanup/17-01-SUMMARY.md`
- Verified task commit `dcb5222`
- Verified task commit `2d16854`
- Verified task commit `80d019b`
- Verified task commit `75139a1`
