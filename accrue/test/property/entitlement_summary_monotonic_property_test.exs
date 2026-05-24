defmodule Accrue.Property.EntitlementSummaryMonotonicPropertyTest do
  @moduledoc """
  Phase 127 (ENT-10) — entitlement-summary monotonic-ordering property.

  The monotonic-ordering invariant for the entitlement-summary cache: no
  matter what order Stripe delivers `entitlements.active_entitlement_summary.updated`
  events (Stripe gives no delivery-order guarantee), the persisted cache row
  for a customer always reflects the snapshot with the **highest event
  timestamp** — older / replayed events can never regress it. Backed by the
  config-gated reducer that reuses `check_stale/2` + `stamp_watermark/3`.

  Structure cloned from `entitlements_fail_closed_property_test.exs`
  (`async: false` + `:entitlements` app-env mutation + `stream_data`).
  """
  use Accrue.BillingCase, async: false
  use ExUnitProperties

  alias Accrue.Billing.EntitlementSummary

  setup do
    prev = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, Keyword.put(prev || [], :stripe_native_sync, :advisory))

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_monotonic",
        email: "monotonic@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  # A generator of N distinct (timestamp, event_id, entitlement_count) snapshots.
  defp snapshots_gen do
    gen all(
          count <- StreamData.integer(2..6),
          base_offset <- StreamData.integer(0..1000)
        ) do
      base = DateTime.add(Accrue.Clock.utc_now(), base_offset, :second)

      for i <- 1..count do
        %{
          ts: DateTime.add(base, i * 60, :second),
          event_id: "evt_mono_#{i}",
          entitlement_count: i
        }
      end
    end
  end

  property "final cache row == highest-ts snapshot regardless of delivery order", %{
    customer: customer
  } do
    check all(snapshots <- snapshots_gen(), max_runs: 50) do
      # Clean the cache between runs so each shuffle starts fresh.
      Repo.delete_all(EntitlementSummary)

      winner = Enum.max_by(snapshots, & &1.ts, DateTime)

      snapshots
      |> Enum.shuffle()
      |> Enum.each(fn snap ->
        event =
          StripeFixtures.entitlement_summary_event(
            [
              customer: customer.processor_id,
              entitlements: Enum.map(1..snap.entitlement_count, fn n ->
                %{"id" => "ent_#{n}", "feature" => "feat_#{n}", "lookup_key" => "lk_#{n}"}
              end)
            ],
            %{"id" => snap.event_id, "created" => DateTime.to_unix(snap.ts)}
          )

        Accrue.Webhook.DefaultHandler.handle(event)
      end)

      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert row, "expected a cache row after processing all snapshots"
      assert row.last_stripe_event_id == winner.event_id
      assert row.entitlement_count == winner.entitlement_count
      assert DateTime.compare(row.last_stripe_event_ts, winner.ts) == :eq
    end
  end
end
