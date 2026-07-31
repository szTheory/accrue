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
          local: {:ok, %{resolved: map(), unmapped_price_ids: [String.t()]}} | {:error, :unavailable},
          stripe_advisory: map()
        }
  def diagnostic_for_customer(%Accrue.Billing.Customer{} = customer) do
    %{
      local: local_diagnostic(customer),
      stripe_advisory: stripe_advisory_diagnostic(customer)
    }
  end

  defp local_diagnostic(customer) do
    {resolved, unmapped_price_ids} = resolve_for_customer(customer)
    {:ok, %{resolved: resolved, unmapped_price_ids: unmapped_price_ids}}
  rescue
    _ -> {:error, :unavailable}
  end

  defp stripe_advisory_diagnostic(customer) do
    if Accrue.Config.stripe_native_sync?() do
      customer |> StripeSync.summary_for_customer() |> normalize_advisory()
    else
      %{state: :disabled, lookup_keys: [], entitlement_count: 0, raw: %{}}
    end
  rescue
    _ -> %{state: :unavailable, lookup_keys: [], entitlement_count: 0, raw: %{}}
  end

  defp normalize_advisory(nil),
    do: %{state: :not_observed, lookup_keys: [], entitlement_count: 0, raw: %{}}

  defp normalize_advisory(summary) do
    keys = lookup_keys(summary.data)
    synced_at = summary.synced_at
    source = source_for(summary.data)
    completeness = completeness_for(summary)

    %{
      state: :recorded,
      lookup_keys: keys,
      entitlement_count: summary.entitlement_count || length(keys),
      synced_at: synced_at,
      source: source,
      completeness: completeness,
      raw: %{
        "lookup_keys" => keys,
        "entitlement_count" => summary.entitlement_count || length(keys),
        "synced_at" => if(synced_at, do: DateTime.to_iso8601(synced_at)),
        "source" => Atom.to_string(source),
        "completeness" => Atom.to_string(completeness)
      }
    }
  end

  defp lookup_keys(data) do
    data
    |> get_in(["entitlements", "data"])
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "lookup_key"))
    |> Enum.filter(&is_binary/1)
    |> Enum.sort()
  end

  defp source_for(%{"_accrue" => %{"source" => "pull"}}), do: :pull
  defp source_for(_data), do: :unavailable

  defp completeness_for(%{truncated: true}), do: :incomplete
  defp completeness_for(_summary), do: :complete
end
