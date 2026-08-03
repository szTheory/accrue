defmodule Accrue.Entitlements.Resolver.Canonical do
  @moduledoc "Resolver-compatible read-only projection of canonical entitlement snapshots."

  @behaviour Accrue.Entitlements.Resolver

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Snapshot}

  @empty %{plan: nil, active_plans: MapSet.new(), features: MapSet.new(), quantities: %{}}

  @impl true
  def resolve(billable, opts \\ []) do
    case account_for(billable, opts) do
      nil -> {:ok, @empty}
      account -> {:ok, snapshot_to_resolved(Snapshot.fetch(Accrue.Repo.repo(), account))}
    end
  end

  defp account_for(billable, opts) do
    case Keyword.get(opts, :account_id) do
      account_id when is_binary(account_id) -> Accrue.Repo.get(Account, account_id)
      _ -> account_for_billable(billable)
    end
  end

  defp account_for_billable(%{__struct__: mod, id: id}) when not is_nil(id) do
    Accrue.Repo.one(
      from(account in Account,
        where:
          account.owner_type == ^mod.__accrue__(:billable_type) and
            account.owner_id == ^to_string(id),
        limit: 1
      )
    )
  rescue
    UndefinedFunctionError -> nil
  end

  defp account_for_billable(_), do: nil

  defp snapshot_to_resolved(snapshot) do
    %{
      plan: List.last(snapshot.plans),
      active_plans: MapSet.new(snapshot.plans),
      features: MapSet.new(snapshot.features),
      quantities: snapshot.quantities,
      grace_plans: MapSet.new(),
      grace_features: MapSet.new(),
      expired_grace_plans: MapSet.new()
    }
  end
end
