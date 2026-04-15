defmodule Accrue.Connect.PlatformFeeTest do
  @moduledoc """
  Unit tests for `Accrue.Connect.PlatformFee.compute/2` and the
  `Accrue.Connect.platform_fee/2` defdelegate (CONN-06, D5-04).

  Shape matches VALIDATION.md rows 15 (USD), 16 (JPY), 17 (KWD) plus
  clamp/reject edge cases. Property tests live in
  `test/property/connect_platform_fee_property_test.exs`.
  """

  use ExUnit.Case, async: true

  alias Accrue.Connect
  alias Accrue.Connect.PlatformFee
  alias Accrue.{ConfigError, Money}

  describe "compute/2 — happy path (default Stripe 2.9% + $0.30)" do
    test "USD $100 * 2.9% + $0.30 = $3.20 (VALIDATION row 15)" do
      gross = Money.new(10_000, :usd)

      assert {:ok, fee} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :usd)
               )

      assert %Money{amount_minor: 320, currency: :usd} = fee
    end

    test "USD $0.01 with 2.9% rounds to 0 minor units (banker's rounding)" do
      gross = Money.new(1, :usd)

      assert {:ok, %Money{amount_minor: 0, currency: :usd}} =
               PlatformFee.compute(gross, percent: Decimal.new("2.9"))
    end

    test "USD $100 with 0% percent and no fixed returns zero" do
      gross = Money.new(10_000, :usd)

      assert {:ok, %Money{amount_minor: 0, currency: :usd}} =
               PlatformFee.compute(gross, percent: Decimal.new("0"))
    end
  end

  describe "compute/2 — zero-decimal currency (JPY) (VALIDATION row 16)" do
    test "JPY ¥10_000 * 2.9% = ¥290 integer-precise" do
      gross = Money.new(10_000, :jpy)

      assert {:ok, %Money{amount_minor: 290, currency: :jpy}} =
               PlatformFee.compute(gross, percent: Decimal.new("2.9"))
    end

    test "JPY with fixed component preserves zero-decimal precision" do
      gross = Money.new(10_000, :jpy)

      assert {:ok, %Money{amount_minor: 320, currency: :jpy}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :jpy)
               )
    end

    test "JPY banker's rounding at integer boundary" do
      # 100 * 2.9% = 2.9 → rounds half-even to 3
      gross = Money.new(100, :jpy)

      assert {:ok, %Money{amount_minor: 3, currency: :jpy}} =
               PlatformFee.compute(gross, percent: Decimal.new("2.9"))
    end
  end

  describe "compute/2 — three-decimal currency (KWD) (VALIDATION row 17)" do
    test "KWD KD 1.000 (minor=1000) * 2.9% = 29 mils" do
      gross = Money.new(1000, :kwd)

      assert {:ok, %Money{amount_minor: 29, currency: :kwd}} =
               PlatformFee.compute(gross, percent: Decimal.new("2.9"))
    end

    test "KWD large gross with fixed preserves 3-decimal precision" do
      # 10 KD = 10_000 mils, 2.9% = 290 mils, + fixed 100 mils = 390 mils
      gross = Money.new(10_000, :kwd)

      assert {:ok, %Money{amount_minor: 390, currency: :kwd}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(100, :kwd)
               )
    end
  end

  describe "compute/2 — clamping" do
    test ":min floors below-min fees" do
      gross = Money.new(100, :usd)

      # 100 * 2.9% = 2.9 → rounds to 3, below the 50-cent floor
      assert {:ok, %Money{amount_minor: 50, currency: :usd}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 min: Money.new(50, :usd)
               )
    end

    test ":max ceilings above-max fees" do
      gross = Money.new(1_000_000, :usd)

      # 1_000_000 * 2.9% = 29_000, clamp to 500
      assert {:ok, %Money{amount_minor: 500, currency: :usd}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 max: Money.new(500, :usd)
               )
    end

    test ":min and :max together — min takes priority on tiny gross" do
      gross = Money.new(10, :usd)

      assert {:ok, %Money{amount_minor: 50, currency: :usd}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 min: Money.new(50, :usd),
                 max: Money.new(500, :usd)
               )
    end
  end

  describe "compute/2 — validation errors" do
    test "mixed currency :fixed rejected" do
      gross = Money.new(10_000, :usd)

      assert {:error, %ConfigError{key: :fixed}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :eur)
               )
    end

    test "mixed currency :min rejected" do
      gross = Money.new(10_000, :usd)

      assert {:error, %ConfigError{key: :min}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 min: Money.new(50, :jpy)
               )
    end

    test "mixed currency :max rejected" do
      gross = Money.new(10_000, :usd)

      assert {:error, %ConfigError{key: :max}} =
               PlatformFee.compute(gross,
                 percent: Decimal.new("2.9"),
                 max: Money.new(500, :kwd)
               )
    end

    test "negative percent rejected" do
      gross = Money.new(10_000, :usd)

      assert {:error, %ConfigError{key: :percent}} =
               PlatformFee.compute(gross, percent: Decimal.new("-1"))
    end

    test "percent > 100 rejected" do
      gross = Money.new(10_000, :usd)

      assert {:error, %ConfigError{key: :percent}} =
               PlatformFee.compute(gross, percent: Decimal.new("100.01"))
    end

    test "nil gross rejected" do
      assert {:error, %ConfigError{key: :gross}} =
               PlatformFee.compute(nil, percent: Decimal.new("2.9"))
    end

    test "non-Money gross rejected" do
      assert {:error, %ConfigError{key: :gross}} =
               PlatformFee.compute(%{amount_minor: 10_000, currency: :usd},
                 percent: Decimal.new("2.9")
               )
    end
  end

  describe "compute/2 — zero gross short-circuit" do
    test "USD zero gross → zero fee (VALIDATION row 20)" do
      assert {:ok, %Money{amount_minor: 0, currency: :usd}} =
               PlatformFee.compute(Money.new(0, :usd),
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :usd)
               )
    end

    test "JPY zero gross → zero fee" do
      assert {:ok, %Money{amount_minor: 0, currency: :jpy}} =
               PlatformFee.compute(Money.new(0, :jpy), percent: Decimal.new("2.9"))
    end

    test "KWD zero gross → zero fee" do
      assert {:ok, %Money{amount_minor: 0, currency: :kwd}} =
               PlatformFee.compute(Money.new(0, :kwd), percent: Decimal.new("2.9"))
    end
  end

  describe "compute/2 — config defaults" do
    test "no opts uses :connect :platform_fee config defaults (2.9% baseline)" do
      gross = Money.new(10_000, :usd)

      assert {:ok, %Money{amount_minor: 290, currency: :usd}} =
               PlatformFee.compute(gross)
    end

    test "opts override config defaults" do
      gross = Money.new(10_000, :usd)

      assert {:ok, %Money{amount_minor: 100, currency: :usd}} =
               PlatformFee.compute(gross, percent: Decimal.new("1"))
    end
  end

  describe "compute!/2 bang variant" do
    test "returns Money on success" do
      gross = Money.new(10_000, :usd)

      assert %Money{amount_minor: 290, currency: :usd} =
               PlatformFee.compute!(gross, percent: Decimal.new("2.9"))
    end

    test "raises on validation error" do
      gross = Money.new(10_000, :usd)

      assert_raise ConfigError, fn ->
        PlatformFee.compute!(gross, percent: Decimal.new("-1"))
      end
    end
  end

  describe "Accrue.Connect.platform_fee/2 defdelegate" do
    test "delegates to PlatformFee.compute/2" do
      gross = Money.new(10_000, :usd)

      assert {:ok, %Money{amount_minor: 320, currency: :usd}} =
               Connect.platform_fee(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :usd)
               )
    end

    test "platform_fee!/2 bang variant delegates and raises" do
      gross = Money.new(10_000, :usd)

      assert %Money{amount_minor: 320, currency: :usd} =
               Connect.platform_fee!(gross,
                 percent: Decimal.new("2.9"),
                 fixed: Money.new(30, :usd)
               )

      assert_raise ConfigError, fn ->
        Connect.platform_fee!(gross, percent: Decimal.new("150"))
      end
    end
  end
end
