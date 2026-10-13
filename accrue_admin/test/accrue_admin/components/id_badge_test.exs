defmodule AccrueAdmin.Components.IdBadgeTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.IdBadge

  test "renders a click-to-copy chip wired to the registered Clipboard hook" do
    html =
      render_component(&IdBadge.id_badge/1,
        id: "ax-id-badge-cus_1",
        id_value: "cus_phase191_host_1",
        copy_label: "customer ID"
      )

    # Registered LiveView hook (survives infinite-scroll/filter re-render) + a unique DOM id.
    assert html =~ ~s(phx-hook="Clipboard")
    assert html =~ ~s(id="ax-id-badge-cus_1")

    # The clipboard payload + the visible/monospace id + full-text title.
    assert html =~ ~s(data-clipboard-text="cus_phase191_host_1")
    assert html =~ ~s(data-clipboard-label="customer ID")
    assert html =~ ~s(title="cus_phase191_host_1")
    assert html =~ "ax-id-badge-text"
    assert html =~ "cus_phase191_host_1"

    # Base + variant class pair (registry render-coverage guardrail).
    assert html =~ "ax-id-badge"
    assert html =~ "ax-id-badge-default"

    # Accessible default label and a copy affordance icon.
    assert html =~ ~s(aria-label="Copy cus_phase191_host_1")
    assert html =~ "<svg"
  end

  test "plain evidence retains keyboard copy semantics without a chip icon" do
    html = render_component(&IdBadge.id_badge/1, id_value: "customer-123", variant: "plain")
    assert html =~ "ax-id-badge-plain"
    assert html =~ ~s(data-clipboard-label="ID")
    assert html =~ ~s(data-clipboard-text="customer-123")
    assert html =~ ~s(aria-label="Copy customer-123")
    assert html =~ ~s(phx-hook="Clipboard")
    refute html =~ "<svg"
  end

  test "derives a stable DOM id from id_value when none is supplied" do
    html = render_component(&IdBadge.id_badge/1, id_value: "cus_derived")

    assert html =~ ~s(id="ax-id-badge-cus_derived")
  end

  test "honors an explicit accessible label override" do
    html =
      render_component(&IdBadge.id_badge/1,
        id: "ax-id-badge-x",
        id_value: "cus_x",
        label: "Copy customer id"
      )

    assert html =~ ~s(aria-label="Copy customer id")
  end
end
