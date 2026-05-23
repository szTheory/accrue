defmodule Accrue.Entitlements.Resolver.LocalMapTest do
  @moduledoc """
  Read-path tests for the default `Accrue.Entitlements.Resolver.LocalMap`:
  reads local subscription state (active/trialing only), folds active items
  into the `active_plans` SET + features UNION + merged quantities, and
  makes ZERO processor calls. Mutates `:entitlements` app env with on_exit
  restore (`async: false`).
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.Resolver.LocalMap

  # Billable whose billable_type "User" matches the factory's default
  # owner_type, so the resolver's (owner_type, owner_id) lookup resolves the
  # customer the factory created.
  defmodule TestUser do
    use Ecto.Schema
    # billable_type "User" matches the factory's default owner_type so the
    # resolver's (owner_type, owner_id) lookup resolves the seeded customer.
    use Accrue.Billable, billable_type: "User"

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  @entitlements [
    plans: [
      p1: [features: [:reports, :export], limits: [seats: 5], price_ids: ["price_p1"]],
      p2: [features: [:export, :api], limits: [api_calls: 100], price_ids: ["price_p2"]]
    ],
    unmapped_action: :deny
  ]

  setup do
    prev = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, @entitlements)

    on_exit(fn ->
      if prev do
        Application.put_env(:accrue, :entitlements, prev)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  defp billable_for(owner_id), do: %TestUser{id: owner_id}

  # Sets the (single) subscription item's quantity, mirroring the inline
  # quantity-bump pattern used by the single-plan cap tests.
  defp set_item_quantity(sub, quantity) do
    sub = Accrue.TestRepo.preload(sub, :subscription_items)
    item = hd(sub.subscription_items)

    {:ok, _} =
      item
      |> Ecto.Changeset.change(quantity: quantity)
      |> Accrue.TestRepo.update()
  end

  describe "resolve/2 single active plan" do
    test "active sub maps to features, quantities, and active_plans" do
      oid = Ecto.UUID.generate()
      %{customer: _c} = Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.member?(resolved.active_plans, :p1)
      assert MapSet.equal?(resolved.features, MapSet.new([:reports, :export]))
      assert resolved.quantities[:seats] == 1
      assert resolved.plan == :p1
    end

    test "min(cap, quantity) caps the seat quantity" do
      oid = Ecto.UUID.generate()
      %{subscription: sub} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      # Bump the item quantity above the cap of 5.
      item = hd(sub.subscription_items)

      {:ok, _} =
        item
        |> Ecto.Changeset.change(quantity: 9)
        |> Accrue.TestRepo.update()

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert resolved.quantities[:seats] == 5
    end

    test "no-cap quota falls back to the raw quantity" do
      oid = Ecto.UUID.generate()
      %{subscription: sub} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p2"})

      item = hd(sub.subscription_items)

      {:ok, _} =
        item
        |> Ecto.Changeset.change(quantity: 3)
        |> Accrue.TestRepo.update()

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      # api_calls cap is 100, quantity 3 -> min = 3
      assert resolved.quantities[:api_calls] == 3
    end
  end

  describe "resolve/2 multi-active-plan (one billable, two different mapped plans)" do
    test "active_plans holds BOTH atoms and features is the union" do
      oid = Ecto.UUID.generate()

      result =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      # Second active sub on the SAME customer (subscribe/2 reuses it) — NOT a
      # second factory call (which would mint a distinct customer).
      {:ok, _} = Accrue.Billing.subscribe(result.customer, "price_p2")

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.member?(resolved.active_plans, :p1)
      assert MapSet.member?(resolved.active_plans, :p2)
      assert MapSet.equal?(resolved.features, MapSet.new([:reports, :export, :api]))
    end

    # WR-01: two active mapped plans that SHARE a quota key must merge
    # deterministically to the most-generous (max) per-plan min(cap, quantity),
    # independent of the DB-return / fold order. The previous Map.put/3 was
    # last-write-wins over row order (non-deterministic). pa: seats cap 10 with
    # qty 8 -> 8; pb: seats cap 5 with qty 3 -> 3; merged seats == max(8, 3).
    test "shared quota key merges to the max per-plan min(cap, qty), order-independent" do
      shared = [
        plans: [
          pa: [features: [:fa], limits: [seats: 10], price_ids: ["price_pa"]],
          pb: [features: [:fb], limits: [seats: 5], price_ids: ["price_pb"]]
        ],
        unmapped_action: :deny
      ]

      Application.put_env(:accrue, :entitlements, shared)

      # pa: cap 10, qty 8 -> min = 8 ; pb: cap 5, qty 3 -> min = 3.
      # Run TWICE, swapping the creation/fold order of pa vs pb, to prove the
      # merged result is order-independent. max(8, 3) == 8 either way.
      merged_seats = fn first_price, first_qty, second_price, second_qty ->
        oid = Ecto.UUID.generate()

        first = Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: first_price})
        set_item_quantity(first.subscription, first_qty)

        {:ok, second_sub} = Accrue.Billing.subscribe(first.customer, second_price)
        set_item_quantity(second_sub, second_qty)

        assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
        resolved.quantities[:seats]
      end

      pa_first = merged_seats.("price_pa", 8, "price_pb", 3)
      pb_first = merged_seats.("price_pb", 3, "price_pa", 8)

      assert pa_first == 8
      assert pb_first == 8
      # Order-independent: the chosen rule yields the same value either way.
      assert pa_first == pb_first
    end
  end

  describe "resolve/2 lifecycle" do
    test "trialing sub counts as active" do
      oid = Ecto.UUID.generate()
      Accrue.Test.Factory.trialing_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.member?(resolved.active_plans, :p1)
    end

    test "canceled sub yields an empty result" do
      oid = Ecto.UUID.generate()
      Accrue.Test.Factory.canceled_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      assert resolved.quantities == %{}
      assert resolved.plan == nil
    end

    # WR-04: a `status: :active` row with a non-nil (past) `ended_at` is
    # simultaneously "active" per `Query.active/1` (status-only) and "canceled"
    # per `Subscription.canceled?/1` (any ended_at). The entitlements read path
    # must NOT grant on an ended subscription — `fold_active/1` excludes ended
    # rows locally without touching the shared `Query.active/1`.
    test "active-status sub with a past ended_at yields NO entitlements (fail-closed)" do
      oid = Ecto.UUID.generate()

      %{subscription: sub} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      past = DateTime.add(Accrue.Clock.utc_now(), -86_400, :second)

      {:ok, ended} =
        sub
        |> Accrue.Billing.Subscription.changeset(%{ended_at: past})
        |> Accrue.TestRepo.update()

      # Sanity: the row is still status :active but is canceled? via ended_at.
      assert ended.status == :active
      assert Accrue.Billing.Subscription.canceled?(ended)

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      assert resolved.quantities == %{}
      assert resolved.plan == nil
    end

    # D-11 paused fail-open gap closed end-to-end: a `status: :active` row with a
    # non-nil `pause_collection` is paused per `Subscription.paused?/1` and must
    # NOT grant entitlement. `fold_active/1`'s base fetch is now
    # `Query.entitling/1`, which carries `is_nil(pause_collection)`, so the
    # resolver no longer folds the paused plan into the resolved map.
    test "active-status sub with a non-nil pause_collection yields NO entitlements (paused gap closed)" do
      oid = Ecto.UUID.generate()

      %{subscription: sub} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      {:ok, paused} =
        sub
        |> Accrue.Billing.Subscription.changeset(%{pause_collection: %{"behavior" => "void"}})
        |> Accrue.TestRepo.update()

      # Sanity: still status :active but paused? via pause_collection, and
      # therefore NOT entitling? per the pure-lifecycle predicate.
      assert paused.status == :active
      assert Accrue.Billing.Subscription.paused?(paused)
      refute Accrue.Billing.Subscription.entitling?(paused)

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      assert resolved.quantities == %{}
      assert resolved.plan == nil
    end
  end

  describe "resolve/2 unmapped + missing" do
    test "unmapped active price_id under :deny is dropped" do
      oid = Ecto.UUID.generate()
      # price_unknown is not in the @entitlements plans.
      Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_unknown"})

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
    end

    test "unmapped active price_id under :raise raises" do
      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(@entitlements, :unmapped_action, :raise)
      )

      oid = Ecto.UUID.generate()
      Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_unknown"})

      assert_raise RuntimeError, fn -> LocalMap.resolve(billable_for(oid), []) end
    end

    test "billable with no customer row yields an empty result" do
      assert {:ok, resolved} = LocalMap.resolve(billable_for(Ecto.UUID.generate()), [])
      assert MapSet.size(resolved.active_plans) == 0
      assert resolved.plan == nil
    end

    test "customer with no active sub yields an empty result" do
      oid = Ecto.UUID.generate()
      %{customer: _c} = Accrue.Test.Factory.customer(%{owner_id: oid})

      assert {:ok, resolved} = LocalMap.resolve(billable_for(oid), [])
      assert MapSet.size(resolved.active_plans) == 0
    end
  end

  describe "resolve/2 fail-closed inputs" do
    test "nil billable yields an empty result (not an error tuple)" do
      assert {:ok, resolved} = LocalMap.resolve(nil, [])
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      assert resolved.quantities == %{}
      assert resolved.plan == nil
    end

    test "wrong-shape billable yields an empty result" do
      assert {:ok, resolved} = LocalMap.resolve(%{not: :a_billable}, [])
      assert MapSet.size(resolved.active_plans) == 0
    end
  end
end
