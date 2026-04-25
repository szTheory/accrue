defmodule Accrue.Emails.InvoiceFinalized do
  @moduledoc """
  Invoice finalized notification.

  Sent when Stripe emits `invoice.finalized`. The PDF-attachment branch
  is wired by `Accrue.Workers.Mailer` — this module only provides the
  subject/body. The template embeds
  `Accrue.Invoices.Components.invoice_header/1`, `line_items/1`, and
  `totals/1` via `Accrue.Emails.HtmlBridge` inside `<mj-raw>` blocks so
  email and PDF share one component library (single source of truth).
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/invoice_finalized.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b, invoice: %{number: num}}}) when is_binary(num),
    do: "Invoice #{num} from #{b[:business_name]}"

  def subject(%{context: %{branding: b}}),
    do: "Your invoice from #{b[:business_name]}"

  def subject(_), do: "Your invoice"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/invoice_finalized.text.eex")
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
