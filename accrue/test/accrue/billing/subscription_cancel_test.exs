defmodule Accrue.Billing.SubscriptionCancelTest do
  @moduledoc """
  D3-26..30a: cancel/resume/pause/unpause matrix with strict state-machine
  guards.

  * `cancel/2` default → `{:ok, %Subscription{status: :canceled}}`
  * `cancel/2` `invoice_now: true` → intent_result tagged union
  * `cancel_at_period_end/2` preserves `:active`, flips
    `cancel_at_period_end`
  * `cancel_at_period_end/2` with `:at` future sets `cancel_at`
  * `resume/1` on canceling sub works; anywhere else raises InvalidState
  * `pause/2` stores `pause_collection`; `unpause/1` clears it
  * `resume/1` on paused raises with pointer to `unpause/1`
  * `unpause/1` on canceling raises with pointer to `resume/1`
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing

  defmodule BraintreeGatewayStub do
    def create(params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: "sub_bt_created",
         plan_id: params[:plan_id],
         payment_method_token: params[:payment_method_token],
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-01T00:00:00Z"
       )}
    end

    def update(id, params, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: id,
         plan_id: params[:plan_id] || "plan_basic",
         status: "Active",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-02T00:00:00Z"
       )}
    end

    def cancel(id, _opts) do
      {:ok,
       struct!(Braintree.Subscription,
         id: id,
         plan_id: "plan_basic",
         status: "Canceled",
         billing_period_start_date: "2024-01-01T00:00:00Z",
         billing_period_end_date: "2024-02-01T00:00:00Z",
         updated_at: "2024-01-03T00:00:00Z"
       )}
    end
  end

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_cancel",
        email: "cancel@example.com"
      })
      |> Repo.insert()

    {:ok, sub} = Billing.subscribe(customer, "price_basic")
    %{customer: customer, sub: sub}
  end

  describe "cancel/2" do
    test "default returns plain {:ok, %Subscription{}} and status :canceled", %{sub: sub} do
      assert {:ok, %Subscription{} = canceled} = Billing.cancel(sub)
      assert canceled.status == :canceled
      assert canceled.id == sub.id
    end

    test "emits subscription.canceled event with mode :immediate", %{sub: sub} do
      assert {:ok, _canceled} = Billing.cancel(sub)

      row =
        Repo.one!(
          from(e in Accrue.Events.Event,
            where: e.type == "subscription.canceled" and e.subject_id == ^sub.id,
            select: e
          )
        )

      assert row.data["mode"] == "immediate" or row.data[:mode] == "immediate"
    end
  end

  describe "cancel_at_period_end/2" do
    test "sets cancel_at_period_end=true; status stays :active; canceling? returns true",
         %{sub: sub} do
      assert {:ok, updated} = Billing.cancel_at_period_end(sub)
      assert updated.cancel_at_period_end == true
      assert updated.status == :active
      assert Subscription.canceling?(updated)
    end

    test "with :at future date sets cancel_at", %{sub: sub} do
      at = DateTime.add(Accrue.Clock.utc_now(), 14 * 86_400, :second)
      assert {:ok, updated} = Billing.cancel_at_period_end(sub, at: at)
      assert %DateTime{} = updated.cancel_at
    end

    test "on braintree it rejects scheduled-end cancellation instead of falling back to immediate" do
      previous_processor = Application.get_env(:accrue, :processor)
      previous_gateway = Application.get_env(:accrue, :braintree_subscription_gateway)

      on_exit(fn ->
        if previous_processor do
          Application.put_env(:accrue, :processor, previous_processor)
        else
          Application.delete_env(:accrue, :processor)
        end

        if previous_gateway do
          Application.put_env(:accrue, :braintree_subscription_gateway, previous_gateway)
        else
          Application.delete_env(:accrue, :braintree_subscription_gateway)
        end
      end)

      Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
      Application.put_env(:accrue, :braintree_subscription_gateway, BraintreeGatewayStub)

      {:ok, customer} =
        %Customer{}
        |> Customer.changeset(%{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "braintree",
          processor_id: "cus_braintree_cancel_#{System.unique_integer([:positive])}",
          email: "bt-cancel-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      assert {:ok, subscription} =
               Billing.subscribe(
                 customer,
                 "plan_basic",
                 payment_method: %{vault_acquisition: %{reference: "pm_token_123"}}
               )

      assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
               Billing.cancel_at_period_end(subscription)

      assert error.message =~ "cancel at period end"
      assert error.message =~ "Accrue.Billing.cancel/2"
      assert error.message =~ "host-owned seam"

      reloaded =
        Repo.preload(Repo.get!(Subscription, subscription.id), :subscription_items, force: true)

      assert reloaded.status == :active
      refute reloaded.cancel_at_period_end
      refute Subscription.canceling?(reloaded)
    end
  end

  describe "resume/1" do
    test "on canceling sub unsets cancel_at_period_end", %{sub: sub} do
      {:ok, canceling} = Billing.cancel_at_period_end(sub)
      assert Subscription.canceling?(canceling)

      assert {:ok, resumed} = Billing.resume(canceling)
      refute resumed.cancel_at_period_end
    end

    test "on non-canceling sub raises InvalidState", %{sub: sub} do
      assert_raise Accrue.Error.InvalidState, ~r/canceling/, fn ->
        Billing.resume(sub)
      end
    end

    test "on paused sub raises InvalidState pointing at unpause/1", %{sub: sub} do
      {:ok, paused} = Billing.pause(sub)

      assert_raise Accrue.Error.InvalidState, ~r/unpause/, fn ->
        Billing.resume(paused)
      end
    end

    test "on braintree returns an actionable next step for reversal attempts", %{sub: sub} do
      previous_processor = Application.get_env(:accrue, :processor)

      on_exit(fn ->
        if previous_processor do
          Application.put_env(:accrue, :processor, previous_processor)
        else
          Application.delete_env(:accrue, :processor)
        end
      end)

      Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)

      canceling = %{
        sub
        | processor: "braintree",
          cancel_at_period_end: true,
          current_period_end: DateTime.add(Accrue.Clock.utc_now(), 3600, :second)
      }

      assert {:error, %Accrue.APIError{code: "processor_operation_unsupported"} = error} =
               Billing.resume(canceling)

      assert error.message =~ "resume/2"
      assert error.message =~ "Create a new subscription"
    end
  end

  describe "pause/2" do
    test "behavior :void stores pause_collection map", %{sub: sub} do
      assert {:ok, paused} = Billing.pause(sub, behavior: :void)
      assert is_map(paused.pause_collection)
      assert Subscription.paused?(paused)
    end
  end

  describe "unpause/1" do
    test "on paused sub clears pause_collection", %{sub: sub} do
      {:ok, paused} = Billing.pause(sub)
      assert {:ok, unpaused} = Billing.unpause(paused)
      refute Subscription.paused?(unpaused)
      assert is_nil(unpaused.pause_collection)
    end

    test "on canceling (non-paused) sub raises InvalidState pointing at resume/1",
         %{sub: sub} do
      {:ok, canceling} = Billing.cancel_at_period_end(sub)

      assert_raise Accrue.Error.InvalidState, ~r/resume/, fn ->
        Billing.unpause(canceling)
      end
    end
  end

  describe "update_quantity multi-item guard" do
    test "raises MultiItemSubscription on multi-item subs", %{customer: customer} do
      # Seed a subscription then manually insert a second item to exercise the guard.
      {:ok, sub} =
        Billing.subscribe(customer, "price_basic", operation_id: "multi-item-guard-subscription")

      {:ok, _extra} =
        %SubscriptionItem{}
        |> SubscriptionItem.changeset(%{
          subscription_id: sub.id,
          processor: "fake",
          processor_id: "si_fake_extra",
          price_id: "price_extra",
          quantity: 1
        })
        |> Repo.insert()

      reloaded = Repo.preload(sub, :subscription_items, force: true)

      assert_raise Accrue.Error.MultiItemSubscription, fn ->
        Billing.update_quantity(reloaded, 7)
      end
    end
  end
end
