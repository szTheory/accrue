defmodule Accrue.Billing.Properties.IdempotencyKeyTest do
  @moduledoc """
  Plan 03-08 Task 3: property tests for
  `Accrue.Processor.Idempotency.key/4` and `subject_uuid/2`. Locks in the
  "same inputs → same key" invariant under random input (D3-60, D3-64).
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Processor.Idempotency

  property "key/4 is deterministic for any (op, subject, operation_id)" do
    check all op <- atom(:alphanumeric),
              subject <- string(:alphanumeric, min_length: 1),
              op_id <- string(:alphanumeric, min_length: 1) do
      assert Idempotency.key(op, subject, op_id) == Idempotency.key(op, subject, op_id)
    end
  end

  property "different subject_id yields different keys" do
    check all op <- atom(:alphanumeric),
              a <- string(:alphanumeric, min_length: 1),
              b <- string(:alphanumeric, min_length: 1),
              a != b,
              op_id <- string(:alphanumeric, min_length: 1) do
      assert Idempotency.key(op, a, op_id) != Idempotency.key(op, b, op_id)
    end
  end

  property "different operation_id yields different keys" do
    check all op <- atom(:alphanumeric),
              subject <- string(:alphanumeric, min_length: 1),
              a <- string(:alphanumeric, min_length: 1),
              b <- string(:alphanumeric, min_length: 1),
              a != b do
      assert Idempotency.key(op, subject, a) != Idempotency.key(op, subject, b)
    end
  end

  property "sequence suffix changes the key" do
    check all op <- atom(:alphanumeric),
              subject <- string(:alphanumeric, min_length: 1),
              op_id <- string(:alphanumeric, min_length: 1),
              a <- integer(0..100),
              b <- integer(0..100),
              a != b do
      assert Idempotency.key(op, subject, op_id, a) !=
               Idempotency.key(op, subject, op_id, b)
    end
  end

  property "subject_uuid/2 is a valid Ecto.UUID" do
    check all op <- atom(:alphanumeric),
              op_id <- string(:alphanumeric, min_length: 1) do
      uuid = Idempotency.subject_uuid(op, op_id)
      assert {:ok, _} = Ecto.UUID.cast(uuid)
    end
  end

  property "subject_uuid/2 is deterministic" do
    check all op <- atom(:alphanumeric),
              op_id <- string(:alphanumeric, min_length: 1) do
      assert Idempotency.subject_uuid(op, op_id) ==
               Idempotency.subject_uuid(op, op_id)
    end
  end
end
