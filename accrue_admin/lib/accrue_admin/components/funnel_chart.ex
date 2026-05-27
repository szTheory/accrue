defmodule AccrueAdmin.Components.FunnelChart do
  @moduledoc """
  3-stage dunning funnel: Entered → Recovered / Exhausted, with an "active" chip
  for in-flight campaigns.

  Renders an inline-SVG horizontal proportional-bar funnel (no JS chart lib).
  Three stacked `<rect>` rows reuse the existing `ax-kpi-delta-{slate,moss,amber}`
  tone palette via `.ax-funnel-row--{slate,moss,amber}` modifier classes. An
  external `<dl>` legend mirrors the same counts/percentages so a screen reader
  or zoomed-out viewport still surfaces the data.

  ## Accessibility

  The SVG declares `role="img"` and links a `<title>` + `<desc>` pair via
  `aria-labelledby="funnel-title funnel-desc"`. Each `<rect>` carries an inline
  `<title>` so hover/screen-reader tooltips explain the stage.

  ## Example

      <FunnelChart.funnel_chart
        entered={10}
        recovered={4}
        exhausted={3}
        active={3}
      />

  @since "1.4.0"
  """

  use Phoenix.Component

  attr(:entered, :integer, required: true)
  attr(:recovered, :integer, required: true)
  attr(:exhausted, :integer, required: true)
  attr(:active, :integer, required: true)
  attr(:class, :string, default: nil)

  def funnel_chart(assigns) do
    assigns =
      assigns
      |> assign(:recovered_pct, pct(assigns.recovered, assigns.entered))
      |> assign(:exhausted_pct, pct(assigns.exhausted, assigns.entered))

    ~H"""
    <article class={["ax-card", "ax-funnel-chart", @class]}>
      <header class="ax-funnel-header">
        <p class="ax-label">Recovery Funnel</p>
        <span class="ax-funnel-active-chip"><%= @active %> currently in dunning</span>
      </header>

      <svg
        viewBox="0 0 100 36"
        role="img"
        aria-labelledby="funnel-title funnel-desc"
        preserveAspectRatio="none"
        class="ax-funnel-svg"
      >
        <title id="funnel-title">Dunning recovery funnel</title>
        <desc id="funnel-desc">
          <%= @entered %> campaigns entered, <%= @recovered %> recovered, <%= @exhausted %> exhausted.
        </desc>

        <g transform="translate(0,0)" class="ax-funnel-row ax-funnel-row--slate">
          <rect width="100" height="10" rx="1.5" class="ax-funnel-bar">
            <title>Entered: <%= @entered %> campaigns</title>
          </rect>
        </g>
        <g transform="translate(0,12)" class="ax-funnel-row ax-funnel-row--moss">
          <rect width={@recovered_pct} height="10" rx="1.5" class="ax-funnel-bar">
            <title>Recovered: <%= @recovered %> campaigns (<%= @recovered_pct %>% of entered)</title>
          </rect>
        </g>
        <g transform="translate(0,24)" class="ax-funnel-row ax-funnel-row--amber">
          <rect width={@exhausted_pct} height="10" rx="1.5" class="ax-funnel-bar">
            <title>
              Exhausted: <%= @exhausted %> campaigns (<%= @exhausted_pct %>% of entered). A $120/yr plan that exhausts dunning contributes $10/mo to Exhausted MRR — annualized MRR snapshot at the exhaustion event.
            </title>
          </rect>
        </g>
      </svg>

      <dl class="ax-funnel-legend">
        <div class="ax-funnel-legend-row">
          <dt>Entered</dt>
          <dd><%= @entered %></dd>
        </div>
        <div class="ax-funnel-legend-row">
          <dt>Recovered</dt>
          <dd>
            <%= @recovered %> <span class="ax-muted">(<%= @recovered_pct %>%)</span>
          </dd>
        </div>
        <div class="ax-funnel-legend-row">
          <dt>Exhausted</dt>
          <dd>
            <%= @exhausted %> <span class="ax-muted">(<%= @exhausted_pct %>%)</span>
          </dd>
        </div>
      </dl>
    </article>
    """
  end

  defp pct(_n, 0), do: 0
  defp pct(n, total), do: round(n * 100 / total)
end
