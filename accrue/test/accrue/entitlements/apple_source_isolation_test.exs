defmodule Accrue.Entitlements.AppleSourceIsolationTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Grant, Observation}
  alias Accrue.Entitlements.Apple.Intake
  alias Accrue.Processor.Fake

  @forbidden_callbacks [
    :cancel_subscription,
    :update_subscription,
    :pause_subscription_collection,
    :create_refund,
    :create_invoice,
    :create_invoice_preview,
    :pay_invoice,
    :create_payment_method,
    :attach_payment_method,
    :detach_payment_method,
    :subscription_item_create,
    :subscription_item_update,
    :subscription_item_delete
  ]

  setup do
    Fake.reset()

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:analytics], products: [apple: [production: ["product_pro"]]]]]
    )

    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", "apple-isolation")
    {:ok, account: account}
  end

  test "management guidance and policy deferrals are exact, typed, and bounded" do
    assert {:ok,
            %{
              state: :externally_managed,
              guidance: %{
                text: "Manage this subscription in Apple.",
                action_label: "Manage subscription",
                url: "https://apps.apple.com/account/subscriptions"
              }
            }} = Accrue.Entitlements.apple_management()

    for outcome <- [
          Accrue.Entitlements.apple_family_sharing(),
          Accrue.Entitlements.apple_offer_authoring()
        ] do
      assert {:ok, %Intake.Outcome{disposition: :deferred, next_action: :review_policy}} = outcome
    end
  end

  test "observation, repair, reconciliation, and concurrent calls do not reach Stripe", %{
    account: account
  } do
    evidence = evidence(account)

    assert {:ok, %Intake.Outcome{disposition: :verified}} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence)

    lineage_id =
      Accrue.TestRepo.one!(Accrue.Entitlements.Apple.Lineage).id

    assert {:ok, %Intake.Outcome{disposition: :pending, reason: :reconciliation_requested}} =
             Accrue.Entitlements.reconcile_apple_lineage(account, lineage_id,
               authorize: fn ^account, :reconcile_apple_lineage -> true end,
               repo: Accrue.TestRepo
             )

    Task.async_stream(1..4, fn _ -> Accrue.Entitlements.apple_management() end)
    |> Enum.each(fn {:ok, _} -> :ok end)

    assert Enum.all?(@forbidden_callbacks, &(Fake.call_count(&1) == 0))
  end

  test "public outcome inspection does not reveal evidence or provider identifiers", %{
    account: account
  } do
    assert {:ok, %Intake.Outcome{} = outcome} =
             Accrue.Entitlements.observe_apple_evidence(account, evidence(account))

    rendered = inspect(outcome)

    for forbidden <- ["txn-private", "orig-private", "cursor", "jws", "account-token"] do
      refute rendered =~ forbidden
    end

    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end

  defp evidence(account) do
    %Intake.VerifiedEvidence{
      environment: :production,
      original_transaction_id: "orig-private",
      app_account_token: account.id,
      provider_event_id: "evt-private",
      provider_transaction_id: "txn-private",
      product_id: "product_pro",
      logical_plan: :pro,
      lifecycle: :grant,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: String.duplicate("a", 64),
      verifier_version: "fake-v1",
      config_version: "v1"
    }
  end
end
