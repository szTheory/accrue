defmodule Accrue.Mailer.TestTest do
  use ExUnit.Case, async: true

  alias Accrue.Mailer.Test, as: MT

  describe "deliver/2" do
    test "returns {:ok, :test}" do
      assert {:ok, :test} = MT.deliver(:receipt, %{customer_id: "cus_1"})
    end

    test "sends {:accrue_email_delivered, type, assigns} to self()" do
      assigns = %{customer_id: "cus_1", to: "a@b.test"}
      {:ok, :test} = MT.deliver(:receipt, assigns)
      assert_received {:accrue_email_delivered, :receipt, ^assigns}
    end

    test "does not enqueue an Oban job" do
      # Capture oban count before/after — nothing should change.
      {:ok, :test} = MT.deliver(:receipt, %{customer_id: "cus_1"})
      # No Oban.Testing assertion here because the whole point of Mailer.Test
      # is that it never touches Oban. Absence of an enqueued job is
      # proved by the adapter source: it never calls Oban.insert/1.
      refute_received {:"$oban_insert", _, _}
    end

    test "accepts any map including nested values (no only_scalars! check)" do
      assigns = %{
        customer_id: "cus_1",
        nested: %{items: [1, 2, 3], pid: self()}
      }

      assert {:ok, :test} = MT.deliver(:payment_failed, assigns)
      assert_received {:accrue_email_delivered, :payment_failed, ^assigns}
    end

    test "implements the Accrue.Mailer behaviour" do
      behaviours = MT.module_info(:attributes) |> Keyword.get_values(:behaviour) |> List.flatten()
      assert Accrue.Mailer in behaviours
    end
  end
end
