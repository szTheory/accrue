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
end
