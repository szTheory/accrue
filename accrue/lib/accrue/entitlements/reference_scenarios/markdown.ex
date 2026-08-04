defmodule Accrue.Entitlements.ReferenceScenarios.Markdown do
  @moduledoc false

  @fixture_relative "accrue/priv/entitlements/v1.59-public-contract.json"
  @scenarios_relative "accrue/priv/entitlements/v1.59-reference-scenarios.json"
  @report_relative "examples/crosswake_tracer/capability-report.json"
  @matrix_relative "examples/accrue_host/docs/capability-limits-matrix.md"
  @version "v1.59"

  @top_level_keys ~w(version verification_command evidence_lanes support privacy_exclusions scenario_ids runtime_capability)
  @lane_keys ~w(deterministic_conformance runtime_capability advisory_parity)
  @support_keys ~w(legacy_hosts apple_subscription_management cross_rail_lifecycle_mutation stale_offline_continuity)
  @runtime_keys ~w(scenario_id report status required_evidence_kinds)
  @privacy_exclusions ~w(raw_transaction_data signed_proof_material account_tokens personally_identifiable_information)
  @expected_lanes %{
    "deterministic_conformance" => "merge_blocking",
    "runtime_capability" => "not_merge_blocking",
    "advisory_parity" => "not_merge_blocking"
  }
  @expected_support %{
    "legacy_hosts" => "compatible",
    "apple_subscription_management" => "externally_managed",
    "cross_rail_lifecycle_mutation" => "not_supported",
    "stale_offline_continuity" => "downloaded_study_and_local_progress_only"
  }

  def write(root) do
    with {:ok, matrix} <- render(root) do
      path = Path.join(root, @matrix_relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, matrix)
      :ok
    end
  end

  def check(root) do
    with {:ok, expected} <- render(root) do
      path = Path.join(root, @matrix_relative)

      case File.read(path) do
        {:ok, ^expected} -> :ok
        _ -> {:error, [path]}
      end
    end
  end

  def render(root) do
    with {:ok, contract} <- read_json(root, @fixture_relative),
         {:ok, scenarios} <- read_json(root, @scenarios_relative),
         {:ok, report} <- read_json(root, @report_relative),
         :ok <- validate_contract(contract, scenarios, report) do
      {:ok, markdown(contract, scenarios)}
    end
  end

  defp markdown(contract, scenarios) do
    scenario_lanes =
      scenarios["scenarios"]
      |> Enum.map(&{&1["id"], &1["evidence_lane"]})
      |> Enum.sort()
      |> Enum.map(fn {id, lane} -> "| `#{id}` | `#{lane}` |" end)

    [
      "# v1.59 Capability and Limits Matrix",
      "",
      "This generated reference contains exact supported and unsupported capability facts. It is not a walkthrough, runbook, App Review guide, security analysis, watchlist, or release narrative.",
      "",
      "Contract version: `#{contract["version"]}`",
      "",
      "## Compatibility and limits",
      "",
      "- Legacy hosts remain compatible.",
      "- Apple subscriptions are externally managed.",
      "- No cross-rail lifecycle, migration, refund, or proration mutation occurs.",
      "- Stale access preserves downloaded study and local progress only; expansion waits for reconnect.",
      "- No raw transaction data, signed proof material, tokens, or PII is exposed.",
      "",
      "## Evidence lanes",
      "",
      "| Lane | Merge authority |",
      "| --- | --- |",
      "| `deterministic_conformance` | `merge_blocking` |",
      "| `runtime_capability` | `not_merge_blocking` |",
      "| `advisory_parity` | `not_merge_blocking` |",
      "",
      "Runtime capability is `#{contract["runtime_capability"]["status"]}` until the tracer records both `crosswake_bridge_compile_unit` and `physical_device` evidence.",
      "",
      "## Scenario references",
      "",
      "| Scenario ID | Evidence lane |",
      "| --- | --- |",
      scenario_lanes,
      "",
      "## Deterministic verification",
      "",
      "Run `#{contract["verification_command"]}` from the repository root. Only `deterministic_conformance` is merge-blocking.",
      ""
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp validate_contract(contract, scenarios, report) do
    with :ok <- exact_keys(contract, @top_level_keys, "public contract"),
         :ok <- equal(contract["version"], @version, "invalid public contract version"),
         :ok <-
           equal(
             contract["verification_command"],
             "cd accrue && mix accrue.entitlements.reference_scenarios --check",
             "invalid verification command"
           ),
         :ok <- exact_keys(contract["evidence_lanes"], @lane_keys, "evidence lanes"),
         :ok <- equal(contract["evidence_lanes"], @expected_lanes, "invalid evidence lanes"),
         :ok <- exact_keys(contract["support"], @support_keys, "support"),
         :ok <- equal(contract["support"], @expected_support, "invalid support limits"),
         :ok <-
           equal(
             contract["privacy_exclusions"],
             @privacy_exclusions,
             "invalid privacy exclusions"
           ),
         :ok <- validate_scenarios(contract["scenario_ids"], scenarios),
         :ok <- validate_runtime(contract["runtime_capability"], report) do
      :ok
    end
  end

  defp validate_scenarios(ids, %{"version" => @version, "scenarios" => scenarios})
       when is_list(ids) and is_list(scenarios) do
    known_ids = scenarios |> Enum.map(& &1["id"]) |> Enum.sort()

    cond do
      ids != Enum.uniq(ids) ->
        {:error, "duplicate public scenario id"}

      Enum.sort(ids) != known_ids ->
        {:error, "public scenario IDs must exactly match the corpus"}

      not Enum.all?(scenarios, &(&1["evidence_lane"] in @lane_keys)) ->
        {:error, "invalid scenario lane"}

      true ->
        :ok
    end
  end

  defp validate_scenarios(_, _), do: {:error, "invalid reference scenario corpus"}

  defp validate_runtime(runtime, report) do
    with :ok <- exact_keys(runtime, @runtime_keys, "runtime capability"),
         :ok <-
           equal(
             runtime["scenario_id"],
             "crosswake_runtime_capability",
             "invalid runtime scenario"
           ),
         :ok <- equal(runtime["report"], @report_relative, "invalid runtime report"),
         :ok <-
           equal(runtime["status"], "feasibility_blocked", "runtime promotion is unsupported"),
         :ok <-
           equal(
             runtime["required_evidence_kinds"],
             ["crosswake_bridge_compile_unit", "physical_device"],
             "invalid runtime evidence kinds"
           ),
         :ok <-
           equal(
             report["overall_status"],
             "feasibility_blocked",
             "capability report must remain feasibility_blocked"
           ),
         true <-
           capability_evidence_present?(report, runtime["required_evidence_kinds"]) ||
             {:error, "capability report missing required evidence inventory"} do
      :ok
    else
      false -> {:error, "capability report missing required evidence inventory"}
      {:error, _reason} = error -> error
    end
  end

  defp capability_evidence_present?(%{"capabilities" => capabilities}, required_kinds)
       when is_list(capabilities) do
    capabilities
    |> Enum.find(&(&1["capability"] == "authenticated_host_transport"))
    |> case do
      %{"required_evidence_kinds" => kinds, "evidence" => evidence} when is_list(evidence) ->
        kinds == required_kinds and Enum.map(evidence, & &1["kind"]) == required_kinds

      _ ->
        false
    end
  end

  defp capability_evidence_present?(_, _), do: false

  defp read_json(root, relative) do
    path = Path.join(root, relative)

    with {:ok, json} <- File.read(path),
         :ok <- reject_duplicate_keys(json),
         {:ok, value} <- Jason.decode(json),
         true <- is_map(value) do
      {:ok, value}
    else
      _ -> {:error, "invalid or missing #{relative}"}
    end
  end

  defp exact_keys(value, expected, label) when is_map(value) do
    if Map.keys(value) |> Enum.sort() == Enum.sort(expected),
      do: :ok,
      else: {:error, "unknown or missing #{label} fields"}
  end

  defp exact_keys(_, _, label), do: {:error, "invalid #{label}"}
  defp equal(actual, expected, _message) when actual == expected, do: :ok
  defp equal(_, _, message), do: {:error, message}

  defp reject_duplicate_keys(json) do
    case Jason.decode(json, objects: :ordered_objects) do
      {:ok, value} when is_struct(value, Jason.OrderedObject) ->
        if duplicate_free?(value), do: :ok, else: {:error, "duplicate JSON key"}

      _ ->
        {:error, "invalid JSON"}
    end
  end

  defp duplicate_free?(%Jason.OrderedObject{values: values}) do
    keys = Enum.map(values, &elem(&1, 0))

    length(keys) == MapSet.size(MapSet.new(keys)) and
      Enum.all?(values, fn {_, value} -> duplicate_free?(value) end)
  end

  defp duplicate_free?(values) when is_list(values), do: Enum.all?(values, &duplicate_free?/1)

  defp duplicate_free?(value) when is_map(value),
    do: Enum.all?(value, fn {_, nested} -> duplicate_free?(nested) end)

  defp duplicate_free?(_), do: true
end
