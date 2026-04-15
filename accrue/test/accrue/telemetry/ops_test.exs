defmodule Accrue.Telemetry.OpsTest do
  use ExUnit.Case, async: false

  alias Accrue.Telemetry.Ops

  setup do
    parent = self()
    handler_id = {__MODULE__, make_ref()}

    events = [
      [:accrue, :ops, :dunning_exhaustion],
      [:accrue, :ops, :webhook_dlq, :replay],
      [:accrue, :ops, :revenue_loss]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _ ->
        send(parent, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
      Accrue.Actor.put_operation_id(nil)
    end)

    :ok
  end

  describe "emit/3" do
    test "atom suffix executes [:accrue, :ops, suffix] event" do
      assert :ok =
               Ops.emit(:dunning_exhaustion, %{count: 1}, %{subscription_id: "sub_x"})

      assert_received {:telemetry, [:accrue, :ops, :dunning_exhaustion], %{count: 1},
                       %{subscription_id: "sub_x"} = meta}

      assert Map.has_key?(meta, :operation_id)
    end

    test "list suffix executes [:accrue, :ops | suffix] event" do
      assert :ok =
               Ops.emit([:webhook_dlq, :replay], %{count: 3, requeued_count: 3}, %{
                 actor: :system,
                 dry_run?: false
               })

      assert_received {:telemetry, [:accrue, :ops, :webhook_dlq, :replay],
                       %{count: 3, requeued_count: 3}, %{actor: :system}}
    end

    test "auto-merges operation_id from Accrue.Actor.current_operation_id/0" do
      :ok = Accrue.Actor.put_operation_id("op_abc123")

      Ops.emit(:revenue_loss, %{count: 1, amount_minor: 9900}, %{
        subject_type: "Subscription",
        subject_id: "sub_x",
        reason: :fraud_refund
      })

      assert_received {:telemetry, [:accrue, :ops, :revenue_loss], _measurements, meta}
      assert meta.operation_id == "op_abc123"
    end

    test "explicit operation_id in metadata is preserved (no double-merge override)" do
      :ok = Accrue.Actor.put_operation_id("op_pdict")

      Ops.emit(:revenue_loss, %{count: 1}, %{operation_id: "op_explicit"})

      assert_received {:telemetry, [:accrue, :ops, :revenue_loss], _meas, meta}
      assert meta.operation_id == "op_explicit"
    end
  end
end
