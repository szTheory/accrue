---
status: verifying
trigger: "Phase 248 heldout fixture leaves cus_e2e_edge_1 in accrue_host_test; ordinary_preview_seed_test.exs:78 sees edge_customers = 1"
created: 2026-10-11
updated: 2026-10-11
---

## Current Focus

reasoning_checkpoint:
  hypothesis: "The heldout setup inserts the edge fixture after shared cleanup and returns a teardown that does not remove it, so later ordinary seed tests read a persisted customer."
  confirming_evidence:
    - "phase248-heldout-setup.js seeds edge_states.exs after baseSetup and returns base teardown unchanged."
    - "Read-only query of accrue_host_test/postgres/127.0.0.1 found all five exact edge fixture rows."
    - "ordinary_preview_seed_test.exs:78 observed edge_customers = 1 twice."
  falsification_test: "An exact scoped teardown removes the edge rows, yet the ordinary seed test still observes edge_customers = 1."
  fix_rationale: "Run a guarded exact-ID edge fixture cleanup when the heldout lifecycle ends, including setup failure."
  blind_spots: "No live heldout browser rerun is planned; validate teardown contract and host tests."
  candidate_causes:
    - "code: heldout teardown does not reverse its seed"
    - "data: a pre-existing independent edge row could also be present"
  and_gate: "No; exact fixture IDs and the setup order explain the failure, while existing data is the persisted consequence."
next_action: "Hand verified fixture lifecycle fix to the Phase 248 integrator for documentation and commit."

## Symptoms

expected: "13 host tests pass after the heldout scenario run."
actual: "ordinary_preview_seed_test.exs:78 sees first.edge_customers = 1, and the 13-test run has one failure twice."
errors: "Assertion with == failed: left 1, right 0"
reproduction: "MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs"
started: "After Phase 248 heldout global setup seeded edge_states.exs."

## Eliminated

- hypothesis: "A different database or remote server caused the count."
  evidence: "Read-only identity query returned accrue_host_test/postgres/127.0.0.1."
  timestamp: 2026-10-11

## Evidence

- timestamp: 2026-10-11
  checked: "Heldout setup and shared setup source"
  found: "Heldout setup adds edge fixture after shared cleanup; shared teardown only unlinks PID file."
  implication: "Seeded rows persist after browser run."
- timestamp: 2026-10-11
  checked: "Test database identity and exact fixture IDs"
  found: "accrue_host_test/postgres/127.0.0.1 contains one edge customer, two edge subscriptions, one edge charge, and one edge invoice."
  implication: "Failure is directly reproducible and exact cleanup can be scoped."
- timestamp: 2026-10-11
  checked: "Guarded cleanup and host regression"
  found: "The exact 13 host tests passed with zero failures after cleanup; a fresh edge seed followed by cleanup and repeated cleanup left all edge counts at zero."
  implication: "The original failure is gone, and cleanup handles repeated teardown."
- timestamp: 2026-10-11
  checked: "Negative lane guard and lifecycle contract"
  found: "Cleanup without heldout lane failed before writes; four Node lifecycle tests passed, including partial-seed failure cleanup."
  implication: "The cleanup remains restricted to the intended browser fixture lifecycle."

## Resolution

root_cause: "Heldout setup seeds edge_states.exs but returns the shared teardown without cleaning its own five edge rows."
fix: "Heldout teardown now runs an exact-ID guarded cleanup before shared teardown."
verification:
  target_test: {result: pass, details: "13 host tests, zero failures"}
  mutation_check: {result: skipped, reason_if_skipped: "No Stryker configuration for this Elixir and Node fixture path"}
  no_op_deletion: {result: pass, details: "Adds scoped cleanup; no production behavior or assertions removed"}
  adjacent_tests: {result: pass, suites_run: ["phase248_heldout_isolation.test.mjs 4/4", "host ordinary preview and seed 13/13", "edge seed-cleanup-repeat cycle"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, details: "Pre-fix original 13-test run failed twice on edge count 1; post-fix run passed 13/13, and lifecycle regression asserts cleanup invocation."}
  guardrail_verdict: accepted
files_changed: [examples/accrue_host/e2e/phase248-heldout-setup.js, examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs, scripts/ci/phase248_heldout_isolation.test.mjs]
