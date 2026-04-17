defmodule AccrueAdmin.WebhookReplayTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.TestRepo

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_single",
        type: "invoice.payment_failed",
        status: :dead
      })

    bulk_one =
      insert_webhook(%{
        processor_event_id: "evt_bulk_1",
        type: "invoice.payment_failed",
        status: :dead
      })

    bulk_two =
      insert_webhook(%{
        processor_event_id: "evt_bulk_2",
        type: "invoice.payment_failed",
        status: :failed
      })

    {:ok, webhook: webhook, bulk_webhooks: [webhook, bulk_one, bulk_two]}
  end

  test "single replay requeues the webhook and records admin audit linkage", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}")

    _ = render_click(element(view, "[data-role='replay-single']"))
    html = render_click(element(view, "[data-role='confirm-replay']"))
    assert html =~ "Webhook replay requested."

    updated = TestRepo.get!(WebhookEvent, webhook.id)
    assert updated.status == :received

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.webhook.replay.completed" and
              event.subject_id == ^webhook.id
        )
      )

    assert audit_event.actor_type == "admin"
    assert audit_event.caused_by_webhook_event_id == webhook.id
  end

  test "bulk replay confirms once and records one admin audit event", %{
    conn: conn,
    bulk_webhooks: bulk_webhooks
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/webhooks?type=invoice.payment_failed")

    audit_count_before =
      TestRepo.aggregate(
        from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
        :count,
        :id
      )

    _ = render_click(element(view, "[data-role='prepare-bulk-replay']"))
    html = render_click(element(view, "[data-role='confirm-bulk-replay']"))
    assert html =~ "Bulk replay requested"

    audit_count_after =
      TestRepo.aggregate(
        from(event in Event, where: event.type == "admin.webhook.bulk_replay.completed"),
        :count,
        :id
      )

    assert audit_count_after == audit_count_before + 1

    webhook_ids = Enum.map(bulk_webhooks, & &1.id)

    blocked_count =
      from(webhook in WebhookEvent,
        where: webhook.id in ^webhook_ids and webhook.status in [:failed, :dead]
      )
      |> TestRepo.aggregate(:count, :id)

    assert blocked_count == 0
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
    |> TestRepo.insert!()
    |> then(fn webhook ->
      webhook
      |> Ecto.Changeset.change(%{status: Map.get(attrs, :status, :received)})
      |> TestRepo.update!()
    end)
  end
end
