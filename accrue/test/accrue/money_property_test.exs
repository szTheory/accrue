defmodule Accrue.MoneyPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Money, as: M
  alias Accrue.Money.MismatchedCurrencyError

  # Representative sample across zero, two, and three-decimal currencies.
  @currencies [:usd, :jpy, :kwd, :gbp, :eur]

  property "new/2 round-trips any integer + known currency (P3)" do
    check all int <- integer(-10_000_000..10_000_000),
              currency <- member_of(@currencies) do
      money = M.new(int, currency)
      assert money.amount_minor == int
      assert money.currency == currency
    end
  end

  property "add/2 on same-currency sums minor units exactly (P1)" do
    check all a <- integer(-1_000_000..1_000_000),
              b <- integer(-1_000_000..1_000_000),
              currency <- member_of(@currencies) do
      m1 = M.new(a, currency)
      m2 = M.new(b, currency)
      result = M.add(m1, m2)
      assert result.amount_minor == a + b
      assert result.currency == currency
    end
  end

  property "add/2 across different currencies always raises (P2)" do
    check all a <- integer(-1_000_000..1_000_000),
              b <- integer(-1_000_000..1_000_000),
              {c1, c2} <-
                bind(member_of(@currencies), fn c1 ->
                  bind(member_of(@currencies -- [c1]), fn c2 -> constant({c1, c2}) end)
                end) do
      m1 = M.new(a, c1)
      m2 = M.new(b, c2)
      assert_raise MismatchedCurrencyError, fn -> M.add(m1, m2) end
    end
  end

  property "new/2 rejects floats (P4)" do
    check all f <- float() do
      assert_raise ArgumentError, fn -> M.new(f, :usd) end
    end
  end

  property "new/2 rejects Decimals (P4)" do
    check all int <- integer(-1_000_000..1_000_000) do
      decimal = Decimal.new(int)
      assert_raise ArgumentError, fn -> M.new(decimal, :usd) end
    end
  end

  # Round-trip through the money_field/1 macro: generate values, push into an
  # Ecto changeset against an embedded schema using the macro, and verify the
  # two physical columns hold the exact generated values. No DB needed —
  # Plan 03 covers live Repo round-trip.
  defmodule RoundTripSchema do
    use Ecto.Schema
    import Accrue.Ecto.Money, only: [money_field: 1]

    @primary_key false
    embedded_schema do
      money_field(:price)
    end
  end

  property "money_field/1 round-trip via Ecto changeset preserves amount+currency (P5)" do
    check all int <- integer(-10_000_000..10_000_000),
              currency <- member_of([:usd, :jpy, :kwd]) do
      attrs = %{price_amount_minor: int, price_currency: Atom.to_string(currency)}

      changeset =
        RoundTripSchema
        |> struct()
        |> Ecto.Changeset.cast(attrs, [:price_amount_minor, :price_currency])

      assert Ecto.Changeset.get_field(changeset, :price_amount_minor) == int
      assert Ecto.Changeset.get_field(changeset, :price_currency) == Atom.to_string(currency)
    end
  end
end
