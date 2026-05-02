defmodule AccruePortal.AuthHook do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [redirect: 2]

  alias AccruePortal.CustomerSession

  def on_mount(:ensure_customer, _params, session, socket) do
    case CustomerSession.resolve(session) do
      {:ok, user, customer} ->
        {:cont,
         socket
         |> assign(:accrue_portal_session, session)
         |> assign(:current_user, user)
         |> assign(:current_customer, customer)}

      {:error, _reason} ->
        {:halt, redirect(socket, to: "/")}
    end
  end
end
