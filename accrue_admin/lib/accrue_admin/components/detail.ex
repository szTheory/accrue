defmodule AccrueAdmin.Components.Detail do
  @moduledoc """
  Reusable building blocks for detail / object pages, following the Stripe-style
  skeleton: summary header → titled sections → label/value field lists.

  These exist so every detail screen (subscription, customer, invoice, charge,
  connect account, webhook) shares one layout vocabulary instead of hand-rolling
  cards, reaping consistency dividends as they're reused.
  """

  use Phoenix.Component

  @doc """
  A titled section wrapper (card). Optional `:actions` slot renders on the right
  of the section header.

      <Detail.detail_section title="Line items">
        <:actions><.button>Add</.button></:actions>
        ...content...
      </Detail.detail_section>
  """
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def detail_section(assigns) do
    ~H"""
    <section class={["ax-card", "ax-detail-section", @class]}>
      <header class="ax-detail-section-head">
        <h3 class="ax-detail-section-title"><%= @title %></h3>
        <div :if={@actions != []} class="ax-detail-section-actions"><%= render_slot(@actions) %></div>
      </header>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  @doc """
  A label → value field list (two columns). `fields` is a list of
  `%{label: ..., value: ...}` maps; values may be strings or rendered content.
  Monetary/numeric values inherit tabular figures from the admin root.
  """
  attr(:fields, :list, required: true)
  attr(:class, :any, default: nil)

  def detail_field_list(assigns) do
    ~H"""
    <dl class={["ax-field-list", @class]}>
      <div :for={field <- @fields} class="ax-field">
        <dt class="ax-field-label"><%= field.label %></dt>
        <dd class="ax-field-value"><%= field.value %></dd>
      </div>
    </dl>
    """
  end

  @doc """
  Summary header for a detail page: an eyebrow + identifier title, an optional
  status pill, and a primary-facts row, with an `:actions` slot on the right.
  """
  attr(:eyebrow, :string, default: nil)
  attr(:title, :string, required: true)
  slot(:status)
  slot(:facts)
  slot(:actions)

  def summary_card(assigns) do
    ~H"""
    <header class="ax-card ax-summary-card">
      <div class="ax-summary-main">
        <p :if={@eyebrow} class="ax-eyebrow"><%= @eyebrow %></p>
        <div class="ax-summary-title-row">
          <h2 class="ax-summary-title"><%= @title %></h2>
          <%= render_slot(@status) %>
        </div>
        <div :if={@facts != []} class="ax-summary-facts"><%= render_slot(@facts) %></div>
      </div>
      <div :if={@actions != []} class="ax-summary-actions"><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
