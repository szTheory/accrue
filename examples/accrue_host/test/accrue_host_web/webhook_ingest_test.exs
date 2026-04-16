defmodule AccrueHostWeb.WebhookIngestTest do
  use AccrueHost.HostFlowProofCase, async: false

  import Ecto.Query

  alias Accrue.Billing.Subscription
  alias Accrue.Events.Event
  alias Accrue.Webhook.DispatchWorker
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  @moduletag :phase10
  @webhook_secret "whsec_test_host"

  test "signed POST to /webhooks/stripe verifies, ingests, dispatches, and stays idempotent" do
    user = AccountsFixtures.user_fixture()

    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    processor_event_id = "evt_host_webhook_subscription_created"
    payload = signed_subscription_payload(subscription.processor_id, processor_event_id)
    signature = LatticeStripe.Webhook.generate_test_signature(payload, @webhook_secret)

    first_conn = post_webhook(payload, signature)
    status_code = first_conn.status

    assert status_code == 200
    assert %{"ok" => true} = Jason.decode!(first_conn.resp_body)

    assert Repo.aggregate(WebhookEvent, :count) == 1
    assert Repo.aggregate(Oban.Job, :count) == 1

    webhook =
      Repo.get_by!(WebhookEvent,
        processor: "stripe",
        processor_event_id: processor_event_id
      )

    assert webhook.type == "customer.subscription.created"
    assert webhook.status == :received

    duplicate_conn = post_webhook(payload, signature)

    assert duplicate_conn.status == 200
    assert %{"ok" => true} = Jason.decode!(duplicate_conn.resp_body)
    assert Repo.aggregate(WebhookEvent, :count) == 1
    assert Repo.aggregate(Oban.Job, :count) == 1

    assert :ok =
             DispatchWorker.perform(%Oban.Job{
               args: %{"webhook_event_id" => webhook.id},
               attempt: 1,
               max_attempts: 25
             })

    webhook = Repo.get!(WebhookEvent, webhook.id)
    assert webhook.status == :succeeded

    assert Repo.exists?(
             from(event in Event,
               where:
                 event.type == "webhook.received" and
                   event.subject_type == "WebhookEvent" and
                   event.subject_id == ^webhook.id
             )
           )

    host_handler_event =
      Repo.one!(
        from(event in Event,
          where:
            event.type == "host.webhook.handled" and
              event.caused_by_webhook_event_id == ^webhook.id
        )
      )

    assert host_handler_event.data["handler"] == "AccrueHost.BillingHandler"
    assert host_handler_event.data["event_type"] == "customer.subscription.created"
    assert host_handler_event.data["object_id"] == subscription.processor_id
    assert Repo.aggregate(Event, :count) >= 2
  end

  test "tampered signed payload is rejected before ingest" do
    payload =
      signed_subscription_payload(
        "sub_tampered",
        "evt_host_webhook_tampered"
      )

    signature = LatticeStripe.Webhook.generate_test_signature(payload, @webhook_secret)
    tampered_payload = String.replace(payload, "sub_tampered", "sub_tampered_changed")

    conn = post_webhook(tampered_payload, signature)

    assert conn.status == 400
    assert %{"error" => "signature_verification_failed"} = Jason.decode!(conn.resp_body)
    assert Repo.aggregate(WebhookEvent, :count) == 0
    assert Repo.aggregate(Oban.Job, :count) == 0
  end

  defp post_webhook(payload, signature) do
    Plug.Test.conn(:post, "/webhooks/stripe", payload)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("stripe-signature", signature)
    |> AccrueHostWeb.Router.call(AccrueHostWeb.Router.init([]))
  end

  defp signed_subscription_payload(subscription_id, processor_event_id) do
    Jason.encode!(%{
      "id" => processor_event_id,
      "object" => "event",
      "type" => "customer.subscription.created",
      "created" => 1_712_880_000,
      "livemode" => false,
      "data" => %{
        "object" => %{
          "id" => subscription_id,
          "object" => "subscription"
        }
      }
    })
  end
end
