defmodule AccrueAdmin.WebhookLiveTest do
  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice}
  alias Accrue.Events
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

    customer = insert_customer(%{processor_id: "cus_123"})
    invoice = insert_invoice(customer, %{processor_id: "in_123"})

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
        subject_id: invoice.id,
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

  test "in-scope replay uses the exact confirmation and success copy", %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    invoice = insert_invoice(customer, %{processor_id: "in_scope_detail"})

    webhook =
      insert_webhook(%{
        processor_event_id: "evt_scope_confirm",
        status: :dead,
        data: %{"object" => %{"id" => invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_scope_confirm",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => invoice.processor_id}}
          })
      })

    {:ok, _event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Invoice",
        subject_id: invoice.id,
        actor_type: "webhook",
        actor_id: webhook.processor_event_id,
        caused_by_webhook_event_id: webhook.id
      })

    {:ok, view, _html} = live(conn, "/billing/webhooks/#{webhook.id}?org=allowed-org")

    html = render_click(element(view, "[data-role='replay-single']"))
    assert html =~ "Replay webhook for the active organization?"

    html = render_click(element(view, "[data-role='confirm-replay']"))
    assert html =~ "Replay requested for the active organization."
  end

  test "webhook loader distinguishes in-scope, out-of-scope, and ambiguous ownership" do
    in_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    out_scope_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    in_scope_invoice = insert_invoice(in_scope_customer, %{processor_id: "in_scope_invoice"})
    out_scope_invoice = insert_invoice(out_scope_customer, %{processor_id: "out_scope_invoice"})

    in_scope_webhook =
      insert_webhook(%{
        processor_event_id: "evt_in_scope",
        data: %{"object" => %{"id" => in_scope_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_in_scope",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => in_scope_invoice.processor_id}}
          })
      })

    out_scope_webhook =
      insert_webhook(%{
        processor_event_id: "evt_out_scope",
        data: %{"object" => %{"id" => out_scope_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_out_scope",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => out_scope_invoice.processor_id}}
          })
      })

    ambiguous_webhook =
      insert_webhook(%{
        processor_event_id: "evt_ambiguous",
        data: %{"object" => %{"id" => "in_unknown"}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_ambiguous",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => "in_unknown"}}
          })
      })

    in_scope_webhook_id = in_scope_webhook.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^in_scope_webhook_id}} = Webhooks.detail(in_scope_webhook.id, owner_scope)
    assert :not_found = Webhooks.detail(out_scope_webhook.id, owner_scope)

    assert {:ambiguous, proof_context} = Webhooks.detail(ambiguous_webhook.id, owner_scope)
    assert proof_context.webhook_id == ambiguous_webhook.id
  end

  test "out-of-scope webhook route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    allowed_invoice = insert_invoice(allowed_customer, %{processor_id: "in_scope_redirect"})
    denied_invoice = insert_invoice(denied_customer, %{processor_id: "out_scope_redirect"})

    allowed_webhook =
      insert_webhook(%{
        processor_event_id: "evt_scope_redirect",
        data: %{"object" => %{"id" => allowed_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_scope_redirect",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => allowed_invoice.processor_id}}
          })
      })

    denied_webhook =
      insert_webhook(%{
        processor_event_id: "evt_denied_redirect",
        data: %{"object" => %{"id" => denied_invoice.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_denied_redirect",
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

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/webhooks/#{allowed_webhook.id}?org=allowed-org")

    assert allowed_html =~ allowed_webhook.processor_event_id

    assert {:error, {:redirect, %{to: "/billing/webhooks?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/webhooks/#{denied_webhook.id}?org=allowed-org")

    assert %{"error" => "You don't have access to billing for this organization."} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert redirect
  end

  test "ambiguous ownership renders blocked copy and no replay action", %{conn: conn} do
    ambiguous_webhook =
      insert_webhook(%{
        processor_event_id: "evt_ambiguous_route",
        status: :dead,
        data: %{"object" => %{"id" => "in_unknown"}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_ambiguous_route",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => "in_unknown"}}
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

    assert {:ok, _view, html} =
             live(conn, "/billing/webhooks/#{ambiguous_webhook.id}?org=allowed-org")

    assert html =~
             "Ownership couldn&#39;t be verified for this webhook. Replay is unavailable until the linked billing owner is resolved."

    refute html =~ "evt_ambiguous_route"
    refute html =~ "Replay webhook for the active organization?"
    refute html =~ "data-role=\"replay-single\""

    refute TestRepo.exists?(
             from(event in Event,
               where:
                 event.type == "admin.webhook.replay.completed" and
                   event.subject_id == ^ambiguous_webhook.id
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
