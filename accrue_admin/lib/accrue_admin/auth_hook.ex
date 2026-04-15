defmodule AccrueAdmin.AuthHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:ensure_admin, _params, session, socket) do
    {:cont, assign(socket, :accrue_admin_session, session)}
  end
end
