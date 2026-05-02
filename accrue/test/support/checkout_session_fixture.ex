defmodule Accrue.Test.CheckoutSessionFixture do
  @moduledoc false

  alias Accrue.Billing.Customer
  alias Accrue.Checkout.LocalSession
  alias Accrue.TestRepo, as: Repo

  def build_customer(attrs \\ %{}) do
    attrs =
      Map.merge(
        %{
          owner_type: "User",
          owner_id: Ecto.UUID.generate(),
          processor: "braintree",
          processor_id:
            "cus_bt_fixture_" <> Integer.to_string(System.unique_integer([:positive])),
          email: "portal-fixture@example.com"
        },
        attrs
      )

    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert!()
  end

  def local_session_fixture(customer, attrs \\ %{}) do
    attrs = local_session_attrs(attrs)

    {:ok, session} = LocalSession.create_or_reuse(customer, attrs)
    session
  end

  def local_session_attrs(attrs \\ %{}) do
    Map.merge(
      %{
        processor: "braintree",
        mode: "subscription",
        ui_mode: "hosted",
        status: "open",
        price_id: "price_fixture",
        line_items: [%{"price" => "price_fixture"}],
        success_url: "https://app.example.test/billing/success",
        cancel_url: "https://app.example.test/billing/cancel",
        return_url: "https://app.example.test/settings/billing",
        operation_id:
          "checkout-fixture-" <> Integer.to_string(System.unique_integer([:positive])),
        metadata: %{"source" => "fixture"},
        data: %{"local_portal" => true}
      },
      attrs
    )
  end
end
