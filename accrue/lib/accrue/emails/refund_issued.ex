defmodule Accrue.Emails.RefundIssued do
  @moduledoc """
  Refund issued notification.

  Sent when Stripe emits `charge.refunded`. Body renders the full fee
  breakdown (`formatted_amount`, `formatted_stripe_fee_refunded`,
  `formatted_merchant_loss`) so the customer sees what was returned
  and what Stripe withheld. Does NOT embed the shared invoice
  components — refunds are a distinct flow from invoices.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/refund_issued.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{refund: %{formatted_amount: amt}}}) when is_binary(amt),
    do: "Refund issued: #{amt}"

  def subject(%{context: %{branding: b}}) when is_list(b) or is_map(b),
    do: "Refund issued by #{b[:business_name]}"

  def subject(_), do: "Refund issued"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/refund_issued.text.eex")
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
