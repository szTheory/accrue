defmodule AccrueAdmin.Router do
  @moduledoc """
  Router helpers for mounting the `:accrue_admin` package into a host app.
  """

  import Phoenix.LiveView.Router
  import Plug.Conn, only: [get_session: 2]

  @default_on_mount [{AccrueAdmin.AuthHook, :ensure_admin}]
  @default_session_keys []
  @owner_scope_session_keys AccrueAdmin.OwnerScope.session_keys()

  @doc """
  Mounts the admin package at `path`.

  ## Options

    * `:session_keys` - explicit host session keys to thread into the admin
      LiveView session
    * `:on_mount` - additional LiveView `on_mount` hooks
    * `:csp_nonce_assign_key` - reserved for later CSP hardening plans
    * `:allow_live_reload` - compile-time gate for dev-only admin routes
  """
  defmacro accrue_admin(path, opts \\ []) do
    opts = Macro.expand_literals(opts, __CALLER__)
    validated = validate_opts!(path, opts)
    mount_path = validated[:mount_path]
    session_keys = validated[:session_keys]
    on_mount = validated[:on_mount]
    dev_routes? = validated[:allow_live_reload]

    quote bind_quoted: [
            mount_path: mount_path,
            session_keys: session_keys,
            on_mount: on_mount,
            dev_routes?: dev_routes?
          ] do
      pipeline :accrue_admin_browser do
        plug(:fetch_session)
        plug(:protect_from_forgery)
        plug(AccrueAdmin.CSPPlug)
        plug(AccrueAdmin.BrandPlug)
      end

      scope mount_path, as: :accrue_admin do
        get("/assets/brand-#{AccrueAdmin.Assets.brand_hash()}", AccrueAdmin.Assets, :brand)
        get("/assets/css-#{AccrueAdmin.Assets.css_hash()}", AccrueAdmin.Assets, :css)
        get("/assets/js-#{AccrueAdmin.Assets.js_hash()}", AccrueAdmin.Assets, :js)

        pipe_through(:accrue_admin_browser)

        live_session :accrue_admin,
          root_layout: {AccrueAdmin.Layouts, :root},
          on_mount: on_mount,
          session: {AccrueAdmin.Router, :__session__, [session_keys, mount_path]} do
          live("/", AccrueAdmin.Live.DashboardLive, :index)
          live("/customers", AccrueAdmin.Live.CustomersLive, :index)
          live("/customers/:id", AccrueAdmin.Live.CustomerLive, :show)
          live("/subscriptions", AccrueAdmin.Live.SubscriptionsLive, :index)
          live("/subscriptions/:id", AccrueAdmin.Live.SubscriptionLive, :show)
          live("/invoices", AccrueAdmin.Live.InvoicesLive, :index)
          live("/invoices/:id", AccrueAdmin.Live.InvoiceLive, :show)
          live("/charges", AccrueAdmin.Live.ChargesLive, :index)
          live("/charges/:id", AccrueAdmin.Live.ChargeLive, :show)
          live("/coupons", AccrueAdmin.Live.CouponsLive, :index)
          live("/coupons/:id", AccrueAdmin.Live.CouponLive, :show)
          live("/promotion-codes", AccrueAdmin.Live.PromotionCodesLive, :index)
          live("/promotion-codes/:id", AccrueAdmin.Live.PromotionCodeLive, :show)
          live("/connect", AccrueAdmin.Live.ConnectAccountsLive, :index)
          live("/connect/:id", AccrueAdmin.Live.ConnectAccountLive, :show)
          live("/events", AccrueAdmin.Live.EventsLive, :index)
          live("/webhooks", AccrueAdmin.Live.WebhooksLive, :index)
          live("/webhooks/:id", AccrueAdmin.Live.WebhookLive, :show)

          if dev_routes? do
            live("/dev/clock", AccrueAdmin.Dev.ClockLive, :index)
            live("/dev/email-preview", AccrueAdmin.Dev.EmailPreviewLive, :index)
            live("/dev/webhook-fixtures", AccrueAdmin.Dev.WebhookFixtureLive, :index)
            live("/dev/components", AccrueAdmin.Dev.ComponentKitchenLive, :index)
            live("/dev/fake-inspect", AccrueAdmin.Dev.FakeInspectLive, :index)
          end
        end
      end
    end
  end

  @spec __session__(Plug.Conn.t(), [atom() | String.t()], String.t()) :: map()
  def __session__(conn, session_keys, mount_path)
      when is_list(session_keys) and is_binary(mount_path) do
    threaded_keys = Enum.uniq(session_keys ++ @owner_scope_session_keys)

    host_session =
      Map.new(threaded_keys, fn key ->
        string_key = to_string(key)
        {string_key, get_session(conn, key)}
      end)

    Map.merge(host_session, %{
      "accrue_admin" => %{
        "brand_css_path" => AccrueAdmin.Assets.hashed_path(:brand, mount_path),
        "assets_css_path" => AccrueAdmin.Assets.hashed_path(:css, mount_path),
        "assets_js_path" => AccrueAdmin.Assets.hashed_path(:js, mount_path),
        "mount_path" => AccrueAdmin.Assets.normalize_mount_path(mount_path),
        "brand" => conn.assigns[:accrue_admin_brand],
        "theme" => conn.assigns[:accrue_admin_theme] || "system",
        "csp_nonce" => conn.assigns[:accrue_admin_csp_nonce]
      }
    })
  end

  @spec assets_path(:css | :js, String.t()) :: String.t()
  def assets_path(kind, mount_path) when kind in [:css, :js] and is_binary(mount_path) do
    AccrueAdmin.Assets.hashed_path(kind, mount_path)
  end

  defp validate_opts!(path, opts) when is_binary(path) and is_list(opts) do
    normalized_path = AccrueAdmin.Assets.normalize_mount_path(path)
    session_keys = Keyword.get(opts, :session_keys, @default_session_keys)
    extra_hooks = Keyword.get(opts, :on_mount, [])

    unless is_list(session_keys) and Enum.all?(session_keys, &(is_atom(&1) or is_binary(&1))) do
      raise ArgumentError, ":session_keys must be a list of atoms or strings"
    end

    unless valid_on_mount?(extra_hooks) do
      raise ArgumentError,
            ":on_mount must be a hook or list of hooks accepted by Phoenix.LiveView"
    end

    if Keyword.has_key?(opts, :csp_nonce_assign_key) and not is_atom(opts[:csp_nonce_assign_key]) do
      raise ArgumentError, ":csp_nonce_assign_key must be an atom when provided"
    end

    allow_live_reload =
      case Keyword.get(opts, :allow_live_reload, Mix.env() != :prod) do
        value when is_boolean(value) -> value
        _ -> raise ArgumentError, ":allow_live_reload must be a boolean"
      end

    [
      mount_path: normalized_path,
      session_keys: session_keys,
      on_mount: @default_on_mount ++ List.wrap(extra_hooks),
      allow_live_reload: allow_live_reload
    ]
  end

  defp validate_opts!(path, _opts) do
    raise ArgumentError,
          "accrue_admin/2 expects the mount path to be a string, got: #{inspect(path)}"
  end

  defp valid_on_mount?(hooks) when is_list(hooks), do: Enum.all?(hooks, &valid_hook?/1)
  defp valid_on_mount?(hook), do: valid_hook?(hook)

  defp valid_hook?(hook) when is_atom(hook), do: true
  defp valid_hook?({mod, arg}) when is_atom(mod), do: is_atom(arg) or is_binary(arg)
  defp valid_hook?(_), do: false
end
