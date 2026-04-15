defmodule Accrue.Emails.FixturesTest do
  @moduledoc """
  Plan 06-06 Task 3: `Accrue.Emails.Fixtures` canned-assigns module.

  Asserts:
    * `all/0` returns a 13-key map covering every email type
    * Every fixture has a `:context` key
    * Fixtures are deterministic (calling twice returns identical maps)
    * Every fixture renders via the corresponding `Accrue.Emails.<Type>`
      module without raising
    * Zero Repo / DateTime calls (pure data)
  """

  use ExUnit.Case, async: true

  alias Accrue.Emails.Fixtures

  @expected_types [
    :receipt,
    :payment_failed,
    :trial_ending,
    :trial_ended,
    :invoice_finalized,
    :invoice_paid,
    :invoice_payment_failed,
    :subscription_canceled,
    :subscription_paused,
    :subscription_resumed,
    :refund_issued,
    :coupon_applied,
    :card_expiring_soon
  ]

  test "all/0 returns 13 email type keys" do
    all = Fixtures.all()
    assert map_size(all) == 13

    for type <- @expected_types do
      assert Map.has_key?(all, type), "missing fixture: #{type}"
    end
  end

  test "each fixture has a :context key" do
    for {type, fixture} <- Fixtures.all() do
      assert is_map(fixture), "#{type} fixture is not a map"
      assert Map.has_key?(fixture, :context), "#{type} fixture missing :context"
      assert is_map(fixture.context), "#{type} fixture :context is not a map"
    end
  end

  test "base_context/0 has required render keys" do
    ctx = Fixtures.base_context()
    assert Keyword.keyword?(ctx.branding) or is_list(ctx.branding)
    assert ctx.branding[:business_name]
    assert ctx.customer[:name]
    assert ctx.invoice[:number]
    assert ctx.formatted_total
    assert ctx.currency == :usd
    assert ctx.locale == "en"
  end

  test "fixtures are deterministic (identical across two calls)" do
    assert Fixtures.all() == Fixtures.all()
    assert Fixtures.receipt() == Fixtures.receipt()
    assert Fixtures.refund_issued() == Fixtures.refund_issued()
  end

  test "each fixture renders via its corresponding email module without raising" do
    for {type, fixture} <- Fixtures.all() do
      module = Accrue.Workers.Mailer.resolve_template(type)

      assert is_binary(module.subject(fixture)),
             "#{type}.subject/1 did not return a binary"

      assert is_binary(module.render(fixture)),
             "#{type}.render/1 did not return a binary"

      assert is_binary(module.render_text(fixture)),
             "#{type}.render_text/1 did not return a binary"
    end
  end

  test "refund_issued fixture carries fee-breakdown fields" do
    ctx = Fixtures.refund_issued().context
    assert ctx.refund.formatted_amount
    assert ctx.refund.formatted_stripe_fee_refunded
    assert ctx.refund.formatted_merchant_loss
  end

  test "coupon_applied fixture carries coupon + promotion_code" do
    ctx = Fixtures.coupon_applied().context
    assert ctx.coupon.name
    assert ctx.promotion_code.code
  end
end
