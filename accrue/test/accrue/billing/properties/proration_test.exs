defmodule Accrue.Billing.Properties.ProrationTest do
  @moduledoc """
  Plan 03-08 Task 3: property tests for money arithmetic invariants
  that proration math depends on. Locks in the currency-preservation
  and mismatched-currency invariants (D-03, D-04).

  Uses `Accrue.Money`'s integer-minor-unit constructor per D-03
  (no floats, no silent Decimal coercion).
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Money
  alias Accrue.Money.MismatchedCurrencyError

  property "Money.add preserves currency and sums minor units" do
    check all a <- integer(0..1_000_000),
              b <- integer(0..1_000_000),
              cur <- member_of([:usd, :eur, :gbp, :jpy]) do
      m1 = Money.new(a, cur)
      m2 = Money.new(b, cur)
      sum = Money.add(m1, m2)
      assert sum.currency == cur
      assert sum.amount_minor == a + b
    end
  end

  property "Money.subtract preserves currency and subtracts minor units" do
    check all a <- integer(0..1_000_000),
              b <- integer(0..1_000_000),
              cur <- member_of([:usd, :eur, :gbp, :jpy]) do
      m1 = Money.new(a, cur)
      m2 = Money.new(b, cur)
      diff = Money.subtract(m1, m2)
      assert diff.currency == cur
      assert diff.amount_minor == a - b
    end
  end

  property "mixed-currency Money.add raises MismatchedCurrencyError (D-04)" do
    check all a <- integer(0..1_000_000),
              b <- integer(0..1_000_000) do
      m1 = Money.new(a, :usd)
      m2 = Money.new(b, :eur)

      assert_raise MismatchedCurrencyError, fn ->
        Money.add(m1, m2)
      end
    end
  end

  property "mixed-currency Money.subtract raises MismatchedCurrencyError (D-04)" do
    check all a <- integer(0..1_000_000),
              b <- integer(0..1_000_000) do
      m1 = Money.new(a, :usd)
      m2 = Money.new(b, :jpy)

      assert_raise MismatchedCurrencyError, fn ->
        Money.subtract(m1, m2)
      end
    end
  end

  property "zero-decimal currencies (JPY) accept arbitrary integer amounts" do
    check all n <- integer(1..1000) do
      m = Money.new(n, :jpy)
      assert m.currency == :jpy
      assert m.amount_minor == n
    end
  end

  property "Money.new/2 rejects float amounts (no float money math)" do
    check all n <- float(min: 0.1, max: 100.0),
              cur <- member_of([:usd, :eur]) do
      assert_raise ArgumentError, fn -> Money.new(n, cur) end
    end
  end

  property "Money.equal?/2 is reflexive" do
    check all a <- integer(0..1_000_000),
              cur <- member_of([:usd, :eur, :gbp, :jpy]) do
      m = Money.new(a, cur)
      assert Money.equal?(m, m)
    end
  end

  property "Money addition is commutative within a currency" do
    check all a <- integer(0..1_000_000),
              b <- integer(0..1_000_000),
              cur <- member_of([:usd, :eur, :gbp, :jpy]) do
      m1 = Money.new(a, cur)
      m2 = Money.new(b, cur)
      assert Money.equal?(Money.add(m1, m2), Money.add(m2, m1))
    end
  end
end
