defmodule Accrue.Entitlements.ReferenceScenarioExecutor.OfflinePolicy do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Entitlements.{Grant, Offline, Observation}
  alias Accrue.Events.Event

  @fixture Path.expand("../../../../priv/entitlements/v1.59-offline-golden-vectors.json", __DIR__)

  def execute(repo, account, %{kind: kind, command: %{payload: payload}})
      when kind in ["offline_proof_stale", "offline_expansion_request", "signed_deny", "rollback_proof", "empty_evidence"] do
    before = counts(repo, account.id)
    vector = vector_for!(kind, payload.offline_vector)
    compact = if(kind == "empty_evidence", do: "", else: vector["compact_jws"])
    context = verification_context(vector)

    {:ok, decision} = Offline.verify(compact, context)
    policy = Offline.action_policy(decision, requested_action!(kind, payload.offline_action))
    after_counts = counts(repo, account.id)

    %{
      result: decision_facts(decision),
      policy: policy_facts(policy),
      durable: Map.merge(after_counts, %{write_delta: write_delta(before, after_counts)}),
      cache: %{disposition: "preserve"}
    }
  end

  defp vector_for!("offline_proof_stale", _), do: vector!("stale_at_freshness")
  defp vector_for!("offline_expansion_request", _), do: vector!("stale_at_freshness")
  defp vector_for!("signed_deny", _), do: vector!("valid_signed_denial")
  defp vector_for!("rollback_proof", _), do: vector!("clock_rollback")
  defp vector_for!("empty_evidence", _), do: vector!("valid_signed_denial")

  defp requested_action!("offline_expansion_request", "download_lesson"), do: :download_premium
  defp requested_action!("offline_expansion_request", :download_lesson), do: :download_premium
  defp requested_action!(_, action) when is_atom(action), do: action

  defp vector!(id) do
    @fixture
    |> File.read!()
    |> Jason.decode!()
    |> Map.fetch!("vectors")
    |> Enum.find(&(&1["id"] == id))
    |> case do
      nil -> raise ArgumentError, "missing offline golden vector: #{id}"
      vector -> vector
    end
  end

  defp verification_context(vector) do
    vector["verification_context"]
    |> Map.put("public_keys", fixture_keys())
    |> Map.new(fn {key, value} -> {context_key!(key), context_value(key, value)} end)
  end

  defp fixture_keys do
    @fixture |> File.read!() |> Jason.decode!() |> get_in(["public_jwks", "keys"])
  end

  defp context_key!(key) do
    %{
      "issuer" => :issuer,
      "audience" => :audience,
      "account_subject" => :account_subject,
      "installation_id" => :installation_id,
      "device_thumbprint" => :device_thumbprint,
      "now" => :now,
      "clock_high_water" => :clock_high_water,
      "accepted_revision" => :accepted_revision,
      "accepted_disposition" => :accepted_disposition,
      "accepted_iat" => :accepted_iat,
      "accepted_fresh_until" => :accepted_fresh_until,
      "public_keys" => :public_keys
    }
    |> Map.fetch!(key)
  end

  defp context_value("accepted_disposition", value) when is_binary(value),
    do: String.to_existing_atom(value)

  defp context_value("clock_high_water", value) when is_map(value),
    do: Map.new(value, fn {key, item} -> {String.to_existing_atom(key), item} end)

  defp context_value(_, value), do: value

  defp decision_facts(decision) do
    %{
      state: Atom.to_string(decision.state),
      reason: Atom.to_string(decision.reason),
      next_action: Atom.to_string(decision.next_action),
      revision: decision.claims && decision.claims.revision,
      claims: claims_facts(decision.claims)
    }
  end

  defp claims_facts(nil), do: %{}

  defp claims_facts(claims),
    do: %{plans: claims.plans, features: claims.features, quantities: claims.quantities}

  defp policy_facts(policy) do
    %{
      action: policy.action,
      allowed: policy.allowed,
      reason: policy_reason(policy),
      next_action: Atom.to_string(policy.next_action)
    }
  end

  defp policy_reason(%{allowed: true, guidance_key: :stale_offline}), do: "allow_downloaded_study"
  defp policy_reason(%{allowed: false, next_action: :reconnect_required}), do: "reconnect_required"
  defp policy_reason(%{allowed: false, next_action: next_action}), do: Atom.to_string(next_action)
  defp policy_reason(_), do: "allowed"

  defp counts(repo, account_id) do
    %{
      observations: repo.aggregate(from(o in Observation, where: o.account_id == ^account_id), :count, :id),
      grants: repo.aggregate(from(g in Grant, where: g.account_id == ^account_id), :count, :id),
      audits: repo.aggregate(from(e in Event, where: e.subject_id == ^account_id), :count, :id)
    }
  end

  defp write_delta(before, after_counts),
    do: after_counts.observations + after_counts.grants + after_counts.audits - before.observations - before.grants - before.audits
end
