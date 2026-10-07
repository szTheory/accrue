defmodule Accrue.Portal.Router do
  @moduledoc """
  Router helpers for mounting the `:accrue_portal` package into a host app.
  """

  import Phoenix.LiveView.Router
  import Plug.Conn, only: [get_session: 2]

  @default_on_mount [{Accrue.Portal.AuthHook, :ensure_customer}]
  @default_session_keys []
  @default_login_path "/"

  @doc """
  Mounts the portal package at `path`.

  ## Options

    * `:session_keys` - explicit host session keys to thread into the portal
      LiveView session
    * `:login_path` - local host-app path used when unauthenticated visitors
      request protected portal pages
    * `:on_mount` - additional LiveView `on_mount` hooks
  """
  defmacro accrue_portal(path, opts \\ []) do
    opts = Macro.expand_literals(opts, __CALLER__)
    validated = validate_opts!(path, opts)
    mount_path = validated[:mount_path]
    session_keys = validated[:session_keys]
    login_path = validated[:login_path]
    on_mount = validated[:on_mount]
    context_adapter = validated[:context_adapter]
    session_name = validated[:session_name]
    blocked_session_name = validated[:blocked_session_name]
    browser_pipeline = validated[:browser_pipeline]
    authenticated_pipeline = validated[:authenticated_pipeline]
    live_authenticated_pipeline = validated[:live_authenticated_pipeline]
    scope_name = validated[:scope_name]

    quote bind_quoted: [
            mount_path: mount_path,
            session_keys: session_keys,
            login_path: login_path,
            context_adapter: context_adapter,
            session_name: session_name,
            blocked_session_name: blocked_session_name,
            browser_pipeline: browser_pipeline,
            authenticated_pipeline: authenticated_pipeline,
            live_authenticated_pipeline: live_authenticated_pipeline,
            scope_name: scope_name,
            on_mount: on_mount
          ] do
      import Phoenix.LiveView.Router, only: [fetch_live_flash: 2]

      pipeline browser_pipeline do
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:protect_from_forgery)
        plug(Accrue.Portal.CSPPlug)
        plug(Accrue.Portal.BrandPlug)
      end

      pipeline authenticated_pipeline do
        plug(Accrue.Portal.AuthPlug,
          mount_path: mount_path,
          login_path: login_path,
          context_adapter: context_adapter,
          session_keys: session_keys
        )
      end

      pipeline live_authenticated_pipeline do
        plug(Accrue.Portal.AuthPlug,
          mount_path: mount_path,
          login_path: login_path,
          customer_required: false,
          context_adapter: context_adapter,
          session_keys: session_keys
        )
      end

      scope mount_path, as: scope_name do
        get("/assets/brand-#{AccruePortal.Assets.brand_hash()}", AccruePortal.Assets, :brand)
        get("/assets/css-#{AccruePortal.Assets.css_hash()}", AccruePortal.Assets, :css)
        get("/assets/js-#{AccruePortal.Assets.js_hash()}", AccruePortal.Assets, :js)

        get(
          "/assets/phoenix-#{AccruePortal.Assets.phoenix_hash()}",
          AccruePortal.Assets,
          :phoenix
        )

        get(
          "/assets/live-view-#{AccruePortal.Assets.live_view_hash()}",
          AccruePortal.Assets,
          :live_view
        )

        pipe_through([browser_pipeline, authenticated_pipeline])

        post("/payment-methods", AccruePortal.Controllers.PaymentMethodController, :create)

        post(
          "/payment-methods/:id/default",
          AccruePortal.Controllers.PaymentMethodController,
          :set_default
        )

        post(
          "/payment-methods/:id/delete",
          AccruePortal.Controllers.PaymentMethodController,
          :delete
        )

        post("/checkout/:token/complete", AccruePortal.Controllers.CheckoutController, :complete)
      end

      scope mount_path, as: scope_name do
        pipe_through([browser_pipeline, live_authenticated_pipeline])

        live_session session_name,
          root_layout: {AccruePortal.Layouts, :root},
          on_mount: on_mount,
          session:
            {Accrue.Portal.Router, :__session__,
             [session_keys, mount_path, login_path, context_adapter]} do
          live("/", AccruePortal.Live.HomeLive, :index)
          live("/subscriptions", AccruePortal.Live.SubscriptionsLive, :index)
          live("/subscriptions/:id", AccruePortal.Live.SubscriptionLive, :show)
          live("/payment-methods", AccruePortal.Live.PaymentMethodsLive, :index)
          live("/payment-methods/new", AccruePortal.Live.AddPaymentMethodLive, :new)
          live("/invoices", AccruePortal.Live.InvoicesLive, :index)
          live("/checkout/:token", AccruePortal.Live.CheckoutLive, :show)
        end

        live_session blocked_session_name,
          root_layout: {AccruePortal.Layouts, :root},
          on_mount: [{Accrue.Portal.AuthHook, :ensure_user}],
          session:
            {Accrue.Portal.Router, :__session__,
             [session_keys, mount_path, login_path, context_adapter]} do
          live("/blocked", AccruePortal.Live.BlockedLive, :index)
        end
      end
    end
  end

  @spec __session__(Plug.Conn.t(), [atom() | String.t()], String.t()) :: map()
  def __session__(conn, session_keys, mount_path),
    do: __session__(conn, session_keys, mount_path, @default_login_path)

  @spec __session__(Plug.Conn.t(), [atom() | String.t()], String.t(), String.t()) :: map()
  def __session__(conn, session_keys, mount_path, login_path)
      when is_list(session_keys) and is_binary(mount_path) do
    __session__(conn, session_keys, mount_path, login_path, nil)
  end

  @spec __session__(Plug.Conn.t(), [atom() | String.t()], String.t(), String.t(), module() | nil) ::
          map()
  def __session__(conn, session_keys, mount_path, login_path, context_adapter)
      when is_list(session_keys) and is_binary(mount_path) do
    host_session =
      Map.new(session_keys, fn key ->
        string_key = to_string(key)
        {string_key, get_session(conn, key)}
      end)

    Map.merge(host_session, %{
      "accrue_portal" => %{
        "mount_path" => Accrue.Config.normalize_mount_path(mount_path),
        "login_path" => normalize_login_path!(login_path),
        "blocked_path" =>
          String.trim_trailing(Accrue.Config.normalize_mount_path(mount_path), "/") <>
            "/blocked",
        "context_adapter" => context_adapter,
        "context_session_keys" => Enum.map(session_keys, &to_string/1),
        "brand_css_path" => AccruePortal.Assets.hashed_path(:brand, mount_path),
        "assets_css_path" => AccruePortal.Assets.hashed_path(:css, mount_path),
        "assets_js_path" => AccruePortal.Assets.hashed_path(:js, mount_path),
        "phoenix_js_path" => AccruePortal.Assets.hashed_path(:phoenix, mount_path),
        "live_view_js_path" => AccruePortal.Assets.hashed_path(:live_view, mount_path),
        "brand" => conn.assigns[:accrue_portal_brand],
        "theme" => conn.assigns[:accrue_portal_theme] || "system",
        "theme_locked" => conn.assigns[:accrue_portal_theme_locked] || false,
        "csp_nonce" => conn.assigns[:accrue_portal_csp_nonce]
      }
    })
  end

  @spec assets_path(:css | :js, String.t()) :: String.t()
  def assets_path(kind, mount_path) when kind in [:css, :js] and is_binary(mount_path) do
    AccruePortal.Assets.hashed_path(kind, mount_path)
  end

  defp validate_opts!(path, opts) when is_binary(path) and is_list(opts) do
    normalized_path = Accrue.Config.normalize_mount_path(path)
    session_keys = Keyword.get(opts, :session_keys, @default_session_keys)
    login_path = opts |> Keyword.get(:login_path, @default_login_path) |> normalize_login_path!()
    extra_hooks = Keyword.get(opts, :on_mount, [])
    context_adapter = Keyword.get(opts, :context_adapter)

    unless is_list(session_keys) and Enum.all?(session_keys, &(is_atom(&1) or is_binary(&1))) do
      raise ArgumentError, ":session_keys must be a list of atoms or strings"
    end

    if login_path == normalized_path or String.starts_with?(login_path, normalized_path <> "/") do
      raise ArgumentError, ":login_path must not point inside the protected portal mount path"
    end

    unless valid_on_mount?(extra_hooks) do
      raise ArgumentError,
            ":on_mount must be a hook or list of hooks accepted by Phoenix.LiveView"
    end

    unless is_nil(context_adapter) or is_atom(context_adapter) do
      raise ArgumentError, ":context_adapter must be a module or nil"
    end

    [
      mount_path: normalized_path,
      session_keys: session_keys,
      login_path: login_path,
      context_adapter: context_adapter,
      session_name: session_name(normalized_path),
      blocked_session_name:
        String.to_atom(Atom.to_string(session_name(normalized_path)) <> "_blocked"),
      browser_pipeline: pipeline_name(normalized_path, "browser"),
      authenticated_pipeline: pipeline_name(normalized_path, "authenticated"),
      live_authenticated_pipeline: pipeline_name(normalized_path, "live_authenticated"),
      scope_name: scope_name(normalized_path),
      on_mount: List.wrap(extra_hooks) ++ @default_on_mount
    ]
  end

  defp validate_opts!(path, _opts) do
    raise ArgumentError,
          "accrue_portal/2 expects the mount path to be a string, got: #{inspect(path)}"
  end

  defp valid_on_mount?(hooks) when is_list(hooks), do: Enum.all?(hooks, &valid_hook?/1)
  defp valid_on_mount?(hook), do: valid_hook?(hook)

  defp valid_hook?(hook) when is_atom(hook), do: true
  defp valid_hook?({mod, arg}) when is_atom(mod), do: is_atom(arg) or is_binary(arg)
  defp valid_hook?(_), do: false

  defp session_name("/billing"), do: :accrue_portal

  defp session_name(path) do
    String.to_atom("accrue_portal_" <> mount_suffix(path))
  end

  defp pipeline_name(path, suffix),
    do: String.to_atom("accrue_portal_" <> mount_suffix(path) <> "_" <> suffix)

  defp scope_name("/billing"), do: :accrue_portal
  defp scope_name(path), do: String.to_atom("accrue_portal_" <> mount_suffix(path))

  defp mount_suffix(path) do
    path
    |> String.trim("/")
    |> then(&Regex.replace(~r/[^a-zA-Z0-9]+/, &1, "_"))
    |> String.downcase()
  end

  defp normalize_login_path!(path) when is_binary(path) do
    if Accrue.Portal.Context.valid_local_path?(path) do
      path
    else
      raise ArgumentError, ":login_path must be a local path beginning with /"
    end
  end

  defp normalize_login_path!(path) do
    raise ArgumentError, ":login_path must be a string, got: #{inspect(path)}"
  end
end

defmodule AccruePortal.Router do
  @moduledoc false

  defmacro accrue_portal(path, opts \\ []) do
    quote do
      require Accrue.Portal.Router
      Accrue.Portal.Router.accrue_portal(unquote(path), unquote(opts))
    end
  end

  defdelegate __session__(conn, session_keys, mount_path), to: Accrue.Portal.Router
  defdelegate __session__(conn, session_keys, mount_path, login_path), to: Accrue.Portal.Router

  defdelegate __session__(conn, session_keys, mount_path, login_path, context_adapter),
    to: Accrue.Portal.Router

  defdelegate assets_path(kind, mount_path), to: Accrue.Portal.Router
end
