# Phase 178: E — Seed Expressiveness & State Coverage - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `accrue_admin/test/support/e2e_fixtures.ex` | fixture-registry | CRUD (direct Ecto) | same file — existing `seed_operator_flows!/0` | exact |
| `accrue_admin/test/support/e2e_plug.ex` | route dispatcher | request-response | same file — existing `post "/seed/operator-flows"` | exact |
| `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` | seed script | CRUD (Ecto upsert) | same file — `past_due_subscription` / `canceled_subscription` block (lines 31–64) | exact (bug fix) |
| `examples/accrue_host/priv/repo/seeds/showcase.exs` | seed script | CRUD (Ecto upsert) | same file — `invoice_specs` JPY block, `extra_sub_specs` loop | exact |
| `examples/accrue_host/priv/repo/seeds/edge_states.exs` (NEW) | seed script | CRUD (Ecto upsert) | `showcase.exs` entire file | role-match |
| `scripts/ci/accrue_host_seed_e2e.exs` | CI fixture runner | CRUD (idempotent cleanup) | same file — `@fixture_*` module attributes + `cleanup_fixture_footprint!` | exact |

---

## Pattern Assignments

### `accrue_admin/test/support/e2e_fixtures.ex` — adding `seed_edge_states!/0` and `seed_overflow!/0`

**Analog:** same file, `seed_operator_flows!/0` (lines 73–134) and `seed_dashboard!/0` (lines 35–71)

**Module header / imports pattern** (lines 1–9):
```elixir
defmodule AccrueAdmin.E2E.Fixtures do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Charge, Customer, Invoice, Refund, Subscription}
  alias Accrue.Events
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.TestRepo
```
New fixtures need no additional aliases — `Accrue.Connect.Account` must be added for `seed_edge_states!/0`.

**Core fixture function pattern** (lines 73–134, `seed_operator_flows!/0`):
```elixir
def seed_operator_flows! do
  customer =
    insert_customer(%{
      name: "E2E Charge Customer",
      email: "charge-e2e@example.com"
    })

  subscription =
    insert_subscription(customer, %{status: :active, processor_id: "sub_e2e_refund"})

  charge =
    insert_charge(customer, subscription, %{
      processor_id: "ch_e2e_refund",
      status: "succeeded",
      amount_cents: 10_000,
      ...
    })

  ...

  %{
    charge_id: charge.id,
    source_event_id: source_event.id,
    single_webhook_id: single_webhook.id,
    bulk_webhook_id: bulk_webhook.id
  }
end
```
- Each function calls the private `insert_*` helpers with an attrs map that overrides defaults.
- Return value is a plain map of all IDs a Playwright spec may need for detail-page navigation.
- Static `processor_id` strings for entities that must survive within a run; `System.unique_integer([:positive])` default in helpers for entities that only need within-run uniqueness.

**Private insert helper pattern** (lines 149–261):
```elixir
defp insert_customer(attrs) do
  defaults = %{
    owner_type: "User",
    owner_id: Ecto.UUID.generate(),
    processor: "fake",
    processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
    metadata: %{},
    data: %{}
  }

  %Customer{}
  |> Customer.changeset(Map.merge(defaults, attrs))
  |> TestRepo.insert!()
end

defp insert_subscription(customer, attrs) do
  defaults = %{
    customer_id: customer.id,
    processor: "fake",
    processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
    status: :trialing,
    metadata: %{},
    data: %{},
    cancel_at_period_end: false,
    lock_version: 1
  }

  %Subscription{}
  |> Subscription.changeset(Map.merge(defaults, attrs))
  |> TestRepo.insert!()
end
```
- `Map.merge(defaults, attrs)` — caller-supplied attrs win; defaults provide required fields.
- Always `TestRepo.insert!()` (not `Repo` — this is the admin test sandbox repo).
- `lock_version: 1` required on `Subscription` and `Charge`.

