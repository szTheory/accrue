# Phase 154: Advisory Cache Core Correctness - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 3 source files + 2 test files
**Analogs found:** 3 / 3 (all source files are the files being modified — analogs are within-file existing patterns)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `accrue/lib/accrue/billing/entitlement_summary.ex` | model (Ecto schema) | CRUD | Self — `force_changeset/2` pattern mirrors other force-changesets in billing schemas | exact |
| `accrue/lib/accrue/webhook/default_handler.ex` | service (write path) | event-driven, request-response | Self — `stamp_summary_watermark/4`, `check_stale/2`, existing telemetry span pattern | exact |
| `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | test | — | `accrue/test/accrue/webhook/wr05_concurrency_test.exs` (concurrent task pattern); self (existing stale-skip telemetry test) | exact |

---

## Pattern Assignments

### `accrue/lib/accrue/billing/entitlement_summary.ex` (model, CRUD)

**Analog:** Self — lines 68–88 (the bug location) + `accrue/lib/accrue/billing/entitlement_summary.ex` full file

**Current `@cast_fields` (lines 68–72) — the bug:**
```elixir
@cast_fields ~w[
  processor customer_id stripe_customer_id livemode entitlement_count
  truncated data synced_at lock_version
  last_stripe_event_ts last_stripe_event_id
]a
```

**ADV-01 fix — remove `lock_version` from `@cast_fields`:**
```elixir
@cast_fields ~w[
  processor customer_id stripe_customer_id livemode entitlement_count
  truncated data synced_at
  last_stripe_event_ts last_stripe_event_id
]a
```

**Current `force_changeset/2` (lines 82–88) — the bug:**
```elixir
@spec force_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
def force_changeset(summary_or_changeset, attrs \\ %{}) do
  summary_or_changeset
  |> cast(attrs, @cast_fields)
  |> optimistic_lock(:lock_version)   # <-- REMOVE THIS LINE (ADV-01)
  |> unique_constraint(:customer_id)
  |> foreign_key_constraint(:customer_id)
