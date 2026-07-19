defmodule AccrueAdmin.Components.StatStrip do
  @moduledoc """
  Compact inline metric strip for list/index pages.

  A quiet alternative to the KPI card band: renders a `<dl>` of label/value pairs
  in a single baseline-aligned row (hairline-separated, wrapping on narrow
  viewports). Use on list pages where the summary metrics should sit above the
  table without pushing it below the fold. The KPI card band (`KpiCard`) stays
  the treatment for the dashboard and detail-page summary rows.

  Each `:stat` slot accepts `label`, `value`, an optional `tone`
  (`moss` | `cobalt` | `amber`) that colors the value only, and an optional
  `href`. When `href` is set the `dt`/`dd` stay as direct children of the
  `.ax-stat` grouping `div` and the link is rendered as a "stretched link"
  overlay (absolutely positioned to cover the whole `.ax-stat`) carrying an
  accessible name built from the label and value. The overlay `<a>` lives
  *inside* the `<dd>` rather than as a sibling of `dt`/`dd`: axe's
  `definition-list` rule flattens role-less grouping `<div>`s and flags any
  resulting non-`dt`/`dd` child, but does not recurse into `dd`, so nesting the
  link there keeps the `<dl>` structurally clean while preserving the overlay.
  """

  use Phoenix.Component

  attr(:label, :string, required: true)
  attr(:component_group, :string, default: nil)

  slot :stat do
    attr(:label, :string)
    attr(:value, :string)
    attr(:tone, :string)
    attr(:href, :string)
  end

  def stat_strip(assigns) do
    ~H"""
    <dl class="ax-stat-strip" aria-label={@label} data-component-group={@component_group}>
      <div :for={stat <- @stat} class={["ax-stat", stat[:href] && "ax-stat--linked"]}>
        <dt class="ax-stat-label"><%= stat[:label] %></dt>
        <dd class={["ax-stat-value", tone_class(stat[:tone])]}>
          <span class="ax-stat-value-text"><%= stat[:value] %></span>
          <a
            :if={stat[:href]}
            class="ax-stat-link"
            href={stat[:href]}
            aria-label={"#{stat[:label]}: #{stat[:value]}"}
          ></a>
        </dd>
      </div>
    </dl>
    """
  end

  defp tone_class("moss"), do: "ax-stat-value--moss"
  defp tone_class("cobalt"), do: "ax-stat-value--cobalt"
  defp tone_class("amber"), do: "ax-stat-value--amber"
  defp tone_class(_tone), do: nil
end
