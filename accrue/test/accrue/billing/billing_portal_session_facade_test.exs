defmodule Accrue.Billing.BillingPortalSessionFacadeTest do
  @moduledoc false

  use Accrue.BillingCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.Customer
  alias Accrue.BillingPortal.Session
  alias Accrue.Processor.Fake

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_portal_facade",
        email: "portal-facade@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "create_billing_portal_session/2" do
    test "happy path returns Fake session", %{customer: customer} do
      assert {:ok, %Session{} = session} =
               Billing.create_billing_portal_session(customer,
                 return_url: "https://example.com/return",
                 configuration: "bpc_test_facade"
               )

      assert String.starts_with?(session.id, "bps_fake_")
    end

    test "failure path respects Fake.scripted_response/2", %{customer: customer} do
      err = %Accrue.APIError{code: "portal_rejected", http_status: 400, message: "nope"}

      :ok =
        Fake.scripted_response(:portal_session_create, {:error, err})

      assert {:error, %Accrue.APIError{code: "portal_rejected"}} =
               Billing.create_billing_portal_session(customer, return_url: "https://x.test")
    end

    test "telemetry metadata excludes portal URL and sets operation", %{customer: customer} do
      handler_id = "billing_portal_facade_test_#{:erlang.unique_integer([:positive])}"
      parent = self()

      :ok =
        :telemetry.attach(
          handler_id,
          [:accrue, :billing, :billing_portal, :create, :start],
          fn _event, _measurements, metadata, _config ->
            send(parent, {:telemetry_start, metadata})
          end,
          nil
        )

      try do
        assert {:ok, %Session{}} =
                 Billing.create_billing_portal_session(customer,
                   return_url: "https://example.com/return",
                   configuration: "bpc_test_facade"
                 )

        assert_receive {:telemetry_start, metadata}
        assert metadata[:operation] == "billing_portal.create"

        refute String.contains?(
                 inspect(metadata),
                 "https://billing.stripe.test/p/session/"
               )
      after
        :telemetry.detach(handler_id)
      end
    end
  end

  describe "create_billing_portal_session!/2" do
    test "accepts a map of attrs", %{customer: customer} do
      session =
        Billing.create_billing_portal_session!(customer, %{
          return_url: "https://example.com/r2"
        })

      assert %Session{} = session
      assert String.starts_with?(session.id, "bps_fake_")
    end
  end
end