**Canceling subscription pattern** (from RESEARCH.md — no existing fixture; use `insert_subscription` with these overrides):
```elixir
insert_subscription(customer, %{
  processor_id: "sub_e2e_canceling",
  status: :active,
  cancel_at_period_end: true,
  current_period_end: DateTime.add(DateTime.utc_now(), 7 * 86_400, :second)
})
```
Reason: `:canceling` is not a DB status — the work-queue filter matches `status == :active AND cancel_at_period_end == true AND current_period_end > now`.

**At-risk/dunning subscription pattern** (from RESEARCH.md — analog: `hero_accounts.exs` lines 33–41):
```elixir
# Must use Subscription.force_status_changeset/2, not changeset/2,
# to bypass transition guards when setting :past_due directly
%Subscription{}
|> Subscription.force_status_changeset(%{
  customer_id: customer.id,
  processor: "fake",
  processor_id: "sub_e2e_dunning_at_risk",
  status: :past_due,
  past_due_since: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second),
  dunning_campaign_started_at: DateTime.add(DateTime.utc_now(), -5 * 86_400, :second)
})
|> TestRepo.insert!()
```
The `dunning_campaign_started_at` field being non-nil on the subscription row is what `Dunning.at_risk_subscriptions/1` (dunning.ex line 242) looks for. No dunning events are required for the row to appear in the at-risk table — the query only excludes rows that HAVE a `dunning.recovered`/`dunning.exhausted` event since the anchor.

**JPY invoice pattern** (from `showcase.exs` lines 198–216):
```elixir
insert_invoice(customer, subscription, %{
  processor_id: "in_e2e_jpy",
  currency: "jpy",          # lowercase string
  total_minor: 55_000,       # full yen — no divide-by-100
  amount_due_minor: 55_000,
  amount_remaining_minor: 55_000,
  status: :open
})
```
`currency: "jpy"` — string, not atom. The existing `insert_invoice` default is `currency: "usd"` — override it. `amount_minor` for JPY is whole yen (zero-decimal currency).

**Overflow fixture loop pattern** (from `background_data.exs` lines 12–96, simplified to use existing helpers):
```elixir
def seed_overflow! do
  customers =
    Enum.map(1..26, fn i ->
      insert_customer(%{
        name: "E2E Overflow Customer #{i}",
        email: "overflow-e2e-#{i}@example.com",
        processor_id: "cus_e2e_overflow_#{i}"
      })
    end)

  Enum.each(customers, fn customer ->
    insert_subscription(customer, %{
      processor_id: "sub_e2e_overflow_#{customer.processor_id}",
      status: :active
    })
  end)

  %{first_customer_id: List.first(customers).id}
end
```
26 rows exceeds `DataTable @default_limit = 25`, triggering the "Load more" cursor. Processor_id uniqueness: suffix `_#{i}` pattern prevents `Ecto.ConstraintError` on the `(processor, processor_id)` unique index.

**Connect Account insert** — no existing helper in `e2e_fixtures.ex`. Add one modeled on `insert_fixture_connect_account!` in `accrue_host_seed_e2e.exs` (lines 464–478):
```elixir
defp insert_connect_account(owner_id, attrs) do
  defaults = %{
    stripe_account_id: "acct_e2e_" <> Integer.to_string(System.unique_integer([:positive])),
    type: "standard",
    owner_type: "User",
    owner_id: owner_id,
    email: "connect-e2e@example.com",
    country: "us",
    charges_enabled: true,
    payouts_enabled: true,
    details_submitted: true,
    capabilities: %{},
    requirements: %{},
    data: %{}
  }

  %Accrue.Connect.Account{}
  |> Accrue.Connect.Account.changeset(Map.merge(defaults, attrs))
  |> TestRepo.insert!()
end
```

---

### `accrue_admin/test/support/e2e_plug.ex` — adding two new routes

**Analog:** same file, lines 33–38 (existing `post "/seed/dashboard"` and `post "/seed/operator-flows"`)

