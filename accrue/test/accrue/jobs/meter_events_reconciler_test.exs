defmodule Accrue.Jobs.MeterEventsReconcilerTest do
  @moduledoc """
  Phase 4 Plan 02 — MeterEventsReconciler (BILL-13, D4-03). Verifies:
    * pending rows older than 60s flip to reported after a tick
    * rows inside the 60s grace window are ignored
    * LIMIT 1000 cap per tick
    * Stripe failures flip rows to failed (do not retry same tick)
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Customer, MeterEvent}
  alias Accrue.Jobs.MeterEventsReconciler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_reconciler",
        email: "rec@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  defp insert_pending(customer, identifier, inserted_at) do
    {:ok, row} =
      %{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "api_call",
        value: 1,
        identifier: identifier,
        occurred_at: DateTime.utc_now()
      }
      |> MeterEvent.pending_changeset()
      |> Repo.insert()

    # Backdate inserted_at past the grace window so reconciler picks it up.
    {1, _} =
      from(m in MeterEvent, where: m.id == ^row.id)
      |> Repo.update_all(set: [inserted_at: inserted_at])

    Repo.reload!(row)
  end

  test "flips stale pending rows to reported", %{customer: customer} do
    stale = DateTime.add(Accrue.Clock.utc_now(), -120, :second)
    row = insert_pending(customer, "mev_stale_1", stale)

    assert {:ok, 1} = MeterEventsReconciler.reconcile()

    reloaded = Repo.reload!(row)
    assert reloaded.stripe_status == "reported"
    assert %DateTime{} = reloaded.reported_at
  end

  test "ignores rows inside the 60s grace window", %{customer: customer} do
    fresh = DateTime.add(Accrue.Clock.utc_now(), -10, :second)
    row = insert_pending(customer, "mev_fresh_1", fresh)

    assert {:ok, 0} = MeterEventsReconciler.reconcile()

    reloaded = Repo.reload!(row)
    assert reloaded.stripe_status == "pending"
  end

  test "flips row to failed when Stripe returns error and emits telemetry", %{
    customer: customer
  } do
    stale = DateTime.add(Accrue.Clock.utc_now(), -120, :second)
    row = insert_pending(customer, "mev_fail_1", stale)

    err = %Accrue.APIError{code: "customer_not_found", http_status: 404, message: "nope"}
    Fake.scripted_response(:report_meter_event, {:error, err})

    test_pid = self()

    :telemetry.attach(
      "test-reconciler-fail",
      [:accrue, :ops, :meter_reporting_failed],
      fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
      nil
    )

    try do
      assert {:ok, 1} = MeterEventsReconciler.reconcile()
    after
      :telemetry.detach("test-reconciler-fail")
    end

    reloaded = Repo.reload!(row)
    assert reloaded.stripe_status == "failed"
    assert reloaded.stripe_error["code"] == "customer_not_found"
    assert_received {:fail, %{count: 1}, %{source: :reconciler}}
  end

  test "respects LIMIT 1000 cap per tick", %{customer: customer} do
    # Insert 1100 rows with a stale timestamp.
    stale = DateTime.add(Accrue.Clock.utc_now(), -120, :second)

    for i <- 1..1_100 do
      insert_pending(customer, "mev_bulk_#{i}", stale)
    end

    assert {:ok, 1_000} = MeterEventsReconciler.reconcile()

    # 100 rows should remain pending for the next tick.
    remaining =
      from(m in MeterEvent, where: m.stripe_status == "pending")
      |> Repo.aggregate(:count, :id)

    assert remaining == 100
  end

  test "queue is :accrue_meters" do
    assert MeterEventsReconciler.__opts__()[:queue] == :accrue_meters
  end
end
