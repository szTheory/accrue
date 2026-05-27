# Phase 137 Summary: Entitlement Cache Robustness & Fidelity

Resolved WR-05 (StaleEntryError) and implemented sync fidelity fixes (IN-01..IN-04) for the entitlement summary advisory cache.

## Deliverables

- **Race-safe Upsert (FIX-01 / WR-05):**
  - Refactored `upsert_entitlement_summary` in `DefaultHandler` to use a DB-level atomic upsert (`Repo.insert` with `on_conflict`).
  - Added an `on_conflict_where` clause that enforces the monotonic watermark (`last_stripe_event_ts`) in the database.
  - This prevents `Ecto.StaleEntryError` during concurrent webhook deliveries for the same customer.

- **Fidelity Fixes (FIX-02 / IN-01..03):**
  - Updated `write_entitlement_summary` to correctly store the `processor` name (IN-01).
  - Preserved `nil` state for the `livemode` field instead of collapsing to `false` (IN-02).
  - Generalized the moduledoc in `StripeFixtures` (IN-03).

- **Observability (IN-04):**
  - Added `accrue.entitlements.summary_synced.count` to the default telemetry metrics.

## Verification Results

### Automated Tests
- `mix test accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`: PASSED (10 tests)
- `mix test accrue/test/accrue/webhook/wr05_concurrency_test.exs`: PASSED (2 tests)
  - Proved that concurrent events succeed without crashing.
  - Proved that the latest event always wins.

### Metrics Verification
- `grep "summary_synced" accrue/lib/accrue/telemetry/metrics.ex`: Verified.

## Traceability
- **FIX-01**: WR-05 StaleEntryError resolved.
- **FIX-02**: Entitlement sync fidelity fixes applied.
