---
phase: 178-e-seed-expressiveness-state-coverage
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - accrue_admin/test/support/e2e_fixtures.ex
  - accrue_admin/test/support/e2e_plug.ex
  - examples/accrue_host/priv/repo/seeds.exs
  - examples/accrue_host/priv/repo/seeds/edge_states.exs
  - examples/accrue_host/priv/repo/seeds/hero_accounts.exs
  - scripts/ci/accrue_host_seed_e2e.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 178-E: Code Review Report

**Reviewed:** 2026-06-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Six files reviewed spanning the admin E2E fixture module, the E2E HTTP plug, the host example
seed entry-point, and the three seed sub-files added in this phase. The primary security concern
(endpoint reachability in production) is **clean**: `AccrueAdmin.E2E.Plug` and
`AccrueAdmin.E2E.Server` live in `test/support/`, are only compiled under `MIX_ENV=test`
(`elixirc_paths(:test)` in mix.exs line 31), are excluded from the published Hex package
(`files:` does not include `test/`), and are never referenced from `lib/`. The
`Mix.env() == :test` guard in `E2E.Server.start!/0` is belt-and-suspenders on top of the
compile-time gate. No prod-reachable path exists.

Idempotency of the host seeds is sound: `upsert/4` in `edge_states.exs` uses
`Repo.get_by(schema, processor: "fake", processor_id: ...)` as its key and is re-run-safe.
The `hero_accounts.exs` bindings are correct — `sub_7d = past_due_subscription.id` (UUID)
is stable across updates, so the dunning-event fix uses the real row ID. The three dunning
windows (7d/30d/90d) intentionally link to different subscriptions and their timestamps
fall in the correct window ranges.

Two warnings surface: (1) an asymmetric route-duplication pattern in the E2E plug, and
(2) dead allowlist entries in `accrue_host_seed_e2e.exs` that reference admin-DB processor
IDs that can never exist in the host DB. Three info items cover naming inconsistency, a
soft-idempotency gap, and an unused function return value.

## Warnings

### WR-01: E2E Plug Has Duplicate Routes for Only Two of Five Seed Endpoints

**File:** `accrue_admin/test/support/e2e_plug.ex:41-55`

**Issue:** The plug defines both `POST /seed/edge-states` (line 41) and
`POST /__e2e__/seed/edge-states` (line 45) as identical actions. Same pattern for
`/seed/overflow` (lines 49 and 53). The `/seed/edge-states` route is reached via
`forward("/__e2e__", Plug)` in `TestRouter` (Phoenix strips the prefix). The
`/__e2e__/seed/edge-states` route is only reachable when the plug is invoked
**directly** (unit tests via `Plug.Test.conn`). The other three seed actions
(`/seed/dashboard`, `/seed/operator-flows`, `/reset`) and the two reads (`/login`,
`/counts`) have **no** `/__e2e__/*` alias, making the pattern inconsistent. Any future
unit test calling `Plug.Test.conn(:post, "/__e2e__/seed/dashboard")` will receive 404
with no compile-time warning.

**Fix:** Either add the `/__e2e__/*` aliases for all routes, or drop the duplicates
and have unit tests call the unprefixed paths directly, matching what the forwarded
router delivers:

```elixir
# Option A: drop the /__e2e__ duplicate routes entirely
# Unit tests should use the same path the forward-router delivers:
# Plug.Test.conn(:post, "/seed/edge-states") |> AccrueAdmin.E2E.Plug.call([])

# Option B: add aliases for all remaining routes for symmetry
post "/__e2e__/reset" do
  Fixtures.reset!()
  json(conn, 200, %{ok: true})
end

post "/__e2e__/seed/dashboard" do
  json(conn, 200, Fixtures.seed_dashboard!())
end

post "/__e2e__/seed/operator-flows" do
  json(conn, 200, Fixtures.seed_operator_flows!())
end
```

---

### WR-02: Cleanup Allowlist Contains Dead Entries That Can Never Match in Host DB

**File:** `scripts/ci/accrue_host_seed_e2e.exs:41-45`

**Issue:** `@fixture_subscription_processor_ids` includes `"sub_e2e_dunning_at_risk"` and
`"sub_e2e_canceling"` (comment: "Plan 02 admin e2e_fixtures.ex: edge-state subscriptions").
These rows are inserted into the **admin** E2E test database (`accrue_admin_test` via
`AccrueAdmin.TestRepo`), not into the host database (`accrue_host_test` via
`AccrueHost.Repo`) that this script cleans. They will never match any row in the host DB.
Similarly, `@fixture_customer_processor_ids` includes `"cus_host_premium_replay"` and
`@fixture_subscription_item_processor_ids` includes `"si_host_premium_replay"` — neither
appears to be inserted anywhere in the script. These dead entries clutter the cleanup,
make the allowlist misleading to future maintainers, and silently mask actual orphan IDs
that should be tracked here.

