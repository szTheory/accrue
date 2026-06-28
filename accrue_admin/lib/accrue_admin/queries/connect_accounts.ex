defmodule AccrueAdmin.Queries.ConnectAccounts do
  @moduledoc """
  Cursor-paginated connected account queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Connect.Account
  alias Accrue.Repo
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    Account
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.apply_cursor(@time_field, cursor)
    |> order_by([account], desc: account.inserted_at, desc: account.id)
    |> limit(^Enum.max([limit + 1, 2]))
    |> select([account], %{
      id: account.id,
      stripe_account_id: account.stripe_account_id,
      owner_type: account.owner_type,
      owner_id: account.owner_id,
      type: account.type,
      country: account.country,
      email: account.email,
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
      deauthorized_at: account.deauthorized_at,
      inserted_at: account.inserted_at
    })
    |> Repo.all()
    |> Behaviour.paginate(limit, @time_field)
  end

  @impl true
  def count_newer_than(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    cursor = Behaviour.decode_cursor(opts)
    owner_scope = Keyword.get(opts, :owner_scope)

    Account
    |> scope_query(owner_scope)
    |> filter_query(filter)
    |> Behaviour.count_newer(@time_field, cursor)
    |> Repo.aggregate(:count)
  end

  @impl true
  def decode_filter(params) when is_map(params) do
    %{
      q: Behaviour.normalize_string(Map.get(params, "q") || Map.get(params, :q)),
      type: Behaviour.normalize_string(Map.get(params, "type") || Map.get(params, :type)),
      charges_enabled:
        Behaviour.parse_boolean(
          Map.get(params, "charges_enabled") || Map.get(params, :charges_enabled)
        ),
      payouts_enabled:
        Behaviour.parse_boolean(
          Map.get(params, "payouts_enabled") || Map.get(params, :payouts_enabled)
        ),
      details_submitted:
        Behaviour.parse_boolean(
          Map.get(params, "details_submitted") || Map.get(params, :details_submitted)
        ),
      deauthorized:
        Behaviour.parse_boolean(Map.get(params, "deauthorized") || Map.get(params, :deauthorized)),
      needs_attention:
        Behaviour.parse_boolean(
          Map.get(params, "needs_attention") || Map.get(params, :needs_attention)
        )
    }
    |> Behaviour.compact_filter()
  end

  @impl true
  def encode_filter(filter) when is_map(filter), do: Behaviour.compact_filter(filter)

  defp scope_query(query, nil), do: query
  defp scope_query(query, %OwnerScope{mode: :global}), do: query

  defp scope_query(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [account],
      account.owner_type == "Organization" and account.owner_id == ^organization_id
    )
  end

  defp filter_query(query, filter) do
    Enum.reduce(filter, query, fn
      {:q, term}, query ->
        pattern = "%#{term}%"

        where(
          query,
          [account],
          ilike(account.stripe_account_id, ^pattern) or
            ilike(account.email, ^pattern) or
            ilike(account.owner_id, ^pattern)
        )

      {:type, type}, query ->
        where(query, [account], account.type == ^type)

      {:charges_enabled, value}, query ->
        where(query, [account], account.charges_enabled == ^value)

      {:payouts_enabled, value}, query ->
        where(query, [account], account.payouts_enabled == ^value)

      {:details_submitted, value}, query ->
        where(query, [account], account.details_submitted == ^value)

      {:deauthorized, true}, query ->
        where(query, [account], not is_nil(account.deauthorized_at))

      {:deauthorized, false}, query ->
        where(query, [account], is_nil(account.deauthorized_at))

      {:needs_attention, true}, query ->
        where(
          query,
          [account],
          not is_nil(account.deauthorized_at) or
            account.details_submitted == false or
            is_nil(account.details_submitted) or
            account.charges_enabled == false or
            is_nil(account.charges_enabled) or
            account.payouts_enabled == false or
            is_nil(account.payouts_enabled)
        )

      {:needs_attention, false}, query ->
        query

      {_unknown, _value}, query ->
        query
    end)
  end
end
