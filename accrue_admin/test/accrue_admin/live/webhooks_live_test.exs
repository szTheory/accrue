defmodule AccrueAdmin.WebhooksLiveTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Webhooks
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

  test "filters webhook rows and renders organization-scoped bulk replay confirmation", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} =
      live(conn, "/billing/webhooks?status=dead&type=invoice.payment_failed&livemode=true")

    assert html =~ "Replay, inspect, and trace webhook delivery"
    assert html =~ "evt_dead"
    refute html =~ "evt_ok"

    html = render_click(element(view, "[data-role='prepare-bulk-replay']"))
    assert html =~ "Confirm bulk replay"
    assert html =~ "Replay 1 failed or dead webhook rows for the active organization?"
  end

  test "scoped bulk replay counts ignore rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_scope_bulk"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_bulk"})

    insert_webhook(%{
      processor_event_id: "evt_scope_bulk",
      status: :dead,
      type: "invoice.payment_failed",
      data: %{"object" => %{"id" => allowed_invoice.processor_id}},
      raw_body:
        Jason.encode!(%{
          "id" => "evt_scope_bulk",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => allowed_invoice.processor_id}}
        })
    })

    insert_webhook(%{
      processor_event_id: "evt_out_scope_bulk",
      status: :dead,
      type: "invoice.payment_failed",
      data: %{"object" => %{"id" => denied_invoice.processor_id}},
      raw_body:
        Jason.encode!(%{
          "id" => "evt_out_scope_bulk",
          "type" => "invoice.payment_failed",
          "data" => %{"object" => %{"id" => denied_invoice.processor_id}}
        })
    })

    owner_scope = organization_owner_scope("org_allowed")

    assert Webhooks.bulk_replay_count(owner_scope, %{
             status: :dead,
             type: "invoice.payment_failed"
           }) ==
             1
  end

  test "blocked bulk replay does not emit replay-success audit events", %{conn: conn} do
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_bulk_blocked"})

    denied_webhook =
      insert_webhook(%{
        processor_event_id: "evt_out_scope_only",
        status: :dead,
        type: "invoice.payment_failed",
        data: %{"object" => %{"id" => denied_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_out_scope_only",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => denied_invoice.processor_id}}
          })
      })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    {:ok, view, _html} =
      live(conn, "/billing/webhooks?status=dead&type=invoice.payment_failed&org=allowed-org")

    html = render_click(element(view, "[data-role='prepare-bulk-replay']"))
    assert html =~ "No failed or dead-lettered webhook rows match the current filters."

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^denied_webhook.id
             )
           )
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

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_invoice(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      currency: "usd",
      status: :open,
      collection_method: "charge_automatically",
      metadata: %{},
      data: %{},
      lock_version: 1,
      processor_id: "in_" <> Integer.to_string(System.unique_integer([:positive]))
    }

    %Invoice{}
    |> Invoice.force_status_changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
