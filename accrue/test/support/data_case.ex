defmodule Accrue.DataCase do
  @moduledoc """
  Wave 0 stub case template. Provides `import Ecto` / `import Ecto.Query` for
  tests that reach for schemaless query helpers without a Repo.

  Plan 03 ships the real Repo-backed case (`Accrue.RepoCase`) in
  `test/support/repo_case.ex` once the `Accrue.TestRepo` module exists. This
  module is intentionally Repo-free at Wave 0 so the harness compiles before
  Plan 03 lands.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Query
    end
  end
end
