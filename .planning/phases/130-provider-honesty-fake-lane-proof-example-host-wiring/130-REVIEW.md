---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - accrue/guides/dunning.md
  - accrue/lib/accrue/processor/braintree.ex
  - accrue/lib/accrue/processor/capabilities.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/test/accrue/dunning/dunning_full_journey_test.exs
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/config/test.exs
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
  - examples/accrue_host/test/accrue_host/dunning_wiring_test.exs
  - scripts/ci/verify_adoption_proof_matrix.sh
  - scripts/ci/verify_processor_support_matrix.sh
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 130: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

This phase delivers provider-honest capability declarations, the Fake-lane full-journey dunning
proof, example-host wiring for the `accrue_dunning` Oban queue, and two CI gate scripts. The
documentation and test files are largely well-structured and the capability convergence/divergence
model (local-identical vs. per-provider) is correctly expressed in `capabilities.ex`.

One blocker was found: a double telemetry emission on the exhaustion path that will cause
double-counting in every production telemetry reporter. Four warnings cover misleading capability
declarations, a floating-point amount conversion inconsistency, a loose drain assertion in the host
wiring test, and a redundant assertion that reads as stronger than it is. Three info items flag
dead telemetry code, an unused/misleading `smart_retry_alignment: true` flag on Fake, and a
migration comment that references the wrong parent migration file.

## Critical Issues

### CR-01: Double telemetry emission on dunning exhaustion path causes metric double-counting

**File:** `accrue/lib/accrue/webhook/default_handler.ex:770-797`

**Issue:** `maybe_emit_dunning_exhaustion/2` fires two separate telemetry events for every single
subscription exhaustion:

1. `[:accrue, :ops, :dunning_exhaustion]` via a raw `:telemetry.execute/3` call (line ~771).
2. `[:accrue, :ops, :dunning_exhausted]` via `Accrue.Telemetry.Ops.emit(:dunning_exhausted, ...)`
   (line ~796).

These are two **different event names** for the same logical occurrence. `telemetry/metrics.ex`
registers counters for both:

```elixir
counter("accrue.ops.dunning_exhaustion.count", tags: [:source])  # old, line ~72
counter("accrue.ops.dunning_exhausted.count", tags: [:source])   # DUN-08 canonical, line ~97
```

Any `TelemetryMetrics` reporter attached to the default metrics will increment BOTH counters on
every exhaustion transition. SRE dashboards, alerts, and the `recovered_vs_lost/1` counter
commentary all assume a single `dunning.exhausted` event per exhaustion. The double fire means
the `dunning_exhaustion` metric is orphaned noise AND the `dunning_exhausted` metric is correct —
but together they produce double the signal, making any rate-based alert fire at twice the actual
rate if both metrics are subscribed.

The `[:accrue, :ops, :dunning_exhaustion]` call appears to be a leftover from a pre-DUN-08
implementation. `Accrue.Telemetry.Ops` docs list `[:accrue, :ops, :dunning_exhaustion]` as the
canonical name but the DUN-08 implementation renamed it to `dunning_exhausted` via `Ops.emit`.

**Fix:** Remove the raw `:telemetry.execute` call on `[:accrue, :ops, :dunning_exhaustion]` and
remove the corresponding `counter("accrue.ops.dunning_exhaustion.count", ...)` metric registration
from `telemetry/metrics.ex`. Then update `telemetry/ops.ex` to list `[:accrue, :ops, :dunning_exhausted]`
in the canonical docs (replacing `dunning_exhaustion`).

```elixir
# REMOVE these lines from maybe_emit_dunning_exhaustion/2:
:telemetry.execute(
  [:accrue, :ops, :dunning_exhaustion],   # DELETE
  %{count: 1},
  %{...}
)

# REMOVE from telemetry/metrics.ex:
counter("accrue.ops.dunning_exhaustion.count", tags: [:source])   # DELETE

# KEEP (this is the canonical DUN-08 event):
Accrue.Telemetry.Ops.emit(:dunning_exhausted, %{count: 1}, %{...})
counter("accrue.ops.dunning_exhausted.count", tags: [:source])
```

