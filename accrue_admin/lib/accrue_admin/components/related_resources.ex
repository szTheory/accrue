defmodule AccrueAdmin.Components.RelatedResources do
  @moduledoc """
  "Related billing" cross-link card for detail screens.

  Threads the billing graph so no detail page is a dead end: a Customer links to
  its subscriptions/invoices, an Invoice to its customer/subscription/charge, a
  Charge back to its invoice, and so on. Renders nothing when there are no links.

      <RelatedResources.related_resources items={[
        %{icon: :users, label: "Customer", value: "Acme Corp", href: ~p"/customers/123"},
        %{icon: :invoices, label: "Invoices", value: "3 open", href: ~p"/invoices?customer=123"}
      ]} />
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.Icon

  @doc """
  Renders a card of related-resource links.

  Each item is a map with `:icon` (an `AccrueAdmin.Components.Icon` name),
  `:label`, `:href`, and an optional `:value` (secondary line, e.g. an id or count).
  """
  attr(:title, :string, default: "Related billing")
  attr(:items, :list, required: true)

  def related_resources(assigns) do
    ~H"""
    <section :if={@items != []} class="ax-card ax-related ax-related-resources" aria-label={@title}>
      <header class="ax-related-head">
        <h3 class="ax-related-title"><%= @title %></h3>
      </header>
      <ul class="ax-related-list">
        <li :for={item <- @items}>
          <a class="ax-related-item" href={item.href}>
            <span class="ax-related-icon"><Icon.icon name={item.icon} size="sm" /></span>
            <span class="ax-related-text">
              <span class="ax-related-label"><%= item.label %></span>
              <span :if={item[:value]} class="ax-related-value"><%= item.value %></span>
            </span>
            <Icon.icon name={:chevron_right} size="sm" class="ax-related-chevron" />
          </a>
        </li>
      </ul>
    </section>
    """
  end
end
