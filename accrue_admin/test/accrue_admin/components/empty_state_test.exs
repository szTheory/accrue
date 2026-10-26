defmodule AccrueAdmin.Components.EmptyStateTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.EmptyState

  test "groups heading, explanation, and recovery action as one reading unit" do
    html =
      render_component(fn assigns ->
        assigns = assigns

        ~H"""
        <EmptyState.empty_state icon={:inbox} title="Nothing in this list yet" body="Records appear here when they match this view.">
          <:actions><a href="/admin/invoices">Open invoices</a></:actions>
        </EmptyState.empty_state>
        """
      end)

    assert html =~
             ~r/class="ax-empty-content"[^>]*>.*Nothing in this list yet.*Records appear here when they match this view\..*Open invoices.*<\/div>/s,
           "the heading, explanation, and recovery action need a shared group"
  end
end
