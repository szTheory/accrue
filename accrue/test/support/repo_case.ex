defmodule Accrue.RepoCase do
  @moduledoc """
  ExUnit case template for tests that need a real `Accrue.TestRepo`
  connection inside the `Ecto.Adapters.SQL.Sandbox`.

  `Accrue.TestRepo` is started once globally by `test/test_helper.exs`
  (Accrue does NOT ship a Repo — D-10 — so there is no library
  supervisor to piggyback on). This case template only checks out a
  sandboxed connection per test and releases it on exit.

  Set `use Accrue.RepoCase, async: true` on test modules that do NOT
  need a shared connection (pure, isolated data); the default is
  shared mode so spawned processes can see the same rows.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accrue.TestRepo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
