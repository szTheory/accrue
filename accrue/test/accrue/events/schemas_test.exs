defmodule Accrue.Events.SchemasTest do
  @moduledoc """
  Plan 03-08 Task 2: canonical event schemas for the 24 Phase 3 event
  types plus the `Accrue.Events.Upcaster` behaviour (D3-65..70).
  """
  use ExUnit.Case, async: true

  alias Accrue.Events.Schemas

  test "registry maps all 24 Phase 3 event atoms" do
    assert Schemas.count() == 24
  end

  test "for/1 returns module for known atom" do
    assert Schemas.for(:"subscription.created") ==
             Accrue.Events.Schemas.SubscriptionCreated

    assert Schemas.for(:"refund.fees_settled") ==
             Accrue.Events.Schemas.RefundFeesSettled

    assert Schemas.for(:"card.expiring_soon") ==
             Accrue.Events.Schemas.CardExpiringSoon
  end

  test "for/1 returns nil for unknown atom" do
    assert Schemas.for(:"unknown.event") == nil
  end

  test "every registered module implements schema_version/0 == 1" do
    for {_type, mod} <- Schemas.all() do
      assert function_exported?(mod, :schema_version, 0)
      assert mod.schema_version() == 1
    end
  end

  test "SubscriptionCreated struct derives Jason.Encoder" do
    payload = %Accrue.Events.Schemas.SubscriptionCreated{
      stripe_id: "sub_1",
      customer_id: "cus_1",
      price_id: "price_1",
      quantity: 1,
      source: :api
    }

    encoded = Jason.encode!(payload)
    assert encoded =~ "sub_1"
    assert encoded =~ "cus_1"
  end

  test "Upcaster behaviour is implemented via upcast/1 on every schema" do
    for {_type, mod} <- Schemas.all() do
      assert function_exported?(mod, :upcast, 1)
      assert {:ok, %{}} = mod.upcast(%{})
    end
  end

  test "Accrue.Events.Upcaster defines upcast/1 callback" do
    callbacks = Accrue.Events.Upcaster.behaviour_info(:callbacks)
    assert {:upcast, 1} in callbacks
  end
end
