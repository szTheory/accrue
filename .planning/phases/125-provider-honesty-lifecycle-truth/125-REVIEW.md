---
phase: 125-provider-honesty-lifecycle-truth
reviewed: 2026-05-23T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - accrue/lib/accrue/billing/query.ex
  - accrue/lib/accrue/billing/subscription.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/entitlements.ex
  - accrue/lib/accrue/entitlements/past_due_grace.ex
  - accrue/lib/accrue/entitlements/resolver.ex
  - accrue/lib/accrue/entitlements/resolver/local_map.ex
  - accrue/lib/accrue/processor/braintree.ex
  - accrue/lib/accrue/processor/capabilities.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/stripe.ex
  - scripts/ci/verify_processor_support_matrix.sh
  - accrue/test/accrue/billing/query_test.exs
  - accrue/test/accrue/billing/subscription_predicates_test.exs
  - accrue/test/accrue/config_entitlements_test.exs
  - accrue/test/accrue/entitlements/local_map_test.exs
  - accrue/test/accrue/entitlements/past_due_grace_test.exs
  - accrue/test/accrue/entitlements/provider_honesty_test.exs
  - accrue/test/accrue/entitlements/resolver_test.exs
  - accrue/test/accrue/processor/capabilities_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 125: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Phase 125 ("provider honesty / lifecycle truth") adds: a pure-lifecycle
`entitling?/1` subscription predicate + its SQL twins (`Query.entitling/1`,
`Query.entitling_with_grace_candidates/1`); a `past_due_grace` config knob and
the `PastDueGrace.within_grace?/2` clock check; a past-due grace overlay in the
`LocalMap` resolver with `grace_plans`/`grace_features`/`expired_grace_plans`
fields and matching telemetry reasons in `Accrue.Entitlements`; and an
`entitlements.local_mapping` convergence row across all three processor
adapters + the CI drift gate.

The core fail-closed contract holds: I could not find a path where a paid
feature is granted incorrectly. The boolean results of `entitled?/2`,
`has_active_plan?/2`, and `resolve/2` are correct across the cases I traced
(paused-gap closure, ended-row exclusion, `:unpaid` never granted,
out-of-window drop). The headline value — entitlement resolution is provider
independent with zero processor calls — is structurally sound and well
guarded by `provider_honesty_test.exs`.

The findings below are about **telemetry-reason accuracy** and **robustness of
the grace lane under partial host config**, not about wrong allow/deny
decisions. Two warnings concern a freshly-`:past_due` subscription (nil
`past_due_since`) and a partially-configured `:dunning` keyword. None are
ship-blocking on the fail-closed axis, but they degrade observability honesty
(which is the stated theme of this phase) and one can surface as an unexpected
exception path.

## Warnings

### WR-01: Freshly `:past_due` sub (nil `past_due_since`) is mislabeled `:past_due_expired` instead of dropped

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:192-198`
**Issue:**
`grace_row/4` classifies a row in three branches. For a `:past_due`
subscription whose `past_due_since` is `nil` (the normal state immediately
after a renewal fails, before the dunning stamp lands — the factory
`past_due_subscription/1` leaves it nil), the flow is:

1. `Subscription.dunning_sweepable?(sub)` → `true` (it matches on
   `status: :past_due` only, ignoring `past_due_since`).
2. `PastDueGrace.within_grace?(sub, grace_days)` → `false` (nil head returns
   false).
3. Falls through to `true -> [{price_id, quantity, :expired}]`.

So the row is tagged `:expired`, its plan is recorded in
`expired_grace_plans`, and `Accrue.Entitlements.entitled?/2` then reports the
deny reason `:past_due_expired`. But a subscription whose grace window was
never started (nil `past_due_since`) has not *expired* a window — it simply has
no window. The accurate reason is `:no_active_subscription` (or a dedicated
"not yet in grace" reason), which is exactly what the `:none` path emits for
the same row.

The boolean result is correct (fail-closed `false`), so this is not a
security issue. But for a phase whose entire thesis is "lifecycle truth" and
honest telemetry, emitting `:past_due_expired` for a sub that never had a
window is a lifecycle lie. It is also unguarded: the test at
`local_map_test.exs:333-343` ("nil past_due_since is fail-closed (dropped)")
asserts only that `active_plans`/`grace_plans` are empty — it does NOT assert
the row is dropped rather than recorded in `expired_grace_plans`, and the
docstring at `local_map.ex` claims nil-since rows are "dropped" when they are
actually recorded as expired.

**Fix:** Treat a nil/non-window `past_due_since` as a non-grace drop, not an
expiry. Reorder so the window-startable check gates expiry:

```elixir
defp grace_row(price_id, quantity, sub, grace_days) do
  cond do
    not Subscription.dunning_sweepable?(sub) -> [{price_id, quantity, false}]
    PastDueGrace.within_grace?(sub, grace_days) -> [{price_id, quantity, true}]
    # Only mark :expired when there was an actual window to expire.
    match?(%DateTime{}, sub.past_due_since) -> [{price_id, quantity, :expired}]
    true -> [{price_id, quantity, false}]
  end
