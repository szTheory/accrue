defmodule AccruePortal.AuthPlug do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias AccruePortal.CustomerSession

  def init(opts), do: opts

  def call(conn, _opts) do
    case CustomerSession.resolve(get_session(conn)) do
      {:ok, user, customer} ->
        conn
        |> assign(:current_user, user)
        |> assign(:current_customer, customer)
        |> assign(
          :accrue_portal_mount_path,
          get_in(get_session(conn), ["accrue_portal", "mount_path"]) ||
            Accrue.Config.portal_mount_path()
        )

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You must sign in to access billing.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
