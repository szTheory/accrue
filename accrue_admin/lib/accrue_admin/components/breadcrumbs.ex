defmodule AccrueAdmin.Components.Breadcrumbs do
  @moduledoc """
  Page-header breadcrumb trail for mounted admin pages.
  """

  use Phoenix.Component

  attr(:items, :list, required: true)

  def breadcrumbs(assigns) do
    ~H"""
    <nav class="ax-breadcrumbs" aria-label="Breadcrumb">
      <ol class="ax-breadcrumbs-list">
        <li :for={{item, index} <- Enum.with_index(@items)} class="ax-breadcrumbs-item">
          <a :if={item[:href]} href={item[:href]} class="ax-breadcrumbs-link">
            <%= item[:label] %>
          </a>
          <span
            :if={!item[:href]}
            class="ax-breadcrumbs-current"
            aria-current={if(index == length(@items) - 1, do: "page", else: nil)}
          >
            <%= item[:label] %>
          </span>
          <span :if={index < length(@items) - 1} class="ax-breadcrumbs-separator" aria-hidden="true">
            /
          </span>
        </li>
      </ol>
    </nav>
    """
  end
end
