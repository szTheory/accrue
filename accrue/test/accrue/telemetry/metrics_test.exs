defmodule Accrue.Telemetry.MetricsTest do
  use ExUnit.Case, async: true

  alias Accrue.Telemetry.Metrics, as: M

  describe "defaults/0" do
    test "returns a list with at least 19 metric definitions" do
      defs = M.defaults()
      assert is_list(defs)
      assert length(defs) >= 19
    end

    test "every entry is a Telemetry.Metrics struct" do
      for def <- M.defaults() do
        # Telemetry.Metrics structs all expose :name and :event_name fields
        assert Map.has_key?(def, :name)
        assert Map.has_key?(def, :event_name)
      end
    end

    test "includes accrue.ops.dunning_exhaustion.count counter" do
      assert has_metric?("accrue.ops.dunning_exhaustion.count")
    end

    test "includes accrue.ops.webhook_dlq.dead_lettered.count counter" do
      assert has_metric?("accrue.ops.webhook_dlq.dead_lettered.count")
    end

    test "includes summary on accrue.webhooks.dispatch.duration" do
      defs = M.defaults()

      assert Enum.any?(defs, fn d ->
               d.__struct__ == Telemetry.Metrics.Summary and
                 metric_name_to_string(d.name) == "accrue.webhooks.dispatch.duration"
             end)
    end

    test "includes ops counters for revenue_loss, incomplete_expired, charge_failed" do
      assert has_metric?("accrue.ops.revenue_loss.count")
      assert has_metric?("accrue.ops.incomplete_expired.count")
      assert has_metric?("accrue.ops.charge_failed.count")
    end

    test "includes ops counters for pdf, ledger upcast, and connect signals" do
      assert has_metric?("accrue.ops.pdf_adapter_unavailable.count")
      assert has_metric?("accrue.ops.events_upcast_failed.count")
      assert has_metric?("accrue.ops.connect_account_deauthorized.count")
      assert has_metric?("accrue.ops.connect_capability_lost.count")
      assert has_metric?("accrue.ops.connect_payout_failed.count")
    end
  end

  defp has_metric?(name) do
    Enum.any?(M.defaults(), fn d -> metric_name_to_string(d.name) == name end)
  end

  defp metric_name_to_string(name) when is_list(name),
    do: name |> Enum.map(&Atom.to_string/1) |> Enum.join(".")

  defp metric_name_to_string(name) when is_binary(name), do: name
end
