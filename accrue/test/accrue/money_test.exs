defmodule Accrue.MoneyTest do
  use ExUnit.Case, async: true

  alias Accrue.Money, as: M
  alias Accrue.Money.MismatchedCurrencyError

  describe "new/2 integer constructor (D-03)" do
    test "USD minor units" do
      assert %M{amount_minor: 1000, currency: :usd} = M.new(1000, :usd)
    end

    test "JPY zero-decimal currency round-trips as-is" do
      assert %M{amount_minor: 100, currency: :jpy} = M.new(100, :jpy)
    end

    test "KWD three-decimal currency round-trips as-is" do
      assert %M{amount_minor: 1000, currency: :kwd} = M.new(1000, :kwd)
    end

    test "negative minor units allowed (refunds, adjustments)" do
      assert %M{amount_minor: -500, currency: :usd} = M.new(-500, :usd)
    end

    test "zero allowed" do
      assert %M{amount_minor: 0, currency: :usd} = M.new(0, :usd)
    end

    test "floats are rejected with a hint about from_decimal/2" do
      assert_raise ArgumentError, ~r/float/, fn -> M.new(10.5, :usd) end
    end

    test "Decimals are rejected on new/2 and point at from_decimal/2" do
      assert_raise ArgumentError, ~r/from_decimal/, fn ->
        M.new(Decimal.new("10.50"), :usd)
      end
    end

    test "unknown currency raises" do
      assert_raise ArgumentError, ~r/unknown ISO 4217/, fn ->
        M.new(100, :zzz)
      end
    end
  end

  describe "from_decimal/2 (D-03)" do
    test "USD two-decimal shift" do
      assert %M{amount_minor: 1050, currency: :usd} =
               M.from_decimal(Decimal.new("10.50"), :usd)
    end

    test "JPY zero-decimal no shift" do
      assert %M{amount_minor: 100, currency: :jpy} =
               M.from_decimal(Decimal.new("100"), :jpy)
    end

    test "KWD three-decimal shift" do
      assert %M{amount_minor: 10_500, currency: :kwd} =
               M.from_decimal(Decimal.new("10.500"), :kwd)
    end

    test "half-even rounding for USD" do
      assert %M{amount_minor: 1050} = M.from_decimal(Decimal.new("10.505"), :usd)
    end
  end

  describe "add/2 (D-04)" do
    test "same-currency addition" do
      a = M.new(1000, :usd)
      b = M.new(2500, :usd)
      assert %M{amount_minor: 3500, currency: :usd} = M.add(a, b)
    end

    test "mismatched-currency addition raises MismatchedCurrencyError" do
      a = M.new(1000, :usd)
      b = M.new(1000, :eur)

      assert_raise MismatchedCurrencyError, fn -> M.add(a, b) end
    end

    test "MismatchedCurrencyError carries left/right" do
      a = M.new(1, :usd)
      b = M.new(1, :eur)

      error = assert_raise MismatchedCurrencyError, fn -> M.add(a, b) end
      assert error.left == :usd
      assert error.right == :eur
      assert error.message =~ "usd"
      assert error.message =~ "eur"
    end
  end

  describe "subtract/2 (D-04)" do
    test "same-currency subtraction" do
      assert %M{amount_minor: 500, currency: :usd} =
               M.subtract(M.new(1000, :usd), M.new(500, :usd))
    end

    test "mismatched-currency subtraction raises" do
      assert_raise MismatchedCurrencyError, fn ->
        M.subtract(M.new(1, :usd), M.new(1, :jpy))
      end
    end
  end

  describe "equal?/2" do
    test "structural equality" do
      assert M.equal?(M.new(1000, :usd), M.new(1000, :usd))
      refute M.equal?(M.new(1000, :usd), M.new(1001, :usd))
      refute M.equal?(M.new(1000, :usd), M.new(1000, :eur))
    end
  end

  describe "to_string/1" do
    test "formats USD" do
      assert M.to_string(M.new(1050, :usd)) =~ "10.50"
    end

    test "formats JPY (zero decimal)" do
      assert M.to_string(M.new(1000, :jpy)) =~ "1,000"
    end
  end

  describe "money_field/1 macro expansion (D-02)" do
    # Inline schema uses the macro; we verify __schema__ reflection.
    defmodule TestSchema do
      use Ecto.Schema
      import Accrue.Ecto.Money, only: [money_field: 1]

      @primary_key false
      embedded_schema do
        money_field(:price)
      end
    end

    test "expands to two physical fields + one virtual accessor" do
      fields = TestSchema.__schema__(:fields)
      virtual = TestSchema.__schema__(:virtual_fields)
      assert :price_amount_minor in fields
      assert :price_currency in fields
      # Virtual fields live in a separate reflection bucket.
      assert :price in virtual
      refute :price in fields
    end

    test "amount_minor is :integer" do
      assert :integer == TestSchema.__schema__(:type, :price_amount_minor)
    end

    test "currency is :string" do
      assert :string == TestSchema.__schema__(:type, :price_currency)
    end

    test "virtual :price field is not persisted" do
      # Virtual fields should not appear in :fields (persisted list).
      refute :price in TestSchema.__schema__(:fields)
    end
  end
end
