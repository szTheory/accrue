defmodule Accrue.Billing.SubscriptionProjectionProviderTest do
  use ExUnit.Case, async: true

  alias Accrue.Billing.SubscriptionProjection

  test "decompose/2 branches explicitly for :braintree" do
    subscription = %{
      "id" => "sub_braintree_123",
      "status" => "Active",
      "plan_id" => "premium_monthly",
      "billing_period_start_date" => "2024-01-01T00:00:00Z",
      "billing_period_end_date" => "2024-02-01T00:00:00Z",
      "first_billing_date" => "2024-01-01"
    }

    assert {:ok, attrs} = SubscriptionProjection.decompose(subscription, processor: :braintree)
    assert attrs.processor_id == "sub_braintree_123"
    assert attrs.status == :active
    assert attrs.cancel_at_period_end == false
    assert %DateTime{} = attrs.current_period_start
    assert %DateTime{} = attrs.current_period_end
    assert attrs.data["plan_id"] == "premium_monthly"
  end

  test "decompose/2 supports a Paddle-style scheduled cancellation payload" do
    subscription = %{
      "id" => "sub_01",
      "status" => "active",
      "custom_data" => %{"workspace_id" => "ws_123"},
      "current_billing_period" => %{
        "starts_at" => "2026-04-01T00:00:00Z",
        "ends_at" => "2026-05-01T00:00:00Z"
      },
      "scheduled_change" => %{
        "action" => "cancel",
        "effective_at" => "2026-05-01T00:00:00Z"
      }
    }

    assert {:ok, attrs} = SubscriptionProjection.decompose(subscription, processor: :paddle)
    assert attrs.processor_id == "sub_01"
    assert attrs.status == :active
    assert attrs.cancel_at_period_end == true
    assert %DateTime{} = attrs.current_period_start
    assert %DateTime{} = attrs.current_period_end
    assert %DateTime{} = attrs.cancel_at
    assert attrs.metadata == %{"workspace_id" => "ws_123"}
    assert attrs.data["scheduled_change"]["action"] == "cancel"
  end

  test "decompose/2 marks paused Paddle subscriptions via scheduled change" do
    subscription = %{
      "id" => "sub_02",
      "status" => "active",
      "scheduled_change" => %{
        "action" => "pause",
        "effective_at" => "2026-05-01T00:00:00Z"
      }
    }

    assert {:ok, attrs} = SubscriptionProjection.decompose(subscription, processor: :paddle)
    assert attrs.pause_collection["action"] == "pause"
  end
end
