defmodule Accrue.Telemetry.OpsEventContractTest do
  @moduledoc false
  use ExUnit.Case, async: false

  @guide_path Path.expand("../../../guides/telemetry.md", __DIR__)
  @lib_root Path.expand("../../../lib", __DIR__)

  @expected_ops_events [
    [:accrue, :ops, :revenue_loss],
    [:accrue, :ops, :dunning_exhaustion],
    [:accrue, :ops, :incomplete_expired],
    [:accrue, :ops, :charge_failed],
    [:accrue, :ops, :meter_reporting_failed],
    [:accrue, :ops, :webhook_dlq, :dead_lettered],
    [:accrue, :ops, :webhook_dlq, :replay],
    [:accrue, :ops, :webhook_dlq, :prune],
    [:accrue, :ops, :pdf_adapter_unavailable],
    [:accrue, :ops, :events_upcast_failed],
    [:accrue, :ops, :connect_account_deauthorized],
    [:accrue, :ops, :connect_capability_lost],
    [:accrue, :ops, :connect_payout_failed]
  ]

  # Rows in guides/telemetry.md + metrics that are host-first or not yet
  # wired with first-party `[:accrue, :ops, …]` literals under lib/.
  @not_wired_first_party_emits MapSet.new([
    [:accrue, :ops, :revenue_loss],
    [:accrue, :ops, :incomplete_expired],
    [:accrue, :ops, :charge_failed]
  ])

  @tuple_re ~r/\[:accrue,\s*:ops(?:,\s*:[a-z_]+)+\]/

  test "guides/telemetry.md lists every canonical ops event as a literal" do
    guide = File.read!(@guide_path)

    missing =
      Enum.reject(@expected_ops_events, fn event ->
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

    extras = found -- @expected_ops_events

    assert extras == [],
           remediation("""
           Undeclared ops tuple(s) in lib/: #{inspect(extras)}.
           Add to @expected_ops_events + guides/telemetry.md, or remove stray literals.
           Update guides/telemetry.md and ops_event_contract_test.exs.
           """)

    unwired = MapSet.difference(MapSet.new(@expected_ops_events), MapSet.new(found))

    assert MapSet.equal?(unwired, @not_wired_first_party_emits),
           remediation("""
           Ops allowlist vs lib mismatch. Unwired from literals: #{inspect(MapSet.to_list(unwired))}.
           Expected only: #{inspect(MapSet.to_list(@not_wired_first_party_emits))}.
           Update guides/telemetry.md and ops_event_contract_test.exs alongside new emit sites.
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
