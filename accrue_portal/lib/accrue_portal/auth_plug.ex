defmodule Accrue.Portal.AuthPlug do
  @moduledoc false

  import Phoenix.Controller, only: [current_path: 1, put_flash: 3, redirect: 2]
  import Plug.Conn

  alias Accrue.Portal.CustomerSession
  alias Accrue.Portal.Context

  @spec init(keyword()) :: keyword()
  def init(opts) do
    opts
    |> Keyword.validate!(
      customer_required: true,
      login_path: "/",
      mount_path: Accrue.Config.portal_mount_path(),
      context_adapter: nil,
      session_keys: []
    )
    |> Keyword.update!(:login_path, &normalize_local_path!/1)
    |> Keyword.update!(:mount_path, &Accrue.Config.normalize_mount_path/1)
  end

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    session = get_session(conn)

    if Keyword.fetch!(opts, :customer_required) do
      require_customer(conn, session, opts)
    else
      require_user(conn, session, opts)
    end
  end

  defp require_customer(conn, session, opts) do
    context_opts =
      opts
      |> Keyword.take([:context_adapter, :session_keys, :mount_path])
      |> Keyword.put(:create?, false)

    case CustomerSession.resolve(session, context_opts) do
      {:ok, %Context{} = context} ->
        conn
        |> assign_authenticated(session, context.actor, context.customer, opts)
        |> assign(:current_actor, context.actor)
        |> assign(:current_billable, context.billable)
        |> assign(:current_context, context)

      {:error, :unauthenticated} ->
        redirect_to_login(conn, opts)

      {:error, _reason} ->
        redirect_to_blocked(conn, opts)
    end
  end

  defp require_user(conn, session, opts) do
    case Accrue.Auth.current_user(session) do
      nil -> redirect_to_login(conn, opts)
      user -> assign_authenticated(conn, session, user, nil, opts)
    end
  end

  defp assign_authenticated(conn, session, user, customer, opts) do
    conn
    |> assign(:accrue_portal_session, session)
    |> assign(:current_user, user)
    |> assign(:current_customer, customer)
    |> assign(:accrue_portal_mount_path, Keyword.fetch!(opts, :mount_path))
  end

  defp redirect_to_blocked(conn, opts) do
    mount_path = Keyword.fetch!(opts, :mount_path)

    conn
    |> redirect(to: String.trim_trailing(mount_path, "/") <> "/blocked")
    |> halt()
  end

  defp redirect_to_login(conn, opts) do
    conn
    |> put_flash(:error, "You must sign in to access billing.")
    |> maybe_store_return_to()
    |> redirect(to: Keyword.fetch!(opts, :login_path))
    |> halt()
  end

  defp maybe_store_return_to(%Plug.Conn{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp normalize_local_path!(path) when is_binary(path) do
    if Accrue.Portal.Context.valid_local_path?(path) do
      path
    else
      raise ArgumentError, ":login_path must be a local path beginning with /"
    end
  end

  defp normalize_local_path!(path) do
    raise ArgumentError, ":login_path must be a string, got: #{inspect(path)}"
  end
end

defmodule AccruePortal.AuthPlug do
  @moduledoc false

  defdelegate init(opts), to: Accrue.Portal.AuthPlug
  defdelegate call(conn, opts), to: Accrue.Portal.AuthPlug
end
