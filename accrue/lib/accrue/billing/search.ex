defmodule Accrue.Billing.Search do
  @moduledoc """
  Provides native PostgreSQL trigram similarity search for core billing objects.

  Utilizes the `pg_trgm` extension and specific GIN indices for fast,
  fuzzy text matching without full table scans. Results are ranked by
  similarity (`GREATEST(similarity(...))` for multi-column searches).
  """

  import Ecto.Query, only: [where: 3, order_by: 3, limit: 2]

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.Invoice

  @doc """
  Searches `Accrue.Billing.Customer` by email or name.
  """
  @spec search_customers(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def search_customers(query \\ Customer, term) do
    query
    |> where(
      [c],
      fragment("? % ?", c.email, ^term) or fragment("? % ?", c.name, ^term)
    )
    |> order_by(
      [c],
      desc:
        fragment(
          "GREATEST(similarity(?, ?), similarity(?, ?))",
          c.email,
          ^term,
          c.name,
          ^term
        )
    )
    |> limit(50)
  end

  @doc """
  Searches `Accrue.Billing.Subscription` by processor_id.
  """
  @spec search_subscriptions(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def search_subscriptions(query \\ Subscription, term) do
    query
    |> where([s], fragment("? % ?", s.processor_id, ^term))
    |> order_by([s], desc: fragment("similarity(?, ?)", s.processor_id, ^term))
    |> limit(50)
  end

  @doc """
  Searches `Accrue.Billing.Invoice` by processor_id or number.
  """
  @spec search_invoices(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  def search_invoices(query \\ Invoice, term) do
    query
    |> where(
      [i],
      fragment("? % ?", i.processor_id, ^term) or fragment("? % ?", i.number, ^term)
    )
    |> order_by(
      [i],
      desc:
        fragment(
          "GREATEST(similarity(?, ?), similarity(?, ?))",
          i.processor_id,
          ^term,
          i.number,
          ^term
        )
    )
    |> limit(50)
  end
end
