defmodule AccrueAdmin.Components.KpiCard do
  @moduledoc """
  Shared KPI card for dashboard and detail-page summary rows.

  When `href` is set, the root becomes an anchor for full-card navigation. Linked cards
  should set `aria_label` to a short description for screen readers.
  """

  use Phoenix.Component

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:delta, :string, default: nil)
  attr(:delta_tone, :string, default: "slate")
  attr(:trend, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:href, :string, default: nil)
  attr(:aria_label, :string, default: nil)
  slot(:meta)
  slot(:sparkline)

  def kpi_card(assigns) do
    ~H"""
    <%= if @href do %>
      <a
        href={@href}
        class={["ax-card ax-kpi-card ax-kpi-card--linked", @class]}
        aria-label={@aria_label}
      >
        <.kpi_inner {assigns} />
      </a>
    <% else %>
      <article class={["ax-card ax-kpi-card", @class]}>
        <.kpi_inner {assigns} />
      </article>
    <% end %>
    """
  end

  defp kpi_inner(assigns) do
    ~H"""
    <header class="ax-kpi-card-header">
      <p class="ax-label"><%= @label %></p>
      <p :if={@trend} class="ax-body ax-kpi-trend"><%= @trend %></p>
    </header>

    <p class="ax-kpi-value"><%= @value %></p>

    <div class="ax-kpi-card-footer">
      <span :if={@delta} class={["ax-kpi-delta", "ax-kpi-delta-" <> normalize_tone(@delta_tone)]}>
        <%= @delta %>
      </span>
      <%= render_slot(@meta) %>
    </div>

    <div :if={@sparkline != []} class="ax-kpi-sparkline">
      <%= render_slot(@sparkline) %>
    </div>
    """
  end

  defp normalize_tone(tone) when tone in ["moss", "cobalt", "amber", "slate", "ink"], do: tone

  defp normalize_tone(tone) when tone in [:moss, :cobalt, :amber, :slate, :ink],
    do: Atom.to_string(tone)

  defp normalize_tone(_tone), do: "slate"
end
