---
phase: 252-production-backed-subscription-stories
plan: "04"
subsystem: testing
tags: [ecto, postgres, subscription-facts, seed, cleanup]

requires:
  - phase: 252-02
    provides: Shared Cadence subscription facts and domain validation.
  - phase: 252-03
    provides: Guarded launcher for fresh numeric host test databases.
provides:
  - PostgreSQL-backed persistence proof for launch and growing-team subscription facts.
  - Opt-in ordinary host seed adapter with lane, database, role, and address checks.
  - Locked held-out cleanup with stable owner identity and unrelated-child preservation proof.
affects: [252-05, 252-07, 252-08]

actuals:
  tokens: 12719.25
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - Exact source facts replay through existing Repo changesets and reload with relationships.
    - Held-out cleanup locks the fixture customer before validating children and deleting in one transaction.
    - Host seed execution requires explicit ordinary-lane selection and a disposable test database.

key-files:
  created:
    - accrue_admin/test/support/subscription_scenario_repo.ex
    - accrue_admin/test/accrue_admin/dev/subscription_scenario_repo_test.exs
    - examples/accrue_host/priv/repo/seeds/phase252_subscription_scenarios.exs
    - examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs
    - .planning/phases/252-production-backed-subscription-stories/252-04-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-04-02-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-04-02-owner-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/deferred-items.md
  modified:
    - dev_support/ui_scenarios/cadence_subscriptions.exs
    - examples/accrue_host/priv/repo/seeds/edge_states.exs
    - examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs
    - scripts/ci/phase248_heldout_isolation.test.mjs

key-decisions:
  - "The host seed accepts only explicitly selected launch or growing-team facts in the ordinary lane after existing database-boundary checks."
  - "Held-out long-text facts use independent stable owner, customer, subscription, item, and processor identities."
  - "Held-out cleanup locks and verifies the exact synthetic customer owner before checking children or deleting rows."

patterns-established:
  - "Test-only persistence adapters compare matching rows and reject conflicting identities without overwriting source facts."
  - "A customer FOR UPDATE lock serializes cleanup with new foreign-key child inserts; the child-set check and deletion remain in the same transaction."

requirements-completed: [SCEN-03, SCEN-04, SCEN-01]

coverage:
  - id: D1
    description: "Launch and growing-team facts persist through the narrow Repo adapter and match their source identities, fields, and reloaded relationships under actual PostgreSQL constraints."
    requirement: SCEN-03
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_scenario_repo_test.exs#test persists launch and growing-team source facts and reloads their exact linked rows (4 tests, 0 failures; launcher partition 9252100416)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guarded host seeding consumes the shared ordinary facts, refuses held-out inputs and conflicts, and preserves an unrelated sentinel."
    requirement: SCEN-01
    verification:
      - kind: integration
        ref: "examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs#ordinary launch and team seeds persist shared facts, replay exactly, and exclude held-out input (launcher partition 9252100427)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Held-out cleanup preserves unrelated children and sentinels, refuses mismatched owner identity, is safe when repeated, and serializes a concurrent child insertion."
    requirement: SCEN-04
    verification:
      - kind: integration
        ref: "examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs#concurrent child insertion serializes before the cleanup child-set guard (launcher partition 9252100427)"
        status: pass
      - kind: unit
        ref: "scripts/ci/phase248_heldout_isolation.test.mjs (6 passed, including cleanup lock ordering and exact owner controls)"
        status: pass
    human_judgment: false

commits: 5
plan_head_before: 453be2bf0798869e4899244c9f60961e7d3665f9
plan_head_after: a266c1db7159878a22cf76f23bcc12f895099b49
duration: 25min
completed: 2026-10-26
status: complete
---

# Phase 252 Plan 04: Production-backed Subscription Stories Summary

**The launch and growing-team Cadence graphs now persist through real Postgres, with lane-separated host seeds and locked exact-owner cleanup.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-10-26T20:21:31-04:00
- **Completed:** 2026-10-26T20:46:04-04:00
- **Tasks:** 2
- **Files modified:** 11 implementation, test, and RED evidence files

## Accomplishments

- Persisted launch and growing-team source facts through existing customer, subscription, and item changesets; reloaded the graph and exercised real foreign-key, not-null, and unique constraints.
- Proved matching replay, conflicting-row refusal, rollback after an interrupted middle insert, and concurrent persistence without duplicate processor identities.
- Added an opt-in ordinary-lane host seed that uses only shared launch/team facts after lane and database identity checks. Held-out stress facts now have independent stable identities.
- Locked the exact held-out customer before scanning its children, verified its stable owner identity, and deleted only the five expected rows inside the same transaction. Integration tests cover refusal with unchanged rows, safe repeated cleanup, sentinel preservation, and a competing child insert.

## Task Commits

1. **252-04-01: Persist representative source facts and prove actual constraints** — `0b801e4c` (RED), `d29f316c` (GREEN).
2. **252-04-02: Guard the seed consumer and refuse unrelated-child deletion** — `3f768a2d` (RED), `2b20d8e3` (RED owner control), `a266c1db` (GREEN).

Measured plan commits: 5, from `453be2bf0798869e4899244c9f60961e7d3665f9` through `a266c1db7159878a22cf76f23bcc12f895099b49`.

## Files Created/Modified

