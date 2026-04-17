defmodule AccrueAdmin.EventsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Invoice}
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

    in_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    out_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    in_scope_invoice = insert_invoice(in_scope_customer, %{processor_id: "in_scope_invoice"})
    out_scope_invoice = insert_invoice(out_scope_customer, %{processor_id: "out_scope_invoice"})

    {:ok, _} =
      Events.record(%{
        type: "invoice.payment_failed.in_scope",
        subject_type: "Invoice",
        subject_id: in_scope_invoice.id,
        actor_type: "admin",
        actor_id: "admin_1",
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, _} =
      Events.record(%{
        type: "invoice.payment_failed.out_of_scope",
        subject_type: "Invoice",
        subject_id: out_scope_invoice.id,
        actor_type: "admin",
        actor_id: "admin_1",
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

    {:ok, webhook_id: webhook.id, in_scope_invoice: in_scope_invoice, out_scope_invoice: out_scope_invoice}
  end

  test "renders the active-organization event feed without out-of-scope rows", %{
    conn: conn,
    webhook_id: webhook_id,
    in_scope_invoice: in_scope_invoice,
    out_scope_invoice: out_scope_invoice
  } do
    conn =
      Phoenix.ConnTest.init_test_session(conn,
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, html} =
             live(
               conn,
               "/billing/events?org=allowed-org&source_webhook_event_id=#{webhook_id}&actor_type=admin"
             )

    assert html =~ "Billing activity for the active organization"
    assert html =~ "invoice.payment_failed.in_scope"
    assert html =~ in_scope_invoice.id
    refute html =~ "invoice.payment_failed.out_of_scope"
    refute html =~ out_scope_invoice.id
    assert html =~ webhook_id
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