end
```

Then add a test asserting a nil-`past_due_since` `:past_due` row denies with
`:no_active_subscription`, NOT `:past_due_expired`.

### WR-02: `grace_days(:dunning)` raises on a partially-configured `:dunning` keyword

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:202`
**Issue:**
```elixir
defp grace_days(:dunning), do: Accrue.Config.dunning() |> Keyword.fetch!(:grace_days)
```
`Accrue.Config.dunning/0` does a **raw** `get!(:dunning)` — it returns whatever
the host put in app env with no per-key merge against the schema default (the
schema default `[mode:, grace_days:, terminal_action:, telemetry_prefix:]` is
only applied when the key is entirely unset). A host that legitimately overrides
`:dunning` partially — e.g. `config :accrue, dunning: [mode: :disabled]` — passes
boot validation (the `:dunning` schema is a bare `:keyword_list` with no required
nested keys), but then `Keyword.fetch!(:grace_days)` raises `KeyError` at
resolve time whenever `past_due_grace: :dunning` is also configured.

The raise is caught by `Accrue.Entitlements.resolve/1`'s `rescue` and collapses
to fail-closed, so no feature leaks. But it converts a routine, valid config
into a per-check exception (with the overhead and noise of `try/rescue` firing
on every entitlement check) and the host gets a silent `false` with no
diagnostic — the opposite of this codebase's "fail loud at boot" convention for
config problems.

**Fix:** Use a defaulted read so a partial `:dunning` degrades gracefully:

```elixir
defp grace_days(:dunning) do
  Accrue.Config.dunning() |> Keyword.get(:grace_days, 14)
end
```

Or, better, surface the dependency at boot: when `past_due_grace: :dunning`,
have `validate_at_boot!/0` assert `dunning[:grace_days]` is a positive integer
so misconfig fails loud rather than silently-closed at runtime.

### WR-03: `entitling?/1` ↔ `Query.entitling/1` twin can drift on string-keyed maps

**File:** `accrue/lib/accrue/billing/subscription.ex:226`
**Issue:**
`entitling?/1` is documented as the in-memory twin of `Query.entitling/1` and
the `query_test.exs:124` "twin invariant" test guards them per-row for
`%Subscription{}` structs. But `entitling?/1` (via `paused?/1` and
`canceled?/1`) also accepts bare `map()` inputs, and the map clauses match on
atom keys (`%{status: ...}`, `%{ended_at: %DateTime{}}`, `%{pause_collection: pc}`).
A string-keyed map (e.g. a raw Stripe/Fake payload shape, which `pending_intent/1`
explicitly normalizes for elsewhere in this same module) falls through every
clause to the `_ -> false` catch-all, so `active?/1` is false and `entitling?/1`
returns `false` regardless of actual lifecycle. The SQL twin has no such blind
spot. The twin invariant test only exercises struct rows, so this divergence is
unguarded.

This is fail-closed (false), so not a security risk, but it is a correctness
trap for any caller that passes a string-keyed processor payload to
`entitling?/1` expecting twin parity with the query.

