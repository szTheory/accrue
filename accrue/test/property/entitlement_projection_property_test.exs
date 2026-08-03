defmodule Accrue.Entitlements.ProjectionPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Accrue.Entitlements.{Grant, Snapshot}

  @now ~U[2026-08-02 12:00:00.000000Z]
  @catalog %{
    "pro-stripe" => %{plan: :pro, features: [:analytics, :exports], quotas: %{seats: 1}},
    "pro-apple" => %{plan: :pro, features: [:exports, :priority_support], quotas: %{seats: 2}}
  }

  property "permuting live grants preserves deterministic collections and authorization signature" do
    check all(quantities <- list_of(integer(1..1_000_000), min_length: 1, max_length: 5)) do
      grants = grants_for(quantities)
      expected = snapshot(grants)

      Enum.each(permutations(grants), fn candidate ->
        actual = snapshot(candidate)
        assert public_view(actual) == public_view(expected)

        assert Snapshot.authorization_signature(actual) ==
                 Snapshot.authorization_signature(expected)
      end)
    end
  end

  property "duplicate logical grants merge feature unions and exact positive integer maxima" do
    check all(
            stripe_quantity <- integer(1..9_223_372_036_854_775_807),
            apple_quantity <- integer(1..9_223_372_036_854_775_807)
          ) do
      grants = [grant(:stripe, stripe_quantity), grant(:apple, apple_quantity)]
      expected_quantity = max(stripe_quantity, apple_quantity)

      snapshot = snapshot(grants ++ grants)

      assert snapshot.plans == [:pro]
      assert snapshot.features == [:analytics, :exports, :priority_support]
      assert snapshot.quantities == %{seats: expected_quantity}

      assert Snapshot.authorization_signature(snapshot) ==
               Snapshot.authorization_signature(snapshot(grants))
    end
  end

  property "authorization signature ignores incidental grant metadata and logical duplicates" do
    check all(
            quantity <- integer(1..1_000_000),
            correlation <- string(:alphanumeric, min_length: 1, max_length: 32)
          ) do
      original = grant(:stripe, quantity)

      enriched = %{
        original
        | id: Ecto.UUID.generate(),
          source_item_id: "source-#{correlation}",
          provider_lineage_id: "lineage-#{correlation}",
          source_observation_id: Ecto.UUID.generate()
      }

      assert Snapshot.authorization_signature(snapshot([original])) ==
               Snapshot.authorization_signature(snapshot([enriched, original]))
    end
  end

  test "cutoffs include effective-at and exclude expiry-at with microsecond adjacency" do
    effective_at = @now
    expiry_at = DateTime.add(@now, 2, :microsecond)
    grant = %{grant(:stripe, 3) | effective_at: effective_at, expires_at: expiry_at}

    assert snapshot([grant], DateTime.add(effective_at, -1, :microsecond)).plans == []
    assert snapshot([grant], effective_at).plans == [:pro]
    assert snapshot([grant], DateTime.add(expiry_at, -1, :microsecond)).plans == [:pro]
    assert snapshot([grant], expiry_at).plans == []
    assert snapshot([grant], DateTime.add(expiry_at, 1, :microsecond)).plans == []
  end

  test "empty and expired grant sets produce a valid empty snapshot" do
    expired = %{grant(:stripe, 3) | expires_at: @now}

    for grants <- [[], [expired]] do
      snapshot = snapshot(grants)
      assert snapshot.plans == []
      assert snapshot.features == []
      assert snapshot.quantities == %{}
      assert snapshot.sources == []
    end
  end

  defp grants_for(quantities) do
    quantities
    |> Enum.with_index()
    |> Enum.map(fn {quantity, index} ->
      rail = if rem(index, 2) == 0, do: :stripe, else: :apple
      grant(rail, quantity, "lineage-#{index}")
    end)
  end

  defp permutations(grants), do: permutations_of(grants)
  defp permutations_of([]), do: [[]]

  defp permutations_of(values) do
    for value <- values,
        rest <- permutations_of(List.delete(values, value)),
        do: [value | rest]
  end

  defp snapshot(grants, now \\ @now) do
    Snapshot.from_grants(grants,
      account_id: "account-opaque",
      revision: 7,
      now: now,
      catalog: @catalog
    )
  end

  defp public_view(snapshot) do
    Map.take(snapshot, [:account_id, :revision, :plans, :features, :quantities, :sources])
  end

  defp grant(rail, quantity, lineage \\ nil) do
    %Grant{
      rail: rail,
      environment: :production,
      provider_lineage_id: lineage || "#{rail}-lineage",
      provider_product_id: if(rail == :stripe, do: "pro-stripe", else: "pro-apple"),
      source_item_id: "#{rail}-source",
      quantity: quantity,
      effective_at: @now,
      expires_at: nil,
      superseded_at: nil
    }
  end
end
