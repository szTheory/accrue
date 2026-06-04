defmodule AccrueAdmin.Components.FilterChipBarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.FilterChipBar

  # --- Existing chip behavior ---

  test "renders active chips with label and tone" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [%{id: :status, label: "Status", value: "open", tone: :cobalt, active: true}],
        label: "Filters"
      )

    assert html =~ "Status"
    assert html =~ "open"
    assert html =~ "ax-filter-chip-cobalt"
  end

  test "renders empty label when no active chips" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [%{id: :status, label: "Status", value: "open", tone: :cobalt, active: false}],
        label: "Filters",
        empty_label: "Nothing filtered"
      )

    assert html =~ "Nothing filtered"
    refute html =~ "ax-filter-chip-cobalt"
  end

  test "renders remove_href as Clear link when set" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{
            id: :status,
            label: "Status",
            tone: :cobalt,
            active: true,
            remove_href: "/invoices"
          }
        ],
        label: "Filters"
      )

    assert html =~ ~s(href="/invoices")
    assert html =~ "Clear"
  end

  test "does not render Clear link when remove_href is absent" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [%{id: :status, label: "Status", tone: :cobalt, active: true}],
        label: "Filters"
      )

    refute html =~ "Clear"
  end

  # --- Plan 175-06: :href extension for inactive/lens chips ---

  test "renders chip label as <a href> when :href is set and active: true with no remove_href" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{
            id: :by_actor,
            label: "By actor",
            tone: :slate,
            active: true,
            href: "/billing/events?actor_type=admin"
          }
        ],
        label: "Quick filters"
      )

    assert html =~ ~s(href="/billing/events?actor_type=admin")
    assert html =~ "By actor"
  end

  test "renders chip label as plain span when :href is absent" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{id: :by_actor, label: "By actor", tone: :slate, active: true}
        ],
        label: "Quick filters"
      )

    refute html =~ ~s(href=)
    assert html =~ "By actor"
  end

  test ":href is ignored when remove_href is also set (remove_href takes precedence)" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{
            id: :by_actor,
            label: "By actor",
            tone: :cobalt,
            active: true,
            remove_href: "/billing/events",
            href: "/billing/events?actor_type=admin"
          }
        ],
        label: "Quick filters"
      )

    # remove_href renders as Clear link
    assert html =~ "Clear"
    assert html =~ ~s(href="/billing/events")
    # The activation href should NOT be rendered separately (Clear already gives navigation)
    refute html =~ ~s(href="/billing/events?actor_type=admin")
  end
end
