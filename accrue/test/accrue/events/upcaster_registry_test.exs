defmodule Accrue.Events.UpcasterRegistryTest do
  use ExUnit.Case, async: true

  alias Accrue.Events.UpcasterRegistry
  alias Accrue.Events.Upcasters.V1ToV2

  describe "chain/3" do
    test "from == to returns empty chain (identity)" do
      assert {:ok, []} = UpcasterRegistry.chain("subscription.created", 1, 1)
      assert {:ok, []} = UpcasterRegistry.chain("anything.at.all", 5, 5)
    end

    test "for unregistered type returns empty chain (identity)" do
      assert {:ok, []} = UpcasterRegistry.chain("not.in.registry", 1, 2)
    end

    test "returns the registered chain modules for known type/version" do
      # subscription.created is registered with V1ToV2 in the example registry
      assert {:ok, modules} =
               UpcasterRegistry.chain("subscription.created", 1, 2)

      assert V1ToV2 in modules
    end

    test "returns {:error, {:unknown_schema_version, v}} for unknown target version" do
      assert {:error, {:unknown_schema_version, 99}} =
               UpcasterRegistry.chain("subscription.created", 1, 99)
    end
  end

  describe "V1ToV2.upcast/1" do
    test "stamps schema version 2 onto payload" do
      assert {:ok, %{"_schema_version" => 2, "foo" => 1}} = V1ToV2.upcast(%{"foo" => 1})
    end
  end
end