**Route pattern** (lines 33–38):
```elixir
post "/seed/dashboard" do
  json(conn, 200, Fixtures.seed_dashboard!())
end

post "/seed/operator-flows" do
  json(conn, 200, Fixtures.seed_operator_flows!())
end
```
New routes to add (verbatim copy of this shape):
```elixir
post "/seed/edge-states" do
  json(conn, 200, Fixtures.seed_edge_states!())
end

post "/seed/overflow" do
  json(conn, 200, Fixtures.seed_overflow!())
end
```
- Route name uses kebab-case (`edge-states`, `overflow`) matching the `operator-flows` convention.
- Function name uses underscore-snake-case (`seed_edge_states!/0`) matching Elixir convention.
- Must be placed BEFORE the catch-all `match _` clause (line 45).

---

### `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` — dunning bug fix

**Analog:** same file, lines 31–64 (the `past_due_subscription` and `canceled_subscription` blocks)

**Before (buggy pattern)** (lines 101, 139, 164):
```elixir
# Phantom UUIDs — these IDs have no accrue_subscriptions row
sub_7d = Ecto.UUID.generate()
sub_30d = Ecto.UUID.generate()
sub_90d = Ecto.UUID.generate()
```

**After (fixed pattern)**:
```elixir
# Read back the IDs of hero subscriptions created above
{:ok, %{subscription: past_due_subscription}} =
  AccrueHost.Billing.billing_state_for(past_due_org)

{:ok, %{subscription: canceled_subscription}} =
  AccrueHost.Billing.billing_state_for(canceled_org)

# Use real subscription IDs so at_risk_subscriptions/1 JOIN resolves
sub_7d = past_due_subscription.id    # was: Ecto.UUID.generate()
sub_30d = canceled_subscription.id   # was: Ecto.UUID.generate()
sub_90d = past_due_subscription.id   # was: Ecto.UUID.generate() (reuse past_due for the 90d active campaign)
```

**Why this fixes it:** `Dunning.at_risk_subscriptions/1` (dunning.ex lines 229–294) does `from(s in Subscription, ...)` — it queries the `accrue_subscriptions` table directly. The dunning events in `hero_accounts.exs` are stored with `subject_id = sub_7d` etc. Those `subject_id` values are compared against `s.id` in the NOT EXISTS subquery (line 245). With phantom UUIDs, the subscription row is never found by the JOIN. With real subscription IDs, `past_due_subscription` (which has `dunning_campaign_started_at` set and no terminal event) appears in the at-risk table.

**Idempotency:** The `record_at/3` helper (used throughout `hero_accounts.exs`) already uses `on_conflict: :nothing` keyed on `idempotency_key` — the fix does not affect idempotency. The `billing_state_for` calls are read-only. The guard `if is_nil(past_due_subscription.dunning_campaign_started_at)` (line 33) already exists — these two `billing_state_for` reads can reuse the already-bound `past_due_subscription`/`canceled_subscription` variables from those guard blocks (lines 31 and 55).

---

### `examples/accrue_host/priv/repo/seeds/showcase.exs` — reference for edge_states.exs

**Analog:** `showcase.exs` lines 1–522 (full file)

**Idempotent get-or-insert helper pattern** (lines 71–83):
```elixir
upsert = fn schema, changeset_fun, processor_id, attrs ->
  case Repo.get_by(schema, processor: "fake", processor_id: processor_id) do
    nil ->
      attrs = attrs |> Map.put(:processor, "fake") |> Map.put(:processor_id, processor_id)
      struct(schema)
      |> changeset_fun.(attrs)
      |> Repo.insert!()
    existing ->
      existing
  end
end
```
This is the canonical idempotency pattern for host seed files. Copy verbatim into `edge_states.exs`.

