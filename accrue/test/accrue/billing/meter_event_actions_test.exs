defmodule Accrue.Billing.MeterEventActionsTest do
  @moduledoc """
  Phase 4 Plan 02 — BILL-13 metered billing (`report_usage/3`) under the
  Fake processor. Exercises the D4-03 outbox contract: pending insert →
  commit → sync-through → flip status; 35-day backdating enforcement;
  idempotent identifier derivation; failure telemetry.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, MeterEvent}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_meter_test",
        email: "meter@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "report_usage/3 happy path" do
    test "inserts pending row, calls Fake, returns {:ok, reported}", %{customer: customer} do
      assert {:ok, %MeterEvent{} = row} = Billing.report_usage(customer, "api_call")
      assert row.stripe_status == "reported"
      assert row.value == 1
      assert row.event_name == "api_call"
      assert row.customer_id == customer.id
      assert row.stripe_customer_id == customer.processor_id
      assert %DateTime{} = row.reported_at
      assert row.identifier =~ "accrue_mev_"
    end

    test "value option stored on row and forwarded as string to Stripe", %{customer: customer} do
      assert {:ok, %MeterEvent{value: 10}} =
               Billing.report_usage(customer, "api_call", value: 10)

      [fake_event] = Fake.meter_events_for(customer)
      assert fake_event.payload.value == "10"
      assert fake_event.event_name == "api_call"
    end

    test "looks up customer by processor_id when passed a string", %{customer: customer} do
      assert {:ok, %MeterEvent{} = row} =
               Billing.report_usage(customer.processor_id, "api_call", value: 3)

      assert row.customer_id == customer.id
      assert row.value == 3
    end

    test "unknown stripe_customer_id returns not-found error" do
      assert {:error, %Accrue.APIError{code: "resource_missing"}} =
               Billing.report_usage("cus_fake_nope", "api_call")
    end
  end

  describe "backdating window" do
    test "timestamp more than 35 days in the past is rejected without inserting", %{
      customer: customer
    } do
      ts = DateTime.add(DateTime.utc_now(), -40 * 86_400, :second)

      assert {:error, :timestamp_out_of_window} =
               Billing.report_usage(customer, "api_call", timestamp: ts)

      assert [] == Repo.all(MeterEvent)
    end

    test "timestamp more than 5 minutes in the future is rejected", %{customer: customer} do
      ts = DateTime.add(DateTime.utc_now(), 10 * 60, :second)

      assert {:error, :timestamp_in_future} =
               Billing.report_usage(customer, "api_call", timestamp: ts)

      assert [] == Repo.all(MeterEvent)
    end

    test "small clock skew inside ±5 minutes is tolerated", %{customer: customer} do
      ts = DateTime.add(DateTime.utc_now(), 120, :second)
      assert {:ok, %MeterEvent{}} = Billing.report_usage(customer, "api_call", timestamp: ts)
    end
  end

  describe "failure path" do
    test "Fake scripted failure flips row to failed and emits telemetry", %{customer: customer} do
      err = %Accrue.APIError{code: "meter_event_rejected", http_status: 400, message: "nope"}
      Fake.scripted_response(:report_meter_event, {:error, err})

      test_pid = self()

      :telemetry.attach(
        "test-meter-fail",
        [:accrue, :ops, :meter_reporting_failed],
        fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
        nil
      )

      try do
        assert {:error, %Accrue.APIError{}} = Billing.report_usage(customer, "api_call")
      after
        :telemetry.detach("test-meter-fail")
      end

      [row] = Repo.all(MeterEvent)
      assert row.stripe_status == "failed"
      assert row.stripe_error["code"] == "meter_event_rejected"
      assert_received {:fail, %{count: 1}, %{source: :inline}}
    end
  end

  describe "idempotency" do
    test "same operation_id + event + value + ts resolves to same row", %{customer: customer} do
      # BillingCase setup stamps a stable operation_id for the whole test.
      ts = DateTime.utc_now()

      assert {:ok, %MeterEvent{id: id1}} =
               Billing.report_usage(customer, "api_call", value: 5, timestamp: ts)

      assert {:ok, %MeterEvent{id: id2}} =
               Billing.report_usage(customer, "api_call", value: 5, timestamp: ts)

      assert id1 == id2
      assert Repo.aggregate(MeterEvent, :count, :id) == 1
    end

    test "operation_id from Accrue.Actor is stamped on the row", %{customer: customer} do
      Accrue.Actor.put_operation_id("op_meter_stamp")
      assert {:ok, row} = Billing.report_usage(customer, "api_call")
      assert row.operation_id == "op_meter_stamp"
      assert row.identifier =~ "op_meter_stamp"
    end
  end

  describe "events ledger" do
    test "report_usage commits an accrue_events row", %{customer: customer} do
      assert {:ok, row} = Billing.report_usage(customer, "api_call", value: 7)

      query =
        from(e in "accrue_events",
          where: e.subject_id == ^row.id and e.type == "meter_event.reported",
          select: count()
        )

      assert Repo.one(query) == 1
    end
  end

  describe "report_usage!/3" do
    test "unwraps success", %{customer: customer} do
      assert %MeterEvent{} = Billing.report_usage!(customer, "api_call")
    end

    test "raises on error" do
      assert_raise Accrue.APIError, fn ->
        Billing.report_usage!("cus_fake_nope", "api_call")
      end
    end
  end
end
