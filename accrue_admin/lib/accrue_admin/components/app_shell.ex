defmodule AccrueAdmin.Components.AppShell do
  @moduledoc """
  Responsive layout shell shared by mounted admin LiveViews.
  """

  use Phoenix.Component

  alias AccrueAdmin.Components.{Sidebar, Topbar}
  alias AccrueAdmin.Nav

  attr(:brand, :map, required: true)
  attr(:current_path, :string, required: true)
  attr(:mount_path, :string, required: true)
  attr(:page_title, :string, required: true)
  attr(:theme, :string, default: "system")
  attr(:active_organization_name, :any, default: nil)
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    assigns =
      assign(assigns, :nav_items, Nav.items(assigns.mount_path, assigns.current_path))

    ~H"""
    <div class="ax-shell" data-mount-path={@mount_path}>
      <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />

      <div class="ax-shell-main">
        <div :if={@active_organization_name} class="ax-active-org-banner" role="status">
          <span class="ax-label">Active organization</span>
          <span class="ax-active-org-name"><%= @active_organization_name %></span>
        </div>

        <Topbar.topbar brand={@brand} page_title={@page_title} theme={@theme} />

        <main class="ax-shell-content" id="main-content">
          <%= render_slot(@inner_block) %>
        </main>
      </div>

      <.dev_toolbar current_path={@current_path} mount_path={@mount_path} />
    </div>
    """
  end

  if Mix.env() != :prod do
    attr(:current_path, :string, required: true)
    attr(:mount_path, :string, required: true)

    defp dev_toolbar(assigns) do
      ~H"""
      <AccrueAdmin.Components.DevToolbar.dev_toolbar
        :if={AccrueAdmin.Components.DevToolbar.visible?()}
        current_path={@current_path}
        mount_path={@mount_path}
      />
      """
    end
  else
    attr(:current_path, :string, required: true)
    attr(:mount_path, :string, required: true)

    defp dev_toolbar(assigns) do
      ~H""
    end
  end

end
