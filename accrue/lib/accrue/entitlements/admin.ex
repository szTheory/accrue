defmodule Accrue.Entitlements.Admin do
  @moduledoc """
  Internal read-only diagnostic seam for the `accrue_admin` entitlements tab
  (ENT-11).

  NOT a public gate API — there is no boolean `entitled?`-style surface here.
  `fetch_entitled/2` is closed and will-not-build: a Stripe-backed predicate
  makes authorization depend on a network call that can fail open under
  partition, while `Accrue.Entitlements.StripeSync.summary_for_customer/1` and
  `resolve_for_customer/1` already provide diagnostic observation. This module answers the
  operator question *"what does the resolver currently grant this customer, and
  what entitling `price_id`s is it silently discarding?"* by returning a
  `{resolved, unmapped_price_ids}` pair — never a grant/deny decision.

  ## One-way dependency

  `admin → billing/entitlements core`, never the reverse. Nothing under
  `Accrue.Billing` or the resolver references this module; it only reads through
  the resolver's SSOT fold.

  ## Resolver scope

  Hard-codes the default `Accrue.Entitlements.Resolver.LocalMap` resolver. The
  diagnostic re-derives the structurally-discarded unmapped drift, which is a
  property of the local plan→`price_id` catalog; custom resolvers are out of
  scope for this read-only diagnostic.

  ## Why a `{resolved, unmapped}` pair

  The resolver drops unmapped entitling `price_id`s under `:deny`
  (`Accrue.Entitlements.Resolver.LocalMap` `handle_unmapped/3`), so the resolved
  map can NEVER surface drift. `unmapped_entitling_price_ids/1` re-reads the
  customer's entitling items independently and returns only the `price_id`s the
  catalog does not map — the operator's drift signal.
  """

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Device, Observation, Snapshot}
  alias Accrue.Entitlements.Offline.ReconnectAttempt
  alias Accrue.Entitlements.Resolver.LocalMap
  alias Accrue.Entitlements.StripeSync

  @doc """
  Returns `{resolved, unmapped_price_ids}` for `customer`:

    * `resolved` — the resolver's SSOT fold (`active_plans`, `features`,
      `quantities`, and the grace sets), reusing `LocalMap.fold_for_customer/1`
      (no re-implemented fold), and
    * `unmapped_price_ids` — the entitling `price_id`s the resolver structurally
      discards under `:deny`, via `LocalMap.unmapped_entitling_price_ids/1`.
  """
  @spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
          {resolved :: map(), unmapped_price_ids :: [String.t()]}
  def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
    {LocalMap.fold_for_customer(customer), LocalMap.unmapped_entitling_price_ids(customer)}
  end

  @doc false
  @spec diagnostic_for_customer(Accrue.Billing.Customer.t()) :: %{
          local:
            {:ok, %{resolved: map(), unmapped_price_ids: [String.t()]}} | {:error, :unavailable},
          stripe_advisory: map()
        }
  def diagnostic_for_customer(%Accrue.Billing.Customer{} = customer) do
    %{
      local: safe_local_diagnostic(customer),
      stripe_advisory: safe_stripe_advisory_diagnostic(customer)
    }
  end

  @doc """
  Returns the closed, read-only diagnostic for one already-authorized entitlement
  account. The host is responsible for resolving and authorizing `account` before
  it reaches this seam; this function deliberately never provisions an account,
  calls a provider, queues work, or records an audit event.

  The result is a support contract, not an explorer: it contains only normalized
  states, bounded ages, and a stable opaque correlation. Raw observations,
  account ownership, device identifiers, proof material, queue data, and provider
  responses are intentionally excluded.
  """
  @spec diagnostic_for_account(Account.t(), keyword()) ::
          {:ok, map()} | {:error, :not_found | :unavailable}
  def diagnostic_for_account(account, opts \\ [])

  def diagnostic_for_account(%Account{id: account_id}, opts) when is_binary(account_id) do
    repo = Keyword.get(opts, :repo, Accrue.Repo.repo())
    now = Keyword.get(opts, :now, DateTime.utc_now())

    case repo.get(Account, account_id) do
      %Account{} = account ->
        snapshot = Snapshot.fetch(repo, account)

        observations =
          repo.all(from(observation in Observation, where: observation.account_id == ^account.id))

        devices = repo.all(from(device in Device, where: device.account_id == ^account.id))

        attempts =
          repo.all(
            from(attempt in ReconnectAttempt,
              where: attempt.account_id == ^account.id,
              order_by: [desc: attempt.inserted_at],
              limit: 1
            )
          )

        {:ok, closed_diagnostic(account, snapshot, observations, devices, attempts, now)}

      nil ->
        {:error, :not_found}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def diagnostic_for_account(_, _opts), do: {:error, :not_found}

  defp safe_local_diagnostic(customer) do
    {resolved, unmapped_price_ids} = resolve_for_customer(customer)
    {:ok, %{resolved: resolved, unmapped_price_ids: unmapped_price_ids}}
  rescue
    _ -> {:error, :unavailable}
  end

  defp safe_stripe_advisory_diagnostic(customer) do
    if Accrue.Config.stripe_native_sync?() do
      customer |> StripeSync.summary_for_customer() |> normalize_advisory()
    else
      disabled_advisory()
    end
  rescue
    _ -> unavailable_advisory()
  end

  defp disabled_advisory, do: advisory(:disabled)
  defp not_observed_advisory, do: advisory(:not_observed)
  defp unavailable_advisory, do: advisory(:unavailable)

  defp normalize_advisory(nil), do: not_observed_advisory()

  defp normalize_advisory(summary) do
    with {:ok, keys} <- lookup_keys(summary.data) do
      observed_at = observed_at_for(summary)
      source = source_for(summary)
      completeness = completeness_for(summary)

      advisory(state_for(summary),
        lookup_keys: keys,
        entitlement_count: entitlement_count_for(summary, keys),
        observed_at: observed_at,
        source: source,
        completeness: completeness
      )
    else
      :error -> unavailable_advisory()
    end
  end

  defp lookup_keys(%{"entitlements" => %{"data" => data}}) when is_list(data) do
    keys = Enum.map(data, &lookup_key/1)

    if Enum.all?(keys, &is_binary/1), do: {:ok, Enum.sort(keys)}, else: :error
  end

  defp lookup_keys(_), do: :error

  defp lookup_key(%{"lookup_key" => key}) when is_binary(key), do: key
  defp lookup_key(_), do: nil

  defp state_for(%{synced_at: synced_at}) when not is_struct(synced_at, DateTime),
    do: :age_unknown

  defp state_for(%{truncated: true}), do: :incomplete
  defp state_for(_summary), do: :recorded

  defp observed_at_for(%{synced_at: %DateTime{} = observed_at}), do: observed_at
  defp observed_at_for(_summary), do: nil

  defp source_for(%{data: %{"_accrue" => %{"source" => "pull"}}}), do: :pull

  defp source_for(%{last_stripe_event_ts: %DateTime{}, last_stripe_event_id: event_id})
       when is_binary(event_id) and byte_size(event_id) > 0,
       do: :webhook

  defp source_for(_summary), do: :unavailable

  defp completeness_for(%{truncated: true}), do: :incomplete
  defp completeness_for(_summary), do: :complete

  defp entitlement_count_for(%{entitlement_count: count}, _keys)
       when is_integer(count) and count >= 0,
       do: count

  defp entitlement_count_for(_summary, keys), do: length(keys)

  defp advisory(state, attrs \\ []) do
    lookup_keys = Keyword.get(attrs, :lookup_keys, [])
    entitlement_count = Keyword.get(attrs, :entitlement_count, 0)
    observed_at = Keyword.get(attrs, :observed_at)
    source = Keyword.get(attrs, :source, :unavailable)
    completeness = Keyword.get(attrs, :completeness, :unknown)

    %{
      state: state,
      entitlement_count: entitlement_count,
      lookup_keys: lookup_keys,
      observed_at: observed_at,
      source: source,
      completeness: completeness,
      raw: %{
        "lookup_keys" => lookup_keys,
        "entitlement_count" => entitlement_count,
        "observed_at" => if(observed_at, do: DateTime.to_iso8601(observed_at)),
        "source" => Atom.to_string(source),
        "completeness" => Atom.to_string(completeness)
      }
    }
  end

  defp closed_diagnostic(account, %Snapshot{} = snapshot, observations, devices, attempts, now) do
    provider = provider_summary(observations, now)
    recovery = recovery_summary(observations, attempts, now)

    %{
      account: %{
        state: :available,
        revision: snapshot.revision,
        correlation: correlation(account.id)
      },
      snapshot: %{
        state: snapshot_state(snapshot),
        revision: snapshot.revision,
        plans: Enum.map(snapshot.plans, &Atom.to_string/1),
        source_count: length(snapshot.sources)
      },
      sources: Enum.map(snapshot.sources, &safe_source(&1, now)),
      provider: provider,
      eligibility: eligibility_summary(snapshot),
      devices: device_summary(devices, now),
      recovery: recovery,
      next_action: next_action(snapshot, provider, recovery)
    }
  end

  defp snapshot_state(%Snapshot{authorization_bounds: bounds})
       when bounds in [:stale, :repairing, :ambiguous],
       do: bounds

  defp snapshot_state(_), do: :available

  defp safe_source(source, now) do
    %{
      rail: source.rail,
      environment: source.environment,
      provenance: :canonical_projection,
      age_seconds: age_seconds(source.effective_at, now)
    }
  end

  defp provider_summary([], _now), do: %{state: :not_observed, age_seconds: nil}

  defp provider_summary(observations, now) do
    latest = Enum.max_by(observations, & &1.observed_at, DateTime)

    %{
      state: provider_state(latest.state),
      age_seconds: age_seconds(latest.observed_at, now)
    }
  end

  defp provider_state(:quarantined), do: :quarantined
  defp provider_state(:retrying), do: :retrying
  defp provider_state(:qualified), do: :available
  defp provider_state(:received), do: :pending
  defp provider_state(_), do: :unavailable

  defp eligibility_summary(%Snapshot{authorization_bounds: state})
       when state in [:stale, :repairing, :ambiguous] do
    %{
      state: :blocked,
      reason: String.to_existing_atom("#{state}_snapshot"),
      next_action: :review_access
    }
  end

  defp eligibility_summary(_),
    do: %{state: :unknown, reason: :not_requested, next_action: :review_access}

  defp device_summary([], _now), do: %{state: :not_registered, count: 0, proof_horizon: :unknown}

  defp device_summary(devices, now) do
    active = Enum.count(devices, &(&1.state == :active))

    %{
      state: if(active > 0, do: :available, else: :needs_attention),
      count: length(devices),
      proof_horizon: proof_horizon(devices, now)
    }
  end

  defp proof_horizon(devices, now) do
    case devices |> Enum.map(& &1.last_seen_at) |> Enum.reject(&is_nil/1) |> Enum.max(DateTime) do
      nil -> :unknown
      seen_at -> if(age_seconds(seen_at, now) <= 30 * 86_400, do: :recent, else: :stale)
    end
  end

  defp recovery_summary(observations, [%ReconnectAttempt{} = attempt], now) do
    %{
      state: recovery_state(attempt.state, observations),
      retry_state: retry_state(attempt.state),
      age_seconds: age_seconds(attempt.updated_at, now)
    }
  end

  defp recovery_summary(observations, [], _now) do
    %{
      state:
        if(Enum.any?(observations, &(&1.state == :quarantined)), do: :needs_repair, else: :clear),
      retry_state:
        if(Enum.any?(observations, &(&1.state == :retrying)), do: :scheduled, else: :none),
      age_seconds: nil
    }
  end

  defp recovery_state(:needs_repair, _), do: :needs_repair
  defp recovery_state(:retrying, _), do: :retrying

  defp recovery_state(_, observations),
    do: if(Enum.any?(observations, &(&1.state == :quarantined)), do: :needs_repair, else: :clear)

  defp retry_state(state) when state in [:admitted, :running, :retrying], do: :scheduled
  defp retry_state(_), do: :none

  defp next_action(_snapshot, %{state: :quarantined}, _recovery), do: :review_access
  defp next_action(_snapshot, _provider, %{state: :needs_repair}), do: :review_access

  defp next_action(%Snapshot{authorization_bounds: state}, _provider, _recovery)
       when state in [:stale, :repairing, :ambiguous], do: :review_access

  defp next_action(_, _, _), do: :review_access

  defp age_seconds(%DateTime{} = timestamp, %DateTime{} = now),
    do: max(DateTime.diff(now, timestamp, :second), 0)

  defp age_seconds(_, _), do: nil

  defp correlation(account_id) do
    account_id
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 16)
  end
end
