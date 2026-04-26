defmodule Accrue.Emails.PaymentSucceededTest do
  use ExUnit.Case, async: true

  alias Accrue.Emails.PaymentSucceeded

  defp fixture do
    %{
      customer_name: "Jo Example",
      amount: "$10.00",
      invoice_number: "INV-4",
      receipt_url: "https://example.test/receipts/r_1"
    }
  end

  test "message/1 returns a Mailglass message" do
    message = PaymentSucceeded.message(fixture())

    assert %Mailglass.Message{} = message
    assert message.swoosh_email.subject == PaymentSucceeded.subject(fixture())
  end

  test "render/1 returns HTML with payment copy" do
    html = PaymentSucceeded.render(fixture())
    assert html =~ ~r/<html|<!DOCTYPE/i
    assert html =~ "Jo Example"
    assert html =~ "INV-4"
  end

  test "render_text/1 returns the receipt copy" do
    text = PaymentSucceeded.render_text(fixture())
    assert text =~ "Jo Example"
    assert text =~ "$10.00"
    assert text =~ "INV-4"
    assert text =~ "https://example.test/receipts/r_1"
  end
end
