defmodule Accrue.Emails.ReceiptTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.{Fixtures, Receipt}

  test "module is loaded" do
    assert Code.ensure_loaded?(Receipt)
  end

  test "message/1 builds a Mailglass receipt mailable" do
    msg = Receipt.message(Fixtures.receipt())

    assert msg.mailable == Receipt
    assert msg.mailable_function == :receipt
    assert msg.swoosh_email.subject == "Receipt from Acme Corp"
  end

  test "subject/1 references business name" do
    assert Receipt.subject(Fixtures.receipt()) =~ "Acme"
  end

  test "subject/1 fallback" do
    assert is_binary(Receipt.subject(%{}))
  end

  test "render/1 and render_text/1 preserve the customer-facing copy" do
    html = Receipt.render(Fixtures.receipt())
    text = Receipt.render_text(Fixtures.receipt())

    assert html =~ "Thanks for your payment"
    assert html =~ "Jo Example"
    assert html =~ "$29.00"
    assert html =~ "INV-2026-0001"

    assert String.downcase(text) =~ "thanks for your payment"
    assert text =~ "Acme Corp"
    assert text =~ "support@acme.test"
    assert text =~ "$29.00"
    assert text =~ "INV-2026-0001"
  end

  test "legacy Accrue.Emails.PaymentSucceeded still exists and is distinct" do
    assert Code.ensure_loaded?(Accrue.Emails.PaymentSucceeded)
    refute Accrue.Emails.PaymentSucceeded == Receipt
  end
end
