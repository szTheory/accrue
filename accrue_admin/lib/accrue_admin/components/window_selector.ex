defmodule AccrueAdmin.Components.WindowSelector do
  @moduledoc """
  Three-preset time window selector for analytics pages.

  Renders a `<nav>` with three `<.link patch>` preset buttons ("7 days UTC",
  "30 days UTC", "90 days UTC") that update the `?window=` URL param via
  LiveView client-side navigation. `handle_params/3` fires automatically —
  no `handle_event` callback is needed in the parent LiveView.

  ## Note on `base_path`

  `base_path` must be a clean path with no existing query params (e.g.,
  `"/billing/analytics/recovery"`). For paths with existing query params,
  build the URL via `URI.encode_query/1` instead of string concatenation.
  """

  use Phoenix.Component

  attr :current_window, :string, required: true  # "7d" | "30d" | "90d"
  attr :base_path, :string, required: true        # e.g. "/billing/analytics/recovery"

  @windows [{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]

  def window_selector(assigns) do
    assigns = assign(assigns, :windows, @windows)

    ~H"""
    <nav class="ax-tabs" aria-label="Time window (UTC)">
      <.link
        :for={{value, label} <- @windows}
        patch={@base_path <> "?window=" <> value}
        class={["ax-tab", @current_window == value && "ax-tab-active"]}
        aria-current={if @current_window == value, do: "page", else: nil}
      >
        <%= label %> UTC
      </.link>
    </nav>
    """
  end
end
