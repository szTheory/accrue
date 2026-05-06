defmodule Accrue.Portal.AuthHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [redirect: 2]

  alias Accrue.Portal.CustomerSession

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_customer, _params, session, socket) do
    mount_customer(session, socket, create?: true)
  end

  def on_mount(:ensure_customer_no_create, _params, session, socket) do
    mount_customer(session, socket, create?: false)
  end

  defp mount_customer(session, socket, opts) do
    case CustomerSession.resolve(session, opts) do
      {:ok, user, customer} ->
        portal = Map.get(session, "accrue_portal", %{})

        {:cont,
         socket
         |> assign(:accrue_portal_session, session)
         |> assign(:brand, Map.get(portal, "brand", %{}))
         |> assign(:theme, Map.get(portal, "theme", "system"))
         |> assign(:csp_nonce, Map.get(portal, "csp_nonce"))
         |> assign(:brand_css_path, Map.get(portal, "brand_css_path"))
         |> assign(:assets_css_path, Map.get(portal, "assets_css_path"))
         |> assign(:assets_js_path, Map.get(portal, "assets_js_path"))
         |> assign(:phoenix_js_path, Map.get(portal, "phoenix_js_path"))
         |> assign(:live_view_js_path, Map.get(portal, "live_view_js_path"))
         |> assign(:current_user, user)
         |> assign(:current_customer, customer)}

      {:error, _reason} ->
        {:halt, redirect(socket, to: redirect_path(session))}
    end
  end

  defp redirect_path(%{"accrue_portal" => %{"mount_path" => mount_path}})
       when is_binary(mount_path) do
    mount_path
  end

  defp redirect_path(_session), do: "/"
end

defmodule AccruePortal.AuthHook do
  @moduledoc false

  defdelegate on_mount(name, params, session, socket), to: Accrue.Portal.AuthHook
end
