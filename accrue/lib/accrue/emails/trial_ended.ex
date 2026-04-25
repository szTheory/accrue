defmodule Accrue.Emails.TrialEnded do
  @moduledoc """
  Trial-ended notification email.

  Sent after the trial period has concluded. Copy emphasizes that a
  payment method must be added to continue using the service.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/trial_ended.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Your #{b[:business_name]} trial has ended"

  def subject(_), do: "Your trial has ended"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/trial_ended.text.eex")
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
