defmodule Accrue.Billing.ResourceDispatchTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Processor.Fake
  alias Accrue.Rails.GatewayRegistry
  alias Accrue.Rails.GatewayRegistry.Error
  alias Accrue.Entitlements.Source.Outcome

  @inventory [
    {:swap_plan, 3, :swap_plan!, 3},
    {:cancel, 2, :cancel!, 2},
    {:cancel_at_period_end, 2, :cancel_at_period_end!, 2},
    {:resume, 2, :resume!, 2},
    {:pause, 2, :pause!, 2},
    {:unpause, 2, :unpause!, 2},
    {:update_quantity, 3, :update_quantity!, 3},
    {:preview_upcoming_invoice, 2, :preview_upcoming_invoice!, 2},
    {:add_item, 3, :add_item!, 3},
    {:remove_item, 2, :remove_item!, 2},
    {:update_item_quantity, 3, :update_item_quantity!, 3}
  ]

  @excluded_families [
    :subscribe,
    :customer,
    :schedule,
    :invoice,
    :charge,
    :refund,
    :payment_method,
    :coupon,
    :meter,
    :dunning
  ]

  setup do
    previous = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :processor, Fake)
    Fake.reset()

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :processor, previous),
        else: Application.delete_env(:accrue, :processor)
    end)
  end

  describe "persisted gateway provenance" do
    test "resolves only the adapter named by the persisted processor" do
      assert {:ok, Accrue.Processor.Fake} = GatewayRegistry.resolve("fake")
      assert {:ok, Accrue.Processor.Stripe} = GatewayRegistry.resolve(:stripe)
      assert {:ok, Accrue.Processor.Braintree} = GatewayRegistry.resolve("braintree")
    end

    test "returns a stable typed error for an unknown or unavailable processor" do
      assert {:error, %Error{code: :unknown_processor, next_action: :inspect_resource_provenance}} =
               GatewayRegistry.resolve("apple")

      assert {:error, %Error{code: :missing_processor, next_action: :inspect_resource_provenance}} =
               GatewayRegistry.resolve(nil)
    end
  end

  describe "persisted lifecycle dispatch inventory" do
    test "checked-in inventory names every lifecycle facade pair and explicit excluded families" do
      assert Enum.map(@inventory, &elem(&1, 0)) == [
               :swap_plan,
               :cancel,
               :cancel_at_period_end,
               :resume,
               :pause,
               :unpause,
               :update_quantity,
               :preview_upcoming_invoice,
               :add_item,
               :remove_item,
               :update_item_quantity
             ]

      assert @excluded_families == [
               :subscribe,
               :customer,
               :schedule,
               :invoice,
               :charge,
               :refund,
               :payment_method,
               :coupon,
               :meter,
               :dunning
             ]

      for {function, arity, bang, bang_arity} <- @inventory do
        assert function_exported?(Billing, function, arity)
        assert function_exported?(Billing, bang, bang_arity)
      end
    end

    test "every non-bang inventory action selects persisted Fake despite a different global processor" do
      for {action, _arity, _bang, _bang_arity} <- @inventory do
        fixture = fixture_for(action)
        Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
        assert_success(action, run(action, fixture, false))
        Application.put_env(:accrue, :processor, Fake)
      end
    end

    test "every bang facade delegates through its persisted-provenance non-bang path" do
      for {action, _arity, _bang, _bang_arity} <- @inventory do
        fixture = fixture_for(action)
        Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
        assert is_struct(run(action, fixture, true))
        Application.put_env(:accrue, :processor, Fake)
      end
    end

    test "every inventory facade emits exactly one lifecycle start/stop pair with bounded metadata" do
      for {action, _arity, _bang, _bang_arity} <- @inventory do
        fixture = fixture_for(action)
        handler = "resource-dispatch-#{action}-#{System.unique_integer([:positive])}"
        test_pid = self()

        :ok =
          :telemetry.attach_many(
            handler,
            [
              [:accrue, :billing, :lifecycle, action, :start],
              [:accrue, :billing, :lifecycle, action, :stop]
            ],
            fn event, _measurements, metadata, _ ->
              send(test_pid, {:lifecycle, action, event, metadata})
            end,
            nil
          )

        assert_success(action, run(action, fixture, false))

        assert_received {:lifecycle, ^action, [:accrue, :billing, :lifecycle, ^action, :start],
                         start_metadata}

        assert_received {:lifecycle, ^action, [:accrue, :billing, :lifecycle, ^action, :stop],
                         _stop_metadata}

        assert Map.keys(start_metadata) --
                 [
                   :action,
                   :resource_id,
                   :account_id,
                   :operation_id,
                   :actor_id,
                   :telemetry_span_context
                 ] == []

        refute Map.has_key?(start_metadata, :actor)
        refute inspect(start_metadata) =~ "seeded@example.test"
        :telemetry.detach(handler)
      end
    end

    test "unknown and missing persisted processors are typed before an adapter can run" do
      assert {:error, %Error{code: :missing_processor}} = GatewayRegistry.resolve(nil)
      assert {:error, %Error{code: :unknown_processor}} = GatewayRegistry.resolve("apple")

      assert {:error, %Error{code: :unknown_processor}} =
               GatewayRegistry.resolve("wrong-provider")
    end

    test "structural regions route every lifecycle action and item mutation through the registry" do
      actions = File.read!("lib/accrue/billing/subscription_actions.ex")
      items = File.read!("lib/accrue/billing/subscription_items.ex")

      for {action, _arity, _bang, _bang_arity} <- Enum.take(@inventory, 8) do
        assert actions =~ "def #{action}"
      end

      assert actions =~ "GatewayRegistry.resolve(processor)"
      assert items =~ "GatewayRegistry.resolve(processor)"
      refute items =~ "Processor.__impl__()"
      refute actions =~ "Processor.__impl__().cancel_subscription"
      refute actions =~ "Processor.__impl__().create_invoice_preview"
    end
  end

  describe "external management" do
    test "returns Apple-owned management guidance as a successful outcome" do
      assert {:ok,
              %Outcome{
                source: :apple,
                capability: :management,
                state: :externally_managed,
                guidance: %{
                  key: :manage_apple_subscription,
                  text: "Manage this subscription in Apple.",
                  action_label: "Manage subscription",
                  url: "https://apps.apple.com/account/subscriptions"
                }
              }} = Accrue.Billing.management(:apple)
    end

    test "management emits one bounded start/stop span pair" do
      test_pid = self()
      handler_id = "resource-dispatch-management-#{System.unique_integer([:positive])}"

      :ok =
        :telemetry.attach_many(
          handler_id,
          [[:accrue, :billing, :management, :start], [:accrue, :billing, :management, :stop]],
          fn event, _measurements, metadata, _config ->
            send(test_pid, {:management_span, event, metadata})
          end,
          nil
        )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %Outcome{state: :externally_managed}} = Accrue.Billing.management(:apple)
      assert_received {:management_span, [:accrue, :billing, :management, :start], start_metadata}
      assert_received {:management_span, [:accrue, :billing, :management, :stop], stop_metadata}

      assert Map.take(start_metadata, [:action, :rail]) == %{action: :management, rail: :apple}
      assert Map.take(stop_metadata, [:action, :rail]) == %{action: :management, rail: :apple}
      refute Map.has_key?(start_metadata, :provider_payload)
      refute Map.has_key?(start_metadata, :email)
    end

    test "existing-resource action regions use the persisted dispatch boundary" do
      source = File.read!("lib/accrue/billing/subscription_actions.ex")

      for action <- [
            "swap_plan",
            "preview_upcoming_invoice",
            "update_quantity",
            "cancel",
            "cancel_at_period_end",
            "resume",
            "pause",
            "unpause"
          ] do
        assert source =~ "def #{action}"
      end

      refute source =~ "Processor.__impl__().cancel_subscription"
      refute source =~ "Processor.__impl__().create_invoice_preview"
    end

    test "item mutations resolve the scoped parent instead of the global processor" do
      source = File.read!("lib/accrue/billing/subscription_items.ex")

      for operation <- [
            "subscription_item_create",
            "subscription_item_delete",
            "subscription_item_update"
          ] do
        assert source =~ "adapter.#{operation}"
      end

      assert source =~ "parent_subscription(item)"
      refute source =~ "Processor.__impl__()"
    end
  end

  defp fixture_for(:resume), do: Accrue.Test.Factory.canceling_subscription()

  defp fixture_for(:unpause) do
    %{subscription: sub} = Accrue.Test.Factory.active_subscription()
    {:ok, paused} = Billing.pause(sub)
    %{subscription: paused}
  end

  defp fixture_for(action) when action in [:remove_item, :update_item_quantity] do
    %{subscription: sub} = Accrue.Test.Factory.active_subscription()
    %{subscription: sub, item: hd(sub.subscription_items)}
  end

  defp fixture_for(_action), do: Accrue.Test.Factory.active_subscription()

  defp run(:swap_plan, %{subscription: sub}, false),
    do: Billing.swap_plan(sub, "price_pro", proration: :none)

  defp run(:swap_plan, %{subscription: sub}, true),
    do: Billing.swap_plan!(sub, "price_pro", proration: :none)

  defp run(:cancel, %{subscription: sub}, false), do: Billing.cancel(sub)
  defp run(:cancel, %{subscription: sub}, true), do: Billing.cancel!(sub)

  defp run(:cancel_at_period_end, %{subscription: sub}, false),
    do: Billing.cancel_at_period_end(sub)

  defp run(:cancel_at_period_end, %{subscription: sub}, true),
    do: Billing.cancel_at_period_end!(sub)

  defp run(:resume, %{subscription: sub}, false), do: Billing.resume(sub)
  defp run(:resume, %{subscription: sub}, true), do: Billing.resume!(sub)
  defp run(:pause, %{subscription: sub}, false), do: Billing.pause(sub)
  defp run(:pause, %{subscription: sub}, true), do: Billing.pause!(sub)
  defp run(:unpause, %{subscription: sub}, false), do: Billing.unpause(sub)
  defp run(:unpause, %{subscription: sub}, true), do: Billing.unpause!(sub)
  defp run(:update_quantity, %{subscription: sub}, false), do: Billing.update_quantity(sub, 2)
  defp run(:update_quantity, %{subscription: sub}, true), do: Billing.update_quantity!(sub, 2)

  defp run(:preview_upcoming_invoice, %{subscription: sub}, false),
    do: Billing.preview_upcoming_invoice(sub)

  defp run(:preview_upcoming_invoice, %{subscription: sub}, true),
    do: Billing.preview_upcoming_invoice!(sub)

  defp run(:add_item, %{subscription: sub}, false),
    do: Billing.add_item(sub, "price_addon", proration: :none)

  defp run(:add_item, %{subscription: sub}, true),
    do: Billing.add_item!(sub, "price_addon", proration: :none)

  defp run(:remove_item, %{item: item}, false), do: Billing.remove_item(item, proration: :none)
  defp run(:remove_item, %{item: item}, true), do: Billing.remove_item!(item, proration: :none)

  defp run(:update_item_quantity, %{item: item}, false),
    do: Billing.update_item_quantity(item, 2, proration: :none)

  defp run(:update_item_quantity, %{item: item}, true),
    do: Billing.update_item_quantity!(item, 2, proration: :none)

  defp assert_success(:preview_upcoming_invoice, {:ok, value}), do: assert(is_struct(value))
  defp assert_success(_action, {:ok, value}), do: assert(is_struct(value))
end
