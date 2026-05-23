defmodule Accrue.Plug.RequireEntitlement do
  @moduledoc """
  A controller-pipeline guard that halts a request unless the resolved billable
  is entitled to a `feature:` (or holds an active `plan:`).

  This is the route-level gate a Phoenix developer reaches for first. It is a
  thin transport adapter: `init/1` validates the opts (raising at compile time
  on ambiguous intent), and `call/2` delegates the allow/deny decision to the
  always-compiled `Accrue.Entitlements.Guard` engine. It is pure Plug — there is
  NO controller-framework coupling, so it works in any Plug pipeline.

  ## Usage

  Gate exactly ONE of a `feature:` or a `plan:`:

      plug Accrue.Plug.RequireEntitlement, feature: :api_access
      plug Accrue.Plug.RequireEntitlement, plan: :pro

  The deny behavior is content-negotiated and host-overridable:

      # Custom HTTP status on the opaque deny body (default 403):
      plug Accrue.Plug.RequireEntitlement, feature: :api_access, status: 402

      # Redirect instead of an opaque body (the target MUST live OUTSIDE this
      # gated pipeline to avoid a redirect loop):
      plug Accrue.Plug.RequireEntitlement, plan: :pro, on_deny: {:redirect, "/pricing"}

      # Resolve the billable explicitly (1-arity fn over the conn). Defaults to
      # `conn.assigns.current_scope.user` then `conn.assigns.current_user`:
      plug Accrue.Plug.RequireEntitlement, feature: :api_access,
        billable: &MyAppWeb.current_org/1

  Global defaults for `on_deny:` / `billable:` live under
  `config :accrue, :entitlements`; a per-guard opt always wins.

  The `require_feature/1` / `require_plan/1` macros in `Accrue.Router` are sugar
  over the single-`feature:`/`plan:` form; reach for the explicit `plug` form
  above when you need `status:` / `on_deny:` / `billable:` overrides.

  ## Security

  The billable is resolved from **server-side assigns only** (the host
  `billable:` fn or the default `current_scope.user` / `current_user` probe) —
  NEVER from request params or headers. The `accept` header is read for content
  negotiation only, never for authorization. The deny path is the fail-closed
  default: a `nil` billable, a raising `billable:` fn, or any resolution
  exception all collapse to a 403. The deny body is opaque — it never echoes the
  gated feature / plan name (D-10).
  """

  @behaviour Plug

  alias Accrue.Entitlements.Guard

  @impl true
  def init(opts) when is_list(opts) do
    case {Keyword.fetch(opts, :feature), Keyword.fetch(opts, :plan)} do
      {{:ok, feature}, :error} when is_atom(feature) ->
        opts

      {:error, {:ok, plan}} when is_atom(plan) or is_binary(plan) ->
        opts

      {{:ok, _}, {:ok, _}} ->
        raise ArgumentError,
              "Accrue.Plug.RequireEntitlement expects exactly one of `:feature` or " <>
                "`:plan`, got both"

      _ ->
        raise ArgumentError,
              "Accrue.Plug.RequireEntitlement requires `feature: atom` or " <>
                "`plan: atom | String.t()`"
    end
  end

  @impl true
  def call(conn, opts) do
    case Guard.check(:plug, conn, opts) do
      {:allow, conn} -> conn
      {:deny, deny_form, ctx} -> Guard.deny_plug(conn, deny_form, ctx, opts)
    end
  end
end
