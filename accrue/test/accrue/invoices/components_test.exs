defmodule Accrue.Invoices.ComponentsTest do
  @moduledoc """
  Integration specs for the shared invoice component library.

  Asserts every component:

    * renders via `Accrue.Emails.HtmlBridge.render/2` outside a LiveView
      socket
    * stamps inline `style=` attributes on structural elements
      (Pitfall 2)
    * HTML-escapes user-controlled input (T-06-03-01)
    * respects the D6-07 transactional footer rule (no unsubscribe)

  Asserts `print_shell/1`:

    * wraps the four components in an html document
    * contains no `@page` CSS block (Pitfall 6)
  """

  use ExUnit.Case, async: true

  alias Accrue.Emails.HtmlBridge
  alias Accrue.Invoices.Components
  alias Accrue.Invoices.Layouts
  alias Accrue.Invoices.RenderContext

  defp build_context(overrides \\ %{}) do
    default_branding = [
      business_name: "TestCo",
      from_email: "noreply@testco.test",
      support_email: "support@testco.test",
      company_address: "123 Test Lane, Testville",
      logo_url: nil,
      accent_color: "#3B82F6",
      secondary_color: "#6B7280",
      font_stack: "Helvetica, Arial, sans-serif"
    ]

    default_ctx = %RenderContext{
      invoice: %{number: "INV-0001"},
      customer: %{name: "Jo Tester", email: "jo@example.test"},
      line_items: [
        %{description: "Widget", quantity: 2, amount_minor: 2000, currency: "usd"},
        %{description: "Gadget", quantity: 1, amount_minor: 1500, currency: "usd"}
      ],
      subtotal_minor: 3500,
      discount_minor: 0,
      tax_minor: nil,
      total_minor: 3500,
      currency: :usd,
      branding: default_branding,
      locale: "en",
      timezone: "Etc/UTC",
      now: ~U[2026-04-15 12:00:00Z],
      hosted_invoice_url: "https://testco.test/i/INV-0001",
      receipt_url: nil,
      formatted_total: "$35.00",
      formatted_subtotal: "$35.00",
      formatted_discount: nil,
      formatted_tax: nil,
      formatted_issued_at: "April 15, 2026"
    }

    Map.merge(default_ctx, overrides)
  end

  describe "invoice_header/1" do
    test "renders business_name + invoice number" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.invoice_header/1, %{context: ctx})

      assert out =~ "TestCo"
      assert out =~ "INV-0001"
      assert out =~ "Invoice #"
    end

    test "renders an <img> when logo_url is present" do
      branding =
        Keyword.put(build_context().branding, :logo_url, "https://testco.test/logo.png")

      ctx = %{build_context() | branding: branding}
      out = HtmlBridge.render(&Components.invoice_header/1, %{context: ctx})

      assert out =~ "<img"
      assert out =~ "https://testco.test/logo.png"
    end

    test "stamps inline style= attributes on structural elements" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.invoice_header/1, %{context: ctx})
      assert out =~ ~s(style=)
    end

    test "HTML-escapes injected invoice number" do
      ctx = build_context(%{invoice: %{number: "<script>alert(1)</script>"}})
      out = HtmlBridge.render(&Components.invoice_header/1, %{context: ctx})

      refute out =~ "<script>"
      assert out =~ "&lt;script&gt;"
    end
  end

  describe "line_items/1" do
    test "renders one <tr> per line item" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.line_items/1, %{context: ctx})

      assert out =~ "Widget"
      assert out =~ "Gadget"
      # Two item rows (plus header)
      assert out |> String.split("<tr") |> length() >= 3
    end

    test "renders headers Description / Qty / Amount" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.line_items/1, %{context: ctx})

      assert out =~ "Description"
      assert out =~ "Qty"
      assert out =~ "Amount"
    end

    test "renders an empty-items list without crashing" do
      ctx = build_context(%{line_items: []})
      out = HtmlBridge.render(&Components.line_items/1, %{context: ctx})
      assert is_binary(out)
      assert out =~ "Description"
    end

    test "HTML-escapes item description" do
      ctx =
        build_context(%{
          line_items: [
            %{description: "<b>evil</b>", quantity: 1, amount_minor: 100, currency: "usd"}
          ]
        })

      out = HtmlBridge.render(&Components.line_items/1, %{context: ctx})

      refute out =~ "<b>evil</b>"
      assert out =~ "&lt;b&gt;evil"
    end
  end

  describe "totals/1" do
    test "always renders Total row with formatted_total" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.totals/1, %{context: ctx})
      assert out =~ "Total"
      assert out =~ "$35.00"
    end

    test "renders Subtotal row when formatted_subtotal is present" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.totals/1, %{context: ctx})
      assert out =~ "Subtotal"
    end

    test "omits Tax row when formatted_tax is nil" do
      ctx = build_context(%{formatted_tax: nil})
      out = HtmlBridge.render(&Components.totals/1, %{context: ctx})
      refute out =~ "Tax"
    end

    test "omits Discount row when formatted_discount is nil" do
      ctx = build_context(%{formatted_discount: nil})
      out = HtmlBridge.render(&Components.totals/1, %{context: ctx})
      refute out =~ "Discount"
    end

    test "renders Discount row with leading minus when set" do
      ctx = build_context(%{formatted_discount: "$5.00"})
      out = HtmlBridge.render(&Components.totals/1, %{context: ctx})
      assert out =~ "Discount"
      assert out =~ "−$5.00"
    end
  end

  describe "footer/1" do
    test "always renders business_name and support_email" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.footer/1, %{context: ctx})

      assert out =~ "TestCo"
      assert out =~ "support@testco.test"
    end

    test "renders company_address row when set" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.footer/1, %{context: ctx})
      assert out =~ "123 Test Lane"
    end

    test "omits company_address row when nil" do
      branding = Keyword.delete(build_context().branding, :company_address)
      ctx = %{build_context() | branding: branding}
      out = HtmlBridge.render(&Components.footer/1, %{context: ctx})

      refute out =~ "123 Test Lane"
    end

    test "NEVER renders the string 'unsubscribe' (D6-07)" do
      ctx = build_context()
      out = HtmlBridge.render(&Components.footer/1, %{context: ctx})
      refute out =~ ~r/unsubscribe/i
    end
  end

  describe "Accrue.Invoices.Layouts.print_shell/1" do
    test "assembles all four components into a single html document" do
      ctx = build_context()
      out = HtmlBridge.render(&Layouts.print_shell/1, %{context: ctx})

      assert out =~ "<!DOCTYPE html>"
      assert out =~ "<html"
      assert out =~ "<body>"
      assert out =~ "TestCo"
      assert out =~ "INV-0001"
      assert out =~ "Widget"
      assert out =~ "Gadget"
      assert out =~ "$35.00"
      assert out =~ "support@testco.test"
    end

    test "contains NO @page CSS declaration (Pitfall 6)" do
      ctx = build_context()
      out = HtmlBridge.render(&Layouts.print_shell/1, %{context: ctx})
      refute out =~ "@page"
    end

    test "ships print-friendly CSS without @page" do
      ctx = build_context()
      out = HtmlBridge.render(&Layouts.print_shell/1, %{context: ctx})
      assert out =~ "margin: 0"
      assert out =~ "page-break-inside: avoid"
    end
  end
end
