defmodule AccrueAdmin.CustomerLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod}
  alias Accrue.Events
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.TestRepo

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    %{customer: customer} =
      Factory.customer(%{email: "detail@example.com", metadata: %{"segment" => "enterprise"}})

    {:ok, subscription} = Billing.subscribe(customer, "price_basic")

    {:ok, _stripe_subscription} =
      Fake.transition(subscription.processor_id, :active, synthesize_webhooks: false)

    subscription = TestRepo.get!(Accrue.Billing.Subscription, subscription.id)

    payment_method =
      TestRepo.insert!(
        PaymentMethod.changeset(%PaymentMethod{}, %{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "pm_detail",
          type: "card",
          card_brand: "visa",
          card_last4: "4242",
          exp_month: 1,
          exp_year: 2032
        })
      )

    customer =
      customer
      |> Customer.changeset(%{
        name: "Detail Customer",
        default_payment_method_id: payment_method.id,
        preferred_locale: "en",
        preferred_timezone: "America/New_York",
        metadata: %{"segment" => "enterprise"}
      })
      |> TestRepo.update!()

    TestRepo.insert!(
      Invoice.changeset(%Invoice{}, %{
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor: "fake",
        processor_id: "in_detail",
        status: :open,
        currency: "usd",
        amount_remaining_minor: 7_500,
        number: "INV-001"
      })
    )

    TestRepo.insert!(
      Charge.changeset(%Charge{}, %{
        customer_id: customer.id,
        subscription_id: subscription.id,
        payment_method_id: payment_method.id,
        processor: "fake",
        processor_id: "ch_detail",
        amount_cents: 7_500,
        currency: "usd",
        status: "succeeded"
      })
    )

    {:ok, _event} =
      Events.record(%{
        type: "customer.updated",
        subject_type: "Customer",
        subject_id: customer.id,
        actor_type: "admin",
        actor_id: "admin_1"
      })

    {:ok, customer: customer}
  end

  test "renders customer tabs for subscriptions, events, and metadata", %{
    conn: conn,
    customer: customer
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/customers/#{customer.id}")
    assert html =~ "Detail Customer"
    assert html =~ "Subscriptions"
    assert html =~ "locale en"

    assert {:ok, _view, events_html} = live(conn, "/billing/customers/#{customer.id}?tab=events")
    assert events_html =~ "customer.updated"

    assert {:ok, _view, metadata_html} =
             live(conn, "/billing/customers/#{customer.id}?tab=metadata")

    assert metadata_html =~ "enterprise"
    assert metadata_html =~ "preferred_timezone"
  end
end
