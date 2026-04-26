defmodule Accrue.Invoices.ComponentsTest do
  use ExUnit.Case, async: true

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

  defp render_component(component, assigns) do
    component
    |> apply([assigns])
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  test "invoice header, line items, totals and footer render safely" do
    ctx = build_context()

    header = render_component(&Components.invoice_header/1, %{context: ctx})
    items = render_component(&Components.line_items/1, %{context: ctx})
    totals = render_component(&Components.totals/1, %{context: ctx})
    footer = render_component(&Components.footer/1, %{context: ctx})

    assert header =~ "TestCo"
    assert header =~ "INV-0001"
    assert items =~ "Widget"
    assert totals =~ "$35.00"
    assert footer =~ "support@testco.test"
    refute footer =~ ~r/unsubscribe/i
  end

  test "components escape user input" do
    ctx =
      build_context(%{
        invoice: %{number: "<script>alert(1)</script>"},
        line_items: [
          %{description: "<b>evil</b>", quantity: 1, amount_minor: 100, currency: "usd"}
        ]
      })

    header = render_component(&Components.invoice_header/1, %{context: ctx})
    items = render_component(&Components.line_items/1, %{context: ctx})

    refute header =~ "<script>alert(1)</script>"
    refute items =~ "<b>evil</b>"
  end

  test "print shell assembles the full document without @page" do
    ctx = build_context()
    out = render_component(&Layouts.print_shell/1, %{context: ctx})

    assert out =~ "<!DOCTYPE html>"
    assert out =~ "TestCo"
    assert out =~ "$35.00"
    refute out =~ "@page"
  end
end
