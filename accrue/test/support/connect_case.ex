defmodule Accrue.ConnectCase do
  @moduledoc """
  ExUnit case template for Phase 5 Connect tests.

  Mirrors `Accrue.BillingCase` but additionally clears the
  `:accrue_connected_account_id` process-dictionary key at both setup
  and `on_exit`, so one test's `Accrue.Connect.with_account/2` scope
  cannot bleed into another (and so stale pdict entries from the owner
  process don't leak into async tests sharing a GenServer-backed Fake).
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accrue.{Connect, Money}
      alias Accrue.Connect.Account
      alias Accrue.TestRepo, as: Repo
      alias Accrue.Processor.Fake
      alias Accrue.Test.StripeFixtures

      import Accrue.Test.StripeFixtures
      import Ecto.Query
    end
  end

  setup tags do
    Process.delete(:accrue_connected_account_id)

    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(
        Accrue.TestRepo,
        shared: not tags[:async]
      )

    on_exit(fn ->
      Process.delete(:accrue_connected_account_id)
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    prior_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :test)

    on_exit(fn ->
      if prior_env do
        Application.put_env(:accrue, :env, prior_env)
      else
        Application.delete_env(:accrue, :env)
      end
    end)

    :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())

    :ok
  end
end
