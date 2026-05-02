defmodule Accrue.Processor.BraintreeLocalPortalTest do
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.Customer
  alias Accrue.BillingPortal.Session, as: BillingPortalSession
  alias Accrue.Checkout.LocalSession
  alias Accrue.Checkout.Session, as: CheckoutSession

  setup do
    previous_processor = Application.get_env(:accrue, :processor)
    previous_mount_path = Application.get_env(:accrue, :portal_mount_path)
    previous_base_url = Application.get_env(:accrue, :portal_base_url)

    Application.put_env(:accrue, :processor, Accrue.Processor.Braintree)
    Application.put_env(:accrue, :portal_mount_path, "/billing")
    Application.put_env(:accrue, :portal_base_url, "https://app.example.test")

    on_exit(fn ->
      if previous_processor do
        Application.put_env(:accrue, :processor, previous_processor)
      else
        Application.delete_env(:accrue, :processor)
      end

      if previous_mount_path do
        Application.put_env(:accrue, :portal_mount_path, previous_mount_path)
      else
        Application.delete_env(:accrue, :portal_mount_path)
      end

      if previous_base_url do
        Application.put_env(:accrue, :portal_base_url, previous_base_url)
      else
        Application.delete_env(:accrue, :portal_base_url)
      end
    end)

    :ok
  end

  test "create_checkout_session/2 persists and reuses local Braintree checkout sessions" do
    customer = insert_braintree_customer()

    assert {:ok, session} =
             CheckoutSession.create(
               customer: customer,
               line_items: [%{"price" => "plan_pro"}],
               success_url: "/after-checkout",
               operation_id: "checkout-op-1"
             )

    persisted = LocalSession.by_id(session.id)

    assert persisted.price_id == "plan_pro"
    assert persisted.success_url == "/after-checkout"
    assert session.url == "https://app.example.test/billing/checkout/" <> persisted.session_token

    assert {:ok, same_session} =
             CheckoutSession.create(
               customer: customer,
               line_items: [%{"price" => "plan_pro"}],
               operation_id: "checkout-op-1"
             )

    assert same_session.id == session.id

    assert {:ok, fetched} = CheckoutSession.retrieve(session.id)
    assert fetched.id == session.id
    assert fetched.url == session.url
  end

  test "create_billing_portal_session/2 returns the local portal URL for Braintree" do
    customer = insert_braintree_customer()

    assert {:ok, portal_session} =
             BillingPortalSession.create(customer: customer, return_url: "/settings/billing")

    assert portal_session.url ==
             "https://app.example.test/billing?return_url=%2Fsettings%2Fbilling"

    assert portal_session.customer == customer.processor_id
  end

  defp insert_braintree_customer do
    %Customer{}
    |> Customer.changeset(%{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "braintree",
      processor_id: "cus_bt_local_123",
      email: "portal@example.com"
    })
    |> Repo.insert!()
  end
end
