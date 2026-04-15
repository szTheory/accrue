defmodule AccrueAdmin.Components.Tabs do
  @moduledoc """
  Link-based tab navigation for admin detail and list subviews.
  """

  use Phoenix.Component

  attr(:tabs, :list, required: true)
  attr(:active, :string, required: true)

  def tabs(assigns) do
    ~H"""
    <nav class="ax-tabs" aria-label="Page sections">
      <a
        :for={tab <- @tabs}
        href={tab[:href]}
        class={["ax-tab", active_tab?(tab, @active) && "ax-tab-active"]}
        aria-current={if(active_tab?(tab, @active), do: "page", else: nil)}
      >
        <span><%= tab[:label] %></span>
        <span :if={tab[:count]} class="ax-tab-count"><%= tab[:count] %></span>
      </a>
    </nav>
    """
  end

  defp active_tab?(tab, active), do: to_string(tab[:id]) == to_string(active)
end
