defmodule Accrue.TestRepo do
  @moduledoc """
  Test-only Ecto.Repo for Accrue's integration tests.

  **Not public API.** Accrue core does not ship a Repo (D-10 — the host
  application owns the Repo lifecycle). This module only exists so that
  Phase 1+ integration tests that need a real Postgres connection have
  something to talk to.

  Located under `test/support/` so `elixirc_paths(:test)` in `mix.exs`
  compiles it only in the `:test` environment — it never lands in a
  published release artifact.
  """

  use Ecto.Repo,
    otp_app: :accrue,
    adapter: Ecto.Adapters.Postgres
end
