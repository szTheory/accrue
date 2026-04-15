defmodule Accrue.Emails.InvoiceMultipartCoverageTest do
  @moduledoc """
  MAIL-15 multipart coverage guard — invoice-bearing half (Plan 06-06).

  Complements `Accrue.Emails.MultipartCoverageTest` (Plan 06-05, non-invoice
  types) by iterating the 5 invoice-bearing atoms, resolving each via
  `Accrue.Workers.Mailer.resolve_template/1`, and asserting subject/1,
  render/1 and render_text/1 return non-empty binaries and contain no
  unsubscribe text (D6-07 library-wide invariant).
  """

  use ExUnit.Case, async: true

  @types [
    :invoice_finalized,
    :invoice_paid,
    :invoice_payment_failed,
    :refund_issued,
    :coupon_applied
  ]

  setup do
    context = %{
      branding: [
        business_name: "Acme",
        from_email: "no-reply@acme.test",
        support_email: "support@acme.test",
        font_stack: "Helvetica, Arial, sans-serif",
        logo_url: nil,
        company_address: nil,
        accent_color: "#1F6FEB",
        secondary_color: "#6B7280"
      ],
      customer: %{name: "Jo", email: "jo@acme.test"},
      invoice: %{
        number: "INV-1",
        hosted_invoice_url: "https://example.test/invoices/in_1"
      },
      line_items: [
        %{description: "Pro plan", quantity: 1, amount_minor: 2000}
      ],
      currency: :usd,
      locale: "en",
      formatted_total: "$20.00",
      formatted_subtotal: "$20.00",
      formatted_discount: nil,
      formatted_tax: nil,
      refund: %{
        id: "re_1",
        formatted_amount: "$10.00",
        formatted_stripe_fee_refunded: "$0.30",
        formatted_merchant_loss: "$0.00"
      },
      charge: %{id: "ch_1"},
      coupon: %{name: "Welcome", percent_off: 10, formatted_amount_off: nil},
      promotion_code: %{code: "WELCOME10"}
    }

    {:ok, assigns: %{context: context, subject: "Test", preview: "Test"}}
  end

  for type <- @types do
    test "#{type} exports subject + render + render_text returning non-empty binaries",
         %{assigns: assigns} do
      type = unquote(type)
      module = Accrue.Workers.Mailer.resolve_template(type)

      assert is_atom(module) and not is_nil(module)
      assert Code.ensure_loaded?(module)
      assert function_exported?(module, :subject, 1)
      assert function_exported?(module, :render, 1)
      assert function_exported?(module, :render_text, 1)

      subject = module.subject(assigns)
      html = module.render(assigns)
      text = module.render_text(assigns)

      assert is_binary(subject) and byte_size(subject) > 0, "#{inspect(type)} subject empty"
      assert is_binary(html) and byte_size(html) > 0, "#{inspect(type)} html empty"
      assert is_binary(text) and byte_size(text) > 0, "#{inspect(type)} text empty"

      assert html =~ ~r/<html|<!DOCTYPE/i, "#{inspect(type)} html does not look like HTML"

      refute text =~ ~r/<html|<body|<script/i,
             "#{inspect(type)} plain text contains HTML tags"

      refute String.downcase(text) =~ "unsubscribe",
             "D6-07 violation: unsubscribe in #{inspect(type)} text"

      refute String.downcase(html) =~ "unsubscribe",
             "D6-07 violation: unsubscribe in #{inspect(type)} html"
    end
  end
end
