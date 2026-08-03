defmodule Accrue.Entitlements.AppleSourceIsolationTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Grant, Observation}
  alias Accrue.Entitlements.Apple.Intake
  alias Accrue.Processor.Fake

  defmodule FakeVerifier do
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction(signed, _) when is_binary(signed), do: Jason.decode(signed)
  end

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

    Application.put_env(:accrue, :apple_reconciliation,
      admission: [
        verifier: FakeVerifier,
        verifier_config: :test,
        product_map: %{"product_pro" => :pro}
      ]
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
    evidence = signed_evidence(account)

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
             Accrue.Entitlements.observe_apple_evidence(account, signed_evidence(account))

    rendered = inspect(outcome)

    for forbidden <- ["txn-private", "orig-private", "cursor", "jws", "account-token"] do
      refute rendered =~ forbidden
    end

    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end

  defp signed_evidence(account) do
    Jason.encode!(%{
      "originalTransactionId" => "orig-private",
      "appAccountToken" => account.id,
      "transactionId" => "txn-private",
      "productId" => "product_pro",
      "signedDate" => 1_754_000_000_000,
      "expiresDate" => 1_800_000_000_000
    })
  end
end
