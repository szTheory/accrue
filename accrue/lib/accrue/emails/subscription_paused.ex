defmodule Accrue.Emails.SubscriptionPaused do
  @moduledoc """
  Subscription-paused notification (MAIL-11a).

  Sent when a subscription transitions to `paused`. When
  `@context[:pause_behavior]` is supplied it's rendered in the body to
  describe the pause semantics (e.g. `keep_as_draft`, `mark_uncollectible`,
  `void`).
  """

  use MjmlEEx,
    mjml_template: "../../../priv/accrue/templates/emails/subscription_paused.mjml.eex"

  @spec subject(map()) :: String.t()
  def subject(%{context: %{branding: b}}),
    do: "Your #{b[:business_name]} subscription is paused"

  def subject(_), do: "Your subscription is paused"

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    EEx.eval_file(text_template_path(), assigns: to_keyword(assigns))
  end

  defp text_template_path do
    Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/subscription_paused.text.eex")
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
