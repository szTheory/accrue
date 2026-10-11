defmodule AccrueHostWeb.Router do
  use AccrueHostWeb, :router

  import AccrueAdmin.Router
  import AccruePortal.Router
  import Accrue.Router
  import AccrueHostWeb.UserAuth

  @live_acceptance_hooks (if Application.compile_env(:accrue_host, :sql_sandbox) do
                            [AccrueHostWeb.LiveAcceptance]
                          else
                            []
                          end)
  @host_live_session_keys [:user_token, :active_organization_id]

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {AccrueHostWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_scope_for_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", AccrueHostWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/pricing", PageController, :pricing)
  end

  # Other scopes may use custom stacks.
  # scope "/api", AccrueHostWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:accrue_host, :dev_routes) do
    scope "/dev" do
      pipe_through(:browser)

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", AccrueHostWeb do
    pipe_through([:browser, :require_authenticated_user])

    post("/app/organization-scope", OrganizationScopeController, :update)

    if Application.compile_env(:accrue_host, :sql_sandbox) do
      get("/api/e2e/dispatch-counts", OrganizationScopeController, :dispatch_counts_for_e2e)

      post(
        "/api/e2e/revoke-membership",
        OrganizationScopeController,
        :revoke_membership_for_e2e
      )
    end

    # Ordering contract: AccrueHostWeb.UserAuth loads scope/auth first, then
    # Accrue.Live.Entitlements checks access; keep the deny target outside this
    # gated session, and see guides/entitlements.md for why missing or unloaded
    # billables fail closed instead of raising.
    live_session :entitled_reports,
      session: {__MODULE__, :__live_session__, [@host_live_session_keys]},
      on_mount:
        @live_acceptance_hooks ++
          [
            {AccrueHostWeb.UserAuth, :require_authenticated},
            {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
          ] do
      live("/app/reports/advanced", AdvancedReportsLive, :index)
    end

    live_session :require_authenticated_user,
      session: {__MODULE__, :__live_session__, [@host_live_session_keys]},
      on_mount: @live_acceptance_hooks ++ [{AccrueHostWeb.UserAuth, :require_authenticated}] do
      live("/app/billing", SubscriptionLive, :show)
      live("/app/entitlements/diagnostics", EntitlementDiagnosticsLive, :show)
      live("/users/settings", UserLive.Settings, :edit)
      live("/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email)
    end

    post("/users/update-password", UserSessionController, :update_password)
  end

  if Application.compile_env(:accrue_host, :sql_sandbox) do
    scope "/admin", as: :accrue_admin do
      pipe_through([:browser, :accrue_admin_browser])

      live_session :phase246_search_fixture,
        root_layout: {AccrueAdmin.Layouts, :root},
        session: {AccrueAdmin.Router, :__session__, [[:user_token], "/admin"]},
        on_mount:
          @live_acceptance_hooks ++
            [
              {AccrueHostWeb.UserAuth, :require_authenticated},
              {AccrueAdmin.AuthHook, :ensure_admin},
              {AccrueAdmin.NavBadgeHook, :default}
            ] do
        live("/__phase246/states", AccrueHostWeb.Phase246StatesLive, :index)
      end
    end
  end

  scope "/", AccrueHostWeb do
    pipe_through([:browser])

    live_session :current_user,
      session: {__MODULE__, :__live_session__, [@host_live_session_keys]},
      on_mount: @live_acceptance_hooks ++ [{AccrueHostWeb.UserAuth, :mount_current_scope}] do
      live("/users/register", UserLive.Registration, :new)
      live("/users/log-in", UserLive.Login, :new)
      live("/users/log-in/:token", UserLive.Confirmation, :new)
    end

    post("/users/log-in", UserSessionController, :create)
    delete("/users/log-out", UserSessionController, :delete)
  end

  pipeline :accrue_webhook_raw_body do
    plug(Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason,
      body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
      length: 1_000_000
    )
  end

  scope "/webhooks" do
    pipe_through(:accrue_webhook_raw_body)
    accrue_webhook("/stripe", :stripe)
  end

  pipeline :accrue_apple_notifications_raw_body do
    plug(Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason,
      body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
      length: 262_144
    )
  end

  scope "/webhooks" do
    pipe_through(:accrue_apple_notifications_raw_body)
    forward("/apple", AccrueHost.AppleNotificationIngress)
  end

  # Protect these mounts with package auth hooks via accrue_admin/2 and accrue_portal/2.
  # Hosts with custom routers may also pipe through Accrue.Auth.require_admin_plug().
  if Application.compile_env(:accrue_host, :sql_sandbox) do
    accrue_admin("/admin",
      session_keys: [:user_token],
      on_mount: AccrueHostWeb.LiveAcceptance,
      allow_live_reload: false
    )

    # on_mount precedes session_keys here so the installer-verbatim portal mount
    # line lives only in the production `else` branch below — preserving
    # InstallBoundaryTest's exactly-once source-text contract.
    accrue_portal("/billing",
      on_mount: AccrueHostWeb.LiveAcceptance,
      session_keys: [:user_token],
      login_path: "/users/log-in"
    )

    accrue_portal("/shared-billing",
      on_mount: AccrueHostWeb.LiveAcceptance,
      session_keys: [:user_token, :active_organization_id, :portal_billable_selection],
      login_path: "/users/log-in",
      context_adapter: AccrueHost.PortalContextAdapter
    )
  else
    accrue_admin("/admin", session_keys: [:user_token], allow_live_reload: false)
    accrue_portal("/billing", session_keys: [:user_token], login_path: "/users/log-in")

    accrue_portal("/shared-billing",
      session_keys: [:user_token, :active_organization_id, :portal_billable_selection],
      login_path: "/users/log-in",
      context_adapter: AccrueHost.PortalContextAdapter
    )
  end

  def __live_session__(conn, session_keys) when is_list(session_keys) do
    Map.new(session_keys, fn key ->
      {to_string(key), Plug.Conn.get_session(conn, key)}
    end)
  end
end
