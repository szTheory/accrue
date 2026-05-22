defmodule Accrue.EntitlementsTest do
  @moduledoc """
  Example + telemetry + ledger-boundary tests for the public
  `Accrue.Entitlements` context: the four fail-closed gate functions, their
  inline `[:accrue, :entitlements, :check]` spans with D-18 metadata, and
  the zero-`accrue_events`-write boundary. Mutates `:entitlements` app env
  with on_exit restore (`async: false`).
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements
  alias Accrue.Events.Event

  defmodule TestUser do
    use Ecto.Schema
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

  defp active_p1(owner_id),
    do: Accrue.Test.Factory.active_subscription(%{owner_id: owner_id, price_id: "price_p1"})

  # ----------------------------------------------------------------------
  # entitled?/2
  # ----------------------------------------------------------------------
  describe "entitled?/2" do
    test "true iff the feature is in the resolved active feature set" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      assert Entitlements.entitled?(b, :reports)
      assert Entitlements.entitled?(b, :export)
      refute Entitlements.entitled?(b, :api)
    end

    test "fail-closed false for nil / non-billable / no-customer / unmapped" do
      refute Entitlements.entitled?(nil, :reports)
      refute Entitlements.entitled?(%{garbage: true}, :reports)
      refute Entitlements.entitled?(billable_for(Ecto.UUID.generate()), :reports)

      oid = Ecto.UUID.generate()
      Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_unknown"})
      refute Entitlements.entitled?(billable_for(oid), :reports)
    end

    test "fail-closed false when the resolver raises" do
      Application.put_env(:accrue, :entitlements, Keyword.put(@entitlements, :resolver, RaisingResolver))
      assert Entitlements.entitled?(billable_for(Ecto.UUID.generate()), :reports) == false
    end
  end

  # ----------------------------------------------------------------------
  # has_active_plan?/2
  # ----------------------------------------------------------------------
  describe "has_active_plan?/2" do
    test "accepts an atom plan and a price_id string" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      assert Entitlements.has_active_plan?(b, :p1)
      assert Entitlements.has_active_plan?(b, "price_p1")
      refute Entitlements.has_active_plan?(b, :p2)
    end

    test "multi-active-plan: true for BOTH plans (atom + string) on one billable" do
      oid = Ecto.UUID.generate()
      result = active_p1(oid)
      {:ok, _} = Accrue.Billing.subscribe(result.customer, "price_p2")
      b = billable_for(oid)

      assert Entitlements.has_active_plan?(b, :p1)
      assert Entitlements.has_active_plan?(b, :p2)
      assert Entitlements.has_active_plan?(b, "price_p1")
      assert Entitlements.has_active_plan?(b, "price_p2")
      refute Entitlements.has_active_plan?(b, :enterprise)
    end

    test "trialing true, canceled false" do
      oid_t = Ecto.UUID.generate()
      Accrue.Test.Factory.trialing_subscription(%{owner_id: oid_t, price_id: "price_p1"})
      assert Entitlements.has_active_plan?(billable_for(oid_t), :p1)

      oid_c = Ecto.UUID.generate()
      Accrue.Test.Factory.canceled_subscription(%{owner_id: oid_c, price_id: "price_p1"})
      refute Entitlements.has_active_plan?(billable_for(oid_c), :p1)
    end

    test "unmapped plan string / unknown atom -> false" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      refute Entitlements.has_active_plan?(b, "price_garbage")
      refute Entitlements.has_active_plan?(b, :unknown_plan)
    end

    test "fail-closed false for nil / non-billable" do
      refute Entitlements.has_active_plan?(nil, :p1)
      refute Entitlements.has_active_plan?(%{garbage: true}, :p1)
    end
  end

  # ----------------------------------------------------------------------
  # features_for/1
  # ----------------------------------------------------------------------
  describe "features_for/1" do
    test "returns a sorted, deduped, plain list (never a MapSet)" do
      oid = Ecto.UUID.generate()
      result = active_p1(oid)
      {:ok, _} = Accrue.Billing.subscribe(result.customer, "price_p2")

      features = Entitlements.features_for(billable_for(oid))
      assert is_list(features)
      refute is_struct(features, MapSet)
      # union of [:reports, :export] and [:export, :api], deduped + sorted
      assert features == [:api, :export, :reports]
    end

    test "fail-closed [] for nil / non-billable / no-customer" do
      assert Entitlements.features_for(nil) == []
      assert Entitlements.features_for(%{garbage: true}) == []
      assert Entitlements.features_for(billable_for(Ecto.UUID.generate())) == []
    end
  end

  # ----------------------------------------------------------------------
  # entitlement_quantity/2
  # ----------------------------------------------------------------------
  describe "entitlement_quantity/2" do
    test "min(cap, quantity) when a cap exists" do
      oid = Ecto.UUID.generate()
      %{subscription: sub} = active_p1(oid)
      item = hd(sub.subscription_items)
      {:ok, _} = item |> Ecto.Changeset.change(quantity: 9) |> Accrue.TestRepo.update()

      assert Entitlements.entitlement_quantity(billable_for(oid), :seats) == 5
    end

    test "raw quantity when no cap" do
      oid = Ecto.UUID.generate()
      %{subscription: sub} =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p2"})

      item = hd(sub.subscription_items)
      {:ok, _} = item |> Ecto.Changeset.change(quantity: 3) |> Accrue.TestRepo.update()

      assert Entitlements.entitlement_quantity(billable_for(oid), :api_calls) == 3
    end

    test "fail-closed 0 for unknown quota / nil / non-billable" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      assert Entitlements.entitlement_quantity(billable_for(oid), :unknown_quota) == 0
      assert Entitlements.entitlement_quantity(nil, :seats) == 0
      assert Entitlements.entitlement_quantity(%{garbage: true}, :seats) == 0
    end
  end

  # ----------------------------------------------------------------------
  # Telemetry — D-18 metadata
  # ----------------------------------------------------------------------
  describe "telemetry" do
    setup do
      test_pid = self()
      ref = make_ref()
      handler_id = {__MODULE__, ref}

      :telemetry.attach_many(
        handler_id,
        [
          [:accrue, :entitlements, :check, :start],
          [:accrue, :entitlements, :check, :stop],
          [:accrue, :entitlements, :check, :exception]
        ],
        fn name, measurements, metadata, _ ->
          send(test_pid, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)
      :ok
    end

    test "entitled? emits start + stop with D-18 metadata and no PII" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      assert Entitlements.entitled?(b, :reports)

      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :start], _, _}
      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, meta}

      assert meta.feature == :reports
      assert meta.result == true
      assert meta.resolver == :local_map
      assert meta.reason in [:entitled, :not_entitled, :unmapped_plan, :no_active_subscription, :error]
      assert meta.reason == :entitled
      assert meta.subject_type == "Accrue.EntitlementsTest.TestUser"
      assert meta.subject_id == to_string(oid)

      refute Map.has_key?(meta, :email)
      refute Map.has_key?(meta, :name)
    end

    test "has_active_plan? for an unmapped plan string emits reason: :unmapped_plan" do
      oid = Ecto.UUID.generate()
      active_p1(oid)

      refute Entitlements.has_active_plan?(billable_for(oid), "price_garbage")

      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, meta}
      assert meta.result == false
      assert meta.reason == :unmapped_plan
    end

    test "all four functions emit a stop event with a boolean/scalar result" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      Entitlements.entitled?(b, :reports)
      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, %{result: r1}}
      assert is_boolean(r1)

      Entitlements.has_active_plan?(b, :p1)
      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, %{result: r2}}
      assert is_boolean(r2)

      Entitlements.features_for(b)
      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, _}

      Entitlements.entitlement_quantity(b, :seats)
      assert_receive {:telemetry_event, [:accrue, :entitlements, :check, :stop], _, _}
    end
  end

  # ----------------------------------------------------------------------
  # Ledger boundary (D-21): zero accrue_events rows written by checks
  # ----------------------------------------------------------------------
  describe "ledger boundary" do
    test "a batch of checks writes ZERO accrue_events rows" do
      oid = Ecto.UUID.generate()
      active_p1(oid)
      b = billable_for(oid)

      before = Accrue.TestRepo.aggregate(Event, :count, :id)

      Entitlements.entitled?(b, :reports)
      Entitlements.entitled?(b, :api)
      Entitlements.has_active_plan?(b, :p1)
      Entitlements.has_active_plan?(b, "price_p1")
      Entitlements.features_for(b)
      Entitlements.entitlement_quantity(b, :seats)

      after_count = Accrue.TestRepo.aggregate(Event, :count, :id)
      assert after_count == before
    end
  end

  # Raising resolver stub for the fail-closed-on-exception leg.
  defmodule RaisingResolver do
    @behaviour Accrue.Entitlements.Resolver
    @impl true
    def resolve(_billable, _opts), do: raise("boom")
  end
end