---

## Warnings

### WR-01: Fake `payment_method` capabilities map understates what the adapter actually implements

**File:** `accrue/lib/accrue/processor/fake.ex:223`

**Issue:** The Fake capabilities declaration is:

```elixir
payment_method: %{vault_acquisition: true, list: true},
```

However the Fake adapter fully implements `create_payment_method`, `retrieve_payment_method`,
`attach_payment_method`, `detach_payment_method`, `update_payment_method`, and
`set_default_payment_method`. `Capabilities.first_party_supported?(fake_caps, [:payment_method, :create])`
returns `false` even though Fake silently executes the operation correctly. The mismatch means
any guard that gates on capability before calling will incorrectly reject the Fake path.

Stripe has the same omission (`payment_method: %{vault_acquisition: true, list: true}`),
while Braintree declares the full set. The support labels in `capabilities.ex` call
`payment_method.create` "all first-party" but neither Fake nor Stripe capability maps reflect
this in the boolean support fields.

**Fix:** Add the missing boolean keys to both Fake and Stripe:

```elixir
# fake.ex and stripe.ex
payment_method: %{
  vault_acquisition: true,
  create: true,
  list: true,
  update: true,
  delete: true,
  set_default: true
},
```

---

### WR-02: `Fake` capabilities declare `smart_retry_alignment: true`, semantically misleading

**File:** `accrue/lib/accrue/processor/fake.ex:240`

**Issue:** The Fake adapter declares:

```elixir
dunning: %{campaign: true, smart_retry_alignment: true}
```

The canonical `@provider_support_labels` in `capabilities.ex` gives Fake's
`smart_retry_alignment` the label `"testing/local-only"`, meaning Fake is the proof lane — not
that it actually implements adaptive smart retries. Stripe's `smart_retry_alignment: true` is
accurate (Stripe genuinely has adaptive payment retries); Fake's `true` carries the same boolean
but different semantics.

Any code that calls `Capabilities.supports?(fake_caps, [:dunning, :smart_retry_alignment])`
gets `true`, which reads as "this processor has smart retries" — incorrect for Fake. While no
current code paths gate on this value at runtime (verified by grep), it creates a correctness
hazard for future consumers of the capability map.

**Fix:**

```elixir
# fake.ex: use false to reflect "no real smart-retry implementation"
dunning: %{campaign: true, smart_retry_alignment: false}
```

Update `@provider_support_labels` if the Fake label should still be `"testing/local-only"` (it
currently is, so the label stays; only the boolean changes). Alternatively, add a third value
(e.g., `:testing_only`) to the capability map type to distinguish "test proof lane" from
"unsupported". The simplest fix is `false`, matching the actual processor behavior.

---

### WR-03: `money_string/1` and inline `amount_str` in `create_refund` use floating-point division where `minor_to_decimal_string/1` uses safe integer arithmetic

**File:** `accrue/lib/accrue/processor/braintree.ex:310-315, 916-918`

**Issue:** The adapter has two different strategies for converting minor-unit integers to decimal
strings for Braintree's wire format:

- `minor_to_decimal_string/1` (line 527–532): Uses `div/2` and `rem/2` — correct integer
  arithmetic that is exact for all values.
- `money_string/1` (line 916–918) and the inline `amount_str` in `create_refund` (line 310–315):
  Both use `:erlang.float_to_binary(a / 100.0, [{:decimals, 2}])` — IEEE 754 float division
  that can lose precision for large amounts.

For currency values up to roughly USD 100,000, float division at 2-decimal precision is
empirically safe. But the inconsistency means the two paths behave differently at the limit, and
billing libraries should never depend on float rounding being consistent.

