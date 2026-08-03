defmodule Accrue.Entitlements.SnapshotTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.{Grant, Snapshot}

  test "folds live rail-qualified grants into one deterministic authorization value" do
    now = ~U[2026-08-02 12:00:00.000000Z]

    grants = [
      grant(:stripe, "stripe-lineage", 3, now),
      grant(:apple, "apple-lineage", 5, now)
    ]

    snapshot =
      Snapshot.from_grants(grants,
        account_id: "account-opaque",
        revision: 1,
        now: now,
        catalog: %{
          "pro-monthly" => %{plan: :pro, features: [:analytics, :exports], quotas: %{seats: 3}},
          "pro-apple" => %{
            plan: :pro,
            features: [:exports, :priority_support],
            quotas: %{seats: 5}
          }
        }
      )

    assert snapshot.account_id == "account-opaque"
    assert snapshot.revision == 1
    assert snapshot.plans == [:pro]
    assert snapshot.features == [:analytics, :exports, :priority_support]
    assert snapshot.quantities == %{seats: 5}
    assert Enum.map(snapshot.sources, & &1.rail) == [:apple, :stripe]
    assert Enum.map(snapshot.sources, & &1.logical_plan) == [:pro, :pro]
    refute inspect(snapshot) =~ "stripe-lineage"
    refute inspect(snapshot) =~ "apple-lineage"
  end

  test "excludes grants exactly at expiry and includes grants immediately before expiry" do
    expiry = ~U[2026-08-02 12:00:00.000000Z]

    grant = %{
      grant(:stripe, "stripe-lineage", 3, DateTime.add(expiry, -1, :second))
      | expires_at: expiry
    }

    assert Snapshot.from_grants([grant], options(expiry, DateTime.add(expiry, -1, :microsecond))).plans ==
             [:pro]

    assert Snapshot.from_grants([grant], options(expiry, expiry)).plans == []

    assert Snapshot.from_grants([grant], options(expiry, DateTime.add(expiry, 1, :microsecond))).plans ==
             []
  end

  test "authorization signature excludes diagnostic source additions while snapshots retain them" do
    now = ~U[2026-08-02 12:00:00.000000Z]

    options =
      options(now, now)
      |> Keyword.put(:catalog, %{
        "pro-monthly" => %{plan: :pro, features: [:analytics], quotas: %{seats: 3}},
        "pro-apple" => %{plan: :pro, features: [:analytics], quotas: %{seats: 3}}
      })

    stripe = grant(:stripe, "stripe-lineage", 3, now)
    apple = grant(:apple, "apple-lineage", 3, now)

    one_source = Snapshot.from_grants([stripe], options)
    two_sources = Snapshot.from_grants([stripe, apple], options)

    assert one_source.sources != two_sources.sources

    assert Snapshot.authorization_signature(one_source) ==
             Snapshot.authorization_signature(two_sources)
  end

  defp options(_expiry, now) do
    [
      account_id: "account-opaque",
      revision: 1,
      now: now,
      catalog: %{"pro-monthly" => %{plan: :pro, features: [:analytics], quotas: %{seats: 3}}}
    ]
  end

  defp grant(rail, lineage, quantity, effective_at) do
    %Grant{
      rail: rail,
      environment: :production,
      provider_lineage_id: lineage,
      provider_product_id: if(rail == :stripe, do: "pro-monthly", else: "pro-apple"),
      source_item_id: "source-#{rail}",
      quantity: quantity,
      effective_at: effective_at,
      expires_at: nil,
      superseded_at: nil
    }
  end
end
