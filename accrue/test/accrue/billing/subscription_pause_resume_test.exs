defmodule Accrue.Billing.SubscriptionPauseResumeTest do
  @moduledoc """
  Phase 4 Plan 03 (BILL-11) — `pause/2` with explicit `:pause_behavior`
  option persisting to the new `accrue_subscriptions.pause_behavior`
  scalar column alongside the existing `pause_collection` map.

  Exercises:

    * String-valued `:pause_behavior` option is validated against the
      three Stripe-supported values and persisted to the new column.
    * `paused_at` is stamped from the Fake clock at pause time.
    * Invalid `:pause_behavior` values are rejected at NimbleOptions
      validation time.
    * `comp_subscription/3` creates a subscription with the 100%-off
      coupon and skips the payment_method check (BILL-14, T-04-03-02).
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_pause_resume",
        email: "pause@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  describe "pause/2 with :pause_behavior option" do
    test "persists pause_behavior string + paused_at to subscription row", %{sub: sub} do
      assert {:ok, paused} =
               Billing.pause(sub, pause_behavior: "mark_uncollectible")

      assert paused.pause_behavior == "mark_uncollectible"
      assert %DateTime{} = paused.paused_at
    end

    test "supports all three Stripe-valid pause_behavior values", %{sub: sub} do
      for behavior <- ["mark_uncollectible", "keep_as_draft", "void"] do
        # Resubscribe for each iteration to reset state cleanly.
        {:ok, customer} =
          %Customer{}
          |> Customer.changeset(%{
            owner_type: "User",
            owner_id: Ecto.UUID.generate(),
            processor: "fake",
            processor_id: "cus_fake_pause_#{behavior}",
            email: "#{behavior}@example.com"
          })
          |> Repo.insert()

        {:ok, fresh_sub} = Billing.subscribe(customer, "price_basic")

        assert {:ok, paused} = Billing.pause(fresh_sub, pause_behavior: behavior)
        assert paused.pause_behavior == behavior
      end

      _ = sub
    end

    test "rejects pause_behavior values outside the allowlist", %{sub: sub} do
      assert_raise NimbleOptions.ValidationError, ~r/pause_behavior/, fn ->
        Billing.pause(sub, pause_behavior: "bogus_value")
      end
    end

    test "paused? returns true after pause", %{sub: sub} do
      {:ok, paused} = Billing.pause(sub, pause_behavior: "void")
      assert Subscription.paused?(paused)
      assert paused.pause_behavior == "void"
    end
  end

  describe "comp_subscription/3" do
    test "creates a subscription without requiring a payment method" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(%{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "fake",
          processor_id: "cus_fake_comp",
          email: "comp@example.com"
        })
        |> Repo.insert()

      assert {:ok, %Subscription{} = sub} =
               Billing.comp_subscription(customer, "price_comp")

      # Comp subscription still has a subscription_items row.
      sub = Repo.preload(sub, :subscription_items, force: true)
      assert [_ | _] = sub.subscription_items
    end

    test "records a subscription.comped event" do
      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(%{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "fake",
          processor_id: "cus_fake_comp_evt",
          email: "compevt@example.com"
        })
        |> Repo.insert()

      {:ok, sub} = Billing.comp_subscription(customer, "price_comp")

      rows =
        Repo.all(
          from(e in Accrue.Events.Event,
            where: e.subject_id == ^sub.id and e.type == "subscription.comped"
          )
        )

      assert length(rows) == 1
    end
  end
end
