defmodule Accrue.Webhook.WR05ConcurrencyTest do
  @moduledoc """
  Phase 137 Plan 02 — FIX-01: WR-05 StaleEntryError concurrency regression test.

  Simulates concurrent entitlement summary updates for the same customer
  to ensure the new atomic upsert logic prevents crashes and maintains
  monotonicity.
  """

  use Accrue.RepoCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Webhook.DefaultHandler

  @cus_processor_id "cus_wr05_race"

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
        processor_id: @cus_processor_id,
        email: "wr05@example.test"
      })
      |> TestRepo.insert()

    %{customer: customer}
  end

  test "concurrent summary events for the same customer do not crash and latest wins", %{
    customer: customer
  } do
    # Enable the advisory cache config for the test.
    prev_config = Application.get_env(:accrue, :entitlements, [])
    on_exit(fn -> Application.put_env(:accrue, :entitlements, prev_config) end)
    Application.put_env(:accrue, :entitlements, Keyword.put(prev_config, :stripe_native_sync, :advisory))

    # Pre-seed the cache with an old watermark.
    old_ts = ~U[2026-01-01 10:00:00Z]
    {:ok, _} =
      %EntitlementSummary{}
      |> EntitlementSummary.force_changeset(%{
        customer_id: customer.id,
        stripe_customer_id: @cus_processor_id,
        last_stripe_event_ts: old_ts,
        last_stripe_event_id: "evt_old"
      })
      |> TestRepo.insert()

    # Prepare two concurrent events: one slightly newer than the other.
    ts1 = ~U[2026-05-26 10:00:00Z]
    ts2 = ~U[2026-05-26 10:00:01Z] # ts2 is newer

    event1 = make_summary_event("evt_1", ts1, ["feat_1"])
    event2 = make_summary_event("evt_2", ts2, ["feat_2"])

    # Before the fix, running these concurrently would often raise StaleEntryError
    # due to the optimistic lock check failing in the second job.
    
    # We use a task for each to simulate concurrency. 
    tasks = [
      Task.async(fn -> DefaultHandler.handle(event1) end),
      Task.async(fn -> DefaultHandler.handle(event2) end)
    ]

    results = Enum.map(tasks, &Task.await/1)

    # Both should return {:ok, _} (either :written, :unchanged, or :stale).
    # Crucially, neither should raise StaleEntryError.
    for result <- results do
      assert {:ok, _} = result
    end

    # Verify that the DB reflects the NEWEST event (ts2).
    row = TestRepo.get_by(EntitlementSummary, customer_id: customer.id)
    assert DateTime.compare(row.last_stripe_event_ts, ts2) == :eq
    assert row.last_stripe_event_id == "evt_2"
    
    # Verify the data corresponds to ts2.
    assert [%{"feature" => "feat_2"}] = row.data["entitlements"]["data"]
  end

  test "older summary event does not overwrite newer state", %{
    customer: customer
  } do
    # Enable the advisory cache config for the test.
    prev_config = Application.get_env(:accrue, :entitlements, [])
    on_exit(fn -> Application.put_env(:accrue, :entitlements, prev_config) end)
    Application.put_env(:accrue, :entitlements, Keyword.put(prev_config, :stripe_native_sync, :advisory))

    # Pre-seed the cache with a newer watermark.
    new_ts = ~U[2026-05-26 10:00:00Z]
    {:ok, _} =
      %EntitlementSummary{}
      |> EntitlementSummary.force_changeset(%{
        customer_id: customer.id,
        stripe_customer_id: @cus_processor_id,
        last_stripe_event_ts: new_ts,
        last_stripe_event_id: "evt_new",
        data: %{"note" => "newer"}
      })
      |> TestRepo.insert()

    # Prepare an older event.
    old_ts = ~U[2026-05-26 09:00:00Z]
    old_event = make_summary_event("evt_old", old_ts, ["feat_old"])

    # Handle the older event. 
    # The Elixir `check_stale` will skip it, but we want to prove 
    # the DB logic also protects us.
    assert {:ok, :stale} = DefaultHandler.handle(old_event)

    # Verify that the DB still reflects the NEWER state.
    row = TestRepo.get_by(EntitlementSummary, customer_id: customer.id)
    assert DateTime.compare(row.last_stripe_event_ts, new_ts) == :eq
    assert row.last_stripe_event_id == "evt_new"
  end

  defp make_summary_event(id, ts, features) do
    %{
      "id" => id,
      "object" => "event",
      "type" => "entitlements.active_entitlement_summary.updated",
      "created" => DateTime.to_unix(ts),
      "data" => %{
        "object" => %{
          "customer" => @cus_processor_id,
          "livemode" => false,
          "object" => "entitlements.active_entitlement_summary",
          "entitlements" => %{
            "object" => "list",
            "has_more" => false,
            "url" => "/v1/customers/#{@cus_processor_id}/entitlements",
            "data" => Enum.map(features, fn f -> 
              %{
                "id" => "ent_" <> Ecto.UUID.generate(),
                "object" => "entitlements.active_entitlement",
                "feature" => f,
                "lookup_key" => f
              }
            end)
          }
        }
      }
    }
  end
end
