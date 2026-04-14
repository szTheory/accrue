defmodule Accrue.Processor.Idempotency.ModuleTest do
  use ExUnit.Case, async: true

  alias Accrue.Processor.Idempotency

  describe "key/4" do
    test "is deterministic across calls" do
      k1 = Idempotency.key(:create_subscription, "sub_123", "op_abc")
      k2 = Idempotency.key(:create_subscription, "sub_123", "op_abc")
      assert k1 == k2
    end

    test "differs when op changes" do
      refute Idempotency.key(:create_subscription, "sub_123", "op_abc") ==
               Idempotency.key(:update_subscription, "sub_123", "op_abc")
    end

    test "differs when subject_id changes" do
      refute Idempotency.key(:create_subscription, "sub_123", "op_abc") ==
               Idempotency.key(:create_subscription, "sub_124", "op_abc")
    end

    test "differs when operation_id changes" do
      refute Idempotency.key(:create_subscription, "sub_123", "op_abc") ==
               Idempotency.key(:create_subscription, "sub_123", "op_xyz")
    end

    test "sequence suffix yields distinct keys" do
      refute Idempotency.key(:create_charge, "cus_1", "op_1", 0) ==
               Idempotency.key(:create_charge, "cus_1", "op_1", 1)
    end

    test "default sequence is 0" do
      assert Idempotency.key(:create_charge, "cus_1", "op_1") ==
               Idempotency.key(:create_charge, "cus_1", "op_1", 0)
    end

    test "format is op_<64-hex>" do
      k = Idempotency.key(:create_subscription, "sub_123", "op_abc")
      assert k =~ ~r/^create_subscription_[0-9a-f]{64}$/
    end
  end

  describe "subject_uuid/2" do
    test "is deterministic" do
      u1 = Idempotency.subject_uuid(:create_subscription, "op_abc")
      u2 = Idempotency.subject_uuid(:create_subscription, "op_abc")
      assert u1 == u2
    end

    test "is Ecto.UUID-castable" do
      u = Idempotency.subject_uuid(:create_subscription, "op_abc")
      assert {:ok, _} = Ecto.UUID.cast(u)
    end

    test "differs for different operation_id" do
      refute Idempotency.subject_uuid(:create_subscription, "op_a") ==
               Idempotency.subject_uuid(:create_subscription, "op_b")
    end
  end
end
