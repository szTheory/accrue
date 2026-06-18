defmodule AccrueAdmin.Components.WindowSelector do
  @moduledoc """
  Three-preset time window selector for analytics pages.

  Renders a `<nav>` with three `<.link patch>` preset buttons ("7 days UTC",
  "30 days UTC", "90 days UTC") that update the `?window=` URL param via
  LiveView client-side navigation. `handle_params/3` fires automatically —
  no `handle_event` callback is needed in the parent LiveView.

  ## Note on `base_path`

  `base_path` may be a clean path or a path with existing query params. The
  component uses `URI` to safely replace the `?window=` param, so any existing
  query string is correctly overwritten rather than producing a double-`?` URL.
  """

  use Phoenix.Component

  # "7d" | "30d" | "90d"
  attr(:current_window, :string, required: true)
  # e.g. "/billing/analytics/recovery"
  attr(:base_path, :string, required: true)

  @windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]

  def window_selector(assigns) do
    assigns = assign(assigns, :windows, @windows)

    ~H"""
    <nav class="ax-tabs" aria-label="Time window (UTC)" data-component-group="tabs-subviews">
      <.link
        :for={{value, label} <- @windows}
        patch={window_href(@base_path, value)}
        class={["ax-tab", @current_window == value && "ax-tab-active"]}
        aria-current={if @current_window == value, do: "page", else: nil}
      >
        <%= label %> UTC
      </.link>
    </nav>
    """
  end

  defp window_href(base_path, value) do
    uri = URI.parse(base_path)

    query =
      uri.query
      |> decode_query()
      |> Map.put("window", value)
      |> URI.encode_query()

    uri
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
