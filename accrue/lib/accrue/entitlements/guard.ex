defmodule Accrue.Entitlements.Guard do
  @moduledoc """
  The always-compiled, LiveView-runtime-free decision engine shared by both
  enforcement surfaces (`Accrue.Plug.RequireEntitlement` and the cond-compiled
  `Accrue.Live.Entitlements` `on_mount` guard).

  This module owns ALL guard decision logic so the two surface modules stay
  thin transport adapters:

    * **Billable resolution** (D-14/D-15) — one shared 1-arity convention.
    * **Resolve-once** (D-17) — the billable is resolved exactly once per
      request/mount and stashed billable-only (never the boolean decision).
    * **Fail-closed delegation** (D-08) — the allow/deny decision is delegated
      to the Phase 123 gate (`Accrue.Entitlements.entitled?/3` /
      `has_active_plan?/3`); the Guard NEVER makes its own allow decision and
      NEVER re-queries subscriptions or reads `.status`.
    * **Tiered `on_deny` resolution** (D-11) — per-guard opt → config global →
      built-in `:forbidden`.
    * **Bounded, no-PII `ctx`** (D-12) — `%{guard:, required:, reason:,
      billable:, surface:}`.
    * **`surface:` telemetry dimension** (D-18) — `:plug | :live` is carried
      onto the inherited `[:accrue, :entitlements, :check]` span.

  It deliberately holds NO LiveView/socket runtime reference (none of the
  LiveView, Component, Socket, or Controller Phoenix modules) so it passes the
  Plan 06 "core stays runtime-LiveView-free" merge gate — it lives OUTSIDE
  `lib/accrue/live/` and reads only an opaque `container` term (a `%Plug.Conn{}`
  for `:plug`, a socket / `%{assigns: ...}` map for `:live`).

  ## Security

  The billable is resolved from **server-side assigns only** — `container.assigns`
  via the host `billable` fn or the default `current_scope.user`/`current_user`
  probe — NEVER from request params or headers. The `accept` header is read for
  content negotiation only, never for authorization. The deny path is the
  fail-closed default: a `nil` billable, a raising `billable` fn, or any
  resolution exception all collapse to a deny.

  ## Deny reason

  The host-facing `ctx.reason` is **coarse by design** (WARNING 2 / D-12). It
  defaults to `:not_entitled` and is best-effort `:no_active_subscription` /
  `:error` only where cheaply known, because the boolean predicate the Guard
  delegates to returns NO reason and we deliberately do NOT make a second gate
  call to fetch one (D-08/D-17 — exactly one gate call per check). The PRECISE
  Phase 123 reason atom (`:not_entitled | :no_active_subscription |
  :unmapped_plan | :error`) lives in the inherited `[:accrue, :entitlements,
  :check]` **telemetry span** metadata, NOT in `ctx`. This converts the silent
  narrowing into a documented contract: read the span for the precise reason,
  read `ctx.reason` for a coarse host-facing bucket.
  """

  @stash_key :accrue_billable

  @typedoc "The opaque transport container: a `%Plug.Conn{}` (`:plug`) or a socket / `%{assigns: ...}` (`:live`)."
  @type container :: term()

  @typedoc "The tiered, host-resolvable deny form (D-11)."
  @type deny_form ::
          :forbidden
          | {:redirect, String.t()}
          | {non_neg_integer(), iodata()}
          | (container(), map() -> term())
          | {module(), atom(), list()}

  @typedoc "Bounded, no-PII deny context (D-12)."
  @type ctx :: %{
          guard: :feature | :plan,
          required: atom() | String.t(),
          reason: atom(),
          billable: term() | nil,
          surface: :plug | :live
        }

  @doc """
  Resolves the billable (precedence + resolve-once + fail-closed), delegates the
  allow/deny decision to the Phase 123 gate carrying `surface:`, and returns
  either `{:allow, container}` or `{:deny, deny_form, ctx}`.

  `opts` keys:

    * `:feature` | `:plan` — exactly one; selects the gate predicate.
    * `:billable` — a 1-arity `fn container -> billable | nil` override (wins
      over the config global and the default probe).
    * `:on_deny` — a per-guard `t:deny_form/0` override (wins over the config
      global and the built-in `:forbidden`).
    * `:status` — a per-guard plug status override (default `403`).

  For the `:plug` surface the resolved billable is stashed once on the conn via
  `Plug.Conn.assign(conn, :accrue_billable, billable)` (read first; resolved at
  most once). For the `:live` surface the resolved billable is stashed onto the
  returned container's assigns via a plain map update (NO `Component.assign`
  reference here) so the cond-compiled surface can mirror it with `assign_new`
  (read first; resolved at most once).
  """
  @spec check(:plug | :live, container(), keyword()) ::
          {:allow, container()} | {:deny, deny_form(), ctx()}
  def check(surface, container, opts) when surface in [:plug, :live] do
    {kind, required} = guard_target!(opts)
    {billable, container} = resolve_once(surface, container, opts)

    allowed? =
      case kind do
        :feature -> Accrue.Entitlements.entitled?(billable, required, surface: surface)
        :plan -> Accrue.Entitlements.has_active_plan?(billable, required, surface: surface)
      end

    if allowed? do
      {:allow, container}
    else
      ctx = %{
        guard: kind,
        required: required,
        reason: deny_reason(billable),
        billable: billable,
        surface: surface
      }

      {:deny, resolve_on_deny(opts), ctx}
    end
  end

  @doc """
  Resolves the billable for `container`, total and never raising. Precedence:

    1. per-guard `billable:` opt (1-arity fn),
    2. `config :accrue, :entitlements, billable:` (1-arity fn or `nil`),
    3. the default probe — `container.assigns.current_scope.user` →
       `container.assigns.current_user` → `nil`.

  The host `billable` fn call is wrapped in the same `rescue`/`catch → nil` as
  `Accrue.Entitlements.resolve/1`, so a raising host fn fails closed (`nil`
  flows to the gate, which denies).
  """
  @spec resolve_billable(:plug | :live, container(), keyword()) :: term() | nil
  def resolve_billable(_surface, container, opts) do
    case billable_fn(opts) do
      fun when is_function(fun, 1) -> safe_apply(fun, container)
      _ -> default_probe(container)
    end
  end

  @doc """
  Translates a resolved `deny_form` on the Plug surface and halts the conn.
  The wire body is OPAQUE (D-10) — `ctx.required`/feature/plan is NEVER echoed
  into the response body; it reaches the host only via `ctx` passed to host
  `on_deny` fns.

    * `:forbidden` → content-negotiated opaque 403 (`{"error":"forbidden"}`
      for JSON `accept`, else `"Forbidden"`); honors a `status:` opt override.
    * `{:redirect, path}` → `302` with a `location` header (pure Plug).
    * `{status, body}` → `send_resp(status, body)`.
    * a 2-arity fn → `fun.(conn, ctx)`.
    * an MFA `{m, f, a}` → `apply(m, f, a ++ [conn, ctx])`.
  """
  @spec deny_plug(Plug.Conn.t(), deny_form(), ctx(), keyword()) :: Plug.Conn.t()
  def deny_plug(conn, deny_form, ctx, opts \\ [])

  def deny_plug(conn, :forbidden, _ctx, opts) do
    status = Keyword.get(opts, :status, 403)
    builtin_forbidden(conn, status)
  end

  def deny_plug(conn, {:redirect, path}, _ctx, _opts) when is_binary(path) do
    conn
    |> Plug.Conn.put_resp_header("location", path)
    |> Plug.Conn.send_resp(302, "")
    |> Plug.Conn.halt()
  end

  def deny_plug(conn, fun, ctx, _opts) when is_function(fun, 2) do
    fun.(conn, ctx)
  end

  def deny_plug(conn, {m, f, a}, ctx, _opts)
      when is_atom(m) and is_atom(f) and is_list(a) do
    apply(m, f, a ++ [conn, ctx])
  end

  def deny_plug(conn, {status, body}, _ctx, _opts) when is_integer(status) do
    conn
    |> Plug.Conn.send_resp(status, body)
    |> Plug.Conn.halt()
  end

  @doc """
  Returns the configured deny path (`config :accrue, :entitlements, deny_path:`,
  default `"/"`) for the LiveView surface's `deny_live/3` to redirect to.
  """
  @spec deny_path() :: String.t()
  def deny_path do
    Accrue.Config.entitlements() |> Keyword.get(:deny_path, "/")
  end

  # --------------------------------------------------------------------------
  # internals
  # --------------------------------------------------------------------------

  # Exactly one of :feature / :plan must be present.
  defp guard_target!(opts) do
    case {Keyword.fetch(opts, :feature), Keyword.fetch(opts, :plan)} do
      {{:ok, feature}, :error} ->
        {:feature, feature}

      {:error, {:ok, plan}} ->
        {:plan, plan}

      {{:ok, _}, {:ok, _}} ->
        raise ArgumentError, "guard opts: pass exactly one of :feature or :plan, not both"

      {:error, :error} ->
        raise ArgumentError, "guard opts: missing required :feature or :plan"
    end
  end

  # Resolve-once (D-17): for :plug, read the :accrue_billable assign first and
  # resolve+stash only if absent; stash the billable TERM only, never a boolean
  # decision (Pitfall 3). For :live, resolve and return the billable for the
  # surface to stash via assign_new (keeps the Component module out of here).
  defp resolve_once(:plug, %Plug.Conn{} = conn, opts) do
    case Map.get(conn.assigns, @stash_key, :__unset__) do
      :__unset__ ->
        billable = resolve_billable(:plug, conn, opts)
        {billable, Plug.Conn.assign(conn, @stash_key, billable)}

      billable ->
        {billable, conn}
    end
  end

  defp resolve_once(:plug, container, opts) do
    # Non-conn plug container (defensive): resolve without stashing.
    {resolve_billable(:plug, container, opts), container}
  end

  defp resolve_once(:live, container, opts) do
    case container do
      %{assigns: %{} = assigns} ->
        case Map.get(assigns, @stash_key, :__unset__) do
          :__unset__ ->
            billable = resolve_billable(:live, container, opts)
            # Carry the billable TERM on the returned container's assigns via a
            # plain map update — NOT a LiveView component assign helper, so this
            # module keeps zero socket-runtime references (Plan 06 merge gate).
            # This mirrors the :plug clause's Plug.Conn.assign (itself a map put);
            # the cond-compiled surface re-stashes via assign_new so the value is
            # registered for change tracking. Without this the surface's
            # assign_new read nil and D-17 resolve-once was silently defeated.
            {billable, %{container | assigns: Map.put(assigns, @stash_key, billable)}}

          billable ->
            {billable, container}
        end

      _ ->
        {resolve_billable(:live, container, opts), container}
    end
  end

  defp billable_fn(opts) do
    case Keyword.fetch(opts, :billable) do
      {:ok, fun} when is_function(fun, 1) -> fun
      _ -> config_billable()
    end
  end

  defp config_billable do
    case Accrue.Config.entitlements() |> Keyword.get(:billable) do
      fun when is_function(fun, 1) -> fun
      _ -> nil
    end
  rescue
    _ -> nil
  end

  # Wrap the host billable fn in the same fail-closed try/rescue/catch as
  # Accrue.Entitlements.resolve/1 — a raising host fn collapses to nil.
  defp safe_apply(fun, container) do
    fun.(container)
  rescue
    _ -> nil
  catch
    _ -> nil
    _, _ -> nil
  end

  # Default probe (D-15): server-side assigns only, nil-safe — current_scope.user
  # then current_user then nil. Never raises (no `.field` on a possible nil).
  defp default_probe(%{assigns: %{} = assigns}) do
    case Map.get(assigns, :current_scope) do
      %{user: user} when not is_nil(user) -> user
      _ -> Map.get(assigns, :current_user)
    end
  end

  defp default_probe(_), do: nil

  # Coarse host-facing reason (D-12 / WARNING 2): :not_entitled when a billable
  # resolved, :no_active_subscription when nothing resolved. The PRECISE reason
  # lives in the :check telemetry span, not here — we make NO extra gate call.
  defp deny_reason(nil), do: :no_active_subscription
  defp deny_reason(_billable), do: :not_entitled

  # Tiered on_deny (D-11): per-guard opt → config global → built-in :forbidden.
  defp resolve_on_deny(opts) do
    case Keyword.fetch(opts, :on_deny) do
      {:ok, form} -> form
      :error -> config_on_deny()
    end
  end

  defp config_on_deny do
    Accrue.Config.entitlements() |> Keyword.get(:on_deny, :forbidden)
  rescue
    _ -> :forbidden
  end

  # Content-negotiated opaque 403 (Pitfall 1: pure Plug, NO Controller module).
  defp builtin_forbidden(conn, status) do
    if json_requested?(conn) do
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(status, Jason.encode!(%{error: "forbidden"}))
      |> Plug.Conn.halt()
    else
      conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(status, "Forbidden")
      |> Plug.Conn.halt()
    end
  end

  defp json_requested?(conn) do
    conn
    |> Plug.Conn.get_req_header("accept")
    |> Enum.any?(&String.contains?(&1, "json"))
  end
end
