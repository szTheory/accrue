defmodule Accrue.RepoCase do
  @moduledoc """
  ExUnit case template for tests that need a real `Accrue.TestRepo`
  connection inside the `Ecto.Adapters.SQL.Sandbox`.

  Starts `Accrue.TestRepo` once per test process via `start_supervised!/1`
  (no library-level supervisor — D-10), checks out a sandboxed
  connection in `setup/1`, and allows shared-mode fan-out for async
  tests that spawn helper processes.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accrue.TestRepo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Accrue.RepoCase
    end
  end

  setup tags do
    Accrue.RepoCase.start_test_repo()
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end

  @doc """
  Starts `Accrue.TestRepo` under the ExUnit supervisor if it is not
  already running. Idempotent — safe to call from every `setup` block.
  """
  def start_test_repo do
    case Process.whereis(Accrue.TestRepo) do
      nil ->
        {:ok, _pid} = Accrue.TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox)
        Ecto.Adapters.SQL.Sandbox.mode(Accrue.TestRepo, :manual)
        :ok

      _pid ->
        :ok
    end
  end
end
