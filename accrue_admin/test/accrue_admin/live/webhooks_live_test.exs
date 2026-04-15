defmodule AccrueAdmin.WebhooksLiveTest do
  use AccrueAdmin.LiveCase, async: false

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

    insert_webhook(%{
      processor_event_id: "evt_dead",
      type: "invoice.payment_failed",
      status: :dead,
      livemode: true,
      received_at: ~U[2026-04-15 10:00:00Z]
    })

    insert_webhook(%{
      processor_event_id: "evt_ok",
      type: "invoice.paid",
      status: :succeeded,
      livemode: false,
      received_at: ~U[2026-04-15 09:00:00Z]
    })

    :ok
  end

  test "filters webhook rows and renders bulk replay confirmation", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} =
      live(conn, "/billing/webhooks?status=dead&type=invoice.payment_failed&livemode=true")

    assert html =~ "Replay, inspect, and trace webhook delivery"
    assert html =~ "evt_dead"
    refute html =~ "evt_ok"

    html = render_click(element(view, "[data-role='prepare-bulk-replay']"))
    assert html =~ "Confirm bulk replay"
    assert html =~ "1 failed or dead webhook rows"
  end

  defp insert_webhook(attrs) do
    defaults = %{
      processor: "stripe",
      processor_event_id: "evt_" <> Integer.to_string(System.unique_integer([:positive])),
      type: "invoice.payment_failed",
      livemode: false,
      endpoint: :default,
      status: :received,
      raw_body:
        Jason.encode!(%{
          "id" => "evt_seed",
          "object" => "event",
          "type" => "invoice.payment_failed"
        }),
      received_at: DateTime.utc_now(),
      data: %{"id" => "evt_seed", "object" => "event", "type" => "invoice.payment_failed"}
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
end
