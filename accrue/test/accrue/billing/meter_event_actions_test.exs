defmodule Accrue.Billing.MeterEventsReportUsageTest do
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

      [fake_event] = Accrue.Test.meter_events_for(customer)
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
      assert_received {:fail, %{count: 1}, %{source: :sync}}
    end

    test "idempotent replay returns {:ok, failed} without duplicate telemetry", %{
      customer: customer
    } do
      err = %Accrue.APIError{code: "meter_event_rejected", http_status: 400, message: "nope"}
      Fake.scripted_response(:report_meter_event, {:error, err})

      :ok = Accrue.Actor.put_operation_id("op_meter_idem_fail")
      ts = ~U[2026-04-10 12:00:00.000000Z]
      opts = [operation_id: "op_meter_idem_fail", timestamp: ts, value: 1]

      test_pid = self()

      :telemetry.attach(
        "test-meter-fail-idem",
        [:accrue, :ops, :meter_reporting_failed],
        fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
        nil
      )

      try do
        assert {:error, %Accrue.APIError{}} =
                 Billing.report_usage(customer, "api_call", opts)

        assert_received {:fail, %{count: 1}, %{source: :sync}}

        assert {:ok, %MeterEvent{stripe_status: "failed"} = row2} =
                 Billing.report_usage(customer, "api_call", opts)

        assert row2.stripe_error["code"] == "meter_event_rejected"

        refute_receive {:fail, _, _}, 100
      after
        :telemetry.detach("test-meter-fail-idem")
      end
    end

    test "report_usage!/3 returns failed row on idempotent replay after processor error", %{
      customer: customer
    } do
      err = %Accrue.APIError{code: "meter_event_rejected", http_status: 400, message: "nope"}
      Fake.scripted_response(:report_meter_event, {:error, err})

      :ok = Accrue.Actor.put_operation_id("op_meter_bang_idem")
      ts = ~U[2026-04-11 12:00:00.000000Z]
      opts = [operation_id: "op_meter_bang_idem", timestamp: ts, value: 2]

      assert_raise Accrue.APIError, fn ->
        Billing.report_usage!(customer, "api_call", opts)
      end

      row = Billing.report_usage!(customer, "api_call", opts)
      assert %MeterEvent{stripe_status: "failed"} = row
      assert row.value == 2
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

  describe "deterministic identifiers (MTR-03)" do
    test "operation_id + fixed timestamp yield stable identifier and idempotent row", %{
      customer: customer
    } do
      :ok = Accrue.Actor.put_operation_id("op_golden_meter_43")

      # Fixed instant within the 35-day backdating window enforced on usage timestamps.
      ts = ~U[2026-04-01 03:04:05.000000Z]

      assert {:ok, %MeterEvent{} = row} =
               Billing.report_usage(customer, "api_call",
                 operation_id: "op_golden_meter_43",
                 timestamp: ts,
                 value: 1
               )

      assert String.starts_with?(row.identifier, "accrue_mev_op_golden_meter_43_")
      assert String.contains?(row.identifier, "api_call")
      assert row.operation_id == "op_golden_meter_43"

      assert {:ok, %MeterEvent{id: id2}} =
               Billing.report_usage(customer, "api_call",
                 operation_id: "op_golden_meter_43",
                 timestamp: ts,
                 value: 1
               )

      assert row.id == id2
    end
  end

  describe "report_usage billing telemetry (smoke)" do
    test "emits one meter_event report_usage stop on happy path", %{customer: customer} do
      test_pid = self()

      :telemetry.attach_many(
        "test-report-usage-telemetry-smoke",
        [
          [:accrue, :billing, :meter_event, :report_usage, :stop]
        ],
        fn event, meas, meta, _ ->
          send(test_pid, {:telemetry, event, meas, meta})
        end,
        nil
      )

      try do
        assert {:ok, _} =
                 Billing.report_usage(customer, "api_call",
                   timestamp: ~U[2026-04-15 00:00:00.000000Z]
                 )

        assert_receive {:telemetry, [:accrue, :billing, :meter_event, :report_usage, :stop], meas,
                        meta}

        assert meta[:event_type] == "api_call"
        assert meas[:duration] >= 0

        refute_receive {:telemetry, [:accrue, :billing, :meter_event, :report_usage, :exception],
                        _, _},
                       50
      after
        :telemetry.detach("test-report-usage-telemetry-smoke")
      end
    end
  end
end
