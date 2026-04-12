# Accrue.Integrations.Sigra — conditionally compiled (D-41, D-45).
#
# Follows CLAUDE.md's 4-pattern conditional compile exactly:
#
#   1. Optional dep in `deps/0` (currently OMITTED because :sigra is not
#      yet published to Hex — once published, add
#      `{:sigra, "~> 0.1", optional: true}` back. The conditional-compile
#      pattern below still functions today via `Code.ensure_loaded?/1`
#      because it asks the code server at compile time, not the dep
#      registry; when :sigra is absent the entire `defmodule` block is
#      elided and `Accrue.Integrations.Sigra` is never defined).
#
#   2. `@compile {:no_warn_undefined, [...]}` silences compiler warnings
#      about `Sigra.Auth` and `Sigra.Audit` whose resolution is deferred
#      to runtime when the host's Sigra is present.
#
#   3. Integration module is guarded at `defmodule` time via
#      `Code.ensure_loaded?(Sigra)` — the scaffolding disappears
#      entirely in the without-sigra matrix.
#
#   4. Runtime dispatch by config (not compile-time aliasing) — hosts
#      flip `config :accrue, :auth_adapter, Accrue.Integrations.Sigra`
#      at runtime to activate this adapter. Plan 05 `Accrue.Auth`
#      resolves the adapter via `Application.get_env/3` at call time,
#      so this module only needs to exist; wiring is host-owned.
#
# Phase 1 ships the SCAFFOLD. Concrete callback bodies fill in during
# Phase 7 (Admin UI) when Sigra APIs are exercised end-to-end and the
# real `Sigra.Auth` / `Sigra.Audit` surface is stable (per CONTEXT.md).

if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @moduledoc """
    First-party Sigra auth adapter for Accrue. Auto-activated when the
    host's `:sigra` dep is present at compile time.

    This module is conditionally compiled: in the `without_sigra` CI
    matrix cell (and in Accrue's current default build, since `:sigra`
    is not yet published to Hex), this `defmodule` block is elided
    entirely and `Accrue.Integrations.Sigra` is never defined. See the
    file header comment for the full 4-pattern rationale.

    ## Scaffold status

    Phase 1 ships the behaviour surface and pass-through delegates to
    the `Sigra.Auth` / `Sigra.Audit` modules. Concrete behaviour
    beyond delegation lands in Phase 7 (Admin UI) when the end-to-end
    auth path is exercised.
    """

    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}

    @impl Accrue.Auth
    def current_user(conn), do: Sigra.Auth.current_user(conn)

    @impl Accrue.Auth
    def require_admin_plug do
      # Phase 7 wires the real admin check. For the Phase 1 scaffold we
      # return a pass-through plug so the adapter is usable but clearly
      # marked as "not production-grade until Phase 7".
      fn conn, _opts -> conn end
    end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(user, event), do: Sigra.Audit.log(user, event)

    @impl Accrue.Auth
    def actor_id(user) when is_map(user), do: Map.get(user, :id) || Map.get(user, "id")
    def actor_id(_), do: nil
  end
end
