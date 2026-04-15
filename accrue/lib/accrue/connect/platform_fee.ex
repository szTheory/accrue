defmodule Accrue.Connect.PlatformFee do
  @moduledoc """
  Pure `Accrue.Money` math for platform fee computation (D5-04, CONN-06).

  **Caller-inject semantics.** This helper computes the platform fee amount
  as a value. It does NOT auto-apply to charges or transfers. Callers thread
  the result into `application_fee_amount:` on their own charge/transfer
  calls so the fee line is always auditable at the call site.

  ## Computation order

  Stripe's documented order of operations for a flat-rate platform fee
  (percent + fixed, optionally clamped):

    1. Percent component — `gross * (percent / 100)` in minor units, with
       banker's rounding (`:half_even`) at integer precision. Minor units
       are integer across all currencies, so this is currency-exponent
       agnostic: JPY (0-decimal), USD (2-decimal), and KWD (3-decimal) all
       round at the same integer boundary.
    2. Fixed component — if present, added verbatim (same currency).
    3. Floor clamp — if `:min` is present and the result is below it,
       raise to the min.
    4. Ceiling clamp — if `:max` is present and the result exceeds it,
       lower to the max.

  Zero gross short-circuits to zero fee before any math.

  ## Config

  Opts override per-call; unset opts fall back to
  `Accrue.Config.get!(:connect) |> Keyword.get(:platform_fee)`.
  """

  alias Accrue.{ConfigError, Money}

  @type opts :: [
          percent: Decimal.t(),
          fixed: Money.t() | nil,
          min: Money.t() | nil,
          max: Money.t() | nil
        ]

  @spec compute(Money.t(), keyword()) :: {:ok, Money.t()} | {:error, Exception.t()}
  def compute(gross, opts \\ [])

  def compute(%Money{} = gross, opts) when is_list(opts) do
    with {:ok, cfg} <- resolve_config(opts),
         :ok <- validate_percent(cfg[:percent]),
         :ok <- validate_currency(gross, cfg[:fixed], :fixed),
         :ok <- validate_currency(gross, cfg[:min], :min),
         :ok <- validate_currency(gross, cfg[:max], :max) do
      if gross.amount_minor == 0 do
        {:ok, Money.new(0, gross.currency)}
      else
        do_compute(gross, cfg)
      end
    end
  end

  def compute(nil, _opts) do
    {:error,
     %ConfigError{
       key: :gross,
       message: "Accrue.Connect.platform_fee/2 requires an %Accrue.Money{} gross amount"
     }}
  end

  def compute(other, _opts) do
    {:error,
     %ConfigError{
       key: :gross,
       message:
         "Accrue.Connect.platform_fee/2 requires an %Accrue.Money{}; got: " <> inspect(other)
     }}
  end

  @doc """
  Bang variant. Raises on validation failure.
  """
  @spec compute!(Money.t(), keyword()) :: Money.t()
  def compute!(gross, opts \\ []) do
    case compute(gross, opts) do
      {:ok, fee} -> fee
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "Accrue.Connect.platform_fee!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp do_compute(%Money{amount_minor: gross_minor, currency: currency}, cfg) do
    percent_component_minor = percent_of_minor(gross_minor, cfg[:percent])

    with_fixed_minor =
      case cfg[:fixed] do
        nil -> percent_component_minor
        %Money{amount_minor: fixed_minor} -> percent_component_minor + fixed_minor
      end

    floored_minor =
      case cfg[:min] do
        nil -> with_fixed_minor
        %Money{amount_minor: min_minor} -> max(with_fixed_minor, min_minor)
      end

    ceilinged_minor =
      case cfg[:max] do
        nil -> floored_minor
        %Money{amount_minor: max_minor} -> min(floored_minor, max_minor)
      end

    # Clamp to non-negative. A pathological combo (negative fixed, no min)
    # could otherwise yield a negative "fee" which is non-sensical.
    final_minor = max(ceilinged_minor, 0)

    {:ok, Money.new(final_minor, currency)}
  end

  # Percent of an integer-minor-unit amount, rounded banker's (half-even)
  # to integer precision. Currency-exponent agnostic: all math in minor
  # units as integers.
  defp percent_of_minor(gross_minor, %Decimal{} = percent) do
    gross_minor
    |> Decimal.new()
    |> Decimal.mult(percent)
    |> Decimal.div(Decimal.new(100))
    |> Decimal.round(0, :half_even)
    |> Decimal.to_integer()
  end

  defp percent_of_minor(_gross_minor, other) do
    raise ArgumentError,
          "platform_fee :percent must be a %Decimal{}; got: #{inspect(other)}"
  end

  defp resolve_config(opts) do
    defaults = Accrue.Config.get!(:connect) |> Keyword.get(:platform_fee, [])

    merged =
      defaults
      |> Keyword.merge(opts)
      |> Keyword.take([:percent, :fixed, :min, :max])

    case Keyword.fetch(merged, :percent) do
      {:ok, %Decimal{}} ->
        {:ok, merged}

      {:ok, other} ->
        {:error,
         %ConfigError{
           key: :percent,
           message:
             "platform_fee :percent must be a %Decimal{}; got: " <> inspect(other)
         }}

      :error ->
        {:error,
         %ConfigError{
           key: :percent,
           message: "platform_fee :percent is required (set via opts or :connect config)"
         }}
    end
  end

  defp validate_percent(%Decimal{} = pct) do
    zero = Decimal.new(0)
    hundred = Decimal.new(100)

    cond do
      Decimal.compare(pct, zero) == :lt ->
        {:error,
         %ConfigError{
           key: :percent,
           message: "platform_fee :percent must be >= 0; got: " <> Decimal.to_string(pct)
         }}

      Decimal.compare(pct, hundred) == :gt ->
        {:error,
         %ConfigError{
           key: :percent,
           message: "platform_fee :percent must be <= 100; got: " <> Decimal.to_string(pct)
         }}

      true ->
        :ok
    end
  end

  defp validate_currency(_gross, nil, _key), do: :ok

  defp validate_currency(%Money{currency: c}, %Money{currency: c}, _key), do: :ok

  defp validate_currency(%Money{currency: gc}, %Money{currency: oc}, key) do
    {:error,
     %ConfigError{
       key: key,
       message:
         "platform_fee #{inspect(key)} currency #{inspect(oc)} does not match " <>
           "gross currency #{inspect(gc)}"
     }}
  end

  defp validate_currency(_gross, other, key) do
    {:error,
     %ConfigError{
       key: key,
       message:
         "platform_fee #{inspect(key)} must be an %Accrue.Money{} or nil; got: " <>
           inspect(other)
     }}
  end
end