- `accrue_admin/test/support/subscription_scenario_repo.ex` and `accrue_admin/test/accrue_admin/dev/subscription_scenario_repo_test.exs` — narrow real-Repo persistence adapter and migrated Postgres conformance tests.
- `examples/accrue_host/priv/repo/seeds/phase252_subscription_scenarios.exs` — explicit ordinary-lane shared-facts seed consumer.
- `examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs` — database-backed seed, cleanup, ownership, replay, and concurrency checks.
- `examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs` — parent row lock, child-set validation, and stable-owner guard.
- `examples/accrue_host/priv/repo/seeds/edge_states.exs` — deterministic synthetic owner identity for the held-out fixture.
- `dev_support/ui_scenarios/cadence_subscriptions.exs` — independent held-out identities.
- `scripts/ci/phase248_heldout_isolation.test.mjs` — retained lane guards and cleanup-order/owner controls.
- Three machine-checked RED evidence records — Repo adapter availability, cleanup locking, and exact owner identity.

## TDD Gate Compliance

- Task 1 RED evidence in `252-04-01-red-evidence.json` returned `RED_EVIDENCE_OK`; the persistence target reached its explicit missing-adapter assertion before implementation. Its GREEN run passed four real PostgreSQL tests.
- Task 2 cleanup-order RED evidence in `252-04-02-red-evidence.json` returned `RED_EVIDENCE_OK`; the target failed because cleanup did not lock the customer before the child-set guard.
- The exact-owner RED in `252-04-02-owner-red-evidence.json` returned `RED_EVIDENCE_OK`; a guarded host integration run also demonstrated that cleanup accepted and deleted a customer after its owner ID changed. The stable-owner guard and database-backed mismatch test fixed that behavior.
- Final GREEN verification passed the four host integration tests and all six Node held-out guard tests. No refactor-only change was needed.

## Decisions Made

- The host seed remains opt-in and accepts only fixed launch and growing-team scenario names. It checks the ordinary lane and the existing disposable database boundary before loading facts or writing rows.
- Held-out facts receive their own stable identity set, and the existing held-out fixture now has a stable synthetic owner so cleanup can prove exact ownership.
- The cleanup lock is acquired before child reads; PostgreSQL foreign-key checks serialize a concurrent child insert against that lock, and cleanup refuses after the insertion commits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected test adapter behavior exposed by real Postgres**
- **Found during:** Task 1
- **Issue:** Source validation and database comparisons exposed incorrect handling of fact maps, billing schema prefixes, timestamp precision, UUID SQL values, and concurrent task errors.
- **Fix:** Kept validated source maps intact, used the migrated billing schema and dumped UUIDs for direct SQL controls, compared timestamps by instant, and propagated competing task failures to the test process.
- **Files modified:** `accrue_admin/test/support/subscription_scenario_repo.ex`, `accrue_admin/test/accrue_admin/dev/subscription_scenario_repo_test.exs`.
- **Verification:** Four real Repo integration tests passed, including constraint failures, rollback, and concurrent inserts.
- **Committed in:** `d29f316c`.

**2. [Rule 2 - Missing Critical] Separated held-out facts from ordinary identities**
- **Found during:** Task 2
- **Issue:** `held_out!(:long_text)` reused launch owner, customer, subscription, and item IDs, violating the plan's lane separation requirement.
- **Fix:** Assigned the held-out case its own stable synthetic identities and asserted the ordinary and held-out identity sets are disjoint.
- **Files modified:** `dev_support/ui_scenarios/cadence_subscriptions.exs`, `examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs`.
- **Verification:** The guarded host integration test confirms disjoint IDs and rejects held-out scenario/lane input in the ordinary seed.
- **Committed in:** `a266c1db`.

**3. [Rule 2 - Missing Critical] Bound held-out cleanup to the exact fixture owner**
- **Found during:** Task 2
- **Issue:** The fixture generated a random owner ID and cleanup checked only email and owner type, allowing a reassigned same-ID customer to be deleted.
- **Fix:** Made the synthetic fixture owner ID stable and require that exact ID before child validation or deletion.
- **Files modified:** `examples/accrue_host/priv/repo/seeds/edge_states.exs`, `examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs`, `examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs`, `scripts/ci/phase248_heldout_isolation.test.mjs`.
- **Verification:** The real host test changes the owner ID and proves cleanup refuses without changing rows; the Node ordering/owner controls pass.
- **Committed in:** `2b20d8e3` (RED test), `a266c1db` (GREEN).

**4. [Rule 3 - Blocking] Ran Mix from each subproject under the guarded launcher**
- **Found during:** Tasks 1 and 2
- **Issue:** The launcher runs its child command from repository root while the Mix projects live under `accrue_admin` and `examples/accrue_host`.
- **Fix:** Wrapped each Mix invocation with an explicit `cd` to its package directory and supplied a fresh numeric partition.
- **Verification:** The final admin and host integration commands passed on launcher-owned partitions.

**Total deviations:** 4 auto-fixed (1 Rule 1, 2 Rule 2, 1 Rule 3). No schema, package, or production API changes were introduced.

## Issues Encountered

- The first launcher attempt was denied at its local `ps` process-identity check (`EPERM`) before starting a test. A scoped retry ran the same guarded command successfully; no database was reset or reused.
- The host test runtime printed the existing ExMoney exchange-rate auto-start deprecation warning. It is recorded in `deferred-items.md` and is outside this plan's scope.

## Known Stubs

None.

## User Setup Required

None. Existing local PostgreSQL, Mix, and Node installations were used; no packages were installed.

## Next Phase Readiness

Plan 252-05 can use the persisted shared facts and the guarded host-heldout cleanup contract. Phase 252 remains in progress; this plan does not mark the phase complete.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- All five measured task commits are ancestors of `plan_head_after`.
- The persisted plan ledger reports 5 commits from `453be2bf0798869e4899244c9f60961e7d3665f9` through `a266c1db7159878a22cf76f23bcc12f895099b49`.
