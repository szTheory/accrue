defmodule Accrue.ConnCase do
  @moduledoc """
  ExUnit case template for Plug/HTTP integration tests.

  Provides `Plug.Test` and `Plug.Conn` helpers alongside Ecto sandbox
  checkout (identical to `Accrue.RepoCase`). Use this for any test that
  exercises a Plug pipeline — webhook plug tests, router tests, etc.

  Set `use Accrue.ConnCase, async: true` on test modules that do NOT
  need a shared connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Plug.Test
      import Ecto
      import Ecto.Query

      alias Accrue.TestRepo
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
