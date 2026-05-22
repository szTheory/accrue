---
phase: 123-config-core-gate-api-foundation
reviewed: 2026-05-22T22:57:45Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - accrue/lib/accrue.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/plan.ex
  - accrue/lib/accrue/entitlements/resolver.ex
  - accrue/lib/accrue/entitlements/resolver/local_map.ex
  - accrue/lib/accrue/telemetry/otel.ex
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/entitlements/local_map_test.exs
  - accrue/test/accrue/entitlements/resolver_test.exs
  - accrue/test/accrue/entitlements_test.exs
  - accrue/test/accrue/telemetry/otel_test.exs
  - accrue/test/property/entitlements_fail_closed_property_test.exs
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 123: Code Review Report

**Reviewed:** 2026-05-22T22:57:45Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the new entitlements / plan-gating foundation: the `:entitlements` config
schema + boot validation (`Accrue.Config`), the fail-closed gate API
(`Accrue.Entitlements` + the four `Accrue.*` delegates), the read-only resolver
behaviour + default `LocalMap` resolver, the `%Plan{}` value struct, and the OTel
attribute allowlist additions.

The design is mostly sound: the `try/rescue/catch` collapse in `resolve/2` is
correct (covers error, exception, throw, AND exit), the cross-plan `price_id`
collision boot guard is correct, the OTel allowlist + prohibited-key denylist keep
PII out of spans, and the LocalMap read path makes zero processor calls.

However there is **one BLOCKER that breaks the fail-closed contract**: a
garbage/non-billable input shaped like `%{id: <non-stringable-term>}` causes the
gate functions to **raise** (via `to_string/1` in the telemetry metadata builder),
not collapse to `false`/`[]`/`0`. The metadata is built *outside* the only
`rescue`, so a "billing/availability hiccup" propagates as a crash to the caller —
exactly what the module's own docstring promises never happens. The fail-closed
property test does not catch it because random `StreamData.term()` essentially
never produces a map keyed specifically on `:id` with a tuple/map/PID value.

There is also a quota-merge defect (last-write-wins instead of a documented union)
that can non-deterministically over- or under-grant a quota for multi-plan
customers, and a few quality/observability concerns.

---

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Gate functions raise (not fail closed) on a billable whose `:id` is non-stringable

**File:** `accrue/lib/accrue/entitlements.ex:198` (and the call sites at `:63`, `:93`, `:112`, `:133`, `:204-211`)

**Issue:** `subject_id/1` does `to_string(id)` for any map/struct with a non-nil
`:id` field:

```elixir
defp subject_id(%{id: id}) when not is_nil(id), do: to_string(id)
defp subject_id(_), do: nil
```

`subject_id/1` is called from `span/5`, which builds the telemetry `metadata` map
**before** invoking `Accrue.Telemetry.span/3` — and `span/5` is itself called
*outside* the only `try/rescue/catch` in this module (that rescue lives in
`resolve/2`, lines 143-153). `to_string/1` raises `Protocol.UndefinedError`
(tuples, maps, PIDs, structs without `String.Chars`) or `ArgumentError`
(non-charlist lists). So:

```elixir
Accrue.entitled?(%{id: {1, 2}}, :reports)        # ** (Protocol.UndefinedError)
Accrue.has_active_plan?(%{id: %{a: 1}}, :p1)      # ** (Protocol.UndefinedError)
Accrue.features_for(%{id: [:a, :b]})              # ** (ArgumentError)
Accrue.entitlement_quantity(%{id: self()}, :seats)# ** (Protocol.UndefinedError)
```

Verified: `to_string({1,2})` → `Protocol.UndefinedError`; `to_string([:a,:b])` →
`ArgumentError`; `to_string(self())` → `Protocol.UndefinedError`.

This directly violates the documented fail-closed contract
(`entitlements.ex:17-23`): "Every function fails closed: `nil`/non-billable/…/
garbage all collapse to `false`/`[]`/`0`. … a billing/availability hiccup never
grants a paid feature for free." A crash is worse than an over-grant: it can take
down the caller's request path. The property test
(`entitlements_fail_closed_property_test.exs:87-95`) uses `StreamData.term()`,
which has effectively zero probability of generating a map keyed exactly on `:id`
with a non-stringable value, so this gap is untested.

**Fix:** Make metadata construction total. Guard `to_string/1` and/or wrap the
metadata build so it can never raise out of a gate function:

```elixir
defp subject_id(%{id: id}) when not is_nil(id) do
  to_string(id)
rescue
  _ -> nil
end

defp subject_id(_), do: nil
```

