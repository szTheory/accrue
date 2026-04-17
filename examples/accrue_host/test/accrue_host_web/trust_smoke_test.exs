defmodule AccrueHostWeb.TrustSmokeTest do
  use AccrueHost.HostFlowProofCase, async: false

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.WebhookEvent
  alias AccrueHost.AccountsFixtures
  alias AccrueHost.Billing
  alias AccrueHost.Repo

  @moduletag :phase15
  @webhook_secret "whsec_test_host"

  test "signed webhook ingest stays inside the release-blocking smoke budget" do
    budget_ms = 100
    user = AccountsFixtures.user_fixture(%{email: "host-trust-smoke@example.test"})

    assert {:ok, %Subscription{} = subscription} =
             Billing.subscribe(user, "price_basic", trial_end: {:days, 14})

    processor_event_id = "evt_host_trust_smoke"
    payload = signed_subscription_payload(subscription.processor_id, processor_event_id)
    signature = LatticeStripe.Webhook.generate_test_signature(payload, @webhook_secret)

    {elapsed_us, conn} = :timer.tc(fn -> post_webhook(payload, signature) end)
    elapsed_ms = System.convert_time_unit(elapsed_us, :microsecond, :millisecond)

    assert conn.status == 200
    assert %{"ok" => true} = Jason.decode!(conn.resp_body)
    assert Repo.aggregate(WebhookEvent, :count) == 1

    assert elapsed_ms <= budget_ms,
           "release-blocking webhook ingest smoke failed: #{elapsed_ms}ms exceeded #{budget_ms}ms"
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
