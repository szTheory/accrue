defmodule Accrue.Telemetry.OpsEventContractTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Accrue.TestSupport.TelemetryOpsInventory

  @guide_path Path.expand("../../../guides/telemetry.md", __DIR__)
  @lib_root Path.expand("../../../lib", __DIR__)

  @tuple_re ~r/\[:accrue,\s*:ops(?:,\s*:[a-z_]+)+\]/

  test "guides/telemetry.md lists every canonical ops event as a literal" do
    guide = File.read!(@guide_path)
    expected_ops_events = TelemetryOpsInventory.expected_ops_events()

    missing =
      Enum.reject(expected_ops_events, fn event ->
        guide |> String.contains?(inspect(event))
      end)

    assert missing == [],
           remediation("""
           Missing ops literal in #{@guide_path} for: #{inspect(missing)}.
           Update guides/telemetry.md and ops_event_contract_test.exs if the inventory changed.
           """)
  end

  test "lib literal ops emits are allowlisted; only documented gaps omit emits" do
    found = scan_lib_ops_tuples()
    expected_ops_events = TelemetryOpsInventory.expected_ops_events()
    not_wired_first_party_emits = TelemetryOpsInventory.not_wired_first_party_emits()

    extras = found -- expected_ops_events

    assert extras == [],
           remediation("""
           Undeclared ops tuple(s) in lib/: #{inspect(extras)}.
           Add to Accrue.TestSupport.TelemetryOpsInventory.expected_ops_events/0 + guides/telemetry.md, or remove stray literals.
           Update guides/telemetry.md and telemetry_ops_inventory.ex.
           """)

    unwired = MapSet.difference(MapSet.new(expected_ops_events), MapSet.new(found))

    assert MapSet.equal?(unwired, not_wired_first_party_emits),
           remediation("""
           Ops allowlist vs lib mismatch. Unwired from literals: #{inspect(MapSet.to_list(unwired))}.
           Expected only: #{inspect(MapSet.to_list(not_wired_first_party_emits))}.
           Update guides/telemetry.md and telemetry_ops_inventory.ex alongside new emit sites.
           """)
  end

  defp remediation(msg),
    do: String.trim(msg) <> " (see guides/telemetry.md and ops_event_contract_test.exs)"

  defp scan_lib_ops_tuples do
    @lib_root
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.flat_map(&collect_ops_events_from_file/1)
    |> Enum.uniq()
  end

  defp collect_ops_events_from_file(path) do
    stripped =
      path
      |> File.read!()
      |> strip_moduledocs()

    literal_tuples =
      Regex.scan(@tuple_re, stripped)
      |> Enum.map(fn [match] -> eval_tuple!(match, path) end)

    ops_emit_atoms =
      Regex.scan(~r/Ops\.emit\(\s*:([a-z_]+)\s*,/m, stripped)
      |> Enum.map(fn [_, suf] ->
        [:accrue, :ops | ops_emit_suffix_segments(suf)]
      end)

    literal_tuples ++ ops_emit_atoms
  end

  defp ops_emit_suffix_segments(suf), do: [String.to_existing_atom(suf)]

  defp strip_moduledocs(body) do
    Regex.replace(~r/@moduledoc\s+\"\"\"[\s\S]*?\"\"\"/m, body, "")
  end

  defp eval_tuple!(match, path) do
    Code.string_to_quoted!(match)
    |> then(fn quoted -> elem(Code.eval_quoted(quoted, [], __ENV__), 0) end)
  rescue
    e ->
      flunk(
        remediation(
          "Could not parse ops tuple #{inspect(match)} from #{path}: #{Exception.message(e)}"
        )
      )
  end
end
