defmodule Accrue.Test.EntitlementsTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.Snapshot
  alias Accrue.Test.Entitlements

  setup do
    keys = [:processor, :rails, :default_rail, :entitlements]
    previous = Map.new(keys, &{&1, Application.get_env(:accrue, &1, :unset)})

    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)

    Application.put_env(:accrue, :rails,
      stripe: [
        source: :stripe,
        processor: Accrue.Processor.Fake,
        environments: [:production],
        default_environment: :production
      ],
      apple: [
        source: :apple,
        environments: [:production],
        default_environment: :production
      ]
    )

    Application.put_env(:accrue, :default_rail, :stripe)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:pro],
          limits: [seats: 1],
          products: [
            stripe: [production: ["price_test_pro"]],
            apple: [production: ["com.example.test.pro"]]
          ]
        ]
      ]
    )

    on_exit(fn ->
      Enum.each(previous, fn
        {key, :unset} -> Application.delete_env(:accrue, key)
        {key, value} -> Application.put_env(:accrue, key, value)
      end)
    end)
  end

  for {scenario, expected_rail} <- [
        none: nil,
        stripe_active: :stripe,
        stripe_cancelled_but_entitled: :stripe,
        apple_active: :apple
      ] do
    test "inserts #{scenario} for host rendering tests" do
      now = ~U[2026-08-30 12:00:00.000000Z]
      %{account: account, grants: grants} = Entitlements.insert!(unquote(scenario), now: now)
      snapshot = Snapshot.fetch(Accrue.TestRepo, account, now: now)

      if unquote(expected_rail) do
        assert [%{rail: unquote(expected_rail)}] = snapshot.sources
        assert snapshot.plans == [:pro]
        assert snapshot.features == [:pro]
        assert snapshot.quantities == %{seats: 1}
        assert length(grants) == 1
      else
        assert snapshot.sources == []
        assert snapshot.plans == []
        assert grants == []
      end
    end
  end

  test "cancelled-but-entitled fixture retains access only until its expiry" do
    now = ~U[2026-08-30 12:00:00.000000Z]
    expires_at = DateTime.add(now, 60, :second)

    %{account: account} =
      Entitlements.insert!(:stripe_cancelled_but_entitled,
        now: now,
        expires_at: expires_at
      )

    assert Snapshot.fetch(Accrue.TestRepo, account, now: now).plans == [:pro]
    assert Snapshot.fetch(Accrue.TestRepo, account, now: expires_at).plans == []
  end
end
