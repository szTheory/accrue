defmodule AccrueAdmin.EventsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events
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
        processor_event_id: "evt_feed",
        type: "invoice.payment_failed",
        status: :dead
      })

    {:ok, _} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: "in_123",
        actor_type: "webhook",
        actor_id: "evt_123",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, _} =
      Events.record(%{
        type: "admin.webhook.replay.completed",
        subject_type: "WebhookEvent",
        subject_id: webhook.id,
        actor_type: "admin",
        actor_id: "admin_1",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, webhook_id: webhook.id}
  end

  test "renders the global activity feed and filters by webhook source", %{
    conn: conn,
    webhook_id: webhook_id
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/events?source_webhook_event_id=#{webhook_id}&actor_type=admin")

    assert html =~ "Append-only billing and admin activity"
    assert html =~ "admin.webhook.replay.completed"
    refute html =~ "invoice.payment_failed"
    assert html =~ webhook_id
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
