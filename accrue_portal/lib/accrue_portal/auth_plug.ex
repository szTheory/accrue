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

    resolution =
      if pinned_form_post?(conn, Keyword.fetch!(opts, :mount_path)) do
        case conn.params do
          %{"context_pin" => pin} when is_binary(pin) and pin != "" ->
            CustomerSession.resolve_pin(
              session,
              pin,
              Keyword.put(context_opts, :endpoint, conn.private[:phoenix_endpoint])
            )

          _ ->
            {:error, :unavailable}
        end
      else
        CustomerSession.resolve(session, context_opts)
      end

    case resolution do
      {:ok, %Context{} = context} ->
        conn
        |> assign_authenticated(session, context.actor, context.customer, opts)
        |> assign(:current_actor, context.actor)
        |> assign(:current_billable, context.billable)
        |> assign(:current_context, context)
        |> assign(:current_context_adapter, Keyword.fetch!(opts, :context_adapter))
        |> assign(:current_context_session_keys, Keyword.fetch!(opts, :session_keys))

      {:error, :unauthenticated} ->
        redirect_to_login(conn, opts)

      {:error, _reason} ->
        conn =
          if checkout_completion_post?(conn, Keyword.fetch!(opts, :mount_path)) do
            put_flash(conn, :error, "Checkout access is unavailable. No payment was submitted.")
          else
            conn
          end

        redirect_to_blocked(conn, opts)
    end
  end

  defp pinned_form_post?(%Plug.Conn{method: "POST", request_path: path}, mount_path) do
    base = String.trim_trailing(mount_path, "/")

    String.starts_with?(path, base <> "/payment-methods") or
      String.starts_with?(path, base <> "/checkout/")
  end

  defp pinned_form_post?(_, _), do: false

  defp checkout_completion_post?(%Plug.Conn{method: "POST", request_path: path}, mount_path) do
    String.starts_with?(path, String.trim_trailing(mount_path, "/") <> "/checkout/")
  end

  defp checkout_completion_post?(_, _), do: false

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
