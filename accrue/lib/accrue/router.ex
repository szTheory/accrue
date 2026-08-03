defmodule Accrue.Router do
  @moduledoc """
  Router helpers for mounting Accrue webhook endpoints.

  ## Usage (Phoenix router)

      import Accrue.Router

      pipeline :accrue_webhook_raw_body do
        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          json_decoder: Jason,
          body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
          length: 1_000_000
      end

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "/stripe", :stripe
      end

  Apple App Store Server Notifications V2 use the same route-scoped body reader:

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_apple_notifications "/apple", verifier_config: apple_verifier_config,
          rate_limiter: &MyApp.AppleRateLimiter.check/1
      end

  ## Multi-endpoint (Phase 4 Connect ready, D2-18)

  The macro accepts a processor atom. Calling `accrue_webhook/2` multiple
  times with different processors works natively:

      scope "/webhooks" do
        pipe_through :accrue_webhook_raw_body
        accrue_webhook "/stripe", :stripe
        accrue_webhook "/connect", :stripe_connect
      end

  Each resolves to its own signing secret via `Accrue.Config`.

  ## Entitlement guards (controller pipeline)

  `require_feature/1` and `require_plan/1` are single-arg sugar over
  `Accrue.Plug.RequireEntitlement` for the common "gate one feature / plan"
  case in a controller's `plug` pipeline:

      import Accrue.Router

      defmodule MyAppWeb.ReportsController do
        use MyAppWeb, :controller

        require_feature :reports      # plug Accrue.Plug.RequireEntitlement, feature: :reports
        require_plan :pro             # plug Accrue.Plug.RequireEntitlement, plan: :pro
        # ... actions
      end

  For advanced overrides (`status:`, `on_deny:`, `billable:`) use the explicit
  plug form directly:

      plug Accrue.Plug.RequireEntitlement, feature: :reports, on_deny: {:redirect, "/pricing"}
  """

  @doc """
  Mounts the Accrue webhook plug at the given `path` for the specified
  `processor`.

  Expands to `forward path, Accrue.Webhook.Plug, processor: processor`.
  Must be called inside a scope that pipes through a pipeline containing
  `Plug.Parsers` with `body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}`.
  """
  defmacro accrue_webhook(path, processor) do
    quote do
      forward(unquote(path), Accrue.Webhook.Plug, processor: unquote(processor))
    end
  end

  @doc """
  Mounts the Apple App Store Server Notifications V2 plug at `path`.

  `opts` are host-supplied `Accrue.Entitlements.Apple.NotificationPlug` options,
  including `:verifier_config` and optional `:rate_limiter`. Must be called inside
  a route-scoped `Plug.Parsers` pipeline using
  `Accrue.Webhook.CachingBodyReader.read_body/2`; otherwise the plug returns a
  retryable `503` without verifying or persisting the notification.
  """
  defmacro accrue_apple_notifications(path, opts) do
    quote do
      forward(
        unquote(path),
        Accrue.Entitlements.Apple.NotificationPlug,
        unquote(opts)
      )
    end
  end

  @doc """
  Gates a controller pipeline on a single `feature`.

  Expands to `plug Accrue.Plug.RequireEntitlement, feature: feature`. For
  `status:` / `on_deny:` / `billable:` overrides, use the explicit
  `plug Accrue.Plug.RequireEntitlement, …` form instead.
  """
  defmacro require_feature(feature) do
    quote do
      plug(Accrue.Plug.RequireEntitlement, feature: unquote(feature))
    end
  end

  @doc """
  Gates a controller pipeline on an active `plan` (an atom plan key or a
  `price_id` String).

  Expands to `plug Accrue.Plug.RequireEntitlement, plan: plan`. For
  `status:` / `on_deny:` / `billable:` overrides, use the explicit
  `plug Accrue.Plug.RequireEntitlement, …` form instead.
  """
  defmacro require_plan(plan) do
    quote do
      plug(Accrue.Plug.RequireEntitlement, plan: unquote(plan))
    end
  end
end
