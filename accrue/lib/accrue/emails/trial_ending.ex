defmodule Accrue.Emails.TrialEnding do
  @moduledoc """
  Trial-ending reminder email.

  Triggered by the `customer.subscription.trial_will_end` Stripe webhook
  (usually 3 days before `trial_end`). Uses the shared transactional MJML
  scaffold + `Accrue.Invoices.Components.footer/1` via `HtmlBridge`.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/trial_ending.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Your #{b[:business_name]} trial is ending soon"

  def subject(_), do: "Your trial is ending soon"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/trial_ending.text.eex")
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