end
```

**ADV-01 fix — remove `optimistic_lock` call; constraints stay:**
```elixir
@spec force_changeset(%__MODULE__{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
def force_changeset(summary_or_changeset, attrs \\ %{}) do
  summary_or_changeset
  |> cast(attrs, @cast_fields)
  |> unique_constraint(:customer_id)
  |> foreign_key_constraint(:customer_id)
end
```

**`lock_version` field declaration (line 61) stays unchanged — D-02, no migration:**
```elixir
field(:lock_version, :integer, default: 1)
```

---

### `accrue/lib/accrue/webhook/default_handler.ex` (service, event-driven)

**Analog:** Self — multiple within-file patterns to copy from, each addressing one requirement.

#### ADV-02: NULL-safe `on_conflict_where` fix

**Current `upsert_entitlement_summary/2` (lines 669–687) — the two bugs:**
```elixir
defp upsert_entitlement_summary(_row, attrs) do
  import Ecto.Query

  %EntitlementSummary{}
  |> EntitlementSummary.force_changeset(attrs)
  |> Repo.insert(
    returning: true,
    conflict_target: :customer_id,
    on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
    on_conflict_where:
      from(e in EntitlementSummary,
        where: e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
        #  ^^ bug: NULL EXCLUDED.last_stripe_event_ts → NULL comparison → no-op
      )
  )
  # ^^ no rescue: Ecto.StaleEntryError propagates to callers
end
```

**After ADV-02 + ADV-03 fix — NULL-safe `on_conflict_where` + `StaleEntryError` intercept:**
```elixir
defp upsert_entitlement_summary(_row, attrs) do
  import Ecto.Query

  %EntitlementSummary{}
  |> EntitlementSummary.force_changeset(attrs)
  |> Repo.insert(
    returning: true,
    conflict_target: :customer_id,
    on_conflict: {:replace_all_except, [:id, :inserted_at, :customer_id]},
    on_conflict_where:
      from(e in EntitlementSummary,
        where:
          fragment("EXCLUDED.last_stripe_event_ts IS NULL") or
            e.last_stripe_event_ts < fragment("EXCLUDED.last_stripe_event_ts")
      )
  )
rescue
  Ecto.StaleEntryError -> {:ok, :stale}
end
```

**Key:** `fragment("EXCLUDED.last_stripe_event_ts IS NULL")` — `EXCLUDED` is a PostgreSQL pseudo-table, not expressible in Ecto DSL. The `or` composition with a left-side fragment is required. The existing `fragment("EXCLUDED.last_stripe_event_ts")` on line 684 proves this form compiles.

#### ADV-03: Stale skip branch in `write_entitlement_summary/9`

**Current `write_entitlement_summary/8` span structure (lines 610–629):**
```elixir
Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  with {:ok, saved} <- upsert_entitlement_summary(row, attrs),
       {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
    :telemetry.execute(
      [:accrue, :entitlements, :summary_synced],
      %{count: 1, entitlement_count: entitlement_count},
      Map.put(metadata, :result, if(material?, do: :written, else: :unchanged))
    )

    if has_more do
      Accrue.Telemetry.Ops.emit(
        :entitlement_summary_truncated,
        %{count: 1},
        %{customer_id: customer.id}
      )
    end

    {:ok, saved}
  end
end)
```

**After ADV-03 fix — `{:ok, :stale}` pre-`with` branch (telemetry inside span, no `maybe_record_summary_event` call):**
```elixir
Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  case upsert_entitlement_summary(row, attrs) do
    {:ok, :stale} ->
      :telemetry.execute(
        [:accrue, :entitlements, :summary_synced],
        %{count: 1, entitlement_count: entitlement_count},
        Map.put(metadata, :result, :unchanged)
      )
      {:ok, :stale}

    {:ok, saved} ->
      with {:ok, _} <- maybe_record_summary_event(material?, saved, evt_id) do
        :telemetry.execute(
          [:accrue, :entitlements, :summary_synced],
          %{count: 1, entitlement_count: entitlement_count},
          Map.put(metadata, :result, if(material?, do: :written, else: :unchanged))
        )

        if has_more do
          Accrue.Telemetry.Ops.emit(
            :entitlement_summary_truncated,
            %{count: 1},
            %{customer_id: customer.id}
          )
        end

        {:ok, saved}
      end

    error ->
      error
  end
end)
```

#### POL-01: `processor` arg threading — `write_entitlement_summary/8 → /9`

**Current function head (line 579) — 8 args:**
```elixir
defp write_entitlement_summary(evt_id, evt_ts, obj, cus_id, customer, row, entitlements, data) do
```

**Current bug (line 595) — always global config processor:**
```elixir
processor: processor_name(),
```

**After POL-01 fix — add `processor` as 9th arg; use `to_string(processor)` from arg:**
```elixir
defp write_entitlement_summary(evt_id, evt_ts, obj, cus_id, customer, row, entitlements, data, processor) do
  # ...
  attrs =
    %{
      customer_id: customer.id,
      stripe_customer_id: cus_id,
      processor: to_string(processor),   # was: processor_name()
      # ...
    }
```

**Call site in `reduce_entitlement_summary_for_customer/7` (lines 551–562) must pass `processor` through:**
```elixir
write_entitlement_summary(
  evt_id,
  evt_ts,
  obj,
  cus_id,
  customer,
  row,
  entitlements,
  data,
  processor   # <-- D-08: add this arg
)
```

#### POL-02: `livemode` nil-guard — mirror `stamp_summary_watermark/4`

**`stamp_summary_watermark/4` pattern to mirror (lines 700–710):**
```elixir
defp stamp_summary_watermark(attrs, %DateTime{} = evt_ts, evt_id, _row),
  do: stamp_watermark(attrs, evt_ts, evt_id)

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, nil), do: attrs

defp stamp_summary_watermark(attrs, _evt_ts, _evt_id, %EntitlementSummary{} = row) do
  Map.merge(attrs, %{
    last_stripe_event_ts: row.last_stripe_event_ts,
    last_stripe_event_id: row.last_stripe_event_id
  })
end
```

**After POL-02 fix — carry prior row's `livemode` when incoming is nil (inline, in attrs construction):**
```elixir
livemode:
  case get(obj, :livemode) do
    nil -> row && row.livemode
    value -> value
  end
