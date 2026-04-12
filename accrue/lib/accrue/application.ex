defmodule Accrue.Application do
  @moduledoc """
  OTP Application entry point for Accrue (FND-05, D-05).

  Empty-supervisor pattern: Accrue is a library, not a service. It does
  NOT start host-owned components (host Repo, Oban, host ChromicPDF pool,
  host Finch pool) — the host application's supervision tree owns those
  (D-33, D-42, Pitfall #4).

  Before the supervisor starts we run two boot-time validations:

    1. `Accrue.Config.validate_at_boot!/0` — validates the current
       `:accrue` application env against the NimbleOptions schema.
       Misconfig fails loud, before any state is touched.

    2. `Accrue.Auth.Default.boot_check!/0` — refuses to boot in `:prod`
       when `:auth_adapter` still points at the dev-permissive default
       (D-40, T-FND-07 mitigation).
  """

  use Application

  @impl true
  def start(_type, _args) do
    :ok = Accrue.Config.validate_at_boot!()
    :ok = Accrue.Auth.Default.boot_check!()

    children = []

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end
end
