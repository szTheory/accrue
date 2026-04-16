defmodule AccrueHost.AccrueCase do
  @moduledoc """
  Shared Accrue integration test support for the host app.

  Use this in tests that need the host Repo sandbox plus the public
  `Accrue.Test` helpers for fake processor, mail, PDF, and event assertions.
  """

  use ExUnit.CaseTemplate

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias AccrueHost.Repo

  import Ecto.Query

  using do
    quote do
      alias AccrueHost.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import AccrueHost.AccrueCase

      use Accrue.Test
    end
  end

  setup tags do
    AccrueHost.DataCase.setup_sandbox(tags)

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

    cleanup_fake_billing_rows!()
    :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())

    :ok
  end

  defp cleanup_fake_billing_rows! do
    Repo.delete_all(
      from(item in SubscriptionItem,
        join: subscription in Subscription,
        on: subscription.id == item.subscription_id,
        where: like(subscription.processor_id, "sub_fake_%")
      )
    )

    Repo.delete_all(
      from(subscription in Subscription,
        where: like(subscription.processor_id, "sub_fake_%")
      )
    )

    Repo.delete_all(
      from(customer in Customer,
        where: like(customer.processor_id, "cus_fake_%")
      )
    )
  end
end
