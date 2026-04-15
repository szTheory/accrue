defmodule Accrue.Emails.PaymentFailed do
  @moduledoc """
  Payment-failed notification (MAIL-04).

  Sent when a payment attempt fails. Body contains retry guidance and a
  CTA pointing at the host-supplied `@context[:update_pm_url]`. Dunning
  cadence and escalation live in the Phase 4 Dunning policy module —
  this email is only the customer-facing notification.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/payment_failed.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Action required: payment failed at #{b[:business_name]}"

  def subject(_), do: "Action required: payment failed"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/payment_failed.text.eex")
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
