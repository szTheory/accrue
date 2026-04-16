defmodule Accrue.Property.MoneyPropertyTest do
  @moduledoc """
  StreamData property tests for Accrue.Money arithmetic edge cases.

  These complement the example-based tests in `Accrue.MoneyTest` with
  randomized inputs to exercise:

    1. Zero-decimal currency safety (JPY, KRW, etc.)
    2. Addition commutativity and associativity
    3. Subtraction identity
    4. Cross-currency rejection (D-04)
    5. Minor-unit roundtrip stability
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Money
  alias Accrue.Money.MismatchedCurrencyError

  # --- generators ---

  # Standard two-decimal currencies (exponent 2)
  @two_decimal_currencies [:usd, :eur, :gbp, :cad, :aud, :chf, :sek, :nok, :dkk]

  # Zero-decimal currencies (exponent 0)
  @zero_decimal_currencies [:jpy, :krw, :vnd, :bif, :clp, :djf]

  # Three-decimal currencies (exponent 3)
  @three_decimal_currencies [:kwd, :bhd, :omr]

  defp amount_gen, do: StreamData.integer(-999_999..999_999)
  defp positive_amount_gen, do: StreamData.integer(1..999_999)

  defp two_decimal_currency_gen, do: StreamData.member_of(@two_decimal_currencies)
  defp zero_decimal_currency_gen, do: StreamData.member_of(@zero_decimal_currencies)
  defp three_decimal_currency_gen, do: StreamData.member_of(@three_decimal_currencies)

  defp any_currency_gen do
    StreamData.member_of(
      @two_decimal_currencies ++ @zero_decimal_currencies ++ @three_decimal_currencies
    )
  end

  # --- properties ---

  property "constructor accepts any integer amount for any valid currency" do
    check all(
            amount <- amount_gen(),
            currency <- any_currency_gen()
          ) do
      money = Money.new(amount, currency)
      assert %Money{amount_minor: ^amount, currency: ^currency} = money
    end
  end

  property "zero-decimal currencies round-trip through new/2" do
    check all(
            amount <- positive_amount_gen(),
            currency <- zero_decimal_currency_gen()
          ) do
      money = Money.new(amount, currency)
      assert money.amount_minor == amount
      assert money.currency == currency
    end
  end

  property "three-decimal currencies round-trip through new/2" do
    check all(
            amount <- positive_amount_gen(),
            currency <- three_decimal_currency_gen()
          ) do
      money = Money.new(amount, currency)
      assert money.amount_minor == amount
      assert money.currency == currency
    end
  end

  property "same-currency addition is commutative" do
    check all(
            a <- amount_gen(),
            b <- amount_gen(),
            currency <- two_decimal_currency_gen()
          ) do
      ma = Money.new(a, currency)
      mb = Money.new(b, currency)
      assert Money.add(ma, mb) == Money.add(mb, ma)
    end
  end

  property "same-currency addition is associative" do
    check all(
            a <- amount_gen(),
            b <- amount_gen(),
            c <- amount_gen(),
            currency <- two_decimal_currency_gen()
          ) do
      ma = Money.new(a, currency)
      mb = Money.new(b, currency)
      mc = Money.new(c, currency)

      left = Money.add(Money.add(ma, mb), mc)
      right = Money.add(ma, Money.add(mb, mc))
      assert left == right
    end
  end

  property "adding zero is identity" do
    check all(
            amount <- amount_gen(),
            currency <- any_currency_gen()
          ) do
      money = Money.new(amount, currency)
      zero = Money.new(0, currency)
      assert Money.add(money, zero) == money
      assert Money.add(zero, money) == money
    end
  end

  property "subtract self yields zero" do
    check all(
            amount <- amount_gen(),
            currency <- any_currency_gen()
          ) do
      money = Money.new(amount, currency)
      result = Money.subtract(money, money)
      assert result.amount_minor == 0
      assert result.currency == currency
    end
  end

  property "add then subtract roundtrips to original" do
    check all(
            a <- amount_gen(),
            b <- amount_gen(),
            currency <- two_decimal_currency_gen()
          ) do
      ma = Money.new(a, currency)
      mb = Money.new(b, currency)
      assert Money.subtract(Money.add(ma, mb), mb) == ma
    end
  end

  property "cross-currency addition raises MismatchedCurrencyError" do
    check all(
            a <- positive_amount_gen(),
            b <- positive_amount_gen()
          ) do
      usd = Money.new(a, :usd)
      eur = Money.new(b, :eur)

      assert_raise MismatchedCurrencyError, fn -> Money.add(usd, eur) end
    end
  end

  property "cross-currency subtraction raises MismatchedCurrencyError" do
    check all(
            a <- positive_amount_gen(),
            b <- positive_amount_gen()
          ) do
      jpy = Money.new(a, :jpy)
      gbp = Money.new(b, :gbp)

      assert_raise MismatchedCurrencyError, fn -> Money.subtract(jpy, gbp) end
    end
  end

  property "from_decimal roundtrips for two-decimal currencies" do
    check all(
            cents <- StreamData.integer(0..999_999),
            currency <- two_decimal_currency_gen()
          ) do
      # Build a Decimal from cents: e.g. 1050 cents -> "10.50"
      decimal = Decimal.div(Decimal.new(cents), Decimal.new(100))
      money = Money.from_decimal(decimal, currency)

      # from_decimal uses banker's rounding, but since we start from an
      # exact cent value the roundtrip should be lossless.
      assert money.amount_minor == cents
      assert money.currency == currency
    end
  end

  property "from_decimal roundtrips for zero-decimal currencies" do
    check all(
            amount <- StreamData.integer(0..999_999),
            currency <- zero_decimal_currency_gen()
          ) do
      decimal = Decimal.new(amount)
      money = Money.from_decimal(decimal, currency)
      assert money.amount_minor == amount
    end
  end

  property "equal?/2 is reflexive" do
    check all(
            amount <- amount_gen(),
            currency <- any_currency_gen()
          ) do
      money = Money.new(amount, currency)
      assert Money.equal?(money, money)
    end
  end

  property "equal?/2 detects different amounts" do
    check all(
            a <- amount_gen(),
            b <- amount_gen(),
            a != b,
            currency <- any_currency_gen()
          ) do
      ma = Money.new(a, currency)
      mb = Money.new(b, currency)
      refute Money.equal?(ma, mb)
    end
  end
end
