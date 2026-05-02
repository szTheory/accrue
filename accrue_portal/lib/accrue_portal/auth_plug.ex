defmodule Accrue.Portal.AuthPlug do
  @moduledoc false

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import Plug.Conn

  alias Accrue.Portal.CustomerSession

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    session = get_session(conn)

    case CustomerSession.resolve(session, create?: false) do
      {:ok, user, customer} ->
        conn
        |> assign(:accrue_portal_session, session)
        |> assign(:current_user, user)
        |> assign(:current_customer, customer)
        |> assign(:accrue_portal_mount_path, redirect_path(session))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "You must sign in to access billing.")
        |> redirect(to: redirect_path(session))
        |> halt()
    end
  end

  defp redirect_path(%{"accrue_portal" => %{"mount_path" => mount_path}})
       when is_binary(mount_path) do
    mount_path
  end

  defp redirect_path(_session), do: Accrue.Config.portal_mount_path()
end

defmodule AccruePortal.AuthPlug do
  @moduledoc false

  defdelegate init(opts), to: Accrue.Portal.AuthPlug
  defdelegate call(conn, opts), to: Accrue.Portal.AuthPlug
end
