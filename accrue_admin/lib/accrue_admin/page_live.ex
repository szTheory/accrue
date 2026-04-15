defmodule AccrueAdmin.PageLive do
  @moduledoc false

  use Phoenix.LiveView

  @impl true
  def mount(_params, session, socket) do
    admin = Map.get(session, "accrue_admin", %{})

    socket =
      socket
      |> assign(:page_title, "Billing")
      |> assign(:assets_css_path, admin["assets_css_path"])
      |> assign(:assets_js_path, admin["assets_js_path"])
      |> assign(:admin_mount_path, admin["mount_path"])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="accrue-admin" data-mount-path={@admin_mount_path}>
      <h1>Accrue Admin</h1>
    </main>
    """
  end
end
