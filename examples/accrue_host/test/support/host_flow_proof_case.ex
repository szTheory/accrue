defmodule AccrueHost.HostFlowProofCase do
  @moduledoc """
  Shared proof setup for focused host billing flow tests.

  Resets deterministic processor state and deletes only the persisted
  browser/direct proof rows that can collide across reruns on a migrated
  test database.
  """

  use ExUnit.CaseTemplate

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.Accounts.User
  alias AccrueHost.Repo

  import Ecto.Query

  @cleanup_event_types [
    "webhook.received",
    "host.webhook.handled",
    "invoice.payment_failed",
    "admin.webhook.replay.completed"
  ]

  @cleanup_user_emails [
    "billing-history@example.test",
    "billing-history@example.com",
    "host-user@example.test",
    "host-admin@example.test"
  ]

  @cleanup_customer_emails [
    "billing-history@example.test",
    "billing-history@example.com"
  ]

  using do
    quote do
      @endpoint AccrueHostWeb.Endpoint

      use AccrueHostWeb, :verified_routes
      use Accrue.Test

      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import AccrueHostWeb.ConnCase
      import Ecto.Query
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

    cleanup_host_flow_footprint!()
    :ok = Accrue.Actor.put_operation_id("test-" <> Ecto.UUID.generate())

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  defp cleanup_host_flow_footprint! do
    delete_proof_jobs!()
    delete_proof_events!()
    delete_proof_webhooks!()
    delete_proof_subscription_items!()
    delete_proof_subscriptions!()
    delete_proof_customers!()
    delete_proof_users!()
  end

  defp delete_proof_jobs! do
    Repo.delete_all(
      from(job in Oban.Job,
        where: job.worker == "Accrue.Webhook.DispatchWorker",
        where: job.state == "discarded"
      )
    )
  end

  defp delete_proof_events! do
    Repo.query!("ALTER TABLE accrue_events DISABLE TRIGGER accrue_events_immutable_trigger")

    try do
      Repo.delete_all(
        from(event in Event,
          where: event.type in ^@cleanup_event_types
        )
      )
    after
      Repo.query!("ALTER TABLE accrue_events ENABLE TRIGGER accrue_events_immutable_trigger")
    end
  end

  defp delete_proof_webhooks! do
    Repo.delete_all(
      from(webhook in WebhookEvent,
        where: like(webhook.processor_event_id, "evt_host_%")
      )
    )
  end

  defp delete_proof_subscription_items! do
    Repo.delete_all(
      from(item in SubscriptionItem,
        where: item.price_id == "price_basic"
      )
    )
  end

  defp delete_proof_subscriptions! do
    Repo.delete_all(
      from(subscription in Subscription,
        where:
          like(subscription.processor_id, "sub_fake_%") or
            like(subscription.processor_id, "sub_host_%")
      )
    )
  end

  defp delete_proof_customers! do
    Repo.delete_all(
      from(customer in Customer,
        where:
          customer.email in ^@cleanup_customer_emails or
            like(customer.email, "host-%@example.test")
      )
    )
  end

  defp delete_proof_users! do
    Repo.delete_all(
      from(user in User,
        where: user.email in ^@cleanup_user_emails
      )
    )
  end
end
