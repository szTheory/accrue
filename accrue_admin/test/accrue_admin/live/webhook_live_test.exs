defmodule AccrueAdmin.WebhookLiveTest do
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
        processor_event_id: "evt_detail",
        type: "invoice.payment_failed",
        status: :dead,
        received_at: ~U[2026-04-15 10:00:00Z],
        raw_body:
          Jason.encode!(%{
            "id" => "evt_detail",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"customer" => "cus_123", "attempt_count" => 3}}
          }),
        data: %{"redacted" => true}
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: "in_123",
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    insert_attempt_job(webhook.id)

    {:ok, webhook: webhook}
  end

  test "renders forensic payload, verification summary, attempt history, and derived events", %{
    conn: conn,
    webhook: webhook
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/webhooks/#{webhook.id}")

    assert html =~ "Signature verification passed"
    assert html =~ "Attempt 3/25"
    assert html =~ "invoice.payment_failed"
    assert html =~ "cus_123"
    assert html =~ "/billing/events?source_webhook_event_id=#{webhook.id}"
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
      |> Ecto.Changeset.change(%{
        status: Map.get(attrs, :status, :received),
        processed_at: Map.get(attrs, :processed_at)
      })
      |> TestRepo.update!()
    end)
  end

  defp insert_attempt_job(webhook_id) do
    TestRepo.insert!(%Oban.Job{
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
