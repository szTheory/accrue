defmodule Accrue.Test.MailerAssertionsTest do
  use ExUnit.Case, async: true

  use Accrue.Test.MailerAssertions

  describe "assert_email_sent/3" do
    test "passes when matching message received" do
      send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})
      assigns = assert_email_sent(:receipt)
      assert assigns == %{customer_id: "cus_1"}
    end

    test "flunks when no message within default timeout" do
      assert_raise ExUnit.AssertionError,
                   ~r/no email of type :receipt delivered within 100ms/,
                   fn ->
                     assert_email_sent(:receipt)
                   end
    end

    test "matches :to on atom key" do
      send(self(), {:accrue_email_delivered, :receipt, %{to: "a@b"}})
      assert_email_sent(:receipt, to: "a@b")
    end

    test "matches :to on string key" do
      send(self(), {:accrue_email_delivered, :receipt, %{"to" => "a@b"}})
      assert_email_sent(:receipt, to: "a@b")
    end

    test "matches :customer_id" do
      send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})
      assert_email_sent(:receipt, customer_id: "cus_1")
    end

    test "subset-matches :assigns via Map.take" do
      send(self(), {:accrue_email_delivered, :receipt, %{foo: 1, bar: 2, baz: 3}})
      assert_email_sent(:receipt, assigns: %{foo: 1, bar: 2})
    end

    test ":matches runs 1-arity predicate" do
      send(self(), {:accrue_email_delivered, :receipt, %{count: 10}})
      assert_email_sent(:receipt, matches: fn a -> a[:count] > 5 end)
    end

    test "flunks when message present but opts do not match" do
      send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})

      assert_raise ExUnit.AssertionError, ~r/did not match/, fn ->
        assert_email_sent(:receipt, customer_id: "cus_2")
      end
    end

    test "explicit timeout override accepted" do
      assert_raise ExUnit.AssertionError, ~r/within 500ms/, fn ->
        assert_email_sent(:receipt, [], 500)
      end
    end
  end

  describe "refute_email_sent/3" do
    test "passes when no message received within timeout" do
      refute_email_sent(:receipt)
    end

    test "passes when a non-matching message is received" do
      send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})
      refute_email_sent(:receipt, customer_id: "cus_2")
    end

    test "flunks when a matching message is received" do
      send(self(), {:accrue_email_delivered, :receipt, %{customer_id: "cus_1"}})

      assert_raise ExUnit.AssertionError, ~r/unexpected email of type :receipt/, fn ->
        refute_email_sent(:receipt, customer_id: "cus_1")
      end
    end
  end

  describe "assert_no_emails_sent/0" do
    test "passes when inbox has no email messages" do
      assert assert_no_emails_sent() == :ok
    end

    test "flunks when any :accrue_email_delivered present" do
      send(self(), {:accrue_email_delivered, :receipt, %{}})

      assert_raise ExUnit.AssertionError, ~r/unexpected email delivered/, fn ->
        assert_no_emails_sent()
      end
    end
  end

  describe "assert_emails_sent/1" do
    test "passes when exact count matches" do
      send(self(), {:accrue_email_delivered, :receipt, %{}})
      send(self(), {:accrue_email_delivered, :receipt, %{}})
      send(self(), {:accrue_email_delivered, :receipt, %{}})
      assert_emails_sent(3)
    end

    test "passes when zero expected and none received" do
      assert_emails_sent(0)
    end

    test "flunks when expected count mismatched (too few)" do
      send(self(), {:accrue_email_delivered, :receipt, %{}})

      assert_raise ExUnit.AssertionError, ~r/expected 3 emails delivered, got 1/, fn ->
        assert_emails_sent(3)
      end
    end

    test "flunks when expected count mismatched (too many)" do
      for _ <- 1..5 do
        send(self(), {:accrue_email_delivered, :receipt, %{}})
      end

      assert_raise ExUnit.AssertionError, ~r/expected 3 emails delivered, got (4|5)/, fn ->
        assert_emails_sent(3)
      end
    end
  end
end
