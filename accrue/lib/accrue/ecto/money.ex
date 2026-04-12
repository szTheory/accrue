defmodule Accrue.Ecto.Money do
  @moduledoc """
  Two storage shapes for `%Accrue.Money{}` in Ecto schemas — both shipped
  in Phase 1 per D-02 and RESEARCH Open Question 5.

  ## 1. Custom `Ecto.Type` — single-column jsonb form

  For places where a money value is one of many properties inside a
  jsonb blob (e.g., `accrue_events.data`), this module implements the
  `Ecto.Type` callbacks and serializes as
  `%{"amount_minor" => integer, "currency" => string}`.

      field :snapshot, Accrue.Ecto.Money

  This form is convenient but is NOT the canonical storage shape for
  first-class money columns. Use `money_field/1` for those.

  ## 2. `money_field/1` macro — two-column canonical form (D-02)

  The canonical form: one money value expands to TWO physical Ecto
  fields plus a virtual accessor.

      defmodule MyApp.Billing.Subscription do
        use Ecto.Schema
        import Accrue.Ecto.Money, only: [money_field: 1]

        schema "subscriptions" do
          money_field :price
          timestamps()
        end
      end

  That expansion produces:

      field :price_amount_minor, :integer
      field :price_currency,     :string
      field :price,              :any, virtual: true

  On load, a `changeset/2` or post-load helper (Phase 2 wires this) sets
  the virtual `:price` field via
  `Accrue.Money.new(row.price_amount_minor, String.to_existing_atom(row.price_currency))`
  so callers see a `%Accrue.Money{}` struct.

  This two-column shape plays well with zero-decimal (JPY) and
  three-decimal (KWD) currencies, is indexable, and is analytics-friendly
  — see Pitfall #1 in 01-RESEARCH.md for why we reject the ex_money
  Postgres composite type as a canonical storage shape.
  """

  use Ecto.Type

  @doc """
  Two-column macro — canonical storage shape per D-02.
  """
  defmacro money_field(name) when is_atom(name) do
    amount_key = :"#{name}_amount_minor"
    currency_key = :"#{name}_currency"

    quote do
      Ecto.Schema.field(unquote(amount_key), :integer)
      Ecto.Schema.field(unquote(currency_key), :string)
      Ecto.Schema.field(unquote(name), :any, virtual: true)
    end
  end

  # --- Ecto.Type callbacks (single-column jsonb form) --------------------

  @impl true
  def type, do: :map

  @impl true
  def cast(%Accrue.Money{} = money), do: {:ok, money}

  def cast({amount, currency}) when is_integer(amount) and is_atom(currency) do
    {:ok, Accrue.Money.new(amount, currency)}
  end

  def cast(%{"amount_minor" => amount, "currency" => currency})
      when is_integer(amount) and is_binary(currency) do
    {:ok, Accrue.Money.new(amount, String.to_existing_atom(currency))}
  rescue
    ArgumentError -> :error
  end

  def cast(%{amount_minor: amount, currency: currency})
      when is_integer(amount) and is_atom(currency) do
    {:ok, Accrue.Money.new(amount, currency)}
  end

  def cast(_), do: :error

  @impl true
  def dump(%Accrue.Money{amount_minor: amount, currency: currency}) do
    {:ok, %{"amount_minor" => amount, "currency" => Atom.to_string(currency)}}
  end

  def dump(_), do: :error

  @impl true
  def load(%{"amount_minor" => amount, "currency" => currency})
      when is_integer(amount) and is_binary(currency) do
    {:ok, Accrue.Money.new(amount, String.to_existing_atom(currency))}
  rescue
    ArgumentError -> :error
  end

  def load(_), do: :error
end