**force_status_changeset for non-normal subscription states** (lines 442–459):
```elixir
%Subscription{}
|> Subscription.force_status_changeset(attrs)
|> Ecto.Changeset.put_change(:inserted_at, sub_backdate)
|> Ecto.Changeset.put_change(:updated_at, sub_backdate)
|> Repo.insert!()
```
Use `force_status_changeset/2` (not `changeset/2`) for any subscription seeded directly into `past_due`, `unpaid`, `paused`, `incomplete`, or `canceled` status. The standard `changeset/2` enforces transition guards.

**JPY invoice pattern** (lines 198–216 — the authoritative host-seed reference):
```elixir
{"in_showcase_paid_jpy", enterprise,
 %{
   status: :paid,
   number: "DEMO-PAID-JPY-0004",
   currency: "jpy",
   subtotal_minor: 50_000,
   tax_minor: 5000,
   total_minor: 55_000,
   total_cents: 55_000,       # Note: total_cents is an alias field, set same as total_minor for JPY
   amount_due_minor: 55_000,
   amount_paid_minor: 55_000,
   amount_remaining_minor: 0,
   paid_at: days_ago.(20),
   ...
 }}
```
Then inserted via: `upsert.(Invoice, &Invoice.force_status_changeset/2, pid, attrs)`

**Idempotent event insert with `on_conflict: :nothing`** (lines 113–128):
```elixir
record_event = fn attrs, idempotency_key, at ->
  row =
    attrs
    |> Map.put(:idempotency_key, idempotency_key)
    |> Map.put(:inserted_at, at)
    |> Map.put_new(:actor_type, "system")
    |> Map.put_new(:schema_version, 1)
    |> Map.put_new(:data, %{})

  Repo.insert_all(Accrue.Events.Event, [row],
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
  )
  :ok
end
```
Use `"seed-edge-"` prefix for idempotency keys in `edge_states.exs` to avoid collisions with `"seed-dunning-"` and `"seed-showcase-"` keys (important for the cleanup test which counts events by idempotency_key prefix).

---

### `examples/accrue_host/priv/repo/seeds/edge_states.exs` (NEW FILE)

**Analog:** `showcase.exs` (entire file — same role, same pattern set)

Copy the following from `showcase.exs`:
1. Alias block (lines 14–26)
2. `upsert` helper (lines 71–83)
3. `upsert_coupon` helper (lines 87–96)
4. `record_event` helper (lines 113–128)
5. The `customer_for_slug` + `sub_for_customer` lookup helpers (lines 39–67) — reuse for long-string customer

Key differences from `showcase.exs`:
- Use `"edge-"` prefix for all idempotency keys and processor_ids.
- Include a long-name customer (120-char name), a canceling subscription (active + `cancel_at_period_end: true`), and a JPY charge (no showcase analog — use `Charge.changeset/2` with `currency: "jpy"`).
- New `edge_states.exs` is loaded AFTER `showcase.exs` and `hero_accounts.exs` in `seeds.exs`.

---

### `scripts/ci/accrue_host_seed_e2e.exs` — extending `@fixture_*` allowlists

**Analog:** same file, lines 24–35 (module attributes block) and lines 148–324 (`cleanup_fixture_footprint!`)

**Module attributes pattern** (lines 24–35):
```elixir
@fixture_processor_event_ids ["evt_host_browser_replay", "evt_host_browser_first_run"]
@fixture_customer_processor_ids ["cus_host_browser_replay", "cus_host_premium_replay"]
@fixture_subscription_processor_ids ["sub_host_browser_replay", "sub_host_premium_replay"]
@fixture_subscription_item_processor_ids ["si_host_browser_replay", "si_host_premium_replay"]
@fixture_discount_codes ["SPRING25", "BROKEN"]
@fixture_checkout_operation_ids ["host-browser-portal-checkout"]
```
Extend by appending to the relevant list. New entries for Phase 178 edge states:
```elixir
@fixture_subscription_processor_ids [
  "sub_host_browser_replay",
  "sub_host_premium_replay",
  "sub_e2e_dunning_at_risk",   # NEW
  "sub_e2e_canceling"           # NEW
]
@fixture_customer_processor_ids [
  "cus_host_browser_replay",
  "cus_host_premium_replay",
  "cus_e2e_edge_1"              # NEW (long-name customer from edge_states.exs)
]
```