**Fix:** Replace both float paths with the safe integer approach already in `minor_to_decimal_string/1`:

```elixir
# Use everywhere instead of float division:
defp cents_to_string(amount_minor) when is_integer(amount_minor) and amount_minor >= 0 do
  dollars = div(amount_minor, 100)
  cents = amount_minor |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
  "#{dollars}.#{cents}"
end
```

Then replace all callers of `money_string/1` and the inline `amount_str` float logic with
`cents_to_string/1` (or rename `minor_to_decimal_string` to be the single canonical function).

---

### WR-04: Drain assertion in host wiring test is a lower-bound check that cannot distinguish correct-count from excess-count

**File:** `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs:221,229`

**Issue:** Stage B uses `assert success_count >= 1` and `assert day5_success >= 1`. These pass
even if 2, 3, or more jobs ran (e.g., due to queue pollution across tests). This can mask
situations where duplicate DunningStep jobs were enqueued, making the campaign fire more steps
than configured. The Stage A test (line 202) correctly asserts `length(jobs) == 1`.

**Fix:**

```elixir
# Line 221: exact count, not lower bound
assert success_count == 1

# Line 229: exact count for the day-5 step
assert day5_success == 1
```

---

## Info

### IN-01: Redundant `or` condition in full-journey test assertion is logically dead code

**File:** `accrue/test/accrue/dunning/dunning_full_journey_test.exs:343`

**Issue:**

```elixir
assert remaining_jobs == [] or length(remaining_jobs) == 0,
       "No further DunningStep jobs should be enqueued after the final step"
```

The two conditions are logically identical: a list is empty if and only if its length is 0.
The `or` makes this assertion appear as two independent safety nets when it is actually one
condition written twice. The recovery test at line 379 uses the simpler `assert remaining_jobs == []`.

**Fix:**

```elixir
assert remaining_jobs == [],
       "No further DunningStep jobs should be enqueued after the final step"
```

---

### IN-02: Orphaned `[:accrue, :ops, :dunning_exhaustion]` listed as canonical in `telemetry/ops.ex` docstring

**File:** `accrue/lib/accrue/telemetry/ops.ex:13`

**Issue:** The module docstring lists `[:accrue, :ops, :dunning_exhaustion]` as a canonical ops
event. This name refers to the old (pre-DUN-08) event that will be removed as part of the CR-01
fix. After CR-01 is applied, the list will reference a no-longer-emitted event while the actual
DUN-08 canonical `[:accrue, :ops, :dunning_exhausted]` is absent from the list.

**Fix:** Update `ops.ex` canonical event list to replace `dunning_exhaustion` with `dunning_exhausted`:

```elixir
# REMOVE:
[:accrue, :ops, :dunning_exhaustion]
# ADD:
[:accrue, :ops, :dunning_exhausted]
```

---

### IN-03: Host migration comment references wrong parent migration file (the accrue library migration, not the host one)

**File:** `examples/accrue_host/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs:14`

**Issue:** The migration docstring says:

> Nullable, forward-only, mirrors the sibling `dunning_sweep_attempted_at` column added in
> `20260414130300_add_dunning_and_pause_columns_to_subscriptions`.

That timestamp `20260414130300` refers to a migration in the `accrue` library's
`priv/repo/migrations/` directory. The host copy of this migration is in
`examples/accrue_host/priv/repo/migrations/` and the parallel host migration for the
`dunning_sweep_attempted_at` column would have a different filename (if it exists). A developer
reading the host migration and searching for `20260414130300` in the host migrations directory
will not find it, creating confusion about which file added the sibling column in the host schema.

**Fix:** Either reference the host-side migration timestamp/filename for the sibling column, or
clarify the comment to indicate the source is in the `accrue` library's migrations:

```elixir
# Mirrors the sibling `dunning_sweep_attempted_at` column added in the
# accrue library migration 20260414130300_add_dunning_and_pause_columns_to_subscriptions.
```

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
