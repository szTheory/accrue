defmodule Accrue.Entitlements.PurchaseDecisionTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.{Account, PurchaseDecision, Snapshot}

  defmodule Billable do
    use Ecto.Schema
    use Accrue.Billable, billable_type: "PurchaseDecisionUser"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "purchase_decision_users" do
    end
  end

  @now ~U[2026-08-02 12:00:00.000000Z]

  test "blocks a different rail that already supplies the requested logical plan" do
    snapshot = snapshot([source(:apple)], 7)

    assert %PurchaseDecision{
             status: :block,
             reason: :equivalent_other_rail,
             target_rail: :stripe,
             logical_plan: :pro,
             revision: 7,
             sources: [%{rail: :apple}]
           } = PurchaseDecision.evaluate(snapshot, :stripe, "price_pro", catalog: catalog())
  end

  test "returns eligible when no live different-rail equivalent exists" do
    assert %PurchaseDecision{status: :eligible, reason: :no_equivalent_grant} =
             PurchaseDecision.evaluate(snapshot([], 2), :stripe, "price_pro", catalog: catalog())
  end

  test "does not infer equivalence from same-rail sources" do
    assert %PurchaseDecision{status: :eligible} =
             PurchaseDecision.evaluate(snapshot([source(:stripe)], 2), :stripe, "price_pro",
               catalog: catalog()
             )
  end

  test "does not over-block another plan on the same source rail" do
    snapshot = snapshot([source(:apple, :starter), source(:apple, :team)], 2)

    assert %PurchaseDecision{status: :eligible, sources: []} =
             PurchaseDecision.evaluate(snapshot, :stripe, "price_pro", catalog: catalog())
  end

  test "fails closed for missing, stale, repairing, and ambiguous snapshot states" do
    for {snapshot, reason} <- [
          {nil, :missing_snapshot},
          {Map.put(snapshot([], 1), :authorization_bounds, :stale), :stale_snapshot},
          {Map.put(snapshot([], 1), :authorization_bounds, :repairing), :repairing_snapshot},
          {Map.put(snapshot([], 1), :authorization_bounds, :ambiguous), :ambiguous_snapshot}
        ] do
      assert %PurchaseDecision{status: :block, reason: ^reason} =
               PurchaseDecision.evaluate(snapshot, :stripe, "price_pro", catalog: catalog())
    end
  end

  test "renders the bounded Apple warning copy without provider internals" do
    decision =
      PurchaseDecision.evaluate(snapshot([source(:apple)], 3), :stripe, "price_pro",
        catalog: catalog()
      )

    assert %PurchaseDecision{
             guidance:
               "This account already has Pro through Apple. Continuing creates another subscription."
           } =
             PurchaseDecision.override(
               decision,
               "because support approved",
               "operator@example.test",
               snapshot: snapshot([source(:apple)], 3),
               product_id: "price_pro",
               catalog: catalog()
             )
  end

  test "public facade emits bounded spans and hashes actor identity" do
    handler = {__MODULE__, make_ref()}
    parent = self()

    :ok =
      :telemetry.attach_many(
        handler,
        [
          [:accrue, :entitlements, :purchase_decision, :start],
          [:accrue, :entitlements, :purchase_decision, :stop]
        ],
        fn event, _measurements, metadata, _ ->
          send(parent, {:purchase_span, event, metadata})
        end,
        nil
      )

    try do
      decision =
        Accrue.Entitlements.purchase_decision("opaque-account-id", :stripe, "price_pro",
          snapshot: snapshot([source(:apple)], 4),
          catalog: catalog(),
          actor_id: "operator@example.test"
        )

      assert decision.status == :block
      assert_receive {:purchase_span, _event, metadata}

      assert Map.keys(metadata) --
               [
                 :revision,
                 :action,
                 :rail,
                 :environment,
                 :disposition,
                 :reason,
                 :account_id,
                 :actor_id,
                 :telemetry_span_context
               ] == []

      refute inspect(metadata) =~ "operator@example.test"
    after
      :telemetry.detach(handler)
    end
  end

  test "override telemetry and audit recursively exclude seeded private values" do
    snapshot = snapshot([source(:apple)], 4)
    decision = PurchaseDecision.evaluate(snapshot, :stripe, "price_pro", catalog: catalog())
    parent = self()
    handler = {__MODULE__, make_ref()}

    :ok =
      :telemetry.attach(
        handler,
        [:accrue, :entitlements, :override_purchase_decision, :stop],
        fn _event, _measurements, metadata, _ -> send(parent, {:override_span, metadata}) end,
        nil
      )

    seeds = [
      "operator@seeded.example",
      "adopter-identity-seeded",
      "raw-receipt-seeded",
      "jws-seeded",
      "apple-token-seeded",
      "provider-payload-seeded"
    ]

    try do
      assert %PurchaseDecision{status: :warn} =
               Accrue.Entitlements.override_purchase_decision(
                 decision,
                 "support-approved",
                 hd(seeds),
                 snapshot: snapshot,
                 product_id: "price_pro",
                 catalog: catalog(),
                 audit: fn audit -> send(parent, {:override_audit, audit}) end,
                 email: hd(seeds),
                 adopter_id: Enum.at(seeds, 1),
                 raw_receipt: Enum.at(seeds, 2),
                 jws: Enum.at(seeds, 3),
                 apple_account_token: Enum.at(seeds, 4),
                 provider_payload: Enum.at(seeds, 5)
               )

      assert_receive {:override_span, metadata}
      assert_receive {:override_audit, audit}

      for forbidden <- [
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
            :payload
          ] do
        refute contains_key?(metadata, forbidden)
        refute contains_key?(audit, forbidden)
      end

      for seed <- seeds do
        refute inspect(metadata) =~ seed
        refute inspect(audit) =~ seed
      end
    after
      :telemetry.detach(handler)
    end
  end

  test "continuation refuses a changed blocking state before any provider command" do
    stale = PurchaseDecision.evaluate(snapshot([], 1), :stripe, "price_pro", catalog: catalog())

    assert {:error, :purchase_blocked} =
             PurchaseDecision.continue(stale, :not_a_billable, "price_pro",
               snapshot: snapshot([source(:apple)], 2),
               product_id: "price_pro",
               operation_id: "purchase-operation-1",
               catalog: catalog()
             )
  end

  test "an ambiguous Stripe continuation returns an operation-bound reconcile result" do
    decision =
      PurchaseDecision.evaluate(snapshot([], 1), :stripe, "price_pro", catalog: catalog())

    assert {:error, %{reason: :reconcile_required, operation_id: "purchase-operation-2"}} =
             PurchaseDecision.continue(decision, :not_a_billable, "price_pro",
               snapshot: snapshot([], 1),
               product_id: "price_pro",
               operation_id: "purchase-operation-2",
               catalog: catalog(),
               subscribe: fn _billable, _price, _opts -> {:error, :ambiguous} end
             )
  end

  test "Apple continuation is an externally-managed no-mutation outcome" do
    decision =
      PurchaseDecision.evaluate(snapshot([], 1), :apple, "product_pro", catalog: catalog())

    assert {:error, %{reason: :externally_managed, operation_id: "apple-operation-1"}} =
             PurchaseDecision.continue(decision, :not_a_billable, "product_pro",
               snapshot: snapshot([], 1),
               product_id: "product_pro",
               operation_id: "apple-operation-1",
               catalog: catalog()
             )
  end

  test "authenticated first purchase provisions exactly once then reads its empty snapshot" do
    billable = %Billable{id: Ecto.UUID.generate()}

    assert %PurchaseDecision{status: :eligible, revision: 0} =
             Accrue.Entitlements.purchase_decision(billable, :stripe, "price_pro",
               authenticated?: true,
               authorize: fn ^billable -> true end,
               catalog: catalog()
             )

    assert 1 ==
             Accrue.TestRepo.aggregate(Account, :count, :id)

    assert 0 == Accrue.Processor.Fake.call_count(:create_subscription)

    assert %PurchaseDecision{status: :eligible, revision: 0} =
             Accrue.Entitlements.purchase_decision(billable, :stripe, "price_pro",
               authenticated?: true,
               authorize: fn ^billable -> true end,
               catalog: catalog()
             )

    assert 1 == Accrue.TestRepo.aggregate(Account, :count, :id)
  end

  test "unauthorized billable reference creates no entitlement account or provider resource" do
    billable = %Billable{id: Ecto.UUID.generate()}

    assert {:error, :unauthorized_billable_reference} =
             Accrue.Entitlements.purchase_decision(billable, :stripe, "price_pro",
               authenticated?: true,
               authorize: fn _ -> false end,
               catalog: catalog()
             )

    assert 0 == Accrue.TestRepo.aggregate(Account, :count, :id)
    assert 0 == Accrue.Processor.Fake.call_count(:create_subscription)
  end

  test "an ambiguous durable operation reconciles before retrying and never dispatches a second create" do
    {:ok, account} =
      Accrue.Entitlements.provision_account("PurchaseDecisionUser", Ecto.UUID.generate())

    decision =
      PurchaseDecision.evaluate(%{snapshot([], 1) | account_id: account.id}, :stripe, "price_pro",
        catalog: catalog()
      )

    parent = self()

    subscribe = fn _billable, _price, _opts ->
      send(parent, :create_dispatched)
      {:error, :ambiguous}
    end

    opts = [
      snapshot: %{snapshot([], 1) | account_id: account.id},
      account_id: account.id,
      product_id: "price_pro",
      operation_id: "purchase-operation-durable",
      catalog: catalog(),
      subscribe: subscribe
    ]

    assert {:error, %{reason: :reconcile_required}} =
             PurchaseDecision.continue(decision, :billable, "price_pro", opts)

    assert_receive :create_dispatched

    assert {:ok, %{id: "sub_provider_completed"}} =
             PurchaseDecision.continue(
               decision,
               :billable,
               "price_pro",
               Keyword.put(opts, :reconcile, fn _operation ->
                 {:ok, %{id: "sub_provider_completed"}}
               end)
             )

    refute_receive :create_dispatched

    assert {:ok, %{status: :already_completed, operation_id: "purchase-operation-durable"}} =
             PurchaseDecision.continue(decision, :billable, "price_pro", opts)
  end

  test "Fake returns the same provider subscription for one idempotency key" do
    params = %{customer: "cus_fake_purchase", items: [%{price: "price_pro"}]}

    assert {:ok, first} =
             Accrue.Processor.Fake.create_subscription(params,
               idempotency_key: "purchase-idem-key"
             )

    assert {:ok, second} =
             Accrue.Processor.Fake.create_subscription(params,
               idempotency_key: "purchase-idem-key"
             )

    assert first.id == second.id
    assert [stored] = Accrue.Processor.Fake.subscriptions_on(:platform)
    assert stored.id == first.id
  end

  test "default continuation reconciles a Fake provider success after an ambiguous response" do
    %{customer: customer} = Accrue.Test.Factory.customer()

    {:ok, account} =
      Accrue.Entitlements.provision_account("PurchaseDecisionUser", Ecto.UUID.generate())

    snapshot = %{snapshot([], 1) | account_id: account.id}
    decision = PurchaseDecision.evaluate(snapshot, :stripe, "price_pro", catalog: catalog())

    opts = [
      snapshot: snapshot,
      account_id: account.id,
      product_id: "price_pro",
      operation_id: "purchase-operation-fake-default",
      catalog: catalog(),
      subscribe: fn billable, price, subscribe_opts ->
        assert {:ok, _subscription} =
                 Accrue.Billing.SubscriptionActions.subscribe(billable, price, subscribe_opts)

        {:error, :ambiguous}
      end
    ]

    assert {:error, %{reason: :reconcile_required}} =
             PurchaseDecision.continue(decision, customer, "price_pro", opts)

    assert {:ok, %{id: "sub_fake_00001"}} =
             PurchaseDecision.continue(decision, customer, "price_pro", opts)

    assert 1 == length(Accrue.Processor.Fake.subscriptions_on(:platform))
  end

  defp snapshot(sources, revision) do
    %Snapshot{
      account_id: "opaque-account-id",
      revision: revision,
      plans: if(sources == [], do: [], else: [:pro]),
      features: [],
      quantities: %{},
      sources: sources,
      authorization_bounds: %{}
    }
  end

  defp source(rail, logical_plan \\ :pro) do
    %{
      rail: rail,
      environment: :production,
      logical_plan: logical_plan,
      effective_at: @now,
      expires_at: nil,
      revoked_at: nil
    }
  end

  defp catalog,
    do: %{
      {:stripe, :production, "price_pro"} => :pro,
      {:apple, :production, "product_pro"} => :pro
    }

  defp contains_key?(term, key) when is_map(term),
    do:
      Map.has_key?(term, key) or
        Enum.any?(term, fn {_key, value} -> contains_key?(value, key) end)

  defp contains_key?(term, key) when is_list(term), do: Enum.any?(term, &contains_key?(&1, key))
  defp contains_key?(_term, _key), do: false
end
