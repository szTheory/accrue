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

  describe "Inspect masking on Session.url (T-04-07-01)" do
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

  describe "Portal configuration checklist guide (CHKT-05)" do
    test "guide file exists and documents the three required Dashboard toggles" do
      path = Path.join([File.cwd!(), "guides", "portal_configuration_checklist.md"])
      assert File.exists?(path)

      content = File.read!(path)
      assert content =~ "at_period_end"
      assert content =~ ~r/retain offers/i
      assert content =~ ~r/cancellation reason/i
    end
  end
end