**Fix:** Remove the cross-DB entries and the uninserted premium IDs from the allowlists:

```elixir
@fixture_subscription_processor_ids [
  "sub_host_browser_replay",
  # sub_host_premium_replay removed (never inserted by this script)
  # sub_e2e_dunning_at_risk + sub_e2e_canceling removed (admin DB, not host DB)
  "sub_e2e_edge_at_risk",
  "sub_e2e_edge_canceling"
]

@fixture_customer_processor_ids [
  "cus_host_browser_replay",
  # cus_host_premium_replay removed (never inserted by this script)
  "cus_e2e_edge_1"
]

@fixture_subscription_item_processor_ids [
  "si_host_browser_replay"
  # si_host_premium_replay removed (never inserted by this script)
]
```

---

## Info

### IN-01: Invoice Processor ID Naming Convention Inconsistency (`inv_` vs `in_`)

**File:** `scripts/ci/accrue_host_seed_e2e.exs:444`

**Issue:** `insert_fixture_invoice!` stores the invoice with `processor_id: "inv_host_browser_replay"` (prefix `inv_`), while the webhook payload at lines 641 and 654 uses `"id" => "in_host_browser_replay"` (Stripe-canonical prefix `in_`). The cleanup LIKE pattern `'inv_host_browser_%'` (line 167) matches only the `inv_` variant. This is internally consistent for this fixture's purpose (the webhook being replayed is an event on the subscription, not a direct invoice lookup), but the naming deviation from Stripe's `in_` convention will confuse maintainers who expect all processor IDs to mirror Stripe IDs. If any code path ever does `Repo.get_by(Invoice, processor_id: stripe_id_from_webhook_payload)`, it will silently return `nil` for this fixture.

**Fix:** Consider aligning to a single convention. If the fixture is intentionally using `inv_` to avoid accidental lookup collisions, add a brief inline comment explaining the deliberate divergence:

```elixir
# processor_id uses "inv_" prefix (not Stripe's "in_") to avoid processor_id
# collision with real Fake-processor allocations during Playwright runs.
processor_id: "inv_host_browser_replay",
```

---

### IN-02: Trialing Subscription Idempotency Is Soft on Re-run

**File:** `examples/accrue_host/priv/repo/seeds/hero_accounts.exs:85-98`

**Issue:** The `unless match?({:ok, %{subscription: ...}}, billing_state_for(trialing_org)) do`
guard skips the entire block — including the `force_status_changeset` call to `:trialing` —
if a subscription already exists. If a re-run finds an existing subscription in a
non-`:trialing` state (e.g., the Fake processor advanced it to `:active`), the seed will
silently leave it in the wrong state. All other demo accounts (past-due, canceled) have
explicit idempotent status-flip guards **outside** the `unless` block (lines 33-41 and
56-63), giving them re-run resilience that the trialing account lacks.

**Fix:** Move the status-flip outside the guard, matching the past-due/canceled pattern:

```elixir
unless match?({:ok, %{subscription: %Accrue.Billing.Subscription{}}},
              AccrueHost.Billing.billing_state_for(trialing_org)) do
  {:ok, _sub} = AccrueHost.Billing.subscribe(trialing_org, "price_basic")
end

{:ok, %{subscription: trialing_subscription}} =
  AccrueHost.Billing.billing_state_for(trialing_org)

if trialing_subscription.status != :trialing do
  trialing_subscription
  |> Accrue.Billing.Subscription.force_status_changeset(%{
    status: :trialing,
    trial_start: now,
    trial_end: DateTime.add(now, 14, :day)
  })
  |> Repo.update!()
end
```

---

### IN-03: `seed_overflow!` Return Value Silently Ignores Subscription Inserts

**File:** `accrue_admin/test/support/e2e_fixtures.ex:229-236`

**Issue:** `Enum.each(customers, fn customer -> insert_subscription(...) end)` discards all
26 return values. Each `insert_subscription` raises on failure (`TestRepo.insert!`), so
failures are not silently swallowed. However, the returned `%Subscription{}` structs are
unreachable after the call — if a future test needs to verify subscription IDs from the
overflow set, it must re-query the DB rather than use the return value from `seed_overflow!`.
The returned map only exposes `first_customer_id`. This is consistent with the existing
overflow test coverage (tests only count rows) but limits fixture expressiveness.

**Fix:** Optionally return subscription IDs if downstream tests ever need them. At minimum,
use `Enum.map` instead of `Enum.each` to signal intent (transforming, not side-effecting only):

```elixir
_subscriptions =
  Enum.map(customers, fn customer ->
    insert_subscription(customer, %{
      processor_id: "sub_e2e_overflow_#{customer.processor_id}",
      status: :active
    })
  end)
```

---

_Reviewed: 2026-06-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
