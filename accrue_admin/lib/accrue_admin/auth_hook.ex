defmodule AccrueAdmin.AuthHook do
  @moduledoc false

  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias AccrueAdmin.OwnerScope

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_admin, params, session, socket) do
    case OwnerScope.resolve(session, params) do
      {:ok, owner_scope} ->
        user = owner_scope.current_admin

        {:cont,
         socket
         |> assign(:accrue_admin_session, session)
         |> assign(:current_admin, user)
         |> assign(:current_owner_scope, owner_scope)
         |> assign(:step_up_pending, false)
         |> assign(:step_up_challenge, nil)
         |> assign(:step_up_error, nil)
         |> assign(:step_up_verified_at, nil)
         |> assign(
           :active_organization_name,
           OwnerScope.active_organization_banner_name(owner_scope)
         )}

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/")}
    end
  end
end
