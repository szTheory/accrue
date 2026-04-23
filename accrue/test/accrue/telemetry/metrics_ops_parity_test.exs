defmodule Accrue.Telemetry.MetricsOpsParityTest do
  @moduledoc "Parity gate for TEL-01: ops inventory tuples vs Accrue.Telemetry.Metrics.defaults/0 event_name."

  use ExUnit.Case, async: true

  alias Accrue.TestSupport.TelemetryOpsInventory

  test "every canonical ops tuple has a defaults/0 metric with matching event_name" do
    defs = load_defaults!()

    assert is_list(defs) and defs != [],
           "Accrue.Telemetry.Metrics.defaults/0 must return metric definitions"

    for tuple <- TelemetryOpsInventory.expected_ops_events() do
      assert Enum.any?(defs, &(&1.event_name == tuple)),
             "missing Telemetry.Metrics default for ops event #{inspect(tuple)} — add a counter in lib/accrue/telemetry/metrics.ex defaults/0"
    end
  end

  defp load_defaults! do
    try do
      Accrue.Telemetry.Metrics.defaults()
    rescue
      e in RuntimeError ->
        flunk("""
        Accrue.Telemetry.Metrics.defaults/0 is unavailable (optional :telemetry_metrics).

        Add {:telemetry_metrics, "~> 1.1"} to accrue/mix.exs deps, run mix deps.get, and recompile.

        #{Exception.message(e)}
        """)
    end
  end
end
