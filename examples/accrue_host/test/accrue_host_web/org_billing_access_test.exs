defmodule AccrueHostWeb.OrgBillingAccessTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Accrue.Billing.{Customer, Subscription}
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  test "direct links to another organization's customer, subscription, and webhook screens redirect with denial copy", %{
    conn: conn
  } do
    admin_user =
      AccrueHost.AccountsFixtures.user_fixture()
      |> Ecto.Changeset.change(billing_admin: true)
      |> Repo.update!()

    allowed_org = AccrueHost.AccountsFixtures.organization_fixture(%{owner: admin_user})
    outsider_org = AccrueHost.AccountsFixtures.organization_fixture()

    assert {:ok, %Subscription{} = outsider_subscription} =
             Billing.subscribe(outsider_org, "price_basic", trial_end: {:days, 14})

    outsider_customer =
      Repo.one!(
        from(customer in Customer,
          where:
            customer.owner_type == "Organization" and customer.owner_id == ^outsider_org.id,
          limit: 1
        )
      )

    outsider_webhook =
      insert_webhook(%{
        processor_event_id: "evt_host_denied",
        status: :dead,
        data: %{"object" => %{"id" => outsider_subscription.processor_id}},
        raw_body:
          Jason.encode!(%{
            "id" => "evt_host_denied",
            "type" => "invoice.payment_failed",
            "data" => %{"object" => %{"id" => outsider_subscription.processor_id}}
          })
      })

    conn =
      conn
      |> log_in_user(admin_user, active_organization_id: allowed_org.id)
      |> Plug.Conn.put_session(:active_organization_slug, allowed_org.slug)
      |> Plug.Conn.put_session(:admin_organization_ids, [allowed_org.id])

    assert_denied_redirect(
      live(conn, "/billing/customers/#{outsider_customer.id}?org=#{allowed_org.slug}"),
      "/billing/customers?org=#{allowed_org.slug}"
    )

    assert_denied_redirect(
      live(conn, "/billing/subscriptions/#{outsider_subscription.id}?org=#{allowed_org.slug}"),
      "/billing/subscriptions?org=#{allowed_org.slug}"
    )

    assert_denied_redirect(
      live(conn, "/billing/webhooks/#{outsider_webhook.id}?org=#{allowed_org.slug}"),
      "/billing/webhooks?org=#{allowed_org.slug}"
    )
  end

  defp assert_denied_redirect(result, expected_path) do
    assert {:error, {:redirect, %{to: ^expected_path, flash: flash_token}}} = result

    assert %{"error" => "You don't have access to billing for this organization."} =
             Phoenix.LiveView.Utils.verify_flash(AccrueHostWeb.Endpoint, flash_token)
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

    %Accrue.Webhook.WebhookEvent{}
    |> Accrue.Webhook.WebhookEvent.ingest_changeset(Map.merge(defaults, attrs))
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
end
