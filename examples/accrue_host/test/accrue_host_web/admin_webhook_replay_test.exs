defmodule AccrueHostWeb.AdminWebhookReplayTest do
  use AccrueHost.HostFlowProofCase, async: false

  @moduletag :phase10

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Processor.Fake
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  test "billing admin can inspect customer/subscription, webhook history, and replay a single webhook row",
       %{conn: conn} do
    admin_user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    customer_user =
      AccrueHost.AccountsFixtures.user_fixture(%{email: "billing-history@example.com"})

    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(customer_user, "price_basic", trial_end: {:days, 14})

    {:ok, _fake_subscription} =
      Fake.transition(subscription.processor_id, :active, synthesize_webhooks: false)

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "User" and customer.owner_id == ^customer_user.id
        )
      )

    subscription =
      Repo.get!(Subscription, subscription.id)
      |> Repo.preload(:subscription_items)

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_host_replay",
        type: "invoice.payment_failed",
        status: :dead,
        raw_body:
          Jason.encode!(%{
            "id" => "evt_host_replay",
            "type" => "invoice.payment_failed",
            "data" => %{
              "object" => %{
                "id" => "in_host_replay",
                "object" => "invoice",
                "customer" => customer.processor_id,
                "subscription" => subscription.processor_id
              }
            }
          }),
        data: %{
          "id" => "evt_host_replay",
          "type" => "invoice.payment_failed",
          "data" => %{
            "object" => %{
              "id" => "in_host_replay",
              "customer" => customer.processor_id,
              "subscription" => subscription.processor_id
            }
          }
        }
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    insert_attempt_job(webhook.id)

    conn = log_in_user(conn, admin_user)

    assert {:ok, _subscription_view, subscription_html} =
             live(conn, "/billing/subscriptions/#{subscription.id}")

    assert subscription_html =~ subscription.id
    assert subscription_html =~ customer_user.email
    assert subscription_html =~ "price_basic"
    assert subscription_html =~ "active"

    assert {:ok, _webhook_view, webhook_html} = live(conn, "/billing/webhooks/#{webhook.id}")
    assert webhook_html =~ webhook.processor_event_id
    assert webhook_html =~ "invoice.payment_failed"
    assert webhook_html =~ "Attempt 3/25"

    assert {:ok, _events_view, events_html} =
             live(conn, "/billing/events?source_webhook_event_id=#{webhook.id}")

    assert events_html =~ "Append-only billing and admin activity"
    assert events_html =~ "invoice.payment_failed"
    assert events_html =~ "activity"

    {:ok, replay_view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

    replay_html = render_click(element(replay_view, "[data-role='replay-single']"))
    assert replay_html =~ "Webhook replay requested."

    updated = Repo.get!(WebhookEvent, webhook.id)
    assert updated.status == :received

    assert {:ok, _audit_view, audit_html} =
             live(conn, "/billing/events?source_webhook_event_id=#{webhook.id}&actor_type=admin")

    assert audit_html =~ "admin.webhook.replay.completed"

    audit_event =
      Repo.one!(
        from(event in Event,
          where:
            event.type == "admin.webhook.replay.completed" and
              event.subject_id == ^webhook.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert audit_event.actor_id == admin_user.id
    assert audit_event.caused_by_webhook_event_id == webhook.id
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body: Jason.encode!(%{"id" => "evt_seed", "object" => "event"}),
      received_at: DateTime.utc_now(),
      data: %{}
    }

    Map.merge(defaults, attrs)
    |> WebhookEvent.ingest_changeset()
    |> Repo.insert!()
    |> then(fn webhook ->
      webhook
      |> Ecto.Changeset.change(%{
        status: Map.get(attrs, :status, :received),
        processed_at: Map.get(attrs, :processed_at)
      })
      |> Repo.update!()
    end)
  end

  defp insert_attempt_job(webhook_id) do
    Repo.insert!(%Oban.Job{
      state: "discarded",
      queue: "accrue_webhooks",
      worker: "Accrue.Webhook.DispatchWorker",
      args: %{"webhook_event_id" => webhook_id},
      errors: [%{"attempt" => 3, "error" => "processor timeout"}],
      attempt: 3,
      max_attempts: 25,
      inserted_at: ~U[2026-04-15 10:01:00.000000Z],
      attempted_at: ~U[2026-04-15 10:02:00.000000Z],
      discarded_at: ~U[2026-04-15 10:03:00.000000Z]
    })
  end
end
