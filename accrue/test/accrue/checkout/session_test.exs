defmodule Accrue.Checkout.SessionTest do
  use ExUnit.Case, async: true

  alias Accrue.Checkout.Session

  test "from_processor maps a hosted transaction-style payload" do
    session =
      Session.from_processor(%{
        "id" => "txn_123",
        "status" => "ready",
        "customer_id" => "ctm_123",
        "subscription_id" => "sub_123",
        "currency" => "usd",
        "checkout" => %{"url" => "https://checkout.example/txn_123"},
        "custom_data" => %{"workspace_id" => "ws_123"}
      })

    assert session.id == "txn_123"
    assert session.object == "checkout.handoff"
    assert session.ui_mode == "hosted"
    assert session.url == "https://checkout.example/txn_123"
    assert session.customer == "ctm_123"
    assert session.subscription == "sub_123"
    assert session.metadata == %{"workspace_id" => "ws_123"}
    assert session.data["status"] == "ready"
  end
end
