# Phase 248 fixture lifecycle regression — 2026-10-11

The Phase 248 held-out browser setup seeded the existing `edge_states.exs` rows after the shared E2E setup cleaned its fixture footprint. Its returned teardown was the shared teardown, which only removed a PID file. The edge customer therefore persisted in the local `accrue_host_test` database after the browser run. The ordinary seed test observed `first.edge_customers == 1` at `test/ordinary_preview_seed_test.exs:78`; the required 13-test host command failed twice with that assertion.

The held-out teardown now removes only five deterministic edge fixture IDs: `cus_e2e_edge_1`, `sub_e2e_edge_at_risk`, `sub_e2e_edge_canceling`, `ch_e2e_edge_jpy`, and `in_e2e_edge_jpy`. Cleanup also runs if seeding fails after writing partial data. The cleanup script requires `PHASE248_PROOF_LANE=heldout`, port `4102`, SQL sandbox enabled, and a connected `accrue_host_test[digits]` database as `postgres` on loopback. It checks the fixture processor, customer email and owner type, parent links, and absence of unrelated customer children before deleting exact rows inside a transaction. A mismatch aborts without a broad reset.

Verification on the connected native test database:

- Identity before cleanup: `accrue_host_test`, `postgres`, `127.0.0.1`; one edge customer, two subscriptions, one charge, and one invoice were present.
- After the guarded cleanup, `MIX_ENV=test mix test test/ordinary_preview_story_contract_test.exs test/ordinary_preview_seed_test.exs test/seeds_idempotency_test.exs` passed: 13 tests, 0 failures.
- `node --test scripts/ci/phase248_heldout_isolation.test.mjs` passed 4/4, including teardown ordering and cleanup after a partially failed seed.
- A fresh edge seed, guarded cleanup, and repeated cleanup completed; read-only counts for all four affected tables were zero.
- Cleanup without the held-out lane was rejected before mutation. The new Elixir script passed `mix format --check-formatted`.

This is a fixture lifecycle correction after the ten current screenshots at source `112d484d`; no product UI or captured asset changed. The prior browser runs and visual inspections retain their recorded source attribution. The mounted held-out browser matrix was not rerun for this regression; the exact host failure, fixture cycle, and lifecycle contract were rerun.
