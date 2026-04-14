defmodule Accrue.Processor.FakeMeterEventTest do
  @moduledoc """
  Phase 4 Plan 02 — Fake adapter for `report_meter_event/1` (BILL-13).
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Customer, MeterEvent}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_meter_proc",
        email: "proc@example.com"
      })
      |> Repo.insert()

    row = %MeterEvent{
      id: Ecto.UUID.generate(),
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      event_name: "api_call",
      value: 7,
      identifier: "accrue_mev_test_proc_1",
      occurred_at: DateTime.utc_now(),
      stripe_status: "pending"
    }

    %{customer: customer, row: row}
  end

  test "returns {:ok, stripe_event} with mev_fake_ id", %{row: row} do
    assert {:ok, stripe_event} = Fake.report_meter_event(row)
    assert stripe_event.id == "mev_fake_" <> row.identifier
    assert stripe_event.object == "billing.meter_event"
    assert stripe_event.event_name == "api_call"
    assert stripe_event.payload.value == "7"
    assert stripe_event.payload.stripe_customer_id == row.stripe_customer_id
    assert stripe_event.identifier == row.identifier
  end

  test "scripted failure returns error without storing", %{customer: customer, row: row} do
    err = %Accrue.APIError{code: "rate_limited", http_status: 429, message: "slow down"}
    Fake.scripted_response(:report_meter_event, {:error, err})

    assert {:error, ^err} = Fake.report_meter_event(row)
    assert [] == Fake.meter_events_for(customer)
  end

  test "meter_events_for/1 returns events stored for a customer", %{
    customer: customer,
    row: row
  } do
    assert {:ok, _} = Fake.report_meter_event(row)
    assert {:ok, _} = Fake.report_meter_event(%{row | identifier: "accrue_mev_test_proc_2"})

    events = Fake.meter_events_for(customer)
    assert length(events) == 2
    assert Enum.all?(events, &(&1.object == "billing.meter_event"))
  end
end
