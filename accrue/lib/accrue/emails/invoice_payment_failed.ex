defmodule Accrue.Emails.InvoicePaymentFailed do
  @moduledoc """
  Invoice payment-failed notification (MAIL-09).

  Sent when Stripe emits `invoice.payment_failed`. Body contains a CTA
  pointing at `@context.invoice.hosted_invoice_url` (the Stripe-hosted
  pay-now page) so the customer can complete payment without Accrue
  hosting its own payment surface. Does NOT attach a PDF — the PDF is
  not available until the invoice is paid.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/invoice_payment_failed.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{invoice: %{number: num}}}) when is_binary(num),
    do: "Action required: payment failed for invoice #{num}"

  def subject(_), do: "Action required: invoice payment failed"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/invoice_payment_failed.text.eex")
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
