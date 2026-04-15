defmodule Accrue.Emails.InvoicePaid do
  @moduledoc """
  Invoice paid confirmation (MAIL-08).

  Sent when Stripe emits `invoice.paid`. Embeds `invoice_header/1`,
  `line_items/1`, and `totals/1` components via `HtmlBridge` so the
  email body mirrors the eventual PDF attachment one-to-one.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/invoice_paid.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{invoice: %{number: num}}}) when is_binary(num),
    do: "Payment received for invoice #{num}"

  def subject(%{context: %{branding: b}}),
    do: "Payment received at #{b[:business_name]}"

  def subject(_), do: "Payment received"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/invoice_paid.text.eex")
  end

  defp to_keyword(map) do
    Enum.reduce(map, [], fn
      {k, v}, acc when is_atom(k) ->
        [{k, v} | acc]

      {k, v}, acc when is_binary(k) ->
        try do
          [{String.to_existing_atom(k), v} | acc]
        rescue
          ArgumentError -> acc
        end
    end)
  end
end
