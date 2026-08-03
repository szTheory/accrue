defmodule Accrue.Entitlements.AppleConvergencePropertyTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo
  use ExUnitProperties

  import Ecto.Query

  alias Accrue.Entitlements.{Account, Grant}
  alias Accrue.Entitlements.Apple.Intake

  setup do
    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:analytics], products: [apple: [production: ["product_pro"]]]]]
    )

    :ok
  end

  property "verified Apple observations converge regardless of provider delivery order" do
    check all(ordered <- member_of([[:active, :refunded], [:refunded, :active]])) do
      {:ok, account} =
        Account.fetch_or_create(
          Accrue.TestRepo,
          "property",
          "apple-convergence-#{System.unique_integer([:positive])}"
        )

      Enum.each(ordered, fn lifecycle ->
        assert {:ok, %Intake.Outcome{disposition: :verified}} =
                 Intake.observe(account, evidence(account, lifecycle), repo: Accrue.TestRepo)
      end)

      assert [] ==
               Accrue.TestRepo.all(
                 from(grant in Grant,
                   where: grant.account_id == ^account.id and is_nil(grant.superseded_at)
                 )
               )
    end
  end

  defp evidence(account, lifecycle) do
    digest =
      case lifecycle do
        :active -> String.duplicate("a", 64)
        :refunded -> String.duplicate("b", 64)
      end

    %Intake.VerifiedEvidence{
      environment: :production,
      original_transaction_id: "property-original-#{account.id}",
      app_account_token: account.id,
      provider_event_id: "property-#{account.id}-#{lifecycle}",
      provider_transaction_id: "property-transaction-#{lifecycle}",
      product_id: "product_pro",
      logical_plan: :pro,
      lifecycle: lifecycle,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: digest,
      verifier_version: "property-v1",
      config_version: "property-v1"
    }
  end
end
