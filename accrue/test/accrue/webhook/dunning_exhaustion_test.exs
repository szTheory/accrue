defmodule Accrue.Webhook.DunningExhaustionTest do
  @moduledoc """
  Phase 4 Plan 04 — webhook-driven dunning exhaustion (BILL-15, D4-02).

  Verifies two pieces of the webhook hot path:

    1. `invoice.payment_failed` bumps the linked subscription's
       `past_due_since` from the Stripe invoice's `next_payment_attempt`,
       and does NOT clear it when Stripe stops retrying
       (`next_payment_attempt: nil`).

    2. `customer.subscription.updated` emits
       `[:accrue, :ops, :dunning_exhaustion]` with the correct `:source`
       discriminant (`:accrue_sweeper` vs `:stripe_native`) when Stripe
       echoes a terminal transition from `:past_due` to
       `:unpaid`/`:canceled`. Non-dunning transitions do NOT emit.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Subscription
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_dunning_wh",
        email: "dunning-wh@example.com"
      })
      |> Repo.insert()

    # Seed a local past_due subscription.
    sub_id = "sub_fake_" <> Integer.to_string(System.unique_integer([:positive]))

    {:ok, sub} =
      %Subscription{customer_id: customer.id, processor: "fake"}
      |> Subscription.force_status_changeset(%{
        processor_id: sub_id,
        status: :past_due
      })
      |> Repo.insert()

    %{customer: customer, sub: sub, sub_id: sub_id}
  end

  # --- Helpers -------------------------------------------------------

  defp stub_invoice_fetch(invoice_id, subscription_id, next_payment_attempt) do
    canonical = %{
      "id" => invoice_id,
      "object" => "invoice",
      "status" => "open",
      "customer" => "cus_fake_dunning_wh",
      "subscription" => subscription_id,
      "currency" => "usd",
      "amount_due" => 1000,
      "amount_paid" => 0,
      "amount_remaining" => 1000,
      "next_payment_attempt" => next_payment_attempt,
      "lines" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_invoice, fn _id, _opts -> {:ok, canonical} end)
    canonical
  end

  defp stub_subscription_fetch(sub_id, status) do
    canonical = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => "cus_fake_dunning_wh",
      "status" => Atom.to_string(status),
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "items" => %{"object" => "list", "data" => []},
      "metadata" => %{}
    }

    :ok = Fake.stub(:retrieve_subscription, fn _id, _opts -> {:ok, canonical} end)
    canonical
  end

  defp attach_telemetry(name) do
    test_pid = self()

    :ok =
      :telemetry.attach(
        name,
        [:accrue, :ops, :dunning_exhaustion],
        fn event, meas, meta, _ -> send(test_pid, {:telemetry, event, meas, meta}) end,
        nil
      )

    on_exit = fn -> :telemetry.detach(name) end
    ExUnit.Callbacks.on_exit(on_exit)
  end

  # --- invoice.payment_failed → past_due_since -----------------------

  describe "invoice.payment_failed past_due_since tracking" do
    test "writes past_due_since from next_payment_attempt on linked subscription",
         %{sub: sub, sub_id: sub_id} do
      # Stripe retries again in 2 days — future timestamp.
      next_attempt_unix =
        DateTime.utc_now() |> DateTime.add(2 * 86_400, :second) |> DateTime.to_unix()

      canonical =
        stub_invoice_fetch("in_fake_pf1", sub_id, next_attempt_unix)

      event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)

      assert {:ok, _} = DefaultHandler.handle(event)

      reloaded = Repo.reload!(sub)
      assert %DateTime{} = reloaded.past_due_since
      assert DateTime.to_unix(reloaded.past_due_since) == next_attempt_unix
    end

    test "does NOT clear past_due_since when next_payment_attempt is nil",
         %{sub: sub, sub_id: sub_id} do
      # Prior past_due_since already set by earlier retry.
      prior =
        DateTime.utc_now()
        |> DateTime.add(-3 * 86_400, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, sub} =
        sub
        |> Subscription.force_status_changeset(%{past_due_since: prior})
        |> Repo.update()

      canonical = stub_invoice_fetch("in_fake_pf2", sub_id, nil)
      event = StripeFixtures.webhook_event("invoice.payment_failed", canonical)

      assert {:ok, _} = DefaultHandler.handle(event)

      reloaded = Repo.reload!(sub)
      assert reloaded.past_due_since == sub.past_due_since
    end
  end

  # --- customer.subscription.updated → dunning_exhaustion telemetry --

  describe "dunning_exhaustion telemetry" do
    test "emits :accrue_sweeper source when sweep_attempted_at is within 5 minutes",
         %{sub: sub, sub_id: sub_id} do
      # Mark this row as recently-swept.
      recent =
        DateTime.utc_now()
        |> DateTime.add(-60, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, sub} =
        sub
        |> Subscription.force_status_changeset(%{dunning_sweep_attempted_at: recent})
        |> Repo.update()

      stub_subscription_fetch(sub_id, :unpaid)
      attach_telemetry("test-dunning-exhaustion-sweeper")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.updated",
          StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "unpaid"})
        )

      assert {:ok, %Subscription{status: :unpaid}} = DefaultHandler.handle(event)

      assert_received {:telemetry, [:accrue, :ops, :dunning_exhaustion], %{count: 1}, meta}
      assert meta.from_status == :past_due
      assert meta.to_status == :unpaid
      assert meta.source == :accrue_sweeper
      assert meta.subscription_id == sub.id
    end

    test "emits :stripe_native source when sweep_attempted_at is nil",
         %{sub: sub, sub_id: sub_id} do
      stub_subscription_fetch(sub_id, :canceled)
      attach_telemetry("test-dunning-exhaustion-native")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.updated",
          StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "canceled"})
        )

      assert {:ok, %Subscription{status: :canceled}} = DefaultHandler.handle(event)

      assert_received {:telemetry, [:accrue, :ops, :dunning_exhaustion], %{count: 1}, meta}
      assert meta.from_status == :past_due
      assert meta.to_status == :canceled
      assert meta.source == :stripe_native
      assert meta.subscription_id == sub.id
    end

    test "emits :stripe_native when sweep_attempted_at is older than 5 minutes",
         %{sub: sub, sub_id: sub_id} do
      old =
        DateTime.utc_now()
        |> DateTime.add(-600, :second)
        |> Map.put(:microsecond, {0, 6})

      {:ok, _sub} =
        sub
        |> Subscription.force_status_changeset(%{dunning_sweep_attempted_at: old})
        |> Repo.update()

      stub_subscription_fetch(sub_id, :unpaid)
      attach_telemetry("test-dunning-exhaustion-old-sweep")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.updated",
          StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "unpaid"})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_received {:telemetry, _, _, %{source: :stripe_native}}
    end

    test "does NOT emit on non-dunning transitions (:active → :canceled)",
         %{customer: customer} do
      # Fresh subscription starting at :active (not past_due).
      active_id = "sub_fake_" <> Integer.to_string(System.unique_integer([:positive]))

      {:ok, _sub} =
        %Subscription{customer_id: customer.id, processor: "fake"}
        |> Subscription.force_status_changeset(%{
          processor_id: active_id,
          status: :active
        })
        |> Repo.insert()

      stub_subscription_fetch(active_id, :canceled)
      attach_telemetry("test-dunning-exhaustion-nonmatch")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.updated",
          StripeFixtures.subscription_created(%{"id" => active_id, "status" => "canceled"})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      refute_received {:telemetry, _, _, _}
    end

    test "emits inside the same Repo.transact as the state write (idempotency)",
         %{sub: sub, sub_id: sub_id} do
      stub_subscription_fetch(sub_id, :unpaid)
      attach_telemetry("test-dunning-exhaustion-txn")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.updated",
          StripeFixtures.subscription_created(%{"id" => sub_id, "status" => "unpaid"})
        )

      assert {:ok, %Subscription{status: :unpaid}} = DefaultHandler.handle(event)
      assert_received {:telemetry, _, %{count: 1}, _}

      # State is committed.
      reloaded = Repo.reload!(sub)
      assert reloaded.status == :unpaid
    end
  end
end
