defmodule Accrue.Invoices.FormatMoneyPropertyTest do
  @moduledoc """
  StreamData property test for `Accrue.Invoices.Render.format_money/3`.

  MAIL-21 correctness requirement: across the currency × locale matrix,
  `format_money/3` must NEVER raise and must always return a non-empty
  binary — even on unknown locales, unknown currencies, or pathological
  amounts. The fallback ladder (locale → en → raw string) keeps a bad
  input from taking out an email pipeline.
  """

  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Invoices.Render

  @currencies [:usd, :eur, :jpy, :kwd, :bhd]
  @locales ["en", "en-US", "fr", "de", "zz"]

  property "format_money/3 returns a non-empty binary for any (amount, currency, locale)" do
    check all(
            amount <- StreamData.integer(0..1_000_000_000),
            currency <- StreamData.member_of(@currencies),
            locale <- StreamData.member_of(@locales),
            max_runs: 120
          ) do
      result = Render.format_money(amount, currency, locale)
      assert is_binary(result)
      assert byte_size(result) > 0
    end
  end

  property "format_money/3 handles negative amounts without raising" do
    check all(
            amount <- StreamData.integer(-1_000_000..-1),
            currency <- StreamData.member_of(@currencies),
            locale <- StreamData.member_of(@locales),
            max_runs: 60
          ) do
      result = Render.format_money(amount, currency, locale)
      assert is_binary(result)
    end
  end
end
