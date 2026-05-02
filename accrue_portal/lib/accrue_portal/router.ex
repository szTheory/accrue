defmodule AccruePortal.Router do
  @moduledoc """
  Router helpers for mounting the `:accrue_portal` package into a host app.
  """

  import Phoenix.LiveView.Router
  import Plug.Conn, only: [get_session: 2]

  @default_on_mount [{AccruePortal.AuthHook, :ensure_customer}]
  @default_session_keys []

  defmacro accrue_portal(path, opts \\ []) do
    opts = Macro.expand_literals(opts, __CALLER__)
    validated = validate_opts!(path, opts)
    mount_path = validated[:mount_path]
    session_keys = validated[:session_keys]
    on_mount = validated[:on_mount]
    brand_asset = asset_path(:brand)
    css_asset = asset_path(:css)
    js_asset = asset_path(:js)

    quote bind_quoted: [
            mount_path: mount_path,
            session_keys: session_keys,
            on_mount: on_mount,
            brand_asset: brand_asset,
            css_asset: css_asset,
            js_asset: js_asset
          ] do
      pipeline :accrue_portal_browser do
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:protect_from_forgery)
        plug(AccruePortal.CSPPlug)
        plug(AccruePortal.BrandPlug)
      end

      pipeline :accrue_portal_authenticated do
        plug(AccruePortal.AuthPlug)
      end

      scope mount_path, as: :accrue_portal do
        get("/assets/" <> brand_asset, AccruePortal.Assets, :brand)
        get("/assets/" <> css_asset, AccruePortal.Assets, :css)
        get("/assets/" <> js_asset, AccruePortal.Assets, :js)

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

        live_session :accrue_portal,
          root_layout: {AccruePortal.Layouts, :root},
          on_mount: on_mount,
          session: {AccruePortal.Router, :__session__, [session_keys, mount_path]} do
          live("/", AccruePortal.Live.HomeLive, :index)
          live("/subscriptions", AccruePortal.Live.SubscriptionsLive, :index)
          live("/payment-methods", AccruePortal.Live.PaymentMethodsLive, :index)
          live("/invoices", AccruePortal.Live.InvoicesLive, :index)
          live("/checkout/:token", AccruePortal.Live.CheckoutLive, :show)
        end
      end
    end
  end

  def __session__(conn, session_keys, mount_path) do
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
        "brand" => conn.assigns[:accrue_portal_brand],
        "theme" => conn.assigns[:accrue_portal_theme] || "system",
        "csp_nonce" => conn.assigns[:accrue_portal_csp_nonce]
      }
    })
  end

  defp validate_opts!(path, opts) when is_binary(path) and is_list(opts) do
    normalized_path = Accrue.Config.normalize_mount_path(path)
    session_keys = Keyword.get(opts, :session_keys, @default_session_keys)
    extra_hooks = Keyword.get(opts, :on_mount, [])

    unless is_list(session_keys) and Enum.all?(session_keys, &(is_atom(&1) or is_binary(&1))) do
      raise ArgumentError, ":session_keys must be a list of atoms or strings"
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

  defp asset_path(kind),
    do: String.split(AccruePortal.Assets.hashed_path(kind, ""), "/") |> List.last()
end
