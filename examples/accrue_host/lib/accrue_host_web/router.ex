defmodule AccrueHostWeb.Router do
  use AccrueHostWeb, :router

  import AccrueAdmin.Router
  import AccruePortal.Router
  import Accrue.Router
  import AccrueHostWeb.UserAuth

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
  end

  # Other scopes may use custom stacks.
  # scope "/api", AccrueHostWeb do
  #   pipe_through :api
  # end

  if Mix.env() == :test do
    scope "/api/sandbox", AccrueHostWeb do
      pipe_through(:api)

      post("/", SandboxController, :create)
      delete("/:metadata", SandboxController, :delete)
    end
  end

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

    # Ordering contract: AccrueHostWeb.UserAuth loads scope/auth first, then
    # Accrue.Live.Entitlements checks access; keep the deny target outside this
    # gated session, and see guides/entitlements.md for why missing or unloaded
    # billables fail closed instead of raising.
    live_session :entitled_reports,
      on_mount: [
        {AccrueHostWeb.UserAuth, :require_authenticated},
        {Accrue.Live.Entitlements, {:require_feature, :advanced_reports}}
      ] do
      live("/app/reports/advanced", AdvancedReportsLive, :index)
    end

    live_session :require_authenticated_user,
      on_mount: [{AccrueHostWeb.UserAuth, :require_authenticated}] do
      live("/app/billing", SubscriptionLive, :show)
      live("/users/settings", UserLive.Settings, :edit)
      live("/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email)
    end

    post("/users/update-password", UserSessionController, :update_password)
  end

  scope "/", AccrueHostWeb do
    pipe_through([:browser])

    live_session :current_user,
      on_mount: [{AccrueHostWeb.UserAuth, :mount_current_scope}] do
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

  # Protect these mounts with package auth hooks via accrue_admin/2 and accrue_portal/2.
  # Hosts with custom routers may also pipe through Accrue.Auth.require_admin_plug().
  accrue_admin("/admin", session_keys: [:user_token], allow_live_reload: false)
  accrue_portal("/billing", session_keys: [:user_token])
end
