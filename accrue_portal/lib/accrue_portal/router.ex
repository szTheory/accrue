defmodule Accrue.Portal.Router do
  @moduledoc """
  Router helpers for mounting the `:accrue_portal` package into a host app.
  """

  import Phoenix.LiveView.Router
  import Plug.Conn, only: [get_session: 2]

  @default_on_mount [{Accrue.Portal.AuthHook, :ensure_customer}]
  @default_session_keys []

  @doc """
  Mounts the portal package at `path`.

  ## Options

    * `:session_keys` - explicit host session keys to thread into the portal
      LiveView session
    * `:on_mount` - additional LiveView `on_mount` hooks
  """
  defmacro accrue_portal(path, opts \\ []) do
    opts = Macro.expand_literals(opts, __CALLER__)
    validated = validate_opts!(path, opts)
    mount_path = validated[:mount_path]
    session_keys = validated[:session_keys]
    on_mount = validated[:on_mount]

    quote bind_quoted: [
            mount_path: mount_path,
            session_keys: session_keys,
            on_mount: on_mount
          ] do
      pipeline :accrue_portal_browser do
        plug(:fetch_session)
        plug(:protect_from_forgery)
        plug(Accrue.Portal.CSPPlug)
        plug(Accrue.Portal.BrandPlug)
      end

      pipeline :accrue_portal_authenticated do
        plug(Accrue.Portal.AuthPlug)
      end

      scope mount_path, as: :accrue_portal do
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

        pipe_through([:accrue_portal_browser, :accrue_portal_authenticated])

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

      scope mount_path, as: :accrue_portal do
        pipe_through(:accrue_portal_browser)

        live_session :accrue_portal,
          root_layout: {AccruePortal.Layouts, :root},
          on_mount: on_mount,
          session: {Accrue.Portal.Router, :__session__, [session_keys, mount_path]} do
          live("/", AccruePortal.Live.HomeLive, :index)
          live("/subscriptions", AccruePortal.Live.SubscriptionsLive, :index)
          live("/subscriptions/:id", AccruePortal.Live.SubscriptionLive, :show)
          live("/payment-methods", AccruePortal.Live.PaymentMethodsLive, :index)
          live("/payment-methods/new", AccruePortal.Live.AddPaymentMethodLive, :new)
          live("/invoices", AccruePortal.Live.InvoicesLive, :index)
          live("/checkout/:token", AccruePortal.Live.CheckoutLive, :show)
        end
      end
    end
  end

  @spec __session__(Plug.Conn.t(), [atom() | String.t()], String.t()) :: map()
  def __session__(conn, session_keys, mount_path)
      when is_list(session_keys) and is_binary(mount_path) do
    host_session =
      Map.new(session_keys, fn key ->
        string_key = to_string(key)
        {string_key, get_session(conn, key)}
      end)

    Map.merge(host_session, %{
      "accrue_portal" => %{
        "mount_path" => Accrue.Config.normalize_mount_path(mount_path),
        "brand_css_path" => AccruePortal.Assets.hashed_path(:brand, mount_path),
        "assets_css_path" => AccruePortal.Assets.hashed_path(:css, mount_path),
        "assets_js_path" => AccruePortal.Assets.hashed_path(:js, mount_path),
        "phoenix_js_path" => AccruePortal.Assets.hashed_path(:phoenix, mount_path),
        "live_view_js_path" => AccruePortal.Assets.hashed_path(:live_view, mount_path),
        "brand" => conn.assigns[:accrue_portal_brand],
        "theme" => conn.assigns[:accrue_portal_theme] || "system",
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
    extra_hooks = Keyword.get(opts, :on_mount, [])

    unless is_list(session_keys) and Enum.all?(session_keys, &(is_atom(&1) or is_binary(&1))) do
      raise ArgumentError, ":session_keys must be a list of atoms or strings"
    end

    unless valid_on_mount?(extra_hooks) do
      raise ArgumentError,
            ":on_mount must be a hook or list of hooks accepted by Phoenix.LiveView"
    end

    [
      mount_path: normalized_path,
      session_keys: session_keys,
      on_mount: @default_on_mount ++ List.wrap(extra_hooks)
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
  defdelegate assets_path(kind, mount_path), to: Accrue.Portal.Router
end
