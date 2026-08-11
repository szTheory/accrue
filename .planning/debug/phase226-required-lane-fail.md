---
status: awaiting_human_verify
trigger: "Phase 226 Plan 11 cannot publish its fixed main cohort because all three first-attempt workflow_dispatch candidates failed the required release-gate matrix at the same main SHA. Diagnose and fix the shared failure without reruns, replacements, topology reduction, required-check demotion, or canonical evidence changes."
created: 2026-08-11T13:43:49Z
updated: 2026-08-11T13:43:49Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

bug_class: bohrbug (provisional — identical failures at one pinned SHA)
reasoning_checkpoint:
  hypothesis: "The failed cohort’s test failures were caused by a test oracle that counted every Oban.Job row, rather than only the job owned by the webhook under test; unrelated suite jobs make the global count eight, so the test falsely reports a release-gate failure."
  confirming_evidence:
    - "All three CI logs show the same webhook tests failing with a global Oban count of 8 where their assertion expected 1."
    - "The failed SHA contains global counts, while descendant commit 8706e743 replaces them with persisted-event identity queries after a RED regression commit deliberately adds an unrelated event."
    - "The current scoped regression test passes locally: 5 tests, 0 failures."
  falsification_test: "If the scoped tests still fail when unrelated jobs are present, or if the failed SHA already scopes its Oban query to the webhook ID, this hypothesis is false."
  fix_rationale: "Filtering by the persisted webhook event ID asserts the actual ownership contract and remains valid when other legitimate jobs coexist in the test database."
  blind_spots: "None for the webhook test cause; the historical dialyzer failures are now confirmed as an independent second failure class."
  candidate_causes:
    - "code: global Oban.Job assertions in webhook integration tests"
    - "config: test suite runs against a shared repository process, allowing unrelated valid rows to coexist"
    - "environment: CI random ordering decides whether those unrelated jobs are already present"
  and_gate: "no for the webhook test failure — the global query alone makes the assertion invalid whenever legitimate unrelated rows exist; shared test state explains its manifestation but is not a second defect."
hypothesis: confirmed: the historical cohort contains two independently resolved release-gate defects — a global webhook-job test oracle and 43 unbaselined known Dialyzer diagnostics. Both fixes are descendants of the failed SHA and pass their local acceptance checks.
test: await maintainer confirmation that the current-main repair is acceptable for the next eligible, first-attempt CI cohort; do not alter, rerun, or replace the three failed historical candidates.
expecting: maintainer confirms the diagnosis and accepts the existing targeted repairs for new-cohort proof under the governing plan.
next_action: request human verification of the current-main repair in the intended CI workflow

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Three fixed, first-attempt workflow_dispatch runs on main at SHA 702dc482df0f65c332be1d4dfb821c4fe60aec49 complete successfully, allowing Plan 226-11 to publish one exactly-three bound cohort.
actual: Runs 31455283075, 31455284172, and 31455285305 all completed with failure; every required release-gate variant failed, so none is eligible for release proof and D-01 blocks publication.
errors: Exact failing job traces have not yet been classified; GitHub reports completed/failure for all three runs.
reproduction: Inspect the three fixed run IDs in szTheory/accrue, or dispatch the checked-in CI workflow on main under the same conditions. The fixed runs must not be rerun or replaced during diagnosis.
started: Observed on 2026-08-11 during Phase 226 Plan 11 Task 2 after Task 1 committed as 9cd5dafc. Phase 225 had previously repaired required-lane signal, so this is a new or newly exposed shared failure.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: The scoped webhook-test repair alone makes every required release-gate variant eligible.
  evidence: Two historical cells reached `Accrue dialyzer` and failed with `Total errors: 43` after their test step passed; Dialyzer is a sequential independent release-gate step.
  timestamp: 2026-08-11T13:52:00Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-11T13:45:00Z
  checked: GitHub failed logs for run 31455285305
  found: The `Admin UI ratchet guardrails` job fails in `cd accrue_admin && npm run ratchet:ledger:verify-frozen`; `verify_ratchet_ledger.mjs` reports a nonempty finding-regressions.ndjson, baseline frozen=false, no two current-epoch foundation dry rounds, nonzero folded findings, and component-kitchen rows below the score floor.
  implication: The failure is deterministic repository fixture/contract state, not an opaque runner failure; compact comparison is needed to prove it is the shared root across all three candidates and to trace whether release-gate depends on it.

- timestamp: 2026-08-11T13:46:00Z
  checked: GitHub Actions job/step summaries for runs 31455283075, 31455284172, and 31455285305
  found: Each run has all four release-gate matrix cells failing. Across cells, the terminal step is either `Accrue test` or `Accrue dialyzer`; the exact cell/step varies between runs. Separately, every run has the parked `Admin UI ratchet guardrails` verifier failure. The workflow graph lists the ratchet job only as an annotation-sweep dependency and explicitly excludes its parked annotations, so it does not explain the required release-gate failures.
  implication: The shared root-cause search must follow the release-gate logs; the ratchet state is an independent known failure, not the reason the required proof lanes are ineligible.

