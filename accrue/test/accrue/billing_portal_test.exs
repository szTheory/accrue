defmodule Accrue.BillingPortalTest do
  @moduledoc """
  Phase 4 Plan 07 (CHKT-04/05) — Customer Billing Portal session
  wrapper, optional `bpc_*` configuration id passthrough, Inspect PII
  mask on the bearer-credential `:url`, and the install-guide
  configuration checklist.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.BillingPortal
  alias Accrue.BillingPortal.Session

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_portal",
        email: "portal@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "Accrue.BillingPortal.Session.create/1" do
    test "creates a portal session for a customer struct + return_url",
         %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 return_url: "https://example.com/account"
               })

      assert is_binary(session.id)
      assert String.starts_with?(session.id, "bps_fake_")
      assert is_binary(session.url)
      assert session.return_url == "https://example.com/account"
    end

    test "accepts an optional configuration: \"bpc_...\" id and forwards it",
         %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Session.create(%{
                 customer: customer,
                 return_url: "https://example.com/account",
                 configuration: "bpc_test_123"
               })

      assert session.configuration == "bpc_test_123"
    end

    test "accepts a stripe customer id string", %{customer: customer} do
      assert {:ok, %Session{}} =
               Session.create(%{
                 customer: customer.processor_id,
                 return_url: "https://example.com/account"
               })
    end

    test "facade Accrue.BillingPortal.create_session/1 delegates", %{customer: customer} do
      assert {:ok, %Session{}} =
               BillingPortal.create_session(%{
                 customer: customer,
                 return_url: "https://example.com/account"
               })
    end
  end

  describe "Inspect masking on Session.url" do
    test "url is replaced with a redacted marker", %{customer: customer} do
      {:ok, session} =
        Session.create(%{
          customer: customer,
          return_url: "https://example.com/account"
        })

      assert is_binary(session.url)
      output = inspect(session)
      assert output =~ "redacted"
      refute output =~ session.url
    end
  end

  describe "Portal configuration checklist guide" do
    test "guide file exists and documents the three required Dashboard toggles" do
      path = Path.join([File.cwd!(), "guides", "portal_configuration_checklist.md"])
      assert File.exists?(path)

      content = File.read!(path)
      assert content =~ "at_period_end"
      assert content =~ ~r/retain offers/i
      assert content =~ ~r/cancellation reason/i
    end

    test "lifecycle guide exists and adjacent guides link back to the same cancellation posture" do
      lifecycle_path = Path.join([File.cwd!(), "guides", "lifecycle_semantics.md"])
      checklist_path = Path.join([File.cwd!(), "guides", "portal_configuration_checklist.md"])
      braintree_path = Path.join([File.cwd!(), "guides", "braintree-local-portal.md"])

      assert File.exists?(lifecycle_path)

      lifecycle = File.read!(lifecycle_path)
      checklist = File.read!(checklist_path)
      braintree = File.read!(braintree_path)

      assert lifecycle =~ "cancel_at_period_end"
      assert lifecycle =~ "resume/2"
      assert lifecycle =~ "pause/2"
      assert lifecycle =~ "unpause/2"
      assert lifecycle =~ "active"
      assert lifecycle =~ "canceling"
      assert lifecycle =~ "paused"
      assert lifecycle =~ "past_due"
      assert lifecycle =~ "ended"
      assert lifecycle =~ "host-owned"
      assert lifecycle =~ "Braintree: `native`"
      assert lifecycle =~ "Braintree supports this path through `Accrue.Billing.cancel/2` today."

      assert checklist =~ "lifecycle_semantics.md"
      assert checklist =~ "at_period_end"
      assert checklist =~ "host-owned seam above `Accrue.Billing.cancel/2`"
      assert braintree =~ "lifecycle_semantics.md"
      assert braintree =~ "The supported first-party Braintree cancellation path is immediate"
      assert braintree =~ "`Accrue.Billing.cancel/2`"
      assert braintree =~ ~r/cancel renewal/i
      assert braintree =~ "host-owned policy seam"
      refute braintree =~ "Offer immediate cancellations using Accrue's cancel functions"
      refute braintree =~ "Braintree supports immediate cancellation"
      refute braintree =~ "Braintree supports `cancel_at_period_end/2`"
    end

    test "webhook and operator guides keep the Braintree replay and recovery contract adjacent" do
      webhook_path = Path.join([File.cwd!(), "guides", "webhooks.md"])
      telemetry_path = Path.join([File.cwd!(), "guides", "telemetry.md"])
      runbook_path = Path.join([File.cwd!(), "guides", "operator-runbooks.md"])
      metered_path = Path.join([File.cwd!(), "guides", "braintree-metered-billing.md"])

      webhook = File.read!(webhook_path)
      telemetry = File.read!(telemetry_path)
      runbook = File.read!(runbook_path)
      metered = File.read!(metered_path)

      assert webhook =~ "Braintree"
      assert webhook =~ "mix accrue.webhooks.replay"
      assert webhook =~ "accrue.portal.checkout.completed"

      assert telemetry =~ "accrue.portal.checkout.completed"
      assert telemetry =~ "[:accrue, :ops, :webhook_dlq, :replay]"
      assert telemetry =~ "[:accrue, :ops, :metered_renewal_stale_repaired]"

      assert runbook =~ "accrue.portal.checkout.completed"
      assert runbook =~ "portal_base_url"
      assert runbook =~ "portal_mount_path"
      assert runbook =~ "[:accrue, :ops, :webhook_dlq, :replay]"

      assert metered =~ "awaiting-payment-method"
      assert metered =~ "failed-exhausted"
      assert metered =~ "operator-runbooks.md"
    end
  end
end
