defmodule Accrue.Entitlements.PurchaseDecisionTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.{PurchaseDecision, Snapshot}

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
end
