defmodule Accrue.Property.ConnectPlatformFeePropertyTest do
  @moduledoc """
  StreamData property tests for `Accrue.Connect.PlatformFee.compute/2`
  (CONN-06, D5-04). Non-negotiable per D5-04: JPY (0-decimal), USD
  (2-decimal), and KWD (3-decimal) are all exercised so currency
  exponent edge cases around rounding are covered.

  Properties verified:

    * `fee <= gross` for every (currency, gross, percent, fixed, min, max)
      tuple where min/max respect gross (VALIDATION row 18)
    * `clamp(clamp(x)) == clamp(x)` — idempotent min/max clamp (row 19)
    * `compute(zero, _) == {:ok, zero}` — zero → zero (row 20)
    * Deterministic — same inputs yield byte-identical output
    * Currency preservation — fee.currency == gross.currency
    * Non-negative — fee.amount_minor >= 0 for all valid inputs
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Connect.PlatformFee
  alias Accrue.Money

  # Three representative currencies per D5-04 — exactly the exponent
  # classes Stripe distinguishes: 0-decimal, 2-decimal, 3-decimal.
  @currencies [:jpy, :usd, :kwd]

  # --- generators ------------------------------------------------------------

  defp currency_gen, do: StreamData.member_of(@currencies)

  # Gross amount in minor units. Upper bound 10_000_000 per plan;
  # covers ¥10M, $100k, and 10k KD — plenty of dynamic range for
  # rounding edge cases without blowing up CI runtime.
  defp gross_minor_gen, do: StreamData.integer(0..10_000_000)

  # Percent 0.00 .. 100.00 as a Decimal. Pre-generate integer 0..10_000
  # then divide by 100 so we land on exact hundredths.
  defp percent_gen do
    StreamData.map(StreamData.integer(0..10_000), fn n ->
      Decimal.div(Decimal.new(n), Decimal.new(100))
    end)
  end

  defp maybe_fixed_gen(currency) do
    StreamData.one_of([
      StreamData.constant(nil),
      StreamData.map(StreamData.integer(0..10_000), fn n -> Money.new(n, currency) end)
    ])
  end

  defp maybe_clamp_gen(currency) do
    StreamData.one_of([
      StreamData.constant(nil),
      StreamData.map(StreamData.integer(0..10_000_000), fn n -> Money.new(n, currency) end)
    ])
  end

  defp gross_money_gen(currency) do
    StreamData.map(gross_minor_gen(), fn n -> Money.new(n, currency) end)
  end

  defp opts_gen(currency) do
    StreamData.bind(percent_gen(), fn percent ->
      StreamData.bind(maybe_fixed_gen(currency), fn fixed ->
        StreamData.bind(maybe_clamp_gen(currency), fn min_clamp ->
          StreamData.map(maybe_clamp_gen(currency), fn max_clamp ->
            base = [percent: percent]
            base = if fixed, do: Keyword.put(base, :fixed, fixed), else: base
            base = if min_clamp, do: Keyword.put(base, :min, min_clamp), else: base
            if max_clamp, do: Keyword.put(base, :max, max_clamp), else: base
          end)
        end)
      end)
    end)
  end

  # --- properties ------------------------------------------------------------

  property "fee <= gross when min <= gross and no fixed (VALIDATION row 18)" do
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            percent <- percent_gen(),
            max_runs: 200
          ) do
      assert {:ok, %Money{amount_minor: fee_minor, currency: ^currency}} =
               PlatformFee.compute(gross, percent: percent)

      # With percent <= 100 and no fixed/min, fee must be <= gross.
      assert fee_minor <= gross.amount_minor
    end
  end

  property "zero gross → zero fee regardless of opts (VALIDATION row 20)" do
    check all(
            currency <- currency_gen(),
            opts <- opts_gen(currency),
            max_runs: 200
          ) do
      zero = Money.new(0, currency)
      assert PlatformFee.compute(zero, opts) == {:ok, zero}
    end
  end

  property "currency is preserved" do
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            opts <- opts_gen(currency),
            max_runs: 200
          ) do
      assert {:ok, %Money{currency: ^currency}} = PlatformFee.compute(gross, opts)
    end
  end

  property "fee is non-negative" do
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            opts <- opts_gen(currency),
            max_runs: 200
          ) do
      assert {:ok, %Money{amount_minor: fee_minor}} = PlatformFee.compute(gross, opts)
      assert fee_minor >= 0
    end
  end

  property "compute/2 is deterministic (same inputs → same output)" do
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            opts <- opts_gen(currency),
            max_runs: 200
          ) do
      assert PlatformFee.compute(gross, opts) == PlatformFee.compute(gross, opts)
    end
  end

  property "clamp(clamp(x)) == clamp(x) — idempotent clamp (VALIDATION row 19)" do
    # Compute once, then feed the fee back in with the same clamps. The
    # result must equal the first result: clamping a value already in
    # the [min, max] range is a no-op. Uses a flat percent of 100 so
    # the "re-fee" on the computed fee lands identical absent clamps,
    # making any clamp idempotency regression immediately visible.
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            min_minor <- StreamData.integer(0..1_000),
            max_minor <- StreamData.integer(1_000..10_000_000),
            max_runs: 200
          ) do
      opts = [
        percent: Decimal.new("100"),
        min: Money.new(min_minor, currency),
        max: Money.new(max_minor, currency)
      ]

      {:ok, once} = PlatformFee.compute(gross, opts)
      {:ok, twice} = PlatformFee.compute(once, opts)
      assert once == twice
    end
  end

  property "min clamp is a floor (fee >= min when gross > 0)" do
    check all(
            currency <- currency_gen(),
            gross_minor <- StreamData.integer(1..10_000_000),
            min_minor <- StreamData.integer(0..10_000),
            percent <- percent_gen(),
            max_runs: 200
          ) do
      gross = Money.new(gross_minor, currency)

      assert {:ok, %Money{amount_minor: fee_minor}} =
               PlatformFee.compute(gross,
                 percent: percent,
                 min: Money.new(min_minor, currency)
               )

      assert fee_minor >= min_minor
    end
  end

  property "max clamp is a ceiling (fee <= max)" do
    check all(
            currency <- currency_gen(),
            gross <- gross_money_gen(currency),
            max_minor <- StreamData.integer(0..10_000_000),
            percent <- percent_gen(),
            max_runs: 200
          ) do
      assert {:ok, %Money{amount_minor: fee_minor}} =
               PlatformFee.compute(gross,
                 percent: percent,
                 max: Money.new(max_minor, currency)
               )

      assert fee_minor <= max_minor
    end
  end
end
