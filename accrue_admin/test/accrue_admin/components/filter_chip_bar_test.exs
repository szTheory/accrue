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

  test "emits Phase 191 focus anchors for active chip apply and clear actions" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{
            id: :status,
            label: "Status",
            value: "past due",
            tone: :amber,
            active: true,
            href: "/billing/invoices?status=past_due"
          },
          %{
            id: :owner_scope,
            label: "Owner scope",
            value: "platform",
            tone: :slate,
            active: true,
            remove_href: "/billing/invoices"
          }
        ],
        label: "Active invoice filters"
      )

    assert html =~ ~s(data-phase191-focus="filter-chip-bar")
    assert html =~ ~s(data-phase191-focus="filter-chip-apply")
    assert html =~ ~s(data-phase191-focus="filter-chip-clear")
  end

  test "emits Phase 196 chips, result count, and clear-all markers together" do
    html =
      render_component(&FilterChipBar.filter_chip_bar/1,
        items: [
          %{
            id: :status_queue,
            label: "At risk",
            value: "past due · canceling",
            tone: :cobalt,
            active: true,
            remove_href: "/billing/subscriptions?view=all&org=acme"
          }
        ],
        label: "Subscription filters",
        result_count: 2,
        result_label: {"subscription", "subscriptions"},
        clear_all_href: "/billing/subscriptions?view=all&org=acme"
      )

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing 2 subscriptions"
    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/subscriptions?view=all&amp;org=acme")
    assert html =~ "At risk"
    assert html =~ "past due · canceling"
    assert html =~ ~s(data-phase191-focus="filter-chip-bar")
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
