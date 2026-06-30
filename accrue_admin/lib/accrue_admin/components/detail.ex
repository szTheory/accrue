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
  A titled section wrapper. Optional `:actions` slot renders on the right
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
    <section class={["ax-detail-section", @class]}>
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
  GOV.UK-style summary list for object detail headers. `rows` is a list of maps
  with `:label`, `:value`, and optional action keys:

    * `:action_label` - visible action text, usually "Change" or "View"
    * `:action_context` - visually hidden context appended after the label
    * `:action_event`, `:action_value`, `:action_target` - LiveView button action
    * `:action_href` - link action

  Use this for row-level actions in the page summary. Keep `detail_field_list/1`
  for read-only drill-section field groups.
  """
  attr(:rows, :list, required: true)
  attr(:class, :any, default: nil)

  def summary_list(assigns) do
    ~H"""
    <dl class={["ax-summary-list", @class]} data-ax-summary-list>
      <div :for={row <- @rows} class="ax-summary-list-row">
        <dt class="ax-summary-list-key"><%= row_value(row, :label) %></dt>
        <dd class="ax-summary-list-value"><%= row_value(row, :value) %></dd>
        <dd :if={row_action?(row)} class="ax-summary-list-actions">
          <a
            :if={row_action_href(row)}
            href={row_action_href(row)}
            class="ax-summary-list-action"
          >
            <span><%= row_action_label(row) %></span>
            <span :if={row_action_context(row)} class="ax-visually-hidden"><%= " " <> row_action_context(row) %></span>
          </a>
          <button
            :if={!row_action_href(row) and row_action_event(row)}
            type="button"
            class="ax-summary-list-action"
            phx-click={row_action_event(row)}
            phx-target={row_action_target(row)}
            phx-value-action_type={row_action_value(row)}
          >
            <span><%= row_action_label(row) %></span>
            <span :if={row_action_context(row)} class="ax-visually-hidden"><%= " " <> row_action_context(row) %></span>
          </button>
        </dd>
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
    <header class="ax-card ax-summary-card" data-component-group="detail-header-metadata-actions">
      <div class="ax-summary-main">
        <p :if={@eyebrow} class="ax-eyebrow"><%= @eyebrow %></p>
        <div class="ax-summary-title-row">
          <h1 class="ax-summary-title"><%= @title %></h1>
          <%= render_slot(@status) %>
        </div>
        <div :if={@facts != []} class="ax-summary-facts"><%= render_slot(@facts) %></div>
      </div>
      <div :if={@actions != []} class="ax-summary-actions"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  defp row_value(row, key), do: Map.get(row, key) || Map.get(row, to_string(key))

  defp row_action?(row) do
    row_action_label(row) && (row_action_href(row) || row_action_event(row))
  end

  defp row_action_label(row), do: row_value(row, :action_label)

  defp row_action_context(row) do
    row_value(row, :action_context) || row_value(row, :hidden_context) || row_value(row, :context)
  end

  defp row_action_event(row), do: row_value(row, :action_event)
  defp row_action_href(row), do: row_value(row, :action_href)
  defp row_action_target(row), do: row_value(row, :action_target)
  defp row_action_value(row), do: row_value(row, :action_value)
end
