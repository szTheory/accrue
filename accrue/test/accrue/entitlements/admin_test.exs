defmodule Accrue.Entitlements.AdminTest do
  @moduledoc """
  Wave 0 unit tests for the internal read-only diagnostic seam
  `Accrue.Entitlements.Admin.resolve_for_customer/1` (ENT-11). The seam HOLDS a
  `%Accrue.Billing.Customer{}` (unlike `LocalMap.resolve/2`, which takes a
  billable) and returns `{resolved, unmapped_price_ids}`:

    * `resolved` reuses the resolver's SSOT fold (`LocalMap.fold_active/1`) — no
      drift, no re-implementation,
    * `unmapped_price_ids` surfaces the entitling `price_id`s the resolver
      structurally discards under `:deny` (`handle_unmapped/3`), which the
      resolved map can NEVER show.

  Mutates the `:entitlements` app env with an `on_exit` restore, so
  `async: false`.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.Admin
  alias Accrue.Entitlements.Reconcile

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

  defp set_past_due_since(sub, since) do
    {:ok, updated} =
      sub
      |> Accrue.Billing.Subscription.changeset(%{past_due_since: since})
      |> Accrue.TestRepo.update()

    updated
  end

  describe "resolve_for_customer/1 mapped" do
    test "a customer on a mapped price_id resolves plans + features, unmapped empty" do
      oid = Ecto.UUID.generate()

      %{customer: customer} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert {resolved, unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.member?(resolved.active_plans, :p1)
      assert MapSet.equal?(resolved.features, MapSet.new([:reports, :export]))
      assert unmapped == []
    end
  end

  describe "resolve_for_customer/1 unmapped drift (Pitfall 1)" do
    test "the factory default price_basic is silently dropped but surfaces in unmapped" do
      oid = Ecto.UUID.generate()

      # Factory default price "price_basic" is NOT in @entitlements -> unmapped.
      %{customer: customer} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid})

      assert {resolved, unmapped} = Admin.resolve_for_customer(customer)
      # Silently dropped from the resolved map (handle_unmapped :deny).
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      # ...but independently surfaced as drift.
      assert "price_basic" in unmapped
    end
  end

  describe "resolve_for_customer/1 under unmapped_action: :raise (WR-03)" do
    test "an unmapped entitling sub raises through the seam (the crash CR-01 contains)" do
      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(@entitlements, :unmapped_action, :raise)
      )

      oid = Ecto.UUID.generate()

      # Factory default "price_basic" is NOT in @entitlements -> the resolver's
      # handle_unmapped/3 raises under :raise rather than silently dropping
      # (the :deny default). This is the seam-level behavior the LiveView guard
      # (CR-01) collapses to a fail-closed error state.
      %{customer: customer} = Accrue.Test.Factory.active_subscription(%{owner_id: oid})

      assert_raise RuntimeError, ~r/unmapped/, fn ->
        Admin.resolve_for_customer(customer)
      end
    end

    test "a fully-mapped customer resolves normally even when :raise is configured" do
      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(@entitlements, :unmapped_action, :raise)
      )

      oid = Ecto.UUID.generate()

      %{customer: customer} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      assert {resolved, unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.member?(resolved.active_plans, :p1)
      assert unmapped == []
    end
  end

  describe "resolve_for_customer/1 empty" do
    test "a customer with no entitling subscription resolves an empty map + []" do
      oid = Ecto.UUID.generate()
      %{customer: customer} = Accrue.Test.Factory.customer(%{owner_id: oid})

      assert {resolved, unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.features) == 0
      assert resolved.quantities == %{}
      assert resolved.plan == nil
      assert unmapped == []
    end

    test "the resolved map always carries the grace_* keys defaulting to empty sets" do
      oid = Ecto.UUID.generate()
      %{customer: customer} = Accrue.Test.Factory.customer(%{owner_id: oid})

      assert {resolved, _unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.size(resolved.grace_plans) == 0
      assert MapSet.size(resolved.grace_features) == 0
      assert MapSet.size(resolved.expired_grace_plans) == 0
    end
  end

  describe "resolve_for_customer/1 grace overlay" do
    test "an in-window past_due sub grants and is tagged in grace_plans" do
      Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, :past_due_grace, 14))

      oid = Ecto.UUID.generate()

      %{customer: customer, subscription: sub} =
        Accrue.Test.Factory.past_due_subscription(%{owner_id: oid, price_id: "price_p1"})

      _ = set_past_due_since(sub, DateTime.add(Accrue.Clock.utc_now(), -1 * 86_400, :second))

      assert {resolved, unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.member?(resolved.active_plans, :p1)
      assert MapSet.member?(resolved.grace_plans, :p1)
      assert unmapped == []
    end

    test "an out-of-window past_due sub is dropped and recorded in expired_grace_plans" do
      Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, :past_due_grace, 14))

      oid = Ecto.UUID.generate()

      %{customer: customer, subscription: sub} =
        Accrue.Test.Factory.past_due_subscription(%{owner_id: oid, price_id: "price_p1"})

      _ = set_past_due_since(sub, DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second))

      assert {resolved, _unmapped} = Admin.resolve_for_customer(customer)
      assert MapSet.size(resolved.active_plans) == 0
      assert MapSet.size(resolved.grace_plans) == 0
      assert MapSet.member?(resolved.expired_grace_plans, :p1)
    end

    test "an out-of-window UNMAPPED past_due sub is NOT reported as catalog drift (WR-01)" do
      Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, :past_due_grace, 14))

      oid = Ecto.UUID.generate()

      # Factory default "price_basic" is unmapped. Pushed out of the grace
      # window it is tagged :expired (not entitling) — the fold drops it
      # because it fell outside the window, NOT because the price is unmapped.
      # Reporting it as drift would point operators at a phantom :plans-config
      # problem, so unmapped must exclude :expired rows.
      %{customer: customer, subscription: sub} =
        Accrue.Test.Factory.past_due_subscription(%{owner_id: oid})

      _ = set_past_due_since(sub, DateTime.add(Accrue.Clock.utc_now(), -30 * 86_400, :second))

      assert {_resolved, unmapped} = Admin.resolve_for_customer(customer)
      refute "price_basic" in unmapped
      assert unmapped == []
    end
  end

  describe "diagnostic_for_customer/1" do
    test "keeps the local resolver result separate from a recorded pull snapshot" do
      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(@entitlements, :stripe_native_sync, :advisory)
      )

      %{customer: customer} =
        Accrue.Test.Factory.active_subscription(%{owner_id: Ecto.UUID.generate(), price_id: "price_p1"})

      observed_at = ~U[2026-07-31 12:34:56Z]

      assert {:ok, _summary} =
               Reconcile.write_pull(
                 customer,
                 observed_at,
                 [
                   %{"lookup_key" => "priority-support", "feature" => "feature_priority"},
                   %{"lookup_key" => "alpha", "feature" => "feature_alpha"}
                 ],
                 "/v1/entitlements/active_entitlements"
               )

      assert %{local: {:ok, %{resolved: resolved, unmapped_price_ids: []}}, stripe_advisory: advisory} =
               Admin.diagnostic_for_customer(customer)

      assert MapSet.member?(resolved.features, :reports)
      assert advisory == %{
               state: :recorded,
               lookup_keys: ["alpha", "priority-support"],
               entitlement_count: 2,
               synced_at: observed_at,
               source: :pull,
               completeness: :complete,
               raw: %{
                 "lookup_keys" => ["alpha", "priority-support"],
                 "entitlement_count" => 2,
                 "synced_at" => "2026-07-31T12:34:56Z",
                 "source" => "pull",
                 "completeness" => "complete"
               }
             }

      assert Admin.resolve_for_customer(customer) == {resolved, []}
    end

    test "returns disabled before reading a historical advisory snapshot" do
      %{customer: customer} =
        Accrue.Test.Factory.active_subscription(%{owner_id: Ecto.UUID.generate(), price_id: "price_p1"})

      assert %{local: {:ok, %{resolved: resolved}}, stripe_advisory: %{state: :disabled}} =
               Admin.diagnostic_for_customer(customer)

      assert MapSet.member?(resolved.features, :reports)
    end
  end
end
