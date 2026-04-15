defmodule AccrueAdmin.Queries.ConnectAccounts do
  @moduledoc """
  Cursor-paginated connected account queries for admin UI surfaces.
  """

  @behaviour AccrueAdmin.Queries.Behaviour

  import Ecto.Query

  alias Accrue.Connect.Account
  alias Accrue.Repo
  alias AccrueAdmin.Queries.Behaviour

  @time_field :inserted_at

  @impl true
  def list(opts \\ []) do
    filter = Keyword.get(opts, :filter, %{})
    limit = Behaviour.normalize_limit(opts)
    cursor = Behaviour.decode_cursor(opts)

    Account
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

    Account
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
        Behaviour.parse_boolean(Map.get(params, "deauthorized") || Map.get(params, :deauthorized))
    }
    |> Behaviour.compact_filter()
  end

  @impl true
  def encode_filter(filter) when is_map(filter), do: Behaviour.compact_filter(filter)

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

      {_unknown, _value}, query ->
        query
    end)
  end
end
