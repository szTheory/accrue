defmodule Accrue.TestRepo.Migrations.CreateObanJobs do
  @moduledoc """
  Oban migration for Accrue's test harness only.

  Lives under `accrue/priv/repo/migrations/` which is consumed by
  `Accrue.TestRepo`. Host applications ship their own Oban migration via
  `mix oban.gen.migration` — Accrue never owns Oban wiring in production
  (D-27). This migration exists so Plan 05's mailer tests can use
  `Oban.Testing` helpers against the test repo.
  """

  use Ecto.Migration

  def up, do: Oban.Migration.up()
  def down, do: Oban.Migration.down(version: 1)
end