```

**Or helper-function form mirroring `stamp_summary_watermark` multi-head style:**
```elixir
defp resolve_livemode(nil, %EntitlementSummary{livemode: prior}) when not is_nil(prior), do: prior
defp resolve_livemode(livemode, _row), do: livemode
```

---

### `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` (test)

**Analog 1:** Self — existing stale-skip telemetry test (lines 145–185) — pattern for telemetry `attach`/`assert_received`

**Analog 2:** `accrue/test/accrue/webhook/wr05_concurrency_test.exs` lines 71–76 — concurrent `Task.async` pattern (to upgrade with `Sandbox.allow/3`)

#### ADV-04: Concurrent test with `Sandbox.allow/3`

**Existing concurrent task pattern in `wr05_concurrency_test.exs` (lines 71–76) — lacks `Sandbox.allow/3`:**
```elixir
tasks = [
  Task.async(fn -> DefaultHandler.handle(event1) end),
  Task.async(fn -> DefaultHandler.handle(event2) end)
]
results = Enum.map(tasks, &Task.await/1)
```

**New pattern — explicit `Sandbox.allow/3` inside each task lambda (D-06 requirement):**
```elixir
test "concurrent delivery — newer timestamp wins", %{customer: customer} do
  parent = self()

  ts_older = ~U[2026-05-26 10:00:00Z]
  ts_newer = ~U[2026-05-26 10:00:01Z]

  event_older = # ... StripeFixtures.entitlement_summary_event with ts_older
  event_newer = # ... StripeFixtures.entitlement_summary_event with ts_newer

  tasks = [
    Task.async(fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Accrue.TestRepo, parent, self())
      DefaultHandler.handle(event_older)
    end),
    Task.async(fn ->
      Ecto.Adapters.SQL.Sandbox.allow(Accrue.TestRepo, parent, self())
      DefaultHandler.handle(event_newer)
    end)
  ]

  results = Task.await_many(tasks)
  for result <- results, do: assert {:ok, _} = result

  row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
  assert DateTime.compare(row.last_stripe_event_ts, ts_newer) == :eq
end
```

**`BillingCase` sandbox mode (billing_case.ex:49):** `async: false` → `shared: not tags[:async]` → `shared: true`, which is the prerequisite for `Sandbox.allow/3` to work. The existing `use Accrue.BillingCase, async: false` at line 26 of `default_handler_entitlement_summary_test.exs` is already correct.

#### ADV-02 nil-timestamp test pattern

**Model from existing stale-skip test (lines 145–185) — attach telemetry, assert row unchanged:**
```elixir
test "nil last_stripe_event_ts event updates the row", %{customer: customer} do
  # Seed a row with no watermark (first-ever state can have nil ts)
  {:ok, _} =
    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(%{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      entitlement_count: 1
      # last_stripe_event_ts deliberately absent
    })
    |> Repo.insert()

  # Event has no `created` timestamp → nil evt_ts path
  nil_ts_event = # ... fixture with created: nil or missing
  assert {:ok, %EntitlementSummary{}} = DefaultHandler.handle(nil_ts_event)
end
```

#### ADV-03 DB-level stale skip test pattern

**Pattern: deliver newer, then concurrent older that bypasses `check_stale` (by arriving after pre-DB gate), assert `{:ok, :stale}` + `result: :unchanged` telemetry:**
```elixir
test "DB-level stale skip: emits result: :unchanged, no ledger event", %{customer: customer} do
  test_pid = self()

  :telemetry.attach(
    "test-ent-db-stale-#{System.unique_integer([:positive])}",
    [:accrue, :entitlements, :summary_synced],
    fn _evt, _meas, meta, _ -> send(test_pid, {:synced, meta}) end,
    nil
  )

  # ... seed row with newer ts, deliver older event that passes check_stale
  # (simulate by using equal ts, then a repeat of the same event)
  # Assert: {:ok, :stale} returned, result: :unchanged telemetry fired
end
```

#### POL-01 processor accuracy test pattern

**Pattern: use `:fake` processor (BillingCase default), assert row has `processor: "stripe"` from event arg not `processor_name()` which returns `"fake"` in test env:**
```elixir
test "processor field reflects event processor, not global config", %{customer: customer} do
  # BillingCase wires Fake processor → processor_name() returns "fake"
  # The event's processor arg is :stripe
  # After POL-01 fix: row.processor should be "stripe", not "fake"
  event = StripeFixtures.entitlement_summary_event(customer: customer.processor_id)
  assert {:ok, %EntitlementSummary{processor: "stripe"}} = DefaultHandler.handle(event)
