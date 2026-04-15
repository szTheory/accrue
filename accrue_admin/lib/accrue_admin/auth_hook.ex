defmodule AccrueAdmin.AuthHook do
  @moduledoc false

  import Phoenix.LiveView, only: [redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias Accrue.Auth

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_admin, _params, session, socket) do
    user = Auth.current_user(session)

    if Auth.admin?(user) do
      {:cont,
       socket
       |> assign(:accrue_admin_session, session)
       |> assign(:current_admin, user)
       |> assign(:step_up_pending, false)
       |> assign(:step_up_challenge, nil)
       |> assign(:step_up_error, nil)
       |> assign(:step_up_verified_at, nil)}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end
end
