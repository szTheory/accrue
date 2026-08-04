defmodule Accrue.Entitlements.ReferenceScenarios do
  @moduledoc "Strict, data-only reader for the v1.59 cross-consumer reference scenarios."

  @version "v1.59"
  @lanes ~w(deterministic_conformance runtime_capability advisory_parity)
  @artifact_names ~w(v1.59-decision-cases.json v1.59-offline-golden-vectors.json capability-report.json)
  @scenario_keys ~w(id evidence_lane frozen_clock actions expected required_artifacts diagnostic)
  @action_keys ~w(kind order at operation)
  @action_kinds ~w(
    apple_verified_purchase stripe_verified_purchase web_login ios_login
    purchase_preflight offline_proof_stale offline_expansion_request
    reconnect_request verified_cache_replace grant_observation refund_observation
    stripe_retraction device_replace signed_deny rollback_proof rotated_key_proof
    empty_evidence equal_order_delivery repeat_delivery parallel_delivery
    durable_interruption resume_delivery expiry_boundary
    capability_report_read provider_advisory_read
  )
  @operation_keys ~w(rail environment logical_product provider_product_id provider_event_id provider_transaction_id provider_lineage_id provider_order offline_vector offline_action)
  @expected_keys ~w(snapshot purchase offline_policy audit_count)
  @snapshot_keys ~w(revision plans sources)
  @purchase_keys ~w(status reason)
  @offline_policy_keys ~w(action)

  defmodule Snapshot do
    @enforce_keys [:revision, :plans, :sources]
    defstruct [:revision, :plans, :sources]
  end

  defmodule Purchase do
    @enforce_keys [:status, :reason]
    defstruct [:status, :reason]
  end

  defmodule OfflinePolicy do
    @enforce_keys [:action]
    defstruct [:action]
  end

  defmodule Expected do
    @enforce_keys [:snapshot, :purchase, :offline_policy, :audit_count]
    defstruct [:snapshot, :purchase, :offline_policy, :audit_count]
  end

  defmodule Scenario do
    @enforce_keys [
      :id,
      :evidence_lane,
      :frozen_clock,
      :actions,
      :expected,
      :required_artifacts,
      :diagnostic
    ]
    defstruct [
      :id,
      :evidence_lane,
      :frozen_clock,
      :actions,
      :expected,
      :required_artifacts,
      :diagnostic
    ]
  end

  defmodule Operation do
    @enforce_keys [
      :rail,
      :environment,
      :logical_product,
      :provider_product_id,
      :provider_event_id,
      :provider_transaction_id,
      :provider_lineage_id,
      :provider_order,
      :offline_vector,
      :offline_action
    ]
    defstruct [
      :rail,
      :environment,
      :logical_product,
      :provider_product_id,
      :provider_event_id,
      :provider_transaction_id,
      :provider_lineage_id,
      :provider_order,
      :offline_vector,
      :offline_action
    ]
  end

  defmodule ExecutionInput do
    @moduledoc false
    @enforce_keys [:account, :operation]
    defstruct [:account, :operation]
  end

  @spec version() :: String.t()
  def version, do: @version

  @spec all() :: [Scenario.t()]
  def all, do: scenarios()

  @spec fetch!(String.t()) :: Scenario.t()
  def fetch!(id) when is_binary(id),
    do: Enum.find(all(), &(&1.id == id)) || raise(KeyError, key: id)

  @doc "The merge-blocking rows; runtime/advisory evidence is never an execution authority."
  @spec deterministic_scenarios() :: [Scenario.t()]
  def deterministic_scenarios,
    do: Enum.filter(all(), &(&1.evidence_lane == :deterministic_conformance))

  @spec production_execution_ids() :: [String.t()]
  def production_execution_ids, do: Enum.map(deterministic_scenarios(), & &1.id)

  @doc """
  Returns the bounded, fixture-declared input used to select a production context.

  This deliberately carries identifiers and an operation only. Every
  deterministic row must declare its operation; snapshot,
  purchase, offline, and audit results stay in the fixture and are supplied by
  the production contexts rather than reconstructed here.
  """
  @spec execution_input!(Scenario.t()) :: ExecutionInput.t()
  def execution_input!(%Scenario{} = scenario) when scenario.evidence_lane == :deterministic_conformance do
    operation =
      scenario.actions
      |> Enum.find_value(&Map.get(&1, :operation))
      |> case do
        %Operation{} = operation -> operation
        nil -> raise ArgumentError, "deterministic scenario is missing a closed operation"
      end

    %ExecutionInput{account: %{owner_id: "reference-scenario-#{scenario.id}"}, operation: operation}
  end

  def execution_input!(_), do: raise(ArgumentError, "scenario is not production-executable")

  @spec valid?(Scenario.t()) :: boolean()
  def valid?(%Scenario{} = scenario) do
    scenario.evidence_lane in [:deterministic_conformance, :runtime_capability, :advisory_parity] and
      valid_id?(scenario.id) and
      utc?(scenario.frozen_clock) and ordered_actions?(scenario.actions) and
      valid_expected?(scenario.expected) and
      deterministic_operation_valid?(scenario) and
      lane_artifacts_valid?(scenario.evidence_lane, scenario.required_artifacts) and
      safe_diagnostic?(scenario.diagnostic)
  end

  def valid?(_), do: false

  defp scenarios do
    path = Path.join(:code.priv_dir(:accrue), "entitlements/v1.59-reference-scenarios.json")
    json = File.read!(path)
    reject_duplicate_keys!(json)

    decoded = Jason.decode!(json)
    require_keys!(decoded, ["version", "scenarios"], "root")
    decoded["version"] == @version || raise ArgumentError, "invalid reference scenario version"

    (is_list(decoded["scenarios"]) and decoded["scenarios"] != []) ||
      raise ArgumentError, "missing scenarios"

    scenarios = Enum.map(decoded["scenarios"], &scenario!/1)
    ids = Enum.map(scenarios, & &1.id)
    length(ids) == MapSet.size(MapSet.new(ids)) || raise ArgumentError, "duplicate scenario id"
    Enum.sort_by(scenarios, & &1.id)
  end

  defp scenario!(value) when is_map(value) do
    require_keys!(value, @scenario_keys, "scenario")
    lane = value["evidence_lane"]
    lane in @lanes || raise ArgumentError, "invalid evidence lane"
    valid_id?(value["id"]) || raise ArgumentError, "invalid scenario id"
    utc!(value["frozen_clock"], "frozen clock")
    actions = actions!(value["actions"])
    expected = expected!(value["expected"])
    artifacts = artifacts!(value["required_artifacts"])

    lane_artifacts_valid?(lane_atom!(lane), artifacts) ||
      raise ArgumentError, "contradictory required artifacts"

    diagnostic = diagnostic!(value["diagnostic"])

    scenario = %Scenario{
      id: value["id"],
      evidence_lane: lane_atom!(lane),
      frozen_clock: value["frozen_clock"],
      actions: actions,
      expected: expected,
      required_artifacts: artifacts,
      diagnostic: diagnostic
    }

    valid?(scenario) || raise ArgumentError, "invalid scenario"
    scenario
  end

  defp scenario!(_), do: raise(ArgumentError, "scenario must be an object")

  defp actions!(actions) when is_list(actions) and actions != [] do
    parsed =
      Enum.map(actions, fn action ->
        action_keys =
          if Map.has_key?(action, "operation"),
            do: @action_keys,
            else: @action_keys -- ["operation"]

        require_keys!(action, action_keys, "action")

        (is_binary(action["kind"]) and action["kind"] in @action_kinds) ||
          raise ArgumentError, "invalid action kind"

        (is_integer(action["order"]) and action["order"] > 0) ||
          raise ArgumentError, "invalid action order"

        utc!(action["at"], "action clock")
        parsed = %{kind: action["kind"], order: action["order"], at: action["at"]}

        if Map.has_key?(action, "operation"),
          do: Map.put(parsed, :operation, operation!(action["operation"], action["kind"])),
          else: parsed
      end)

    ordered_actions?(parsed) || raise ArgumentError, "unordered actions"
    parsed
  end

  defp actions!(_), do: raise(ArgumentError, "missing actions")

  defp operation!(value, _kind) when is_map(value) do
    require_keys!(value, @operation_keys, "operation")
    rail = value["rail"]
    valid_ids = @operation_keys -- ["rail", "environment", "provider_order", "offline_action"]

    if rail in ["apple", "stripe"] and
         value["environment"] in ["production", "sandbox"] and
         Enum.all?(valid_ids, &valid_id?(value[&1])) and
         is_integer(value["provider_order"]) and value["provider_order"] > 0 and
         value["offline_action"] in ["read_downloaded_lesson", "download_lesson"] do
      %Operation{
        rail: source_atom!(rail),
        environment: String.to_existing_atom(value["environment"]),
        logical_product: value["logical_product"],
        provider_product_id: value["provider_product_id"],
        provider_event_id: value["provider_event_id"],
        provider_transaction_id: value["provider_transaction_id"],
        provider_lineage_id: value["provider_lineage_id"],
        provider_order: value["provider_order"],
        offline_vector: value["offline_vector"],
        offline_action: offline_operation_action!(value["offline_action"])
      }
    else
      raise ArgumentError, "invalid operation"
    end
  end

  defp operation!(_, _), do: raise(ArgumentError, "invalid operation")

  defp offline_operation_action!("read_downloaded_lesson"), do: :read_downloaded_lesson
  defp offline_operation_action!("download_lesson"), do: :download_lesson

  defp expected!(value) when is_map(value) do
    require_keys!(value, @expected_keys, "expected")
    snapshot = value["snapshot"]
    require_keys!(snapshot, @snapshot_keys, "snapshot")
    purchase = value["purchase"]
    require_keys!(purchase, @purchase_keys, "purchase")
    policy = value["offline_policy"]
    require_keys!(policy, @offline_policy_keys, "offline policy")

    (is_integer(snapshot["revision"]) and snapshot["revision"] >= 0) ||
      raise ArgumentError, "invalid revision"

    (is_list(snapshot["plans"]) and
       Enum.all?(snapshot["plans"], &valid_id?/1)) || raise ArgumentError, "invalid plans"

    (is_list(snapshot["sources"]) and
       Enum.all?(snapshot["sources"], &(&1 in ["stripe", "apple"]))) ||
      raise ArgumentError, "invalid sources"

    purchase["status"] in ["eligible", "warn", "block"] ||
      raise ArgumentError, "invalid purchase status"

    (is_binary(purchase["reason"]) and purchase["reason"] =~ ~r/^[a-z0-9_]{3,80}$/) ||
      raise ArgumentError, "invalid purchase reason"

    policy["action"] in ["allow_downloaded_study", "reconnect_required", "deny"] ||
      raise ArgumentError, "invalid offline policy"

    (is_integer(value["audit_count"]) and value["audit_count"] >= 0) ||
      raise ArgumentError, "invalid audit count"

    %Expected{
      snapshot: %Snapshot{
        revision: snapshot["revision"],
        plans: snapshot["plans"],
        sources: Enum.map(snapshot["sources"], &source_atom!/1)
      },
      purchase: %Purchase{
        status: purchase_status!(purchase["status"]),
        reason: purchase["reason"]
      },
      offline_policy: %OfflinePolicy{action: offline_action!(policy["action"])},
      audit_count: value["audit_count"]
    }
  end

  defp expected!(_), do: raise(ArgumentError, "expected must be an object")

  defp artifacts!(artifacts) when is_list(artifacts) and artifacts != [] do
    (Enum.all?(artifacts, &(&1 in @artifact_names)) and artifacts == Enum.uniq(artifacts)) ||
      raise ArgumentError, "invalid artifacts"

    artifacts
  end

  defp artifacts!(_), do: raise(ArgumentError, "missing artifacts")

  defp diagnostic!(diagnostic) when is_map(diagnostic) and map_size(diagnostic) > 0 do
    Enum.all?(diagnostic, fn {key, value} ->
      is_binary(key) and key =~ ~r/^[a-z][a-z0-9_]{2,40}$/ and is_binary(value) and
        byte_size(value) <= 80
    end) || raise ArgumentError, "unsafe diagnostic"

    diagnostic
  end

  defp diagnostic!(_), do: raise(ArgumentError, "missing diagnostic")

  defp valid_expected?(%Expected{
         snapshot: %Snapshot{revision: revision, plans: plans, sources: sources},
         purchase: %Purchase{status: status, reason: reason},
         offline_policy: %OfflinePolicy{action: action},
         audit_count: count
       }),
       do:
         is_integer(revision) and revision >= 0 and is_list(plans) and
           Enum.all?(plans, &valid_id?/1) and is_list(sources) and
           Enum.all?(sources, &(&1 in [:stripe, :apple])) and status in [:eligible, :warn, :block] and
           is_binary(reason) and reason =~ ~r/^[a-z0-9_]{3,80}$/ and
           action in [:allow_downloaded_study, :reconnect_required, :deny] and
           is_integer(count) and count >= 0

  defp valid_expected?(_), do: false

  # Empty snapshots are an intentional closed result only at revision zero.
  # Non-empty authorization state must retain its source evidence.
  defp deterministic_operation_valid?(%Scenario{evidence_lane: :deterministic_conformance, actions: actions}),
    do: Enum.any?(actions, &match?(%Operation{}, Map.get(&1, :operation)))

  defp deterministic_operation_valid?(%Scenario{}), do: true

  defp valid_artifacts?(items),
    do:
      is_list(items) and items != [] and Enum.all?(items, &(&1 in @artifact_names)) and
        items == Enum.uniq(items)

  defp lane_artifacts_valid?(:deterministic_conformance, items),
    do:
      valid_artifacts?(items) and "v1.59-decision-cases.json" in items and
        "capability-report.json" not in items

  defp lane_artifacts_valid?(:runtime_capability, items), do: items == ["capability-report.json"]
  defp lane_artifacts_valid?(:advisory_parity, items), do: valid_artifacts?(items)

  defp safe_diagnostic?(value),
    do:
      is_map(value) and map_size(value) > 0 and
        Enum.all?(value, fn {key, item} ->
          is_binary(key) and key =~ ~r/^[a-z][a-z0-9_]{2,40}$/ and is_binary(item) and
            byte_size(item) <= 80
        end)

  defp ordered_actions?(actions),
    do:
      is_list(actions) and actions != [] and
        Enum.map(actions, & &1.order) == Enum.to_list(1..length(actions)) and
        Enum.all?(actions, fn action ->
          action.kind in @action_kinds and utc?(action.at) and
            (not Map.has_key?(action, :operation) or match?(%Operation{}, action.operation))
        end)

  defp valid_id?(value), do: is_binary(value) and value =~ ~r/^[a-z0-9_]{3,80}$/

  defp lane_atom!("deterministic_conformance"), do: :deterministic_conformance
  defp lane_atom!("runtime_capability"), do: :runtime_capability
  defp lane_atom!("advisory_parity"), do: :advisory_parity
  defp source_atom!("stripe"), do: :stripe
  defp source_atom!("apple"), do: :apple
  defp purchase_status!("eligible"), do: :eligible
  defp purchase_status!("warn"), do: :warn
  defp purchase_status!("block"), do: :block
  defp offline_action!("allow_downloaded_study"), do: :allow_downloaded_study
  defp offline_action!("reconnect_required"), do: :reconnect_required
  defp offline_action!("deny"), do: :deny
  defp utc?(value), do: is_binary(value) and match?({:ok, _, 0}, DateTime.from_iso8601(value))

  defp utc!(value, name),
    do: if(utc?(value), do: value, else: raise(ArgumentError, "invalid #{name}"))

  defp require_keys!(map, keys, name) when is_map(map) do
    Map.keys(map) |> Enum.sort() == Enum.sort(keys) ||
      raise ArgumentError, "unknown or missing #{name} fields"
  end

  defp require_keys!(_, _, name), do: raise(ArgumentError, "#{name} must be an object")

  defp reject_duplicate_keys!(json) do
    case Jason.decode(json, objects: :ordered_objects) do
      {:ok, value} ->
        if(duplicate_free?(value), do: :ok, else: raise(ArgumentError, "duplicate JSON key"))

      _ ->
        raise ArgumentError, "duplicate JSON key"
    end
  end

  defp duplicate_free?(%Jason.OrderedObject{values: values}),
    do:
      Enum.map(values, &elem(&1, 0)) |> then(&(length(&1) == MapSet.size(MapSet.new(&1)))) and
        Enum.all?(values, fn {_, value} -> duplicate_free?(value) end)

  defp duplicate_free?(values) when is_list(values), do: Enum.all?(values, &duplicate_free?/1)

  defp duplicate_free?(value) when is_map(value),
    do: Enum.all?(value, fn {_, nested} -> duplicate_free?(nested) end)

  defp duplicate_free?(_), do: true
end
