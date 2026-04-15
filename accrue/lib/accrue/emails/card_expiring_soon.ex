defmodule Accrue.Emails.CardExpiringSoon do
  @moduledoc """
  Card-expiring-soon reminder email.

  Triggered by the `Accrue.Workers.DetectExpiringCards` cron sweeper when
  a saved payment method is within the reminder threshold of its
  `exp_month`/`exp_year`. Not a Stripe webhook — this is Accrue-internal
  cron dispatch (see Phase 3).
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/card_expiring_soon.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Your card on file at #{b[:business_name]} is expiring soon"

  def subject(_), do: "Your card is expiring soon"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/card_expiring_soon.text.eex")
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