end
```

#### POL-02 livemode carry-forward test pattern

```elixir
test "follow-up event with absent livemode carries forward prior row livemode", %{customer: customer} do
  # Seed row with livemode: true
  {:ok, _} =
    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(%{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      livemode: true,
      last_stripe_event_ts: some_ts,
      last_stripe_event_id: "evt_first"
    })
    |> Repo.insert()

  # Deliver a second event where livemode key is absent in the payload
  # After POL-02 fix: row.livemode should still be true
  second_event = # ... fixture without livemode in the object
  assert {:ok, %EntitlementSummary{livemode: true}} = DefaultHandler.handle(second_event)
end
```

---

## Shared Patterns

### `check_stale/2` — pre-DB stale gate (lines 1677–1686)

**Source:** `accrue/lib/accrue/webhook/default_handler.ex:1677-1686`
**Role:** The application-layer stale gate before the DB upsert. Phase 154 does NOT change this function — it is the first gate. The DB `on_conflict_where` is the second gate that catches concurrent writers that both passed `check_stale`.

```elixir
defp check_stale(nil, _evt_ts), do: :ok
defp check_stale(%{last_stripe_event_ts: nil}, _evt_ts), do: :ok
defp check_stale(_row, nil), do: :ok

defp check_stale(%{last_stripe_event_ts: last}, evt_ts) do
  case DateTime.compare(evt_ts, last) do
    :lt -> :stale
    _ -> :ok
  end
end
```

### Telemetry span + execute pattern (lines 610–629)

**Source:** `accrue/lib/accrue/webhook/default_handler.ex:610-629`
**Apply to:** The stale branch in the ADV-03 fix must emit telemetry INSIDE the `Accrue.Telemetry.span` block (not before/after), so the span completes correctly. The `result: :unchanged` metadata key is the signal for operators.

```elixir
Accrue.Telemetry.span([:accrue, :entitlements, :sync], metadata, fn ->
  # ... case branch here ...
  :telemetry.execute(
    [:accrue, :entitlements, :summary_synced],
    %{count: 1, entitlement_count: entitlement_count},
    Map.put(metadata, :result, :unchanged)
  )
end)
```

### `{:ok, :stale}` return convention — already established

**Source:** `accrue/lib/accrue/webhook/default_handler.ex:549`
**Apply to:** `upsert_entitlement_summary/2` return and `write_entitlement_summary/9` propagation. This convention is already used at line 549 for the `check_stale` pre-DB gate branch — D-04/D-05 extend it to the DB-level gate return.

```elixir
# Existing at line 549 — the pre-DB stale return:
{:ok, :stale}

# New at upsert_entitlement_summary/2 — the DB-level stale intercept:
rescue
  Ecto.StaleEntryError -> {:ok, :stale}
```

### `processor_name()` — the global config lookup to STOP using

**Source:** `accrue/lib/accrue/webhook/default_handler.ex:1716-1722`
**Apply to:** Replace with `to_string(processor)` from the function arg throughout the write path (D-07 + D-08). `processor_name()` is correct for subscription/invoice/charge reducers that do NOT take `processor` as an arg — do NOT replace those call sites.

```elixir
defp processor_name do
  case Processor.__impl__() do
    Accrue.Processor.Fake -> "fake"
    Accrue.Processor.Stripe -> "stripe"
    other -> other |> Module.split() |> List.last() |> String.downcase()
  end
end
```

### `BillingCase` + `Sandbox.allow/3` for concurrent tests

**Source:** `accrue/test/support/billing_case.ex:47-54`
**Apply to:** ADV-04 concurrent test. `async: false` → sandbox `shared: true` — this is the prerequisite for `Sandbox.allow/3` to work. The `allow` call must be inside the task lambda (not in the parent process).

```elixir
# billing_case.ex:49 — shared: true when async: false
pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
```

---

## No Analog Found

No files fall into this category. All files being modified have direct in-codebase patterns (the files themselves, plus the sibling test files).

---

## Metadata

**Analog search scope:** `accrue/lib/accrue/billing/`, `accrue/lib/accrue/webhook/`, `accrue/test/accrue/webhook/`, `accrue/test/support/`
**Files scanned:** 5 (entitlement_summary.ex, default_handler.ex lines 500–730 + 1677–1722, default_handler_entitlement_summary_test.exs, wr05_concurrency_test.exs, billing_case.ex)
**Pattern extraction date:** 2026-05-30
