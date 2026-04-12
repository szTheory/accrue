defmodule Accrue.Money do
  @moduledoc """
  Accrue's canonical money value type — a thin, opinionated wrapper over the
  `:ex_money` currency table.

  ## Shape

  `%Accrue.Money{amount_minor: integer(), currency: atom()}` — amounts are
  always stored in the currency's minor unit (cents for USD, yen for JPY,
  fils-thousandths for KWD). The currency is always an atom matching the
  lowercase ISO 4217 code (`:usd`, `:jpy`, `:kwd`).

  ## Constructor discipline (D-03)

  The primary constructor is `new/2` with an integer in minor units — the
  same shape Stripe's API uses, so developers can paste Stripe integers
  directly:

      iex> Accrue.Money.new(1000, :usd)
      %Accrue.Money{amount_minor: 1000, currency: :usd}   # $10.00

  Passing a `Decimal` or a `float` to `new/2` raises `ArgumentError`. Use
  `from_decimal/2` for explicit decimal conversions — the shift to minor
  units is currency-exponent aware via ex_money's CLDR table.

  ## Cross-currency arithmetic (D-04)

  Operations on two `Accrue.Money` values with different currencies
  raise `Accrue.Money.MismatchedCurrencyError`. There are no silent FX
  conversions and no tagged-tuple returns — the failure is loud and
  immediate at the call site.
  """

  alias Accrue.Money.MismatchedCurrencyError

  @enforce_keys [:amount_minor, :currency]
  defstruct [:amount_minor, :currency]

  @type t :: %__MODULE__{amount_minor: integer(), currency: atom()}

  @doc """
  Primary integer-minor-unit constructor.

  Raises `ArgumentError` when given a float or a `Decimal`. Use
  `from_decimal/2` for decimal conversions.

  Raises `ArgumentError` if the currency atom is not a known ISO 4217 code.
  """
  @spec new(integer(), atom()) :: t()
  def new(amount_minor, currency)
      when is_integer(amount_minor) and is_atom(currency) do
    _ = exponent!(currency)
    %__MODULE__{amount_minor: amount_minor, currency: currency}
  end

  def new(%Decimal{}, _currency) do
    raise ArgumentError,
          "Accrue.Money.new/2 requires (integer, atom); " <>
            "use Accrue.Money.from_decimal/2 for Decimal conversions"
  end

  def new(amount, _currency) when is_float(amount) do
    raise ArgumentError,
          "Accrue.Money.new/2 does not accept floats — money arithmetic " <>
            "must never touch float. Pass an integer in minor units, or use " <>
            "Accrue.Money.from_decimal/2."
  end

  def new(amount, currency) do
    raise ArgumentError,
          "Accrue.Money.new/2 requires (integer, atom); got " <>
            "(#{inspect(amount)}, #{inspect(currency)})"
  end

  @doc """
  Decimal constructor — shifts the value into the currency's minor unit
  according to `ex_money`'s CLDR iso_digits for that currency.

  Zero-decimal currencies (JPY, KRW) do not shift. Three-decimal currencies
  (KWD, BHD) multiply by 1000. Rounding is half-even (banker's rounding),
  matching Stripe's default.
  """
  @spec from_decimal(Decimal.t(), atom()) :: t()
  def from_decimal(%Decimal{} = decimal, currency) when is_atom(currency) do
    exponent = exponent!(currency)

    amount_minor =
      decimal
      |> Decimal.mult(Decimal.new(power_of_10(exponent)))
      |> Decimal.round(0, :half_even)
      |> Decimal.to_integer()

    %__MODULE__{amount_minor: amount_minor, currency: currency}
  end

  @doc """
  Addition. Raises `Accrue.Money.MismatchedCurrencyError` on currency
  mismatch (D-04).
  """
  @spec add(t(), t()) :: t()
  def add(%__MODULE__{currency: c} = a, %__MODULE__{currency: c} = b) do
    %__MODULE__{amount_minor: a.amount_minor + b.amount_minor, currency: c}
  end

  def add(%__MODULE__{currency: l}, %__MODULE__{currency: r}) do
    raise MismatchedCurrencyError, left: l, right: r
  end

  @doc """
  Subtraction. Raises `Accrue.Money.MismatchedCurrencyError` on currency
  mismatch (D-04).
  """
  @spec subtract(t(), t()) :: t()
  def subtract(%__MODULE__{currency: c} = a, %__MODULE__{currency: c} = b) do
    %__MODULE__{amount_minor: a.amount_minor - b.amount_minor, currency: c}
  end

  def subtract(%__MODULE__{currency: l}, %__MODULE__{currency: r}) do
    raise MismatchedCurrencyError, left: l, right: r
  end

  @doc """
  Structural equality — same amount_minor AND same currency atom.
  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(%__MODULE__{} = a, %__MODULE__{} = b), do: a == b

  @doc """
  Human-readable formatting. Delegates to `ex_money`'s CLDR-backed
  formatter, which handles locale-aware currency symbols and grouping.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{amount_minor: amount_minor, currency: currency}) do
    exponent = exponent!(currency)

    decimal =
      amount_minor
      |> Decimal.new()
      |> Decimal.div(Decimal.new(power_of_10(exponent)))

    m = Money.new!(currency, decimal)
    Money.to_string!(m)
  end

  # --- internals ---------------------------------------------------------

  @spec exponent!(atom()) :: non_neg_integer()
  defp exponent!(currency) do
    case Money.Currency.currency_for_code(currency) do
      {:ok, %{iso_digits: digits}} when is_integer(digits) ->
        digits

      _ ->
        raise ArgumentError,
              "unknown ISO 4217 currency: #{inspect(currency)}"
    end
  end

  @spec power_of_10(non_neg_integer()) :: pos_integer()
  defp power_of_10(0), do: 1
  defp power_of_10(1), do: 10
  defp power_of_10(2), do: 100
  defp power_of_10(3), do: 1000
  defp power_of_10(4), do: 10_000
  defp power_of_10(n) when is_integer(n) and n > 0, do: Integer.pow(10, n)
end
