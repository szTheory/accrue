defmodule AccrueAdmin.RepoCase do
  @moduledoc """
  ExUnit case template for repo-backed admin query tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias AccrueAdmin.TestRepo

      import Ecto.Query
    end
  end

  setup tags do
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(AccrueAdmin.TestRepo, shared: not tags[:async])

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
