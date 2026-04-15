defmodule Accrue.Invoices.Components do
  @moduledoc """
  Phoenix.Component function components shared by email (via
  `Accrue.Emails.HtmlBridge` + `<mj-raw>`) and PDF (via
  `Accrue.Invoices.Layouts.print_shell/1`).

  ## Single source of truth

  Both the email HTML body and the PDF body assemble these four
  components (`invoice_header/1`, `line_items/1`, `totals/1`,
  `footer/1`) against the same `RenderContext`. That is the entire
  point of the Wave-2 render architecture — one component library,
  two output pipelines, byte-identical money strings.

  ## Inline-style discipline (Pitfall 2)

  Every structural element carries its CSS via `brand_style/1`, which
  reads from the frozen branding snapshot in `@context.branding`.
  MJML's post-render CSS inliner does NOT descend into `<mj-raw>`
  blocks — classname-only styles would be invisible in the final
  email. Inline-or-nothing.

  ## Transactional-only footer (D6-07)

  Accrue emails are transactional (receipts, dunning, invoice
  notifications) — CAN-SPAM exempts them from opt-out requirements,
  and adding an opt-out link to a receipt is actively harmful UX.
  The footer intentionally renders `business_name` + `support_email`
  + conditional `company_address` and NOTHING ELSE.
  """

  use Phoenix.Component

  attr(:context, :map, required: true)

  def invoice_header(assigns) do
    ~H"""
    <table
      style={brand_style(:table_reset, @context.branding)}
      role="presentation"
      cellpadding="0"
      cellspacing="0"
      width="100%"
    >
      <tr>
        <td style={brand_style(:logo_cell, @context.branding)}>
          <%= if @context.branding[:logo_url] do %>
            <img
              src={@context.branding[:logo_url]}
              alt={@context.branding[:business_name]}
              style="max-height: 48px;"
            />
          <% else %>
            <span><%= @context.branding[:business_name] %></span>
          <% end %>
        </td>
        <td style={brand_style(:number_cell, @context.branding)}>
          Invoice #<%= @context.invoice.number %>
        </td>
      </tr>
    </table>
    """
  end

  attr(:context, :map, required: true)

  def line_items(assigns) do
    ~H"""
    <table
      style={brand_style(:line_items, @context.branding)}
      role="presentation"
      cellpadding="0"
      cellspacing="0"
      width="100%"
    >
      <thead>
        <tr>
          <th style={brand_style(:th, @context.branding)}>Description</th>
          <th style={brand_style(:th, @context.branding)}>Qty</th>
          <th style={brand_style(:th, @context.branding)}>Amount</th>
        </tr>
      </thead>
      <tbody>
        <tr
          :for={item <- @context.line_items || []}
          style={brand_style(:line_row, @context.branding)}
        >
          <td style={brand_style(:td, @context.branding)}><%= item.description %></td>
          <td style={brand_style(:td_num, @context.branding)}><%= item.quantity %></td>
          <td style={brand_style(:td_num, @context.branding)}>
            <%= Accrue.Invoices.Render.format_money(
              item.amount_minor || 0,
              @context.currency,
              @context.locale
            ) %>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  attr(:context, :map, required: true)

  def totals(assigns) do
    ~H"""
    <table
      style={brand_style(:totals, @context.branding)}
      role="presentation"
      cellpadding="0"
      cellspacing="0"
      width="100%"
    >
      <tr
        :if={@context.formatted_subtotal}
        style={brand_style(:totals_row, @context.branding)}
      >
        <td style={brand_style(:totals_label, @context.branding)}>Subtotal</td>
        <td style={brand_style(:totals_value, @context.branding)}>
          <%= @context.formatted_subtotal %>
        </td>
      </tr>
      <tr
        :if={@context.formatted_discount}
        style={brand_style(:totals_row, @context.branding)}
      >
        <td style={brand_style(:totals_label, @context.branding)}>Discount</td>
        <td style={brand_style(:totals_value, @context.branding)}>
          −<%= @context.formatted_discount %>
        </td>
      </tr>
      <tr
        :if={@context.formatted_tax}
        style={brand_style(:totals_row, @context.branding)}
      >
        <td style={brand_style(:totals_label, @context.branding)}>Tax</td>
        <td style={brand_style(:totals_value, @context.branding)}>
          <%= @context.formatted_tax %>
        </td>
      </tr>
      <tr style={brand_style(:totals_row, @context.branding)}>
        <td style={brand_style(:totals_label, @context.branding)}><strong>Total</strong></td>
        <td style={brand_style(:totals_value, @context.branding)}>
          <strong><%= @context.formatted_total %></strong>
        </td>
      </tr>
    </table>
    """
  end

  attr(:context, :map, required: true)

  def footer(assigns) do
    ~H"""
    <table
      style={brand_style(:footer, @context.branding)}
      role="presentation"
      cellpadding="0"
      cellspacing="0"
      width="100%"
    >
      <tr>
        <td style={brand_style(:footer_line, @context.branding)}>
          <%= @context.branding[:business_name] %> &middot;
          <a
            href={"mailto:" <> to_string(@context.branding[:support_email])}
            style={brand_style(:footer_line, @context.branding)}
          >
            <%= @context.branding[:support_email] %>
          </a>
        </td>
      </tr>
      <tr :if={@context.branding[:company_address]}>
        <td style={brand_style(:footer_line, @context.branding)}>
          <%= @context.branding[:company_address] %>
        </td>
      </tr>
    </table>
    """
  end

  defp brand_style(key, branding), do: Accrue.Invoices.Styles.for(key, branding)
end
