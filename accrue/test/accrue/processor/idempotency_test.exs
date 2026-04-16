defmodule Accrue.Processor.IdempotencyTest do
  use ExUnit.Case, async: false

  alias Accrue.Processor.Fake
  alias Accrue.Processor.Stripe

  setup do
    case Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Fake.reset()

    # Clear any pdict state from previous tests
    Process.delete(:accrue_operation_id)
    Process.delete(:accrue_stripe_api_version)

    :ok
  end

  # ---------------------------------------------------------------------------
  # PROC-04: Deterministic idempotency keys
  # ---------------------------------------------------------------------------

  describe "compute_idempotency_key/3" do
    test "produces a deterministic 'accr_' prefixed key" do
      key = Stripe.compute_idempotency_key(:create_customer, "user_1", operation_id: "op_123")

      assert String.starts_with?(key, "accr_")
      # "accr_" (5) + 22 chars
      assert String.length(key) == 27
    end

    test "same inputs produce same key (deterministic)" do
      opts = [operation_id: "op_123"]
      key1 = Stripe.compute_idempotency_key(:create_customer, "user_1", opts)
      key2 = Stripe.compute_idempotency_key(:create_customer, "user_1", opts)

      assert key1 == key2
    end

    test "different inputs produce different keys" do
      opts = [operation_id: "op_123"]
      key1 = Stripe.compute_idempotency_key(:create_customer, "user_1", opts)
      key2 = Stripe.compute_idempotency_key(:create_customer, "user_2", opts)
      key3 = Stripe.compute_idempotency_key(:update_customer, "user_1", opts)
      key4 = Stripe.compute_idempotency_key(:create_customer, "user_1", operation_id: "op_456")

      assert key1 != key2
      assert key1 != key3
      assert key1 != key4
    end

    test "uses Actor.current_operation_id/0 as seed when set (D2-12)" do
      Accrue.Actor.put_operation_id("webhook_evt_123")

      key1 = Stripe.compute_idempotency_key(:create_customer, "user_1", [])

      # Same as explicit operation_id
      key2 =
        Stripe.compute_idempotency_key(:create_customer, "user_1",
          operation_id: "webhook_evt_123"
        )

      assert key1 == key2
    after
      Process.delete(:accrue_operation_id)
    end

    test "emits Logger.warning when no seed available (D2-12)" do
      # No operation_id in opts, no pdict value
      Process.delete(:accrue_operation_id)

      {result, log} =
        ExUnit.CaptureLog.with_log(fn ->
          Stripe.compute_idempotency_key(:create_customer, "user_1", [])
        end)

      assert String.starts_with?(result, "accr_")
      assert log =~ "no operation_id seed"
      assert log =~ "retries will NOT be idempotent"
    end
  end

  # ---------------------------------------------------------------------------
  # PROC-06: API version three-level precedence
  # ---------------------------------------------------------------------------

  describe "resolve_api_version/1" do
    test "opts[:api_version] overrides pdict overrides config default" do
      # Level 3: config default (always present)
      default = Stripe.resolve_api_version([])
      assert default == "2026-03-25.dahlia"

      # Level 2: pdict override
      Process.put(:accrue_stripe_api_version, "2025-01-01.test")
      pdict = Stripe.resolve_api_version([])
      assert pdict == "2025-01-01.test"

      # Level 1: explicit opts override
      explicit = Stripe.resolve_api_version(api_version: "2024-06-15.custom")
      assert explicit == "2024-06-15.custom"
    after
      Process.delete(:accrue_stripe_api_version)
    end
  end

  # ---------------------------------------------------------------------------
  # D2-15: with_api_version/2 helper
  # ---------------------------------------------------------------------------

  describe "Accrue.Stripe.with_api_version/2" do
    test "pushes/pops pdict correctly" do
      assert Process.get(:accrue_stripe_api_version) == nil

      result =
        Accrue.Stripe.with_api_version("2025-01-01.test", fn ->
          assert Process.get(:accrue_stripe_api_version) == "2025-01-01.test"
          :inner_result
        end)

      assert result == :inner_result
      assert Process.get(:accrue_stripe_api_version) == nil
    end

    test "restores previous pdict value on exit" do
      Process.put(:accrue_stripe_api_version, "original")

      Accrue.Stripe.with_api_version("override", fn ->
        assert Process.get(:accrue_stripe_api_version) == "override"
      end)

      assert Process.get(:accrue_stripe_api_version) == "original"
    after
      Process.delete(:accrue_stripe_api_version)
    end

    test "restores previous value even on exception" do
      Process.put(:accrue_stripe_api_version, "original")

      assert_raise RuntimeError, fn ->
        Accrue.Stripe.with_api_version("override", fn ->
          raise "boom"
        end)
      end

      assert Process.get(:accrue_stripe_api_version) == "original"
    after
      Process.delete(:accrue_stripe_api_version)
    end
  end

  # ---------------------------------------------------------------------------
  # Fake processor idempotency key tracking
  # ---------------------------------------------------------------------------

  describe "Fake processor idempotency tracking" do
    test "same idempotency key returns same result" do
      key = "accr_test_key_001"

      {:ok, customer1} =
        Accrue.Processor.create_customer(%{email: "a@b.com"}, idempotency_key: key)

      {:ok, customer2} =
        Accrue.Processor.create_customer(%{email: "c@d.com"}, idempotency_key: key)

      assert customer1.id == customer2.id
      # Second call should NOT have created a new customer
      assert customer1.email == customer2.email
    end

    test "different idempotency keys create different resources" do
      {:ok, customer1} =
        Accrue.Processor.create_customer(%{email: "a@b.com"}, idempotency_key: "key_1")

      {:ok, customer2} =
        Accrue.Processor.create_customer(%{email: "c@d.com"}, idempotency_key: "key_2")

      assert customer1.id != customer2.id
    end

    test "no idempotency key always creates new resource" do
      {:ok, customer1} = Accrue.Processor.create_customer(%{email: "a@b.com"}, [])
      {:ok, customer2} = Accrue.Processor.create_customer(%{email: "a@b.com"}, [])

      assert customer1.id != customer2.id
    end
  end
end
