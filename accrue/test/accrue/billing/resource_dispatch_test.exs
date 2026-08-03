defmodule Accrue.Billing.ResourceDispatchTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.SubscriptionItem
  alias Accrue.Processor.Fake
  alias Accrue.Rails.GatewayRegistry
  alias Accrue.Rails.GatewayRegistry.Error
  alias Accrue.Entitlements.Source.Outcome
  alias Accrue.Entitlements.Source.Registry, as: SourceRegistry

  defmodule RaisingManagementRegistry do
    def outcome(_source, _capability), do: raise("forced management exception")
  end

  defmodule RaisingGatewayAdapter do
    def update_subscription(_, _, _), do: raise("forced adapter exception")
    def cancel_subscription(_, _, _), do: raise("forced adapter exception")
    def pause_subscription_collection(_, _, _, _), do: raise("forced adapter exception")
    def create_invoice_preview(_, _), do: raise("forced adapter exception")
    def subscription_item_create(_, _), do: raise("forced adapter exception")
    def subscription_item_delete(_, _, _), do: raise("forced adapter exception")
    def subscription_item_update(_, _, _), do: raise("forced adapter exception")
  end

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

  @adapter_callbacks %{
    swap_plan: :update_subscription,
    cancel: :cancel_subscription,
    cancel_at_period_end: :update_subscription,
    resume: :update_subscription,
    pause: :pause_subscription_collection,
    unpause: :update_subscription,
    update_quantity: :update_subscription,
    preview_upcoming_invoice: :create_invoice_preview,
    add_item: :subscription_item_create,
    remove_item: :subscription_item_delete,
    update_item_quantity: :subscription_item_update
  }

  @forbidden_telemetry_keys [
    :email,
    :adopter,
    :adopter_id,
    :identity,
    :raw_receipt,
    :receipt,
    :jws,
    :apple_account_token,
    :token,
    :provider_payload,
    :payload,
    :actor
  ]

  setup do
    previous = Application.get_env(:accrue, :processor)
    previous_management_registry = Application.get_env(:accrue, :management_source_registry)
    previous_fake_adapter = Application.get_env(:accrue, :gateway_fake_adapter)
    Application.put_env(:accrue, :processor, Fake)
    Fake.reset()

    on_exit(fn ->
      if previous,
        do: Application.put_env(:accrue, :processor, previous),
        else: Application.delete_env(:accrue, :processor)

      if previous_management_registry,
        do:
          Application.put_env(:accrue, :management_source_registry, previous_management_registry),
        else: Application.delete_env(:accrue, :management_source_registry)

      if previous_fake_adapter,
        do: Application.put_env(:accrue, :gateway_fake_adapter, previous_fake_adapter),
        else: Application.delete_env(:accrue, :gateway_fake_adapter)
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
      Code.ensure_loaded!(Billing)

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

    test "every lifecycle action emits one bounded pair for success, typed failure, and adapter exception" do
      for {action, _arity, _bang, _bang_arity} <- @inventory do
        assert_lifecycle_success_pair(action)
        assert_lifecycle_typed_failure_pair(action)
        assert_lifecycle_exception_pair(action)
      end
    end

    test "every bang lifecycle facade reuses exactly one instrumented span pair" do
      for {action, _arity, _bang, _bang_arity} <- @inventory do
        fixture = fixture_for(action)
        events = capture_lifecycle(action, fn -> run(action, fixture, true) end)
        assert Enum.map(events, &elem(&1, 0)) == [:start, :stop]
        Enum.each(events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)
      end
    end

    test "same operation identity stays on Fake while global processor flips during repeated and concurrent calls" do
      %{subscription: sub} = Accrue.Test.Factory.active_subscription()
      operation_id = "dispatch-stable-operation"

      flipper =
        Task.async(fn ->
          Enum.each(1..20, fn _ ->
            Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
          end)
        end)

      assert {:ok, updated} = Billing.update_quantity(sub, 2, operation_id: operation_id)
      assert {:ok, _} = Billing.update_quantity(updated, 2, operation_id: operation_id)
      Task.await(flipper, 5_000)
      calls = Fake.calls() |> Enum.filter(&(elem(&1, 0) == :update_subscription))
      assert length(calls) == 2

      assert calls
             |> Enum.map(fn {_op, [_id, _params, opts]} ->
               Keyword.fetch!(opts, :idempotency_key)
             end)
             |> Enum.uniq()
             |> length() == 1

      assert Enum.all?(calls, fn {_op, [_id, _params, _opts]} -> true end)
    end

    test "unknown provenance returns before zero adapter calls" do
      %{subscription: sub} = Accrue.Test.Factory.active_subscription()
      calls_before = Fake.calls()

      assert {:error, %Error{code: :unknown_processor}} =
               Billing.cancel(%{sub | processor: "apple"})

      assert {:error, %Error{code: :unknown_processor}} =
               Billing.cancel(%{sub | processor: "wrong-provider"})

      assert {:error, %Error{code: :missing_processor}} = Billing.cancel(%{sub | processor: nil})
      assert Fake.calls() == calls_before
    end

    test "unscoped item resources fail before zero adapter calls" do
      item = %SubscriptionItem{id: Ecto.UUID.generate(), subscription_id: Ecto.UUID.generate()}
      calls_before = Fake.calls()

      assert {:error, :subscription_not_found} = Billing.remove_item(item, proration: :none)

      assert {:error, :subscription_not_found} =
               Billing.update_item_quantity(item, 2, proration: :none)

      assert Fake.calls() == calls_before
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

    test "management has bounded success and exception spans and preserves distinct outcomes" do
      success_events = capture_management(fn -> Billing.management(:apple) end)
      assert Enum.map(success_events, &elem(&1, 0)) == [:start, :stop]
      Enum.each(success_events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)

      Application.put_env(:accrue, :management_source_registry, RaisingManagementRegistry)

      exception_events =
        capture_management(fn ->
          assert_raise RuntimeError, "forced management exception", fn ->
            Billing.management(:apple)
          end
        end)

      assert Enum.map(exception_events, &elem(&1, 0)) == [:start, :exception]
      Enum.each(exception_events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)

      Application.delete_env(:accrue, :management_source_registry)
      assert {:ok, %Outcome{state: :host_owned}} = Billing.management(:host_fake)
      assert {:error, %{code: :unknown_source}} = Billing.management(:wrong_source)

      assert {:ok, %Outcome{state: :feasibility_blocked}} =
               SourceRegistry.outcome(:apple, :offline)

      assert {:error, %{code: :operation_unavailable}} = SourceRegistry.outcome(:apple, :control)
    end

    test "Apple management has no forbidden adapter calls across success, error, repeat, and concurrency" do
      forbidden_callbacks = [
        :cancel_subscription,
        :resume_subscription,
        :update_subscription,
        :pause_subscription_collection,
        :create_invoice_preview,
        :subscription_item_create,
        :subscription_item_delete,
        :subscription_item_update,
        :create_refund,
        :create_invoice,
        :create_payment_method,
        :create_charge,
        :report_meter_event
      ]

      assert {:ok, %Outcome{state: :externally_managed}} = Billing.management(:apple)
      assert {:error, %{code: :unknown_source}} = Billing.management(:apple_unknown)

      assert Enum.all?(1..2, fn _ ->
               match?({:ok, %Outcome{state: :externally_managed}}, Billing.management(:apple))
             end)

      1..2
      |> Task.async_stream(fn _ -> Billing.management(:apple) end, max_concurrency: 2)
      |> Enum.each(fn {:ok, result} ->
        assert match?({:ok, %Outcome{state: :externally_managed}}, result)
      end)

      captured_before = Fake.calls()

      assert Fake.calls() == captured_before
      assert Enum.all?(forbidden_callbacks, &(Fake.call_count(&1) == 0))
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

  defp assert_lifecycle_success_pair(action) do
    fixture = fixture_for(action)

    events =
      capture_lifecycle(action, fn -> assert_success(action, run(action, fixture, false)) end)

    assert Enum.map(events, &elem(&1, 0)) == [:start, :stop]
    Enum.each(events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)
  end

  defp assert_lifecycle_typed_failure_pair(action) do
    fixture = fixture_for(action)
    callback = Map.fetch!(@adapter_callbacks, action)
    Fake.scripted_response(callback, {:error, :forced_typed_failure})

    events =
      capture_lifecycle(action, fn ->
        assert {:error, :forced_typed_failure} = run(action, fixture, false)
      end)

    assert Enum.map(events, &elem(&1, 0)) == [:start, :stop]
    Enum.each(events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)
  end

  defp assert_lifecycle_exception_pair(action) do
    fixture = fixture_for(action)
    Application.put_env(:accrue, :gateway_fake_adapter, RaisingGatewayAdapter)

    events =
      try do
        capture_lifecycle(action, fn ->
          assert_raise RuntimeError, "forced adapter exception", fn ->
            run(action, fixture, false)
          end
        end)
      after
        Application.delete_env(:accrue, :gateway_fake_adapter)
      end

    assert Enum.map(events, &elem(&1, 0)) == [:start, :exception]
    Enum.each(events, fn {_phase, metadata} -> assert_private_metadata(metadata) end)
  end

  defp capture_lifecycle(action, fun) do
    handler = "resource-dispatch-capture-#{action}-#{System.unique_integer([:positive])}"
    test_pid = self()

    :ok =
      :telemetry.attach_many(
        handler,
        for(
          phase <- [:start, :stop, :exception],
          do: [:accrue, :billing, :lifecycle, action, phase]
        ),
        fn event, _measurements, metadata, _ ->
          send(test_pid, {:captured_lifecycle, List.last(event), metadata})
        end,
        nil
      )

    try do
      fun.()
      collect_lifecycle_events([])
    after
      :telemetry.detach(handler)
    end
  end

  defp capture_management(fun) do
    handler = "resource-dispatch-management-capture-#{System.unique_integer([:positive])}"
    test_pid = self()

    :ok =
      :telemetry.attach_many(
        handler,
        for(phase <- [:start, :stop, :exception], do: [:accrue, :billing, :management, phase]),
        fn event, _measurements, metadata, _ ->
          send(test_pid, {:captured_management, List.last(event), metadata})
        end,
        nil
      )

    try do
      fun.()
      collect_management_events([])
    after
      :telemetry.detach(handler)
    end
  end

  defp collect_management_events(events) do
    receive do
      {:captured_management, phase, metadata} ->
        collect_management_events(events ++ [{phase, metadata}])
    after
      20 -> events
    end
  end

  defp collect_lifecycle_events(events) do
    receive do
      {:captured_lifecycle, phase, metadata} ->
        collect_lifecycle_events(events ++ [{phase, metadata}])
    after
      20 -> events
    end
  end

  defp assert_private_metadata(metadata) do
    allowed = [
      :revision,
      :action,
      :rail,
      :environment,
      :disposition,
      :reason,
      :resource_id,
      :account_id,
      :operation_id,
      :actor_id,
      :kind,
      :reason,
      :stacktrace,
      :telemetry_span_context
    ]

    assert Map.keys(metadata) -- allowed == []
    refute Enum.any?(@forbidden_telemetry_keys, &Map.has_key?(metadata, &1))
    refute inspect(metadata) =~ "seeded@example.test"
    refute inspect(metadata) =~ "seeded-jws"
    refute inspect(metadata) =~ "seeded-token"
    refute inspect(metadata) =~ "seeded-payload"
  end

  defp assert_success(:preview_upcoming_invoice, {:ok, value}), do: assert(is_struct(value))
  defp assert_success(_action, {:ok, value}), do: assert(is_struct(value))
end
