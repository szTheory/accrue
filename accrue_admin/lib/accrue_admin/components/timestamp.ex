defmodule AccrueAdmin.Components.Timestamp do
  @moduledoc "Renders an exact timestamp with a browser-local display."

  use Phoenix.Component

  attr(:value, :any, default: nil)
  attr(:id, :string, required: true)

  def timestamp(assigns) do
    case assigns.value do
      %DateTime{} = value ->
        iso = DateTime.to_iso8601(value)

        assigns =
          assigns
          |> assign(:iso, iso)
          |> assign(:utc_text, Calendar.strftime(value, "%b %d, %Y %H:%M:%S UTC"))

        ~H"""
        <span id={@id} class="ax-timestamp" data-time-display data-iso={@iso} phx-hook="TimeDisplay">
          <button
            id={@id <> "-copy"}
            type="button"
            class="ax-timestamp-copy"
            phx-hook="Clipboard"
            data-clipboard-text={@iso}
            aria-label={"Copy timestamp " <> @iso}
          ><time datetime={@iso}><%= @utc_text %></time></button>
          <span class="ax-timestamp-zone" data-time-zone aria-live="polite">UTC</span>
          <span class="ax-visually-hidden" data-time-copy-status aria-live="polite"></span>
        </span>
        """

      _ ->
        ~H"""
        <span id={@id}>Time unavailable</span>
        """
    end
  end
end
