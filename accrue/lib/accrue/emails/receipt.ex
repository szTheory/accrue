defmodule Accrue.Emails.Receipt do
  @moduledoc """
  Canonical receipt email.

  Sent when a one-off or subscription payment succeeds. This module does
  NOT attach a PDF — the PDF-bearing variant is `Accrue.Emails.InvoicePaid`.
  Both are registered in `Accrue.Workers.Mailer` dispatch.

  `Accrue.Emails.PaymentSucceeded` is a legacy alias retained for
  back-compat; downstream code should dispatch by atom (`:receipt`).
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/receipt.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Receipt from #{b[:business_name]}"

  def subject(_), do: "Receipt"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/receipt.text.eex")
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