**Fix:** Either (a) document explicitly that `entitling?/1` and the other
predicates require atom-keyed maps / structs and reject string-keyed payloads
by design, or (b) if string-keyed support is intended (the `map()` typespec
implies it), add dual-key clauses mirroring `pending_intent/1`'s `fetch_key/2`
normalization, and extend the twin test to cover a string-keyed row.

### WR-04: Negative divergence guard regex misses uppercase / cell-boundary tokens

**File:** `scripts/ci/verify_processor_support_matrix.sh:109`
**Issue:**
```bash
if grep -Eq '^\| entitlements\.[a-z_]+ \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
```
The guard intends to catch ANY per-provider divergence label sprouting on an
`entitlements.*` row. Two gaps:

1. The capability key class `[a-z_]+` excludes digits and uppercase. A future
   row like `entitlements.local_mapping_v2` or `entitlements.RBAC` would not
   match the anchor and would silently bypass the guard.
2. The tokens are matched case-sensitively. A label written `Unsupported` or
   `Native` (the exact casing used in the *positive* `require_substring` rows
   elsewhere in this same file, e.g. line 28 `| ... | Unsupported | ...`) would
   slip past the lowercase-only alternation.

So a real drift toward the deferred Phase 127 Stripe-native path, if authored
with capitalized labels matching the house style of the rest of the table,
would not be caught — defeating the guard's stated purpose.

**Fix:** Broaden the key class and make the token match case-insensitive:

```bash
if grep -Eiq '^\| entitlements\.[a-z0-9_]+ \|.*\b(native|unsupported|bounded)\b' "${matrix}"; then
```

(Note: `-i` will also lowercase-fold the `entitlements.` anchor, which is fine
since the literal is already lowercase.)

## Info

### IN-01: `grace_plans` / `expired_grace_plans` can hold the same plan simultaneously

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:119-138`
**Issue:** When a customer holds the same mapped plan via both an in-window
`:past_due` sub AND an out-of-window `:past_due` sub (or an active sub + an
expired past_due sub on the same plan), the plan atom can end up in both
`grace_plans`/`active_plans` and `expired_grace_plans`. The booleans remain
correct because `entitled?/2` and `has_active_plan?/2` check the affirmative
sets first, but the resolved map carries a slightly contradictory state that a
future consumer reading `expired_grace_plans` directly could misinterpret.
**Fix:** After folding, subtract `active_plans` from `expired_grace_plans`
(`MapSet.difference(acc.expired_grace_plans, acc.active_plans)`) so the expired
set is exclusive, mirroring how `grace_features` already subtracts
`non_grace_features`.

### IN-02: Lines exceed the project's effective line width

**File:** `accrue/lib/accrue/entitlements/resolver/local_map.ex:111,183`
**Issue:** Line 111 (100 chars) and line 183 (104 chars) exceed the ~98-char
width the rest of the file and codebase hold to; `mix format` will not break
these automatically but `credo --strict` (run in CI per CLAUDE.md) may flag the
`MaxLineLength` check.
**Fix:** Extract the inline `MapSet.difference(...)` (line 111) to a named
binding and break the `Enum.flat_map(fn ... end)` closure (line 183) onto its
own indented line.

### IN-03: `past_due_grace` accessor docstring/typespec drift

**File:** `accrue/lib/accrue/config.ex:770-771`
**Issue:** `@spec past_due_grace() :: :none | :dunning | pos_integer()` and the
docstring describe the resolved policy, but the function does a raw
`Keyword.get(:past_due_grace, :none)` over `entitlements/0`. If a host stuffs a
non-schema value directly into app env and skips boot validation (e.g. in a
test that calls `put_env` without `validate_at_boot!`), the accessor will return
that bad value, violating the typespec. This is consistent with the rest of the
"raw runtime read" accessors in this module, so it is informational only.
**Fix:** None required if the boot-validation invariant is trusted; otherwise
note in the docstring that the value is only typespec-guaranteed after
`validate_at_boot!/0` has run.

---

_Reviewed: 2026-05-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
