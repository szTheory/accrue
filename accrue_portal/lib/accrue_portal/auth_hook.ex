defmodule Accrue.Portal.AuthHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [redirect: 2]

  alias Accrue.Portal.CustomerSession
  alias Accrue.Portal.Context

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_customer, params, session, socket) do
    mount_customer(session, socket, create?: true, pin: Map.get(params, "context_pin"))
  end

  def on_mount(:ensure_customer_no_create, params, session, socket) do
    mount_customer(session, socket, create?: false, pin: Map.get(params, "context_pin"))
  end

  def on_mount(:ensure_user, _params, session, socket) do
    case Accrue.Auth.current_user(session) do
      nil -> {:halt, redirect(socket, to: login_path(session))}
      actor -> {:cont, assign_portal_shell(socket, session, actor)}
    end
  end

  defp mount_customer(session, socket, opts) do
    resolution =
      case Keyword.get(opts, :pin) do
        pin when is_binary(pin) and pin != "" ->
          CustomerSession.resolve_pin(session, pin, endpoint: socket.endpoint)

        _ ->
          CustomerSession.resolve(session, opts)
      end

    case resolution do
      {:ok, %Context{} = context} ->
        pin =
          case Keyword.get(opts, :pin) do
            pin when is_binary(pin) and pin != "" ->
              pin

            _ ->
              case Context.mint_pin(context, socket.endpoint) do
                {:ok, pin} -> pin
                _ -> nil
              end
          end

        {:cont,
         socket
         |> assign_portal_shell(session, context.actor)
         |> assign(:current_actor, context.actor)
         |> assign(:current_billable, context.billable)
         |> assign(:current_context, context)
         |> assign(:current_context_pin, pin)
         |> assign(
           :current_context_adapter,
           get_in(session, ["accrue_portal", "context_adapter"])
         )
         |> assign(:current_customer, context.customer)}

      {:error, :unauthenticated} ->
        {:halt, redirect(socket, to: login_path(session))}

      {:error, _reason} ->
        {:halt, redirect(socket, to: blocked_path(session))}
    end
  end

  defp assign_portal_shell(socket, session, actor) do
    portal = Map.get(session, "accrue_portal", %{})

    socket
    |> assign(:accrue_portal_session, session)
    |> assign(:brand, Map.get(portal, "brand", %{}))
    |> assign(:theme, Map.get(portal, "theme", "system"))
    |> assign(:theme_locked, Map.get(portal, "theme_locked", false))
    |> assign(:csp_nonce, Map.get(portal, "csp_nonce"))
    |> assign(:brand_css_path, Map.get(portal, "brand_css_path"))
    |> assign(:assets_css_path, Map.get(portal, "assets_css_path"))
    |> assign(:assets_js_path, Map.get(portal, "assets_js_path"))
    |> assign(:phoenix_js_path, Map.get(portal, "phoenix_js_path"))
    |> assign(:live_view_js_path, Map.get(portal, "live_view_js_path"))
    |> assign(:base_path, Map.get(portal, "mount_path"))
    |> assign(:current_user, actor)
  end

  defp login_path(%{"accrue_portal" => %{"login_path" => login_path}})
       when is_binary(login_path) do
    login_path
  end

  defp login_path(_session), do: "/"

  defp blocked_path(%{"accrue_portal" => %{"blocked_path" => path}}) when is_binary(path),
    do: path

  defp blocked_path(%{"accrue_portal" => %{"mount_path" => path}}) when is_binary(path),
    do: String.trim_trailing(path, "/") <> "/blocked"

  defp blocked_path(_session), do: "/billing/blocked"
end

defmodule AccruePortal.AuthHook do
  @moduledoc false

  defdelegate on_mount(name, params, session, socket), to: Accrue.Portal.AuthHook
end
