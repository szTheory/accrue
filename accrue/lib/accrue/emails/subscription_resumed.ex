defmodule Accrue.Emails.SubscriptionResumed do
  @moduledoc """
  Subscription-resumed notification.

  Sent when a previously paused subscription returns to `active`.
  Charges resume on the next billing cycle.
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/subscription_resumed.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Your #{b[:business_name]} subscription has resumed"

  def subject(_), do: "Your subscription has resumed"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/subscription_resumed.text.eex")
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
