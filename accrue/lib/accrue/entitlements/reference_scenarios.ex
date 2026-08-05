defmodule Accrue.Entitlements.ReferenceScenarios do
  @moduledoc "Strict, data-only reader for the v1.59 cross-consumer reference scenarios."

  @version "v1.59"
  @lanes ~w(deterministic_conformance runtime_capability advisory_parity)
  @artifact_names ~w(v1.59-decision-cases.json v1.59-offline-golden-vectors.json capability-report.json)
  @scenario_keys ~w(id evidence_lane frozen_clock actions expected required_artifacts diagnostic)
  @action_keys ~w(kind order at command expected_transition)
  @command_keys ~w(kind payload)
  @transition_keys ~w(kind seam result durable cache)
  @action_kinds ~w(apple_verified_purchase stripe_verified_purchase web_login ios_login purchase_preflight offline_proof_stale offline_expansion_request reconnect_request verified_cache_replace grant_observation refund_observation stripe_retraction device_replace signed_deny rollback_proof rotated_key_proof empty_evidence equal_order_delivery repeat_delivery parallel_delivery durable_interruption resume_delivery expiry_boundary capability_report_read provider_advisory_read)
  @observation_kinds ~w(apple_verified_purchase stripe_verified_purchase grant_observation refund_observation stripe_retraction equal_order_delivery repeat_delivery parallel_delivery)
  @read_kinds ~w(web_login ios_login verified_cache_replace resume_delivery)
  @offline_kinds ~w(offline_proof_stale offline_expansion_request signed_deny rollback_proof empty_evidence)
  @offline_context_kinds @offline_kinds ++ ["rotated_key_proof"]
  @operation_keys ~w(rail environment logical_product provider_product_id provider_event_id provider_transaction_id provider_lineage_id provider_order offline_vector offline_action)
  @base_payload_keys ~w(account_ref clock)
  @device_replace_payload_keys ~w(account_ref clock prior_device_ref replacement_installation_ref replacement_key_fixture challenge_ref idempotency_ref prior_transition reason actor_ref)
  @lifecycle_payload_keys @base_payload_keys ++
                            (@operation_keys -- ~w(offline_vector offline_action))
  @offline_payload_keys @base_payload_keys ++ @operation_keys
  @reconnect_payload_keys @base_payload_keys ++
                            (@operation_keys -- ~w(offline_vector offline_action))
  @ordering_payload_keys @base_payload_keys ++
                           (@operation_keys -- ~w(offline_vector offline_action))
  @equal_order_payload_keys @ordering_payload_keys ++ ~w(deliveries permutations)
  @repeat_delivery_payload_keys @ordering_payload_keys ++ ~w(deliveries repeat_count)
  @parallel_delivery_payload_keys @ordering_payload_keys ++ ~w(deliveries workers)
  @resume_payload_keys @base_payload_keys ++
                         (@operation_keys -- ~w(offline_vector offline_action))
  @durable_interruption_payload_keys @resume_payload_keys ++ ~w(request_ref interruption_hook)
  @resume_delivery_payload_keys @base_payload_keys ++ ~w(request_ref)
  @expiry_payload_keys @base_payload_keys ++
                         (@operation_keys -- ~w(offline_vector offline_action))
  @payload_keys_by_kind %{
    "apple_verified_purchase" => @lifecycle_payload_keys,
    "stripe_verified_purchase" => @lifecycle_payload_keys,
    "grant_observation" => @lifecycle_payload_keys,
    "refund_observation" => @lifecycle_payload_keys,
    "stripe_retraction" => @lifecycle_payload_keys,
    "web_login" => @base_payload_keys,
    "ios_login" => @base_payload_keys,
    "purchase_preflight" => @lifecycle_payload_keys,
    "expiry_boundary" => @expiry_payload_keys,
    "offline_proof_stale" => @offline_payload_keys,
    "offline_expansion_request" => @offline_payload_keys,
    "signed_deny" => @offline_payload_keys,
    "rollback_proof" => @offline_payload_keys,
    "empty_evidence" => @offline_payload_keys,
    "reconnect_request" => @reconnect_payload_keys,
    "verified_cache_replace" => @base_payload_keys,
    "device_replace" => @device_replace_payload_keys,
    "rotated_key_proof" => @offline_payload_keys,
    "equal_order_delivery" => @equal_order_payload_keys,
    "repeat_delivery" => @repeat_delivery_payload_keys,
    "parallel_delivery" => @parallel_delivery_payload_keys,
    "durable_interruption" => @durable_interruption_payload_keys,
    "resume_delivery" => @resume_delivery_payload_keys
  }
  @expected_keys ~w(snapshot purchase offline_policy audit_count)

  defmodule Snapshot, do: defstruct([:revision, :plans, :sources])
  defmodule Purchase, do: defstruct([:status, :reason])
  defmodule OfflinePolicy, do: defstruct([:action])
  defmodule Expected, do: defstruct([:snapshot, :purchase, :offline_policy, :audit_count])

  defmodule Scenario,
    do:
      defstruct([
        :id,
        :evidence_lane,
        :frozen_clock,
        :actions,
        :expected,
        :required_artifacts,
        :diagnostic
      ])

  defmodule Command, do: defstruct([:kind, :payload])
  defmodule ExpectedTransition, do: defstruct([:kind, :seam, :result, :durable, :cache])

  def version, do: @version
  def all, do: scenarios()
  def fetch!(id), do: Enum.find(all(), &(&1.id == id)) || raise(KeyError, key: id)

  def deterministic_scenarios,
    do: Enum.filter(all(), &(&1.evidence_lane == :deterministic_conformance))

  def production_execution_ids, do: Enum.map(deterministic_scenarios(), & &1.id)
  def action_families, do: @action_kinds

  def action_family!(kind), do: Map.fetch!(@payload_keys_by_kind, kind)

  def command!(%Scenario{evidence_lane: :deterministic_conformance, actions: actions}, order) do
    case Enum.find(actions, &(&1.order == order)) do
      %{command: %Command{} = command} -> command
      _ -> raise ArgumentError, "deterministic action is missing a closed command"
    end
  end

  def command!(_, _), do: raise(ArgumentError, "scenario is not production-executable")

  def valid?(%Scenario{} = s) do
    s.evidence_lane in [:deterministic_conformance, :runtime_capability, :advisory_parity] and
      valid_id?(s.id) and utc?(s.frozen_clock) and ordered_actions?(s.actions) and
      valid_commands?(s.actions) and valid_expected?(s.expected) and
      lane_artifacts_valid?(s.evidence_lane, s.required_artifacts) and
      safe_diagnostic?(s.diagnostic)
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

    rows = Enum.map(decoded["scenarios"], &scenario!/1)
    ids = Enum.map(rows, & &1.id)
    length(ids) == MapSet.size(MapSet.new(ids)) || raise ArgumentError, "duplicate scenario id"
    Enum.sort_by(rows, & &1.id)
  end

  defp scenario!(value) when is_map(value) do
    require_keys!(value, @scenario_keys, "scenario")
    lane = lane!(value["evidence_lane"])
    valid_id?(value["id"]) || raise ArgumentError, "invalid scenario id"
    utc!(value["frozen_clock"], "frozen clock")

    scenario = %Scenario{
      id: value["id"],
      evidence_lane: lane,
      frozen_clock: value["frozen_clock"],
      actions: actions!(value["actions"], lane),
      expected: expected!(value["expected"]),
      required_artifacts: artifacts!(value["required_artifacts"]),
      diagnostic: diagnostic!(value["diagnostic"])
    }

    valid?(scenario) || raise ArgumentError, "invalid scenario"
    scenario
  end

  defp scenario!(_), do: raise(ArgumentError, "scenario must be an object")

  defp actions!(actions, lane) when is_list(actions) and actions != [] do
    parsed =
      Enum.map(actions, fn action ->
        require_keys!(
          action,
          if(lane == :deterministic_conformance, do: @action_keys, else: ~w(kind order at)),
          "action"
        )

        kind = action["kind"]
        kind in @action_kinds || raise ArgumentError, "invalid action kind"

        (is_integer(action["order"]) and action["order"] > 0) ||
          raise ArgumentError, "invalid action order"

        utc!(action["at"], "action clock")
        base = %{kind: kind, order: action["order"], at: action["at"]}

        if lane == :deterministic_conformance,
          do:
            Map.merge(base, %{
              command: command!(action["command"], kind, action["at"]),
              expected_transition: transition!(action["expected_transition"], kind)
            }),
          else: base
      end)

    ordered_actions?(parsed) || raise ArgumentError, "unordered actions"
    parsed
  end

  defp actions!(_, _), do: raise(ArgumentError, "missing actions")

  # One family selects one exact key inventory. The fixture is input only: it
  # cannot name an observation default, reducer output, or executable callback.
  defp command!(%{"kind" => kind, "payload" => payload}, kind, at) when is_map(payload) do
    keys = payload_keys(kind)
    require_keys!(payload, keys, "#{kind} payload")
    payload["clock"] == at || raise ArgumentError, "command clock mismatch"
    valid_id?(payload["account_ref"]) || raise ArgumentError, "invalid command account reference"
    normalized = Enum.into(payload, %{}, fn {k, v} -> {String.to_atom(k), v} end)
    validate_payload!(kind, normalized)
    %Command{kind: kind, payload: normalize_payload(normalized)}
  end

  defp command!(_, _, _), do: raise(ArgumentError, "invalid command")
  defp payload_keys(kind), do: action_family!(kind)

  defp validate_payload!(kind, p) do
    utc!(p.clock, "command clock")

    if kind == "durable_interruption" do
      (p.interruption_hook in ["after_admission", "after_issuance_commit"] and
         valid_id?(p.request_ref) and valid_resume_operation?(p)) ||
        raise ArgumentError, "invalid durable_interruption payload"
    else
      if kind == "resume_delivery" do
        valid_id?(p.request_ref) || raise ArgumentError, "invalid resume_delivery payload"
      else
        if kind in @observation_kinds and
             kind not in [
               "apple_verified_purchase",
               "stripe_verified_purchase",
               "grant_observation",
               "refund_observation",
               "stripe_retraction"
             ] do
          valid_ordering_schedule!(kind, p)
        else
          if kind == "device_replace" do
            (Enum.all?(
               @device_replace_payload_keys -- ~w(clock prior_transition reason),
               fn key ->
                 valid_id?(Map.fetch!(p, String.to_atom(key)))
               end
             ) and p.prior_transition in ["superseded", "revoked"] and
               ((p.prior_transition == "superseded" and p.reason == "planned_replacement") or
                  (p.prior_transition == "revoked" and p.reason == "lost_or_compromised"))) ||
              raise ArgumentError, "invalid device_replace payload"
          else
            if kind not in @read_kinds do
              (p.rail in ["apple", "stripe", :apple, :stripe] and
                 p.environment in ["production", "sandbox", :production, :sandbox] and
                 Enum.all?(
                   @operation_keys --
                     ~w(rail environment provider_order offline_vector offline_action),
                   &valid_id?(Map.fetch!(p, String.to_atom(&1)))
                 ) and is_integer(p.provider_order) and p.provider_order > 0 and
                 offline_context_valid?(kind, p)) ||
                raise ArgumentError, "invalid #{kind} payload"
            end
          end
        end
      end
    end
  end

  defp valid_resume_operation?(p) do
    p.rail in ["apple", "stripe", :apple, :stripe] and
      p.environment in ["production", "sandbox", :production, :sandbox] and
      Enum.all?(
        @operation_keys -- ~w(rail environment provider_order offline_vector offline_action),
        &valid_id?(Map.fetch!(p, String.to_atom(&1)))
      ) and is_integer(p.provider_order) and p.provider_order > 0
  end

  defp valid_ordering_schedule!(kind, p) do
    deliveries = Map.fetch!(p, :deliveries)

    (is_list(deliveries) and deliveries != [] and
       Enum.all?(deliveries, &valid_ordering_delivery?/1)) ||
      raise ArgumentError, "invalid #{kind} deliveries"

    case kind do
      "equal_order_delivery" ->
        permutations = Map.fetch!(p, :permutations)

        (is_list(permutations) and permutations != [] and
           Enum.all?(permutations, &valid_permutation?(&1, length(deliveries)))) ||
          raise ArgumentError, "invalid equal_order_delivery permutations"

      "repeat_delivery" ->
        (is_integer(p.repeat_count) and p.repeat_count > 1) ||
          raise ArgumentError, "invalid repeat_delivery count"

      "parallel_delivery" ->
        workers = Map.fetch!(p, :workers)

        (is_list(workers) and length(workers) > 1 and
           Enum.all?(workers, &valid_delivery_index?(&1, length(deliveries)))) ||
          raise ArgumentError, "invalid parallel_delivery workers"
    end
  end

  defp valid_ordering_delivery?(delivery) when is_map(delivery) do
    keys = ["clock" | @operation_keys -- ~w(offline_vector offline_action)]

    Map.keys(delivery) |> Enum.map(&to_string/1) |> Enum.sort() == Enum.sort(keys) and
      field(delivery, :rail) in ["apple", "stripe", :apple, :stripe] and
      field(delivery, :environment) in ["production", "sandbox", :production, :sandbox] and
      Enum.all?(@operation_keys -- ~w(rail environment offline_vector offline_action), fn key ->
        value = field(delivery, String.to_atom(key))
        if key == "provider_order", do: is_integer(value) and value > 0, else: valid_id?(value)
      end) and utc?(field(delivery, :clock))
  end

  defp valid_ordering_delivery?(_), do: false
  defp valid_delivery_index?(index, count), do: is_integer(index) and index >= 0 and index < count

  defp valid_permutation?(indexes, count) when is_list(indexes),
    do: Enum.sort(indexes) == Enum.to_list(0..(count - 1))

  defp valid_permutation?(_, _), do: false
  defp field(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp offline_context_valid?(kind, p) when kind in @offline_context_kinds,
    do:
      valid_id?(p.offline_vector) and
        p.offline_action in [
          "read_downloaded_lesson",
          "download_lesson",
          :read_downloaded_lesson,
          :download_lesson
        ]

  defp offline_context_valid?(_kind, p),
    do: not Map.has_key?(p, :offline_vector) and not Map.has_key?(p, :offline_action)

  defp normalize_payload(%{deliveries: deliveries} = payload) do
    %{payload | deliveries: Enum.map(deliveries, &normalize_delivery/1)}
  end

  defp normalize_payload(
         %{rail: rail, environment: environment, offline_action: action} = payload
       ) do
    %{
      payload
      | rail: source_atom!(rail),
        environment: environment_atom!(environment),
        offline_action: offline_action_atom!(action)
    }
  end

  defp normalize_payload(payload), do: payload

  defp normalize_delivery(delivery) do
    delivery
    |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)
    |> Map.update!(:rail, &source_atom!/1)
    |> Map.update!(:environment, &environment_atom!/1)
  end

  defp transition!(
         %{
           "kind" => kind,
           "seam" => seam,
           "result" => result,
           "durable" => durable,
           "cache" => cache
         },
         kind
       )
       when kind != "device_replace" and is_map(result) and is_map(durable) and is_map(cache) do
    require_keys!(result, ~w(tag disposition), "expected transition result")

    require_keys!(
      durable,
      ~w(state observation_kind snapshot_revision),
      "expected transition durable"
    )

    require_keys!(cache, ~w(disposition), "expected transition cache")
    seam in transition_seams(kind) || raise ArgumentError, "invalid expected transition seam"

    (result["tag"] == "executed" and result["disposition"] == kind) ||
      raise ArgumentError, "invalid expected transition result"

    (durable["state"] in ["observed", "unchanged"] and
       durable["observation_kind"] in ["grant", "retract", "none"] and
       is_integer(durable["snapshot_revision"]) and durable["snapshot_revision"] >= 0) ||
      raise ArgumentError, "invalid expected transition durable"

    cache["disposition"] in ["replace", "preserve", "none"] ||
      raise ArgumentError, "invalid expected transition cache"

    %ExpectedTransition{
      kind: kind,
      seam: seam,
      result: atomize(result),
      durable: atomize(durable),
      cache: atomize(cache)
    }
  end

  defp transition!(
         %{
           "kind" => "device_replace",
           "seam" => "offline_replace_device",
           "result" => result,
           "durable" => durable,
           "cache" => cache
         },
         "device_replace"
       ) do
    require_keys!(
      result,
      ~w(tag disposition prior_state replacement_state),
      "device replacement result"
    )

    require_keys!(
      durable,
      ~w(prior_device_count replacement_device_count prior_state replacement_state challenge_consumed audit_type audit_delta snapshot_revision),
      "device replacement durable"
    )

    require_keys!(cache, ~w(prior replacement), "device replacement cache")

    (result == %{
       "tag" => "replaced",
       "disposition" => "replaced",
       "prior_state" => durable["prior_state"],
       "replacement_state" => durable["replacement_state"]
     } and durable["prior_device_count"] == 1 and durable["replacement_device_count"] == 1 and
       durable["prior_state"] in ["superseded", "revoked"] and
       durable["replacement_state"] == "active" and durable["challenge_consumed"] == true and
       durable["audit_type"] == "entitlements.offline.device_replaced" and
       durable["audit_delta"] == 1 and is_integer(durable["snapshot_revision"]) and
       cache == %{
         "prior" => "server_reject_on_next_contact",
         "replacement" => "reconnect_required"
       }) || raise ArgumentError, "invalid device replacement transition"

    %ExpectedTransition{
      kind: "device_replace",
      seam: "offline_replace_device",
      result: atomize(result),
      durable: atomize(durable),
      cache: atomize(cache)
    }
  end

  defp transition!(_, _), do: raise(ArgumentError, "invalid expected transition")

  defp atomize(map), do: Enum.into(map, %{}, fn {k, v} -> {String.to_atom(k), v} end)

  defp transition_seams(kind) when kind in @observation_kinds,
    do: ["observation_projector", "apple_admission"]

  defp transition_seams("resume_delivery"), do: ["offline_reconnect"]
  defp transition_seams("expiry_boundary"), do: ["snapshot"]
  defp transition_seams(kind) when kind in @read_kinds, do: ["snapshot", "offline_verify_cache"]
  defp transition_seams("purchase_preflight"), do: ["purchase_decision"]

  defp transition_seams(kind) when kind in @offline_kinds,
    do: ["offline_verify_policy", "offline_verify"]

  defp transition_seams(kind)
       when kind in ["reconnect_request", "durable_interruption"],
       do: ["offline_reconnect"]

  defp transition_seams("device_replace"), do: ["offline_register_device"]
  defp transition_seams("rotated_key_proof"), do: ["verification_key_retention"]
  defp transition_seams(_), do: []

  defp expected!(%{
         "snapshot" => s,
         "purchase" => p,
         "offline_policy" => o,
         "audit_count" => count
       }) do
    require_keys!(s, ~w(revision plans sources), "snapshot")
    require_keys!(p, ~w(status reason), "purchase")
    require_keys!(o, ~w(action), "offline policy")

    (is_integer(s["revision"]) and s["revision"] >= 0 and is_list(s["plans"]) and
       Enum.all?(s["plans"], &valid_id?/1) and is_list(s["sources"]) and
       Enum.all?(s["sources"], &(&1 in ["stripe", "apple"])) and
       p["status"] in ["eligible", "warn", "block"] and is_binary(p["reason"]) and
       o["action"] in ["allow_downloaded_study", "reconnect_required", "deny"] and
       is_integer(count) and count >= 0) || raise ArgumentError, "invalid expected"

    %Expected{
      snapshot: %Snapshot{
        revision: s["revision"],
        plans: s["plans"],
        sources: Enum.map(s["sources"], &source_atom!/1)
      },
      purchase: %Purchase{status: status_atom!(p["status"]), reason: p["reason"]},
      offline_policy: %OfflinePolicy{action: offline_policy_atom!(o["action"])},
      audit_count: count
    }
  end

  defp expected!(_), do: raise(ArgumentError, "expected must be an object")

  defp artifacts!(xs) when is_list(xs) and xs != [] do
    (Enum.all?(xs, &(&1 in @artifact_names)) and xs == Enum.uniq(xs)) ||
      raise(ArgumentError, "invalid artifacts")

    xs
  end

  defp artifacts!(_), do: raise(ArgumentError, "invalid artifacts")

  defp diagnostic!(m) when is_map(m) and map_size(m) > 0 do
    Enum.all?(m, fn {k, v} -> is_binary(k) and is_binary(v) and byte_size(v) <= 80 end) ||
      raise(ArgumentError, "unsafe diagnostic")

    m
  end

  defp diagnostic!(_), do: raise(ArgumentError, "missing diagnostic")
  defp valid_expected?(%Expected{}), do: true
  defp valid_expected?(_), do: false

  defp valid_commands?(actions) do
    Enum.all?(actions, fn
      %{kind: kind, command: %Command{kind: command_kind, payload: payload}}
      when is_map(payload) ->
        kind == command_kind and
          Map.keys(payload) |> Enum.sort() ==
            payload_keys(kind) |> Enum.map(&String.to_atom/1) |> Enum.sort() and
          try do
            validate_payload!(kind, payload)
            true
          rescue
            ArgumentError -> false
          end

      %{command: nil} ->
        true

      %{command: %Command{}} ->
        false

      _ ->
        true
    end)
  end

  defp lane_artifacts_valid?(:deterministic_conformance, xs),
    do: "v1.59-decision-cases.json" in xs and "capability-report.json" not in xs

  defp lane_artifacts_valid?(:runtime_capability, xs), do: xs == ["capability-report.json"]
  defp lane_artifacts_valid?(:advisory_parity, xs), do: is_list(xs) and xs != []
  defp safe_diagnostic?(m), do: is_map(m) and map_size(m) > 0

  defp ordered_actions?(actions),
    do:
      Enum.map(actions, & &1.order) == Enum.to_list(1..length(actions)) and
        Enum.all?(actions, fn a ->
          a.kind in @action_kinds and utc?(a.at) and
            (not Map.has_key?(a, :command) or
               (a.command.kind == a.kind and a.expected_transition.kind == a.kind))
        end)

  defp valid_id?(x), do: is_binary(x) and x =~ ~r/^[a-z0-9_]{3,80}$/
  defp source_atom!("stripe"), do: :stripe
  defp source_atom!("apple"), do: :apple
  defp environment_atom!("production"), do: :production
  defp environment_atom!("sandbox"), do: :sandbox
  defp offline_action_atom!("read_downloaded_lesson"), do: :read_downloaded_lesson
  defp offline_action_atom!("download_lesson"), do: :download_lesson
  defp status_atom!("eligible"), do: :eligible
  defp status_atom!("warn"), do: :warn
  defp status_atom!("block"), do: :block
  defp offline_policy_atom!("allow_downloaded_study"), do: :allow_downloaded_study
  defp offline_policy_atom!("reconnect_required"), do: :reconnect_required
  defp offline_policy_atom!("deny"), do: :deny
  defp lane!(x) when x in @lanes, do: String.to_existing_atom(x)
  defp lane!(_), do: raise(ArgumentError, "invalid evidence lane")
  defp utc?(x), do: is_binary(x) and match?({:ok, _, 0}, DateTime.from_iso8601(x))
  defp utc!(x, n), do: if(utc?(x), do: x, else: raise(ArgumentError, "invalid #{n}"))

  defp require_keys!(m, keys, name) when is_map(m),
    do:
      Map.keys(m) |> Enum.sort() == Enum.sort(keys) ||
        raise(ArgumentError, "unknown or missing #{name} fields")

  defp require_keys!(_, _, name), do: raise(ArgumentError, "#{name} must be an object")

  defp reject_duplicate_keys!(json) do
    {:ok, value} = Jason.decode(json, objects: :ordered_objects)
    duplicate_free?(value) || raise ArgumentError, "duplicate JSON key"
  end

  defp duplicate_free?(%Jason.OrderedObject{values: values}),
    do:
      length(values) == MapSet.size(MapSet.new(Enum.map(values, &elem(&1, 0)))) and
        Enum.all?(values, fn {_, v} -> duplicate_free?(v) end)

  defp duplicate_free?(xs) when is_list(xs), do: Enum.all?(xs, &duplicate_free?/1)
  defp duplicate_free?(m) when is_map(m), do: Enum.all?(m, fn {_, v} -> duplicate_free?(v) end)
  defp duplicate_free?(_), do: true
end
