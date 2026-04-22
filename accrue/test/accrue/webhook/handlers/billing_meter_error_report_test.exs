defmodule Accrue.Webhook.Handlers.BillingMeterErrorReportTest do
  @moduledoc """
  Phase 4 Plan 02 — webhook reducer for
  `v1.billing.meter.error_report_triggered` (BILL-13, Pitfall 5).

  Verifies the handler flips a previously-reported MeterEvent row to
  `failed`, emits the ops telemetry with `source: :webhook`, and
  gracefully ignores unknown identifiers.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Customer, MeterEvent}
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_meter_webhook",
        email: "mw@example.com"
      })
      |> Repo.insert()

    {:ok, row} =
      %{
        customer_id: customer.id,
        stripe_customer_id: customer.processor_id,
        event_name: "api_call",
        value: 1,
        identifier: "mev_ident_test_wh_1",
        occurred_at: DateTime.utc_now()
      }
      |> MeterEvent.pending_changeset()
      |> Repo.insert()

    # Move the row to :reported so we can observe the webhook-driven
    # flip to :failed (the reverse transition that this handler exists
    # for — Stripe's async validation catches customer-mapping errors
    # AFTER the initial 200 OK).
    {:ok, row} =
      row
      |> MeterEvent.reported_changeset(%{})
      |> Repo.update()

    %{customer: customer, row: row}
  end

  defp error_event(identifier) do
    %{
      id: "evt_test_mere_1",
      type: "v1.billing.meter.error_report_triggered",
      created: DateTime.to_unix(DateTime.utc_now()),
      data: %{
        object: %{
          object: "billing.meter.error_report",
          meter: "mtr_test",
          identifier: identifier,
          reason: %{
            error_code: "meter_event_customer_not_found",
            error_message: "customer mapping failed"
          },
          validation_start: DateTime.to_unix(DateTime.utc_now()),
          validation_end: DateTime.to_unix(DateTime.utc_now())
        }
      }
    }
  end

  test "flips the matching row to failed", %{row: row} do
    assert {:ok, %MeterEvent{} = updated} = DefaultHandler.handle(error_event(row.identifier))
    assert updated.id == row.id
    assert updated.stripe_status == "failed"
    assert updated.stripe_error["object"] == "billing.meter.error_report"
  end

  test "emits [:accrue, :ops, :meter_reporting_failed] with source: :webhook", %{row: row} do
    test_pid = self()

    :telemetry.attach(
      "test-meter-webhook",
      [:accrue, :ops, :meter_reporting_failed],
      fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
      nil
    )

    try do
      assert {:ok, %MeterEvent{}} = DefaultHandler.handle(error_event(row.identifier))
    after
      :telemetry.detach("test-meter-webhook")
    end

    assert_received {:fail, %{count: 1}, %{source: :webhook, webhook_event_id: "evt_test_mere_1"}}
  end

  test "duplicate delivery does not emit a second meter_reporting_failed", %{row: row} do
    test_pid = self()

    :telemetry.attach(
      "test-meter-webhook-dup",
      [:accrue, :ops, :meter_reporting_failed],
      fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
      nil
    )

    try do
      assert {:ok, %MeterEvent{}} = DefaultHandler.handle(error_event(row.identifier))

      assert {:ok, %MeterEvent{stripe_status: "failed"}} =
               DefaultHandler.handle(error_event(row.identifier))

      assert_received {:fail, %{count: 1}, %{source: :webhook}}
      refute_receive {:fail, _, _}, 100
    after
      :telemetry.detach("test-meter-webhook-dup")
    end
  end

  test "handle_event/3 unversioned type with DispatchWorker-shaped ctx", %{row: row} do
    evt = %Accrue.Webhook.Event{
      type: "billing.meter.error_report_triggered",
      object_id: "mer_test_obj",
      livemode: false,
      created_at: DateTime.utc_now(),
      processor_event_id: "evt_unversioned_meter",
      processor: :fake
    }

    ctx = %{
      meter_error_object: %{
        "identifier" => row.identifier,
        "object" => "billing.meter.error_report",
        "reason" => %{
          "error_code" => "meter_event_customer_not_found",
          "error_message" => "customer mapping failed"
        }
      }
    }

    test_pid = self()

    :telemetry.attach(
      "test-meter-handle-event",
      [:accrue, :ops, :meter_reporting_failed],
      fn _evt, meas, meta, _ -> send(test_pid, {:fail, meas, meta}) end,
      nil
    )

    try do
      assert :ok = DefaultHandler.handle_event(evt.type, evt, ctx)
    after
      :telemetry.detach("test-meter-handle-event")
    end

    assert_received {:fail, %{count: 1},
                     %{source: :webhook, webhook_event_id: "evt_unversioned_meter"}}

    reloaded = Repo.reload!(row)
    assert reloaded.stripe_status == "failed"
  end

  test "unknown identifier is acknowledged without raising" do
    assert {:ok, :ignored} = DefaultHandler.handle(error_event("mev_ident_does_not_exist"))
  end
end
