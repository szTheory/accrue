defmodule Accrue.Entitlements.Snapshot do
  @moduledoc """
  A deterministic, privacy-bounded view of an account's effective grants.

  The snapshot is derived from current grant rows; it is never persisted and
  never contains provider evidence or lineage identifiers.
  """

  alias Accrue.Entitlements.Grant

  @enforce_keys [:account_id, :revision, :plans, :features, :quantities, :sources]
  defstruct [
    :account_id,
    :revision,
    :plans,
    :features,
    :quantities,
    :sources,
    :authorization_bounds
  ]

  @type source :: %{
          required(:rail) => atom(),
          required(:environment) => atom(),
          required(:logical_plan) => atom(),
          required(:effective_at) => DateTime.t(),
          optional(:expires_at) => DateTime.t() | nil,
          optional(:revoked_at) => DateTime.t() | nil
        }
  @type t :: %__MODULE__{
          account_id: Ecto.UUID.t() | String.t(),
          revision: non_neg_integer(),
          plans: [atom()],
          features: [atom()],
          quantities: %{optional(atom()) => pos_integer()},
          sources: [source()]
        }

  @spec from_grants([Grant.t() | map()], keyword()) :: t()
  def from_grants(grants, opts) when is_list(grants) and is_list(opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    catalog = Keyword.get(opts, :catalog, catalog())

    {plans, features, quantities, sources, authorization_bounds} =
      grants
      |> Enum.filter(&live?(&1, now))
      |> Enum.reduce({MapSet.new(), MapSet.new(), %{}, MapSet.new(), %{}}, fn grant, acc ->
        fold_grant(grant, catalog, acc)
      end)

    %__MODULE__{
      account_id: Keyword.fetch!(opts, :account_id),
      revision: Keyword.get(opts, :revision, 0),
      plans: plans |> MapSet.to_list() |> Enum.sort(),
      features: features |> MapSet.to_list() |> Enum.sort(),
      quantities: quantities,
      sources:
        sources
        |> MapSet.to_list()
        |> Enum.sort_by(
          &{&1.rail, &1.environment, &1.logical_plan, &1.effective_at, &1.expires_at,
           &1.revoked_at}
        ),
      authorization_bounds: authorization_bounds
    }
  end

  @doc "Fetches and folds an account's current grants without mutating state."
  @spec fetch(Ecto.Repo.t(), map() | Ecto.UUID.t(), keyword()) :: t() | nil
  def fetch(repo, account, opts \\ [])
  def fetch(repo, %{id: account_id, revision: revision}, opts), do: fetch(repo, account_id, revision, opts)
  def fetch(repo, account_id, opts) when is_binary(account_id), do: fetch(repo, account_id, nil, opts)

  @doc "The material authorization fields used for monotonic revision decisions."
  @spec authorization_signature(t()) :: term()
  def authorization_signature(%__MODULE__{} = snapshot) do
    # Sources explain *why* access exists, but they are diagnostic provenance.
    # Revisions track only the effective authorization presented to consumers.
    {snapshot.plans, snapshot.features, snapshot.quantities,
     normalize_authorization_bounds(snapshot.authorization_bounds)}
  end

  defp normalize_authorization_bounds(bounds) when is_map(bounds), do: bounds
  defp normalize_authorization_bounds(_), do: %{}

  defp fetch(repo, account_id, revision, opts) do
    import Ecto.Query

    revision =
      case repo.one(
             from(account in Accrue.Entitlements.Account, where: account.id == ^account_id)
           ) do
        %{revision: current_revision} -> current_revision
        nil -> revision || 0
      end

    grants =
      repo.all(
        from(grant in Grant,
          where: grant.account_id == ^account_id and is_nil(grant.superseded_at)
        )
      )

    from_grants(grants, account_id: account_id, revision: revision, now: Keyword.get_lazy(opts, :now, &DateTime.utc_now/0))
  end

  defp fold_grant(grant, catalog, {plans, features, quantities, sources, authorization_bounds}) do
    case Map.get(catalog, product_key(grant)) || Map.get(catalog, grant.provider_product_id) ||
           legacy_product(grant, catalog) do
      nil ->
        {plans, features, quantities, sources, authorization_bounds}

      %{plan: plan} = product ->
        quota_values = Map.get(product, :quotas, %{})

        merged_quantities =
          Enum.reduce(quota_values, quantities, fn {quota, configured_quantity}, result ->
            quantity = max(grant.quantity, configured_quantity)
            Map.update(result, quota, quantity, &max(&1, quantity))
          end)

        {MapSet.put(plans, plan),
         MapSet.union(features, MapSet.new(Map.get(product, :features, []))), merged_quantities,
         MapSet.put(sources, source(grant, plan)),
         Map.update(authorization_bounds, plan, bounds(grant), &merge_bounds(&1, bounds(grant)))}
    end
  end

  defp product_key(grant), do: {grant.rail, grant.environment, grant.provider_product_id}

  defp legacy_product(%{logical_plan: logical_plan}, catalog) when is_binary(logical_plan) do
    Enum.find_value(catalog, &legacy_catalog_match(&1, logical_plan)) ||
      Accrue.Config.entitlements()
      |> Keyword.get(:plans, [])
      |> Enum.find_value(fn {plan, entry} ->
        if Atom.to_string(plan) == logical_plan,
          do: %{
            plan: plan,
            features: Keyword.get(entry, :features, []),
            quotas: Map.new(Keyword.get(entry, :limits, []))
          }
      end)
  end

  defp legacy_product(_, _), do: nil

  defp legacy_catalog_match({_key, product}, logical_plan) do
    if Atom.to_string(product.plan) == logical_plan, do: product
  end

  defp source(grant, logical_plan) do
    %{
      rail: grant.rail,
      environment: grant.environment,
      logical_plan: logical_plan,
      effective_at: grant.effective_at,
      expires_at: grant.expires_at,
      revoked_at: grant.superseded_at
    }
  end

  defp bounds(grant), do: %{effective_at: grant.effective_at, expires_at: grant.expires_at}

  defp merge_bounds(left, right) do
    %{
      effective_at: earliest(left.effective_at, right.effective_at),
      expires_at: latest_expiry(left.expires_at, right.expires_at)
    }
  end

  defp earliest(left, right) do
    if DateTime.compare(left, right) == :gt, do: right, else: left
  end

  defp latest_expiry(nil, _right), do: nil
  defp latest_expiry(_left, nil), do: nil

  defp latest_expiry(left, right) do
    if DateTime.compare(left, right) == :lt, do: right, else: left
  end

  defp live?(grant, now) do
    is_nil(grant.superseded_at) and DateTime.compare(grant.effective_at, now) != :gt and
      (is_nil(grant.expires_at) or DateTime.compare(now, grant.expires_at) == :lt)
  end

  defp catalog do
    plans = Accrue.Config.entitlements() |> Keyword.get(:plans, [])

    Accrue.Config.entitlement_product_catalog()
    |> Enum.reduce(%{}, fn {{rail, environment, product_id}, plan}, acc ->
      entry = Keyword.get(plans, plan, [])

      Map.put(acc, {rail, environment, product_id}, %{
        plan: plan,
        features: Keyword.get(entry, :features, []),
        quotas: Map.new(Keyword.get(entry, :quotas, []))
      })
    end)
  rescue
    _ -> %{}
  end
end
