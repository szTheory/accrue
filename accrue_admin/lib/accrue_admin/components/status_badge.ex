defmodule AccrueAdmin.Components.StatusBadge do
  @moduledoc """
  Semantic status badge with fixed admin palette mappings.
  """

  use Phoenix.Component

  attr(:status, :any, required: true)
  attr(:label, :string, default: nil)
  attr(:tone, :string, default: nil)

  def status_badge(assigns) do
    tone = assigns.tone || status_tone(assigns.status)

    assigns =
      assigns
      |> assign(:tone, tone)
      |> assign(:label_text, assigns.label || humanize(assigns.status))

    ~H"""
    <span class={["ax-status-badge", "ax-status-badge-" <> @tone]}>
      <span class="ax-status-dot" aria-hidden="true"></span>
      <span><%= @label_text %></span>
    </span>
    """
  end

  defp status_tone(status) when status in [:paid, :active, :succeeded, :success, :ok], do: "moss"

  defp status_tone(status)
       when status in [:draft, :processing, :info, :queued, :refunded, :trialing],
       do: "cobalt"

  defp status_tone(status)
       when status in [:past_due, :warning, :grace_period, :retrying, :requires_action],
       do: "amber"

  defp status_tone(status) when status in [:canceled, :neutral, :archived, :void], do: "slate"
  defp status_tone(_status), do: "ink"

  defp humanize(status) when is_atom(status), do: status |> Atom.to_string() |> humanize()

  defp humanize(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp humanize(_status), do: "Unknown"
end
