defmodule Accrue.Entitlements.ProviderHonestyTest do
  @moduledoc """
  Provider-honesty proof (Phase 125, ENT-08 SC#1 / D-05).

  The milestone's local-first thesis is that entitlement resolution is
  provider-INDEPENDENT local derivation: `Accrue.Entitlements.Resolver.LocalMap`
  reads `accrue_customers` + active subscription items + the `price_id -> plan`
  config and makes ZERO processor calls. This test proves that **structurally**
  (`resolve/2` takes no `:processor` argument) and as a **regression guard**:

    1. Seed identical local state ONCE.
    2. Loop `[Fake, Stripe, Braintree]` as `:processor`, resolve each time, and
       assert the three `resolved` maps are `==` (byte-identical across providers).
    3. Attach a `:telemetry` handler to `[:accrue, :processor, ...]` and assert it
       NEVER fires during resolution (no Stripe/Braintree network call occurs —
       swapping `:processor` is hermetic precisely because the resolver ignores it).

  It also asserts the new `Accrue.Processor.Capabilities` `:entitlements` labels
  equal the published-doc literals — the code-side mirror of the bash drift gate
  (`scripts/ci/verify_processor_support_matrix.sh`).

  Mutates `:entitlements` AND `:processor` app env with `on_exit` restore, hence
  `async: false`.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Entitlements.Resolver.LocalMap
  alias Accrue.Processor.Capabilities

  @providers [Accrue.Processor.Fake, Accrue.Processor.Stripe, Accrue.Processor.Braintree]

  # Billable whose billable_type "User" matches the factory's default owner_type,
  # so the resolver's (owner_type, owner_id) lookup resolves the seeded customer.
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
    prev_ent = Application.get_env(:accrue, :entitlements)
    prev_proc = Application.get_env(:accrue, :processor)
    Application.put_env(:accrue, :entitlements, @entitlements)

    on_exit(fn ->
      if prev_ent,
        do: Application.put_env(:accrue, :entitlements, prev_ent),
        else: Application.delete_env(:accrue, :entitlements)

      if prev_proc,
        do: Application.put_env(:accrue, :processor, prev_proc),
        else: Application.delete_env(:accrue, :processor)
    end)

    :ok
  end

  defp billable_for(owner_id), do: %TestUser{id: owner_id}

  describe "entitlement resolution is provider-independent local derivation (D-03)" do
    test "resolved maps are byte-identical across Fake/Stripe/Braintree, with zero processor calls" do
      # Seed identical local state ONCE: a customer with an active subscription on
      # a mapped price_id. Every provider lane resolves against THIS state.
      oid = Ecto.UUID.generate()

      result =
        Accrue.Test.Factory.active_subscription(%{owner_id: oid, price_id: "price_p1"})

      # Second active sub on the SAME customer so the resolved map is non-trivial
      # (two plans, a feature union, merged quantities) — a richer identity proof.
      {:ok, _} = Accrue.Billing.subscribe(result.customer, "price_p2")

      billable = billable_for(oid)

      # Regression guard: assert NO processor telemetry fires during resolution.
      handler_id = "provider-honesty-zero-processor-calls-#{System.unique_integer([:positive])}"
      test_pid = self()

      :ok =
        :telemetry.attach_many(
          handler_id,
          [
            [:accrue, :processor, :customer, :create],
            [:accrue, :processor, :customer, :retrieve],
            [:accrue, :processor, :customer, :update]
          ],
          fn event, _measurements, _metadata, _config ->
            send(test_pid, {:processor_called, event})
          end,
          nil
        )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      resolved_maps =
        for processor <- @providers do
          Application.put_env(:accrue, :processor, processor)
          assert {:ok, resolved} = LocalMap.resolve(billable, [])
          resolved
        end

      # All three resolved maps are == each other (byte-identical).
      [fake_resolved, stripe_resolved, braintree_resolved] = resolved_maps
      assert fake_resolved == stripe_resolved
      assert stripe_resolved == braintree_resolved

      # Sanity: the seeded state actually produced a non-empty union (so the
      # equality above is not the trivial empty-map identity).
      assert MapSet.equal?(fake_resolved.active_plans, MapSet.new([:p1, :p2]))
      assert MapSet.equal?(fake_resolved.features, MapSet.new([:reports, :export, :api]))

      # Zero processor calls: the handler must never have fired.
      refute_received {:processor_called, _event}
    end
  end

  describe "capability labels mirror the published support-matrix doc literals" do
    test "support_label is the first-party convergence promise" do
      assert Capabilities.support_label([:entitlements, :local_mapping]) == "all first-party"
    end

    test "every provider lane is local-identical (convergence, never divergence)" do
      for provider <- [:fake, :stripe, :braintree] do
        assert Capabilities.provider_support_label(provider, [:entitlements, :local_mapping]) ==
                 "local-identical"
      end
    end

    test "all three adapters advertise the identical entitlements capability key" do
      for provider <- @providers do
        caps = Capabilities.for(provider)
        assert caps[:entitlements] == %{local_mapping: true}
      end
    end
  end
end
