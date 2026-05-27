defmodule Accrue.Analytics.Dunning do
  @moduledoc """
  Analytics context for Dunning.

  Provides MRR-based recovery vs lost metrics without adding new database
  tables, querying directly against the `accrue_events` ledger via Ecto JSONB
  aggregations.
  """

  import Ecto.Query, only: [from: 2, where: 3]

  alias Accrue.Events.Event
  alias Accrue.Repo

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"

  @doc """
  Folds the `accrue_events` ledger into a flat
  `%{recovered_cents: n, lost_cents: n}` map answering the merchant question
  "how much MRR did dunning recover vs. lose to terminal action?"

  This adds NO new table: it groups by the two confirmed-transition lifecycle
  ledger types written by the campaign:

    * `recovered` = sum of `mrr_value_cents` from `dunning.recovered`
    * `lost`      = sum of `mrr_value_cents` from `dunning.exhausted`

  ## Options

    * `:since` — `%DateTime{}` lower bound (inclusive), inclusive on
      `inserted_at >= since`.
    * `:until` — `%DateTime{}` upper bound (inclusive), `inserted_at <= until`.

  ## Examples

      iex> Accrue.Analytics.Dunning.recovered_vs_lost_mrr()
      %{recovered_cents: 12000, lost_cents: 3000}
  """
  @spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer()}
  def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
    query =
      from(e in Event,
        where: e.type in [@recovered_type, @exhausted_type],
        group_by: e.type,
        select:
          {e.type,
           sum(
             fragment(
               "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
               e.data,
               e.data
             )
           )}
      )
      |> apply_window(opts)

    results = Repo.all(query) |> Map.new()

    %{
      recovered_cents: Map.get(results, @recovered_type) || 0,
      lost_cents: Map.get(results, @exhausted_type) || 0
    }
  end

  defp apply_window(query, opts) do
    query
    |> maybe_since(opts[:since])
    |> maybe_until(opts[:until])
  end

  defp maybe_since(query, %DateTime{} = since),
    do: where(query, [e], e.inserted_at >= ^since)

  defp maybe_since(query, _), do: query

  defp maybe_until(query, %DateTime{} = until),
    do: where(query, [e], e.inserted_at <= ^until)

  defp maybe_until(query, _), do: query
end