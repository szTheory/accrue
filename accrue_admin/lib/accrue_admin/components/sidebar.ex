defmodule AccrueAdmin.Components.Sidebar do
  @moduledoc """
  Sidebar navigation for the admin shell.

  Supports collapsible specialist-zone groups (Recovery, Developer, Catalog) and
  status-toned attention-count badges on group headers. The primary Billing group
  is always expanded (no toggle, no chevron).

  ## Group rendering rules
  - `collapsible: false` (nil group, Billing, Connect) → static `<p>` label or no label.
  - `collapsible: true` (Recovery, Developer, Catalog) → `<button>` toggle with
    `aria-expanded`, `aria-controls`, chevron icon, and optional status-toned badge.
  - Badge renders only when `group_meta.badge` is a positive integer.
  - Link list wraps in `<div id="sidebar-group-links-{slug}" hidden={collapsed?}>`.
  - Default expanded state: true when collapsible is false OR badge > 0.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

  attr(:brand, :map, required: true)
  attr(:current_path, :string, required: true)
  attr(:items, :list, required: true)

  def sidebar(assigns) do
    ~H"""
    <aside class="ax-sidebar" aria-label="Admin navigation">
      <div class="ax-sidebar-brand">
        <%= if @brand.logo_url do %>
          <img src={@brand.logo_url} alt={@brand.app_name} class="ax-sidebar-logo" />
        <% else %>
          <span class="ax-sidebar-mark" aria-hidden="true">A</span>
        <% end %>

        <div>
          <p class="ax-sidebar-name"><%= @brand.app_name %></p>
          <p class="ax-sidebar-brand-sub">Accrue Admin</p>
        </div>
      </div>

      <nav class="ax-sidebar-nav">
        <%= for {group, items, group_meta} <- grouped_items(@items) do %>
          <section
            id={"sidebar-group-section-#{slugify(group)}"}
            class="ax-sidebar-nav-group"
            phx-hook={if group_meta.collapsible, do: "SidebarCollapse"}
            data-group={if group_meta.collapsible, do: slugify(group)}
            data-controls={if group_meta.collapsible, do: "sidebar-group-links-#{slugify(group)}"}
          >
            <%= if group_meta.collapsible do %>
              <button
                class="ax-sidebar-group-label ax-sidebar-group-toggle"
                type="button"
                aria-expanded={to_string(group_initially_expanded?(group_meta))}
                aria-controls={"sidebar-group-links-#{slugify(group)}"}
                data-collapse-toggle="true"
              >
                <%= group %>
                <span
                  :if={group_meta.badge}
                  class={badge_class(group_meta.tone)}
                  aria-label={badge_aria_label(group, group_meta.badge)}
                >
                  <%= group_meta.badge %>
                </span>
                <Icon.icon name={:chevron_right} size="sm" class="ax-sidebar-group-chevron" />
              </button>
            <% else %>
              <p :if={group} class="ax-sidebar-group-label"><%= group %></p>
            <% end %>

            <div id={"sidebar-group-links-#{slugify(group)}"} class="ax-sidebar-group-links" hidden={not group_initially_expanded?(group_meta)}>
              <a :for={item <- items} href={item.href} class={nav_class(item, @current_path)}>
                <Icon.icon name={item.icon} size="sm" class="ax-sidebar-link-icon" />
                <span class="ax-sidebar-link-label"><%= item.label %></span>
              </a>
            </div>
          </section>
        <% end %>
      </nav>
    </aside>
    """
  end

  # Returns {group, items, group_meta} 3-tuples. group_meta is derived from the first item
  # in each group (all items in a group share :collapsible and :badge per nav.ex convention).
  #
  # Uses Enum.group_by (order-independent) followed by a deterministic sort so
  # duplicate groups are merged even if Nav.items/3 ever returns them
  # non-contiguously (e.g. from a plugin-injected item list).  Group ordering
  # follows the first occurrence of each group key in the original list, which
  # preserves the Nav.items/3 document order.
  defp grouped_items(items) do
    grouped = Enum.group_by(items, &Map.get(&1, :group))

    # Determine group ordering from first-occurrence position in the original list.
    group_order =
      items
      |> Enum.map(&Map.get(&1, :group))
      |> Enum.uniq()

    Enum.map(group_order, fn group ->
      group_items = Map.fetch!(grouped, group)
      [first | _] = group_items
      collapsible = Map.get(first, :collapsible, false)
      badge = Map.get(first, :badge)
      tone = badge_tone(group)
      group_meta = %{collapsible: collapsible, badge: badge, tone: tone}
      {group, group_items, group_meta}
    end)
  end

  # True when group is always-expanded (collapsible: false) OR has badge work to show.
  defp group_initially_expanded?(%{collapsible: false}), do: true
  defp group_initially_expanded?(%{badge: badge}) when is_integer(badge) and badge > 0, do: true
  defp group_initially_expanded?(_), do: false

  # Returns the full CSS class string for a badge based on tone.
  defp badge_class(:warning), do: "ax-badge ax-badge-warning"
  defp badge_class(:danger), do: "ax-badge ax-badge-danger"
  defp badge_class(_), do: "ax-badge"

  # Returns an accessible aria-label string for a group badge.
  defp badge_aria_label("Recovery", n), do: "#{n} at-risk subscriptions"
  defp badge_aria_label("Developer", n), do: "#{n} webhooks need attention"
  defp badge_aria_label(group, n), do: "#{n} #{group} items need attention"

  # Maps group name to status tone for badge coloring.
  defp badge_tone("Recovery"), do: :warning
  defp badge_tone("Developer"), do: :danger
  defp badge_tone(_), do: :neutral

  # Converts a group name to a lowercase slug for use in HTML IDs and data attributes.
  # Returns a fallback "ungrouped" for nil groups.
  defp slugify(nil), do: "ungrouped"

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp nav_class(item, current_path) do
    current_path_root = current_path |> URI.parse() |> Map.get(:path) |> Kernel.||("")
    item_root = item.href |> URI.parse() |> Map.get(:path) |> Kernel.||("")

    active? =
      if item.label == "Home" do
        current_path_root == item_root
      else
        current_path_root == item_root or String.starts_with?(current_path_root, item_root <> "/")
      end

    if active? do
      "ax-sidebar-link ax-sidebar-link-active"
    else
      "ax-sidebar-link"
    end
  end
end
