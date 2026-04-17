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
    replay_suffix = Integer.to_string(System.unique_integer([:positive]))
    processor_event_id = "evt_host_replay_" <> replay_suffix
    invoice_id = "in_host_replay_" <> replay_suffix

    admin_user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    organization = AccrueHost.AccountsFixtures.organization_fixture(%{owner: admin_user})

    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(organization, "price_basic", trial_end: {:days, 14})

    {:ok, _fake_subscription} =
      Fake.transition(subscription.processor_id, :active, synthesize_webhooks: false)

    customer =
      Repo.one!(
        from(customer in Customer,
          where: customer.owner_type == "Organization" and customer.owner_id == ^organization.id
        )
      )

    subscription =
      Repo.get!(Subscription, subscription.id)
      |> Repo.preload(:subscription_items)

    webhook =
      insert_webhook(%{
        processor_event_id: processor_event_id,
        type: "invoice.payment_failed",
        status: :dead,
        raw_body:
          Jason.encode!(%{
            "id" => processor_event_id,
            "type" => "invoice.payment_failed",
            "data" => %{
              "object" => %{
                "id" => invoice_id,
                "object" => "invoice",
                "customer" => customer.processor_id,
                "subscription" => subscription.processor_id
              }
            }
          }),
        data: %{
          "id" => processor_event_id,
          "type" => "invoice.payment_failed",
          "data" => %{
            "object" => %{
              "id" => invoice_id,
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

    conn =
      conn
      |> log_in_user(admin_user, active_organization_id: organization.id)
      |> Plug.Conn.put_session(:active_organization_slug, organization.slug)
      |> Plug.Conn.put_session(:admin_organization_ids, [organization.id])
      |> fetch_flash()

    assert {:ok, _subscription_view, subscription_html} =
             live(conn, "/billing/subscriptions/#{subscription.id}?org=#{organization.slug}")

    assert subscription_html =~ subscription.id
    assert subscription_html =~ organization.name
    assert subscription_html =~ "price_basic"
    assert subscription_html =~ "active"

    assert {:ok, _webhook_view, webhook_html} =
             live(conn, "/billing/webhooks/#{webhook.id}?org=#{organization.slug}")

    assert webhook_html =~ webhook.processor_event_id
    assert webhook_html =~ "invoice.payment_failed"
    assert webhook_html =~ "Attempt 3/25"

    assert {:ok, _events_view, events_html} =
             live(conn, "/billing/events?source_webhook_event_id=#{webhook.id}")

    assert events_html =~ "Append-only billing and admin activity"
    assert events_html =~ "invoice.payment_failed"
    assert events_html =~ "activity"

    {:ok, replay_view, _html} =
      live(conn, "/billing/webhooks/#{webhook.id}?org=#{organization.slug}")

    replay_html = render_click(element(replay_view, "[data-role='replay-single']"))
    assert replay_html =~ "Replay webhook for the active organization?"

    replay_html = render_click(element(replay_view, "[data-role='confirm-replay']"))
    assert replay_html =~ "Replay requested for the active organization."

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

  test "ambiguous or out-of-scope webhook replay blocks single and bulk replay without success audits",
       %{conn: conn} do
    admin_user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    allowed_org = AccrueHost.AccountsFixtures.organization_fixture(%{owner: admin_user})
    outsider_org = AccrueHost.AccountsFixtures.organization_fixture()

    assert {:ok, %Subscription{} = outsider_subscription} =
             Billing.subscribe(outsider_org, "price_basic", trial_end: {:days, 14})

    outsider_webhook =
      insert_webhook(%{
        processor_event_id: "evt_host_out_scope",
        type: "invoice.payment_failed",
        status: :dead,
        raw_body:
          Jason.encode!(%{
            "id" => "evt_host_out_scope",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => outsider_subscription.processor_id}}
          }),
        data: %{
          "id" => "evt_host_out_scope",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => outsider_subscription.processor_id}}
        }
      })

    ambiguous_webhook =
      insert_webhook(%{
        processor_event_id: "evt_host_ambiguous",
        type: "invoice.payment_failed",
        status: :dead,
        raw_body:
          Jason.encode!(%{
            "id" => "evt_host_ambiguous",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => "in_unknown"}}
          }),
        data: %{
          "id" => "evt_host_ambiguous",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => "in_unknown"}}
        }
      })

    conn =
      conn
      |> log_in_user(admin_user, active_organization_id: allowed_org.id)
      |> Plug.Conn.put_session(:active_organization_slug, allowed_org.slug)
      |> Plug.Conn.put_session(:admin_organization_ids, [allowed_org.id])
      |> fetch_flash()

    assert {:error,
            {:redirect,
             %{to: "/billing/webhooks?org=" <> _slug, flash: %{"error" => denial_copy}}}} =
             live(conn, "/billing/webhooks/#{outsider_webhook.id}?org=#{allowed_org.slug}")

    assert denial_copy == "You don't have access to billing for this organization."

    assert {:ok, _view, ambiguous_html} =
             live(conn, "/billing/webhooks/#{ambiguous_webhook.id}?org=#{allowed_org.slug}")

    assert ambiguous_html =~
             "Ownership couldn&#39;t be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

    {:ok, bulk_view, _html} =
      live(
        conn,
        "/billing/webhooks?status=dead&type=invoice.payment_failed&org=#{allowed_org.slug}"
      )

    bulk_html = render_click(element(bulk_view, "[data-role='prepare-bulk-replay']"))
    assert bulk_html =~ "No failed or dead-lettered webhook rows match the current filters."

    assert Repo.aggregate(
             from(event in Event,
               where: event.type == "admin.webhook.replay.completed"
             ),
             :count,
             :id
           ) == 0
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