(Prefer also narrowing the accepted shapes — e.g. only stringify when
`is_binary(id) or is_integer(id) or is_atom(id)` and `inspect/1` otherwise — since
`inspect/1` never raises.) Add a property/unit case covering
`%{id: {1, 2}}`, `%{id: %{}}`, `%{id: [:a, :b]}`, and `%{id: self()}` to lock the
fail-closed contract.

## Warnings

### WR-01: Cross-plan quota merge is last-write-wins, not the documented union

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:89-105`

**Issue:** When two active subscriptions on two different mapped plans both define
the *same* quota key, `merge_plan/4` overwrites the accumulated value with
`Map.put/3`:

```elixir
quantities =
  Enum.reduce(limits, acc.quantities, fn {quota_key, cap}, q ->
    Map.put(q, quota_key, min(cap, quantity))   # blind overwrite
  end)
```

The fold processes `active_items` in DB-return order, so the **last** folded plan
wins for any shared quota key. The docs and phase plan explicitly promise a
*merge/union*: `resolver.ex:36` ("merged `quota_key => min(cap, quantity)` map"),
`local_map.ex:20` ("`quantities` — merged `quota_key => min(cap, quantity)`"),
123-03-PLAN.md L97 ("merged min(cap, qty) per quota_key"), and the surrounding
semantics are union everywhere else (`active_plans` SET union, `features` UNION).

Impact: for a customer holding plan A (`seats: cap 10`, qty 8 → 8) and plan B
(`seats: cap 5`, qty 3 → 3), `entitlement_quantity(billable, :seats)` returns
either 8 or 3 depending on row order — **non-deterministic**, and it can both
under-grant (8→3) and over-grant (3→8) relative to a defensible merge rule. For a
billing gate this is a correctness/fail-open hazard. The current tests dodge it
because the two fixtures use disjoint quota keys (`p1: seats`, `p2: api_calls`).

**Fix:** Decide and implement an explicit merge rule (max is the natural
"union/most-generous" choice; if "least generous" is intended, use min — but be
deterministic), e.g.:

```elixir
quantities =
  Enum.reduce(limits, acc.quantities, fn {quota_key, cap}, q ->
    Map.update(q, quota_key, min(cap, quantity), &max(&1, min(cap, quantity)))
  end)
```

Add a test: one customer, two active mapped plans that *share* a quota key, and
assert the merged result is the chosen rule (and is order-independent).

### WR-02: `subject_id` is unbounded-cardinality, contradicting the "bounded-cardinality" OTel comment

**File:** `accrue/lib/accrue/telemetry/otel.ex:18-26` (allowlist), `accrue/lib/accrue/entitlements.ex:198,211`

**Issue:** The OTel allowlist comment (`otel.ex:18`) labels the entitlement
attributes "bounded-cardinality decision metadata," but `subject_id` carries
`to_string(customer/billable.id)` — one distinct value per customer (unbounded).
Promoting a per-customer id to an exported span *attribute* on a hot per-check
path can blow up trace-backend cardinality/cost and is the kind of identifier many
orgs treat as sensitive in telemetry exhaust. (`subject_id` is also the same value
that raises in CR-01.)

**Fix:** Either (a) drop `:subject_id` from `@allowed_attributes` so it stays in
in-process `:telemetry` metadata only (where high cardinality is cheap) and never
crosses the OTel export boundary, or (b) keep it but correct the comment to state
it is an unbounded-cardinality identifier deliberately exported, and document the
operator cost. Recommend (a) unless there is a concrete tracing need for
per-customer span filtering.

### WR-03: `entitlements/0` docstring claims nested defaults are applied, but `get!/1` does not normalize

**File:** `accrue/lib/accrue/config.ex:834-845`

**Issue:** The `entitlements/0` doc says "The schema's nested defaults normalize
each plan entry, so the resolver (Plan 03) can read this without re-running the
full validator." But `entitlements/0` is `get!(:entitlements)`, which returns the
**raw** app-env keyword list (or the top-level default `[]`); it does NOT apply
the nested per-plan defaults (`features: []`, `limits: []`, `price_ids: []`).
`validate_at_boot!/0` discards the normalized result (`_ = NimbleOptions.validate!`
on `config.ex:484`) and never writes it back to app env. The 123-01-SUMMARY (L82)
correctly states the opposite ("a raw runtime read, not a normalized merge"), so
the docstring here is wrong and could mislead a future maintainer into relying on
defaults that are not present.

The code happens to be safe today because the resolver (`local_map.ex:90-91`,
`catalog/0`) uses `Keyword.get(_, key, default)` everywhere — but that is the
*only* reason an unvalidated/partial entitlements config doesn't crash.

**Fix:** Correct the docstring to match reality (raw read; resolver tolerates
missing nested keys via `Keyword.get` defaults), or actually normalize via
`NimbleOptions.validate!` inside `entitlements/0` if normalized reads are desired.

### WR-04: Entitlements read path inherits the `active?` vs `canceled?` overlap (status-only "active")

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:66-73`, via `accrue/lib/accrue/billing/query.ex:30-32`