- timestamp: 2026-08-11T13:47:00Z
  checked: Failed log for release-gate job 93667672069 (run 31455283075, advisory sigra cell)
  found: `Accrue.Webhook.IngestTest` fails three assertions in `test/accrue/webhook/ingest_test.exs` (lines 38, 63, and 100): both `length(jobs)` and `Accrue.TestRepo.aggregate(Oban.Job, :count)` are 8 where the tests require 1. The failed cases are the normal POST, duplicate POST, and rollback paths.
  implication: The visible failures share the same deterministic excess-Oban-job symptom; the test's assertion is not an incidental SQL error. The likely defect is test database/job-worker isolation or unwanted Oban job insertion.

- timestamp: 2026-08-11T13:49:00Z
  checked: Pinned SHA 702dc482df0f65c332be1d4dfb821c4fe60aec49 against current main history and `Accrue.Webhook.IngestTest`
  found: The pinned test asserted whole-table `Oban.Job` cardinality. Current main includes `1c46755f test(225-01): expose webhook global-observation failure` followed by `8706e743 fix(225-01): scope webhook assertions to event identity`; its diff replaces only the global counts with queries keyed by the persisted webhook event ID. The current assertions are therefore immune to unrelated jobs in the shared test database.
  implication: The release-test root cause is a false global-observation test oracle, not extra jobs inserted by the webhook under test. The existing minimal code fix is already present on main; the remaining investigation must confirm whether the dialyzer reports an independent cause.

- timestamp: 2026-08-11T13:50:00Z
  checked: Fixed run metadata and release-gate workflow definition
  found: All three candidates are first-attempt `workflow_dispatch` runs on `main` at exactly 702dc482df0f65c332be1d4dfb821c4fe60aec49. `Accrue test` and `Accrue dialyzer` are sequential independent workflow steps; a test failure stops that cell before dialyzer, which explains why the terminal failing step varies by cell. The ratchet failure remains non-blocking by explicit annotation-sweep exclusion.
  implication: The matrix-wide symptom is consistent with the bad test oracle and the test repair must be verified on a SHA after the repair commit; the historical cohort cannot be altered or reused.

- timestamp: 2026-08-11T13:51:00Z
  checked: Current-main focused regression execution with CI-equivalent PostgreSQL environment
  found: `PGUSER=postgres PGPASSWORD=postgres PGHOST=localhost MIX_ENV=test mix test test/accrue/webhook/ingest_test.exs --warnings-as-errors` completed with `5 tests, 0 failures`. The repair commit is a descendant of the failed SHA, not included in it.
  implication: The proposed narrow fix is executable and passes the direct regression path; full-suite and dialyzer-step checks remain before accepting the incident as fixed.

- timestamp: 2026-08-11T13:52:00Z
  checked: Dedicated `Accrue dialyzer` step output from all four affected historical jobs
  found: The Dialyzer step reaches `Total errors: 43, Skipped: 2, Unnecessary Skips: 14` and exits status 2 in each cell. Its warnings include invalid specs, unreachable patterns, local functions with no return, unknown Entitlements types, and type mismatches; this is not test/database cleanup output.
  implication: The failed cohort has an OR-branching root-cause set: the global webhook-test oracle blocks cells that fail tests, while unaddressed Dialyzer diagnostics independently block cells that complete tests.

- timestamp: 2026-08-11T13:53:00Z
  checked: Current `.dialyzer_ignore.exs` and post-failure history
  found: Commit 4a87de8 (`fix(ci): baseline known Dialyzer warnings`) is after the failed SHA and adds 26 narrow ignore entries matching the historical warnings by file and warning kind, including the invalid config spec, entitlements unknown types/patterns/calls, and test-support vector checks. It does not suppress whole directories.
  implication: The Dialyzer failure is a second known-baseline gap at the historical SHA, not a runner/cache anomaly. It already has a committed targeted remediation on main.

- timestamp: 2026-08-11T13:54:00Z
  checked: Current-main Dialyzer under CI-equivalent test environment variables
  found: `PGUSER=postgres PGPASSWORD=postgres PGHOST=localhost MIX_ENV=test mix dialyzer --format github` completed successfully with `Total errors: 43, Skipped: 43, Unnecessary Skips: 14` and `done (passed successfully)`. The 43 historical findings are now all matched by narrow baseline entries.
  implication: Both independent historical failures have a targeted descendant repair validated locally. Remote cohort eligibility still needs human/plan-authorized CI verification on the repaired SHA; the historical failures remain immutable evidence.
## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: The failed SHA used a global `Oban.Job` count as a webhook-ingestion test oracle; other valid suite jobs made it observe eight rows and falsely fail despite the requested webhook having exactly one owned dispatch job. Separately, the failed SHA lacked narrow baseline entries for 43 known Dialyzer diagnostics, so cells that passed tests failed static analysis.
fix: Existing commit 8706e743 scopes webhook, dispatch-job, and ledger assertions to the persisted webhook event identity after commit 1c46755f demonstrated the former global-observation failure. Existing commit 4a87de8 adds narrow file-and-warning-kind ignore entries for the known Dialyzer baseline.
verification: Focused current-main webhook regression test passes (5 tests, 0 failures) with an explicit unrelated webhook present. Current-main Dialyzer passes with all 43 historical findings narrowly skipped. Full-suite terminal output was not captured and is not claimed.
files_changed: [accrue/test/accrue/webhook/ingest_test.exs, accrue/.dialyzer_ignore.exs]
