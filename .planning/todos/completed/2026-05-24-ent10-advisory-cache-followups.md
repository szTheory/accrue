completed: 2026-05-31
---
created: 2026-05-24T00:00:00Z
title: ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)
area: webhooks
resolves_phase: 154
files:
  - accrue/lib/accrue/webhook/default_handler.ex:613-623
  - accrue/lib/accrue/billing/entitlement_summary.ex:82-88
  - accrue/lib/accrue/telemetry/metrics.ex:88
  - accrue/test/support/stripe_fixtures.ex:3
resolved_by:
  - .planning/phases/154-advisory-cache-core-correctness/154-01-SUMMARY.md
  - .planning/phases/155-stripefixtures-polish-telemetry-counters/155-01-SUMMARY.md
---

## Problem

Deferred findings from the Phase 127 code review (`127-REVIEW.md`). None block
ENT-10 (the optional Stripe-native advisory cache); they are robustness/fidelity
polish on freshly-shipped code.

- **WR-05** — `force_changeset/2` carries `optimistic_lock(:lock_version)`. Two
  Oban jobs processing summary events for the same customer concurrently both
  load the same `lock_version`; the second `Repo.update` raises
  `Ecto.StaleEntryError` (and concurrent inserts race the `unique_index(:customer_id)`).
  Self-healing via Oban retry (25 attempts), but noisy — crashes rather than
  serializing the expected concurrent-delivery case.
- **IN-01** — `write_entitlement_summary/8` omits `:processor`, so rows fall back
  to the schema default `"stripe"` even under the Fake processor. Harmless today
  (cache is Stripe-native, customer-keyed) but inaccurate for non-Stripe customers.
- **IN-02** — `livemode: get(obj, :livemode) == true` collapses absent→`false`
  even though the column is nullable; minor fidelity loss of the "unknown" state.
- **IN-03** — `stripe_fixtures.ex` moduledoc still says "Phase 3 tests" though it
  now also hosts the Phase 127 `entitlement_summary_event/2` fixture (cosmetic).
- **IN-04** — No default `summary_synced` counter in `Metrics.defaults/0` (only
  `entitlement_summary_truncated`). Intentional host-choice; document it.

## Solution

- WR-05: prefer a DB-level upsert (`Repo.insert(..., on_conflict:, conflict_target: :customer_id)`)
  so concurrent deliveries serialize at the unique index instead of crashing —
  confirm it still honours the stale-skip watermark — OR rescue
  `Ecto.StaleEntryError`/constraint errors and re-read+retry once in-transaction.
- IN-01: set `processor: processor_name()` in attrs (or document the column is
  always `"stripe"` for the advisory cache).
- IN-02: pass through the raw boolean-or-nil if the unknown/false distinction
  matters to operators; otherwise leave as-is.
- IN-03: generalize the moduledoc wording.
- IN-04: add `counter("accrue.entitlements.summary_synced.count", tags: [:result])`
  to the default recipe, or note the intentional omission in the metrics moduledoc.

## Resolution

Closed by v1.47:

- WR-05 / ADV-01..04: Phase 154 removed webhook-path optimistic locking, added the NULL-safe DB conflict guard, added stale `{:ok, :stale}` handling, and verified concurrent delivery with `Sandbox.allow/3`.
- IN-01 / POL-01: Phase 154 threads the webhook processor through `write_entitlement_summary/9`.
- IN-02 / POL-02: Phase 154 preserves prior `livemode` when a follow-up event omits the key.
- IN-03 / POL-03: Phase 155 generalized `StripeFixtures` docs and added first-class `:omit_livemode` support.
- IN-04 / POL-04: Phase 155 added the missing malformed/orphan entitlement-summary webhook counters to default telemetry metrics. The broader `summary_synced` default-counter choice remains intentionally outside this completed todo.