**Issue:** `fold_active/1` selects active subscriptions via `Query.active/1`, which
filters on `status in [:active, :trialing]` only. But `Subscription.canceled?/1`
(`subscription.ex:162-167`) returns `true` for any row with a non-nil `ended_at`
*regardless of status*. A subscription row with `status: :active` AND a set
`ended_at` is therefore simultaneously "active" (per `Query.active`) and
"canceled" (per `canceled?`), and the resolver would **grant** entitlements for an
ended subscription — a fail-open edge for a paid gate. `Query`'s own moduledoc
(`query.ex:8-12`) warns that direct status comparisons "miss edge cases like
`cancel_at_period_end` and `ended_at`."

This is shared, pre-existing `Query.active/1` behavior (consistent with
`Subscription.active?/1`), not introduced here, so it is a WARNING rather than a
BLOCKER — but the entitlements read path is a new, security-relevant consumer of
that ambiguity and should not silently grant on ended subscriptions.

**Fix:** Tighten the entitlements active filter to exclude ended rows, e.g. add
`and is_nil(s.ended_at)` to the `fold_active/1` query (or introduce a
`Query.entitlement_active/1` that ANDs `is_nil(ended_at)`), and add a test for a
`status: :active, ended_at: <past>` subscription resolving to no entitlements.

## Info

### IN-01: `feature` telemetry key is overloaded to carry a plan in `has_active_plan?`

**File:** `accrue/lib/accrue/entitlements.ex:73-93`

**Issue:** In `has_active_plan?/2` the third tuple element bound as `feature` is
actually the plan atom / plan term, and it is then passed as the `:feature`
telemetry metadata key (`span(billable, feature, ...)`). Reusing the `:feature`
key for a plan value is semantically muddy for anyone consuming the
`[:accrue, :entitlements, :check]` events and trying to distinguish a feature
check from a plan check.

**Fix:** Either add a distinct `:plan` metadata key for plan checks, or rename the
local to make the overload explicit and document in the moduledoc that `:feature`
holds "the checked feature OR plan, depending on the gate function."

### IN-02: `min(cap, quantity)` semantics differ from struct doc when no cap exists

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:93-96`, `accrue/lib/accrue/entitlements/plan.ex:14-17`

**Issue:** `Plan` doc says `:quantities` are "already reduced to `min(cap,
quantity)` by the resolver where a cap exists." For a quota key that exists as a
plan limit, the resolver always writes `min(cap, quantity)`. But the
*entitlement_quantity/2* contract ("`min(cap, quantity)` where a cap exists, else
the raw quantity") is satisfied indirectly: a quota key with no configured limit
is simply absent from `quantities`, so `entitlement_quantity` returns `0` for it,
not "the raw quantity." That "else the raw quantity" branch only applies when a
key has a limit entry — there is no path that returns an uncapped raw quantity for
an unlisted quota key. The docs (`accrue.ex:55-58`, `entitlements.ex:116-117`)
read as if uncapped keys return the raw item quantity; they actually return `0`.
This is consistent fail-closed behavior but the doc wording is misleading.

**Fix:** Clarify the doc: a quota key absent from a plan's `:limits` returns `0`
(fail-closed), not the raw subscription quantity. The "else the raw quantity"
phrasing should be removed or scoped to "a configured limit with no upper bound,"
which the current schema (`pos_integer` caps) cannot express.

### IN-03: `nil` subject_id is exported to OTel as the literal string `"nil"`

**File:** `accrue/lib/accrue/telemetry/otel.ex:113-132`

**Issue:** When `subject_id` is `nil` (no `:id` on the billable), the metadata map
still contains `subject_id: nil`. `sanitize_attributes/1` finds `:subject_id` in
the allowlist and runs `sanitize_value(nil)`, which falls to the catch-all
`inspect(value)` → `"nil"`. So spans get `accrue.subject_id = "nil"` rather than
the attribute being omitted. Harmless but noisy.

**Fix:** Skip allowlisted keys whose value is `nil` (omit the attribute), e.g.
short-circuit in `sanitize_attributes/1` when `value == nil`.

---

_Reviewed: 2026-05-22T22:57:45Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
