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
  attr(:current_owner_scope, :any, default: nil)
  attr(:active_organization_name, :any, default: nil)
  attr(:nav_attention_counts, :map, default: %{})
  slot(:inner_block, required: true)

  def app_shell(assigns) do
    assigns =
      assign(
        assigns,
        :nav_items,
        Nav.items(assigns.mount_path, assigns.current_path, assigns.nav_attention_counts)
      )
      |> assign(
        :stale_disable_selector,
        Enum.join(
          [
            "[data-stale-disable]",
            "button[phx-click]",
            "button[phx-submit]",
            "button[form]",
            "form[phx-submit] button[type='submit']",
            "form[phx-submit] button:not([type])",
            "input[type='submit'][phx-click]",
            "input[type='submit'][phx-submit]",
            "[data-role='confirm-action']",
            "[data-role='confirm-refund']",
            "[data-role='confirm-replay']",
            "[data-role='confirm-bulk-replay']",
            "[data-role='step-up-submit']"
          ],
          ", "
        )
      )

    ~H"""
    <div
      id="accrue-admin-shell"
      class="ax-shell"
      data-mount-path={@mount_path}
      data-connection-state="connected"
      data-stale-disable-selector={@stale_disable_selector}
      phx-hook="ConnectionState"
    >
      <Sidebar.sidebar brand={@brand} current_path={@current_path} items={@nav_items} />

      <div class="ax-shell-main">
        <div :if={@active_organization_name} class="ax-active-org-banner" role="status">
          <span class="ax-label">Active organization</span>
          <span class="ax-active-org-name"><%= @active_organization_name %></span>
        </div>

        <div
          id="accrue-admin-connection-status"
          class="ax-connection-state"
          role="status"
          aria-live="polite"
          aria-atomic="true"
          data-connection-status
          data-connection-state="connected"
          hidden
        >
          <span class="ax-status-dot" aria-hidden="true"></span>
          <span
            data-connection-state-message
            data-disconnected-copy="Connection lost. Reconnecting before actions can run."
            data-restored-copy="Connection restored. Review the current state before running an action."
          >
          </span>
        </div>

        <Topbar.topbar theme={@theme} />

        <main
          class="ax-shell-content ax-content"
          id="main-content"
          tabindex="-1"
          data-phase191-focus="main-content"
        >
          <%= render_slot(@inner_block) %>
        </main>
      </div>

      <.live_component
        module={AccrueAdmin.Components.GlobalSearch}
        id="global-search"
        mount_path={@mount_path}
        current_owner_scope={@current_owner_scope}
      />

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
