defmodule Accrue.Oban.MiddlewareTest do
  use ExUnit.Case, async: true

  alias Accrue.Oban.Middleware

  setup do
    Process.delete(:accrue_connected_account_id)
    on_exit(fn -> Process.delete(:accrue_connected_account_id) end)
    :ok
  end

  describe "put/1 — operation_id stamping (D3-63)" do
    test "stamps Accrue.Actor operation_id with oban-<id>-<attempt> format" do
      assert :ok = Middleware.put(%{id: 123, attempt: 2})
      assert Accrue.Actor.current_operation_id() == "oban-123-2"
    end

    test "accepts a full %Oban.Job{} by duck-typing on :id and :attempt keys" do
      job = %{id: 456, attempt: 1, args: %{}}
      assert :ok = Middleware.put(job)
      assert Accrue.Actor.current_operation_id() == "oban-456-1"
    end
  end

  describe "put/1 — Connect account pdict propagation (D5-01)" do
    test "restores :accrue_connected_account_id from job args[\"stripe_account\"]" do
      job = %{id: 1, attempt: 1, args: %{"stripe_account" => "acct_connect_123"}}
      assert :ok = Middleware.put(job)
      assert Process.get(:accrue_connected_account_id) == "acct_connect_123"
    end

    test "does not touch pdict when args lacks :stripe_account" do
      Process.put(:accrue_connected_account_id, "acct_prior")

      job = %{id: 2, attempt: 1, args: %{}}
      assert :ok = Middleware.put(job)

      assert Process.get(:accrue_connected_account_id) == "acct_prior"
    end

    test "does not touch pdict when args is absent (legacy 2-key map)" do
      Process.put(:accrue_connected_account_id, "acct_prior")

      assert :ok = Middleware.put(%{id: 3, attempt: 1})
      assert Process.get(:accrue_connected_account_id) == "acct_prior"
    end

    test "empty string stripe_account is ignored (fail-safe — never set pdict to \"\")" do
      job = %{id: 4, attempt: 1, args: %{"stripe_account" => ""}}
      assert :ok = Middleware.put(job)
      assert Process.get(:accrue_connected_account_id) == nil
    end

    test "downstream Processor.Stripe.resolve_stripe_account/1 picks up the pdict value" do
      job = %{id: 5, attempt: 1, args: %{"stripe_account" => "acct_downstream"}}
      :ok = Middleware.put(job)

      assert Accrue.Processor.Stripe.resolve_stripe_account([]) == "acct_downstream"
    end
  end
end
