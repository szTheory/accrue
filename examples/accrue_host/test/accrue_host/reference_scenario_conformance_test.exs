defmodule AccrueHost.ReferenceScenarioConformanceTest do
  use AccrueHost.DataCase, async: false

  alias Accrue.Entitlements.{Account, Observation, Projector, ReferenceScenarios}

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

  setup do
    prior =
      for key <- [:entitlements, :apple_reconciliation, :rails],
          into: %{},
          do: {key, Application.get_env(:accrue, key)}

    on_exit(fn -> Enum.each(prior, fn {key, value} -> restore(key, value) end) end)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:analytics],
          quotas: [seats: 3],
          products: [stripe: [production: ["price_pro"]], apple: [production: ["product_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production],
      apple: [environments: [:production], default_environment: :production]
    )

    Application.put_env(:accrue, :apple_reconciliation,
      admission: [
        verifier: FakeVerifier,
        verifier_config: :test,
        product_map: %{"product_pro" => :pro},
        verifier_version: "fake-v1",
        config_version: "host-test-v1"
      ]
    )
  end

  @tag :tracer
  test "the host drives Apple-to-web through its configured Repo" do
    scenario = ReferenceScenarios.fetch!("apple_purchase_to_web_login")
    account = account!("host-apple-web")
    payload = payload!(scenario)

    assert {:ok, _} =
             Accrue.Entitlements.observe_apple_evidence(
               account,
               apple_evidence(account, payload)
             )

    assert_host_result(scenario, account, :stripe, "price_pro")
  end

  @tag :tracer
  test "the host drives Stripe-to-iOS through its configured Repo" do
    scenario = ReferenceScenarios.fetch!("stripe_purchase_to_ios_login")
    account = account!("host-stripe-ios")
    payload = payload!(scenario)

    assert {:ok, observation} =
             Observation.insert_idempotently(
               AccrueHost.Repo,
               observation_attrs(account, payload)
             )

    assert {:ok, _} = Projector.project(observation)
    assert_host_result(scenario, account, :apple, "product_pro")
  end

  defp assert_host_result(scenario, account, opposite_rail, product_id) do
    assert {:ok, snapshot} = Accrue.Entitlements.snapshot(account)
    assert snapshot.revision == scenario.expected.snapshot.revision
    assert snapshot.plans == [:pro]
    assert Enum.map(snapshot.sources, & &1.rail) == scenario.expected.snapshot.sources
    decision = Accrue.Entitlements.purchase_decision(account.id, opposite_rail, product_id)
    assert decision.status == scenario.expected.purchase.status
    assert Atom.to_string(decision.reason) == scenario.expected.purchase.reason
    assert {:ok, other_snapshot} = Accrue.Entitlements.snapshot(account!("other-#{scenario.id}"))
    assert other_snapshot.plans == []
  end

  defp payload!(scenario) do
    scenario.actions
    |> Enum.find(
      &match?(
        %{command: %{kind: kind}}
        when kind in ["apple_verified_purchase", "stripe_verified_purchase"],
        &1
      )
    )
    |> then(& &1.command.payload)
  end

  defp account!(owner_id),
    do: Account.fetch_or_create(AccrueHost.Repo, "reference_host", owner_id) |> elem(1)

  defp apple_evidence(account, op),
    do:
      Jason.encode!(%{
        "originalTransactionId" => op.provider_lineage_id,
        "appAccountToken" => account.id,
        "transactionId" => op.provider_transaction_id,
        "productId" => op.provider_product_id,
        "signedDate" => 1_754_000_000_000,
        "expiresDate" => 1_800_000_000_000
      })

  defp observation_attrs(account, op),
    do: %{
      account_id: account.id,
      rail: op.rail,
      environment: op.environment,
      provider_event_id: op.provider_event_id,
      provider_transaction_id: op.provider_transaction_id,
      kind: "grant",
      provider_lineage_id: op.provider_lineage_id,
      provider_product_id: op.provider_product_id,
      provider_order: op.provider_order,
      observed_at: ~U[2026-08-04 12:01:00.000000Z],
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest: String.duplicate("a", 64)
    }

  defp restore(key, nil), do: Application.delete_env(:accrue, key)
  defp restore(key, value), do: Application.put_env(:accrue, key, value)
end
