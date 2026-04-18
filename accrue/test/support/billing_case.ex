defmodule Accrue.BillingCase do
  @moduledoc """
  ExUnit case template for Phase 3 billing tests.

  Sets up the `Accrue.TestRepo` sandbox, starts and resets
  `Accrue.Processor.Fake`, forces the `:accrue, :env` flag to `:test`
  (so `Accrue.Clock.utc_now/0` reads the Fake clock), seeds a per-test
  operation ID, and imports `Accrue.Test.StripeFixtures` for canned
  Stripe API payloads.

  Use as:

      defmodule MyTest do
        use Accrue.BillingCase, async: true

        test "foo" do
          customer = insert_customer()
          assert Accrue.Clock.utc_now() == Accrue.Processor.Fake.now()
        end
      end
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Accrue.{Billing, Money}
      alias Accrue.TestRepo, as: Repo

      alias Accrue.Billing.{
        Charge,
        Customer,
        Invoice,
        PaymentMethod,
        Subscription,
        SubscriptionItem
      }

      alias Accrue.Processor.Fake
      alias Accrue.Test.StripeFixtures

      import Accrue.Test.StripeFixtures
      import Ecto.Query
    end
  end

  setup tags do
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(
        Accrue.TestRepo,
        shared: not tags[:async]
      )

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset_preserve_connect()

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