**Allowlist collision avoidance:** The `seed_e2e_cleanup_test.exs` uses processor_ids with `"unrelated_"` prefix (`cus_unrelated_replay`, `sub_unrelated_replay`, `evt_unrelated_replay`, `si_unrelated_replay`). Always use `"e2e_"` prefix for Phase 178 additions. Never add a string that matches the `"unrelated_"` namespace.

**Cleanup delete-order constraint** (lines 148–324): child rows must be deleted before parent rows. The existing order is: events (with trigger disabled) → oban_jobs → webhooks → subscription_items → subscriptions → sessions → customers → users. New fixture entries slot into the existing delete clauses by being appended to the `@fixture_*` lists — no new delete clauses needed if the new entities are customers and subscriptions.

---

## Shared Patterns

### Idempotency: `on_conflict: :nothing` + `idempotency_key`
**Source:** `showcase.exs` lines 113–128 (`record_event` helper), `background_data.exs` line 106–113 (`Repo.insert_all` with `on_conflict: :nothing`)
**Apply to:** All event inserts in `edge_states.exs` and `hero_accounts.exs`
```elixir
Repo.insert_all(Accrue.Events.Event, [row],
  on_conflict: :nothing,
  conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
)
```

### Idempotency: `upsert` get-or-insert for schemas with `processor_id`
**Source:** `showcase.exs` lines 71–83
**Apply to:** All Invoice, Charge, Subscription, Coupon, PromotionCode inserts in `edge_states.exs`
```elixir
case Repo.get_by(schema, processor: "fake", processor_id: processor_id) do
  nil -> struct(schema) |> changeset_fun.(attrs) |> Repo.insert!()
  existing -> existing
end
```

### `force_status_changeset/2` for seeding non-standard states
**Source:** `showcase.exs` lines 442–459; `hero_accounts.exs` lines 35–41
**Apply to:** Any subscription seeded with `:past_due`, `:paused`, `:unpaid`, `:incomplete`, `:canceled` in host seed files; at-risk subscription in `e2e_fixtures.ex`
```elixir
%Subscription{}
|> Subscription.force_status_changeset(attrs)
|> Repo.insert!()
# or in e2e_fixtures.ex:
|> TestRepo.insert!()
```

### `System.unique_integer([:positive])` for within-run uniqueness
**Source:** `e2e_fixtures.ex` lines 154, 168, 186, 211, 243
**Apply to:** Default `processor_id` generation in all new `insert_*` private helpers in `e2e_fixtures.ex`. For named fixtures that need stable IDs, override with explicit strings.

### Webhook seeding: `ingest_changeset` + manual status override
**Source:** `e2e_fixtures.ex` lines 255–261
```elixir
attrs
|> Map.delete(:status)
|> WebhookEvent.ingest_changeset()
|> Ecto.Changeset.put_change(:status, status)
|> TestRepo.insert!()
```
`ingest_changeset/1` does not accept `status` directly — status must be put after the changeset is built.

### Bulk insert with `Enum.map(1..N, fn i -> ... end)` + `Enum.each`
**Source:** `background_data.exs` lines 12–113
**Apply to:** `seed_overflow!/0` in `e2e_fixtures.ex` — use `Enum.map(1..26, fn i -> insert_customer(...) end)` rather than `TestRepo.insert_all` (helpers already accept atom maps via changesets; insert_all would require raw maps and bypass changeset validation).

---

## No Analog Found

No files in Phase 178 lack a codebase analog. All new code is either an extension of an existing file or modeled on a directly-readable existing seed file.

---

## Metadata

**Analog search scope:** `accrue_admin/test/support/`, `examples/accrue_host/priv/repo/seeds/`, `scripts/ci/`, `accrue/lib/accrue/analytics/`
**Files scanned:** 8
**Pattern extraction date:** 2026-06-04
