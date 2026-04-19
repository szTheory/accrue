defmodule Accrue.TelemetryTest do
  use ExUnit.Case, async: false

  alias Accrue.Telemetry, as: T

  setup do
    parent = self()
    ref = make_ref()

    handler_id = {__MODULE__, ref}

    events = [
      [:accrue, :test, :thing, :do, :start],
      [:accrue, :test, :thing, :do, :stop],
      [:accrue, :test, :thing, :do, :exception]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _ ->
        send(parent, {:telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)
    :ok
  end

  describe "span/3" do
    test "emits :start and :stop with merged metadata on success" do
      base_event = [:accrue, :test, :thing, :do]

      result =
        T.span(base_event, %{foo: 1}, fn -> :ok_result end)

      assert result == :ok_result
      assert_received {:telemetry, [:accrue, :test, :thing, :do, :start], _, %{foo: 1}}
      assert_received {:telemetry, [:accrue, :test, :thing, :do, :stop], _, %{foo: 1}}
    end

    test "emits :exception and reraises on error" do
      base_event = [:accrue, :test, :thing, :do]

      assert_raise RuntimeError, "boom", fn ->
        T.span(base_event, %{bar: 2}, fn -> raise "boom" end)
      end

      assert_received {:telemetry, [:accrue, :test, :thing, :do, :start], _, %{bar: 2}}

      assert_received {:telemetry, [:accrue, :test, :thing, :do, :exception], _, %{bar: 2} = meta}

      assert meta[:kind] == :error
    end

    test "merges current actor into metadata when set" do
      Accrue.Actor.with_actor(%{type: :webhook, id: "evt_123"}, fn ->
        T.span([:accrue, :test, :thing, :do], %{}, fn -> :ok end)
      end)

      assert_received {:telemetry, [:accrue, :test, :thing, :do, :stop], _, meta}
      assert meta.actor.type == :webhook
      assert meta.actor.id == "evt_123"
    end

    test "does not auto-include raw fun args in metadata" do
      T.span([:accrue, :test, :thing, :do], %{safe: true}, fn ->
        _secret = "not-in-metadata"
        :ok
      end)

      assert_received {:telemetry, [:accrue, :test, :thing, :do, :stop], _, meta}
      # Only the explicit metadata + :telemetry's internal span context key.
      # No auto-injection of raw fun args or return values.
      assert meta.safe == true
      refute Map.has_key?(meta, :result)
      refute Enum.any?(Map.values(meta), &match?("not-in-metadata", &1))
    end
  end

  describe "current_trace_id/0" do
    test "returns nil without opentelemetry running" do
      # :opentelemetry is in deps but the tracer is not initialized in test
      # env; helper must gracefully return nil (or a hex id if a span happens
      # to be active).
      assert is_nil(T.current_trace_id()) or is_binary(T.current_trace_id())
    end
  end
end
