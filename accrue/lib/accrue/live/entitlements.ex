# Accrue.Live.Entitlements — the LiveView enforcement surface (ENT-07, D-03/D-04).
#
# This is the ONLY always-shipped core file permitted to reference the LiveView
# socket runtime, and only inside the `Code.ensure_loaded?(Phoenix.LiveView)`
# block below. It follows the same conditional-compile 4-pattern as
# `lib/accrue/integrations/sigra.ex` (clone of sigra.ex:31-32,52):
#
#   1. The `defmodule` is wrapped in `if Code.ensure_loaded?(Phoenix.LiveView)`.
#      DIVERGENCE from Sigra (D-04): `:phoenix_live_view` is a HARD core dep
#      (accrue/mix.exs), so this branch is NEVER elided in practice — the gate
#      is belt-and-suspenders / self-documenting, not load-bearing. It exists so
#      the Plan 06 merge gate has a single, obvious place where LiveView refs are
#      sanctioned, and so the file reads identically to the Sigra adapter.
#   2. `@compile {:no_warn_undefined, [...]}` keeps `mix compile
#      --warnings-as-errors` clean even though the LiveView/Component refs are
#      resolved at runtime.
#   3. The module is guarded at `defmodule` time via `Code.ensure_loaded?/1`.
#   4. There is NO decision logic here — the allow/deny decision is delegated to
#      `Accrue.Entitlements.Guard.check/3`; this file is a thin surface adapter
#      that only translates the Guard's deny enum into socket cont/halt.

if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Accrue.Live.Entitlements do
    @moduledoc """
    `on_mount/4` entitlement guard for host LiveViews (ENT-07).

    Gate a LiveView (or a whole `live_session`) on a feature or plan by adding
    this hook to the `on_mount:` list:

        live_session :paid, on_mount: [
          {MyAppWeb.UserAuth, :ensure_authenticated},
          {Accrue.Live.Entitlements, {:require_feature, :reports}}
        ] do
          live "/reports", ReportsLive
        end

    Or gate on an active plan:

        {Accrue.Live.Entitlements, {:require_plan, :pro}}

    On allow it returns `{:cont, socket}` (the resolved billable is stashed once
    on the socket under `:accrue_billable`). On deny it returns `{:halt, socket}`
    where the socket has been redirected (and, for the `:forbidden` path, given a
    generic flash error).

    All decision logic — billable resolution, the fail-closed gate call, and the
    tiered `on_deny` resolution — lives in `Accrue.Entitlements.Guard`. This
    module only surface-translates the Guard's deny form into LiveView terms.

    ## Ordering (REQUIRED — read this)

    The host's authentication `on_mount` hook MUST run BEFORE this guard in the
    `on_mount:` list (D-20). This guard gates *entitlement only*, never
    authentication: it resolves the billable from server-side socket assigns
    (the default scope/user probe, or your configured `billable` fn). If it runs
    before auth has populated those assigns, the billable resolves to `nil` and
    EVERY user is denied (fail-closed, but spuriously). List your auth hook
    first.

    ## Deny destination (avoid redirect loops)

    The deny destination — the per-guard/`config` `on_deny` `{:redirect, path}`
    target, or the `config :accrue, :entitlements, deny_path:` fallback (default
    `"/"`) — MUST live OUTSIDE the gated `live_session` (D-13). A deny target
    that is itself behind this guard produces an infinite redirect / a LiveView
    that never mounts.

    ## Deny surface-translation (D-21)

      * `{:redirect, path}` → `redirect(socket, to: path)`.
      * `:forbidden` → `put_flash(:error, …)` + `redirect(to: deny_path())`.
      * `{status, body}` → degrades to the `:forbidden` path. A raw HTTP status +
        body is meaningless on a socket, so the one irreducible plug-vs-socket
        asymmetry collapses to the flash+redirect deny. Hosts never see this
        plumbing.

    The deny flash is intentionally generic ("You don't have access to this
    page.") and NEVER names the required feature or plan (D-10).

    ## Conditional compilation

    This module is wrapped in `Code.ensure_loaded?(Phoenix.LiveView)` and is the
    ONLY always-shipped core file allowed to reference the LiveView socket
    runtime (D-03/D-04). Because `:phoenix_live_view` is a hard core dep the
    branch is never actually elided, but the wrapper keeps the surface refs
    confined to one auditable location for the Plan 06 merge gate.
    """

    @compile {:no_warn_undefined, [Phoenix.LiveView, Phoenix.Component]}

    import Phoenix.LiveView, only: [redirect: 2, put_flash: 3]
    import Phoenix.Component, only: [assign_new: 3]

    @stash_key :accrue_billable
    @deny_flash "You don't have access to this page."

    @spec on_mount(
            {:require_feature, atom()} | {:require_plan, atom() | String.t()},
            map(),
            map(),
            Phoenix.LiveView.Socket.t()
          ) ::
            {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
    def on_mount({:require_feature, feature}, _params, _session, socket) do
      decide(:feature, feature, socket)
    end

    def on_mount({:require_plan, plan}, _params, _session, socket) do
      decide(:plan, plan, socket)
    end

    # Delegate the decision to the Guard; translate only. No billable resolution,
    # no gate call, no ctx building here (all in Accrue.Entitlements.Guard).
    defp decide(kind, required, socket) do
      case Accrue.Entitlements.Guard.check(:live, socket, [{kind, required}]) do
        {:allow, socket} ->
          # Resolve-once stash (D-17): the Guard already resolved the billable
          # and returned it on the socket assigns; mirror it under :accrue_billable
          # billable-only (NEVER the boolean decision, Pitfall 3). `assign_new` is
          # the only Phoenix.Component call and it stays inside the cond-compile block.
          socket =
            assign_new(socket, @stash_key, fn ->
              Map.get(socket.assigns, @stash_key)
            end)

          {:cont, socket}

        {:deny, deny_form, _ctx} ->
          {:halt, deny(socket, deny_form)}
      end
    end

    # Surface-translate the deny enum (D-21):
    #   {:redirect, path} -> redirect to path
    #   :forbidden (and the {status, body} degradation) -> flash + redirect to deny_path
    defp deny(socket, {:redirect, path}) when is_binary(path) do
      redirect(socket, to: path)
    end

    defp deny(socket, _other) do
      socket
      |> put_flash(:error, @deny_flash)
      |> redirect(to: Accrue.Entitlements.Guard.deny_path())
    end
  end
end
