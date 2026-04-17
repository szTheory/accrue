defmodule AccrueAdmin.CustomerLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod}
  alias Accrue.Events
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Customers
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

    subscription =
      subscription.id
      |> then(&TestRepo.get!(Accrue.Billing.Subscription, &1))
      |> Accrue.Billing.Subscription.changeset(%{
        automatic_tax_disabled_reason: "requires_location_inputs"
      })
      |> TestRepo.update!()

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
        number: "INV-001",
        automatic_tax_disabled_reason: "finalization_requires_location_inputs",
        last_finalization_error_code: "customer_tax_location_invalid"
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
    assert html =~ "Tax &amp; ownership"
    assert html =~ "Subscriptions"
    assert html =~ "locale en"
    assert html =~ "Tax risk"
    assert html =~ "Tax risk detected"
    assert html =~ "1 subscription needs attention"
    assert html =~ "1 invoice needs attention"

    assert {:ok, _view, events_html} = live(conn, "/billing/customers/#{customer.id}?tab=events")
    assert events_html =~ "customer.updated"

    assert {:ok, _view, metadata_html} =
             live(conn, "/billing/customers/#{customer.id}?tab=metadata")

    assert metadata_html =~ "enterprise"
    assert metadata_html =~ "preferred_timezone"
  end

  test "customer loader denies rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_customer_id = allowed_customer.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^allowed_customer_id}} = Customers.detail(allowed_customer.id, owner_scope)
    assert :not_found = Customers.detail(denied_customer.id, owner_scope)
  end

  test "out-of-scope customer route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        active_organization_name: "Allowed Org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/customers/#{allowed_customer.id}?org=allowed-org")

    assert allowed_html =~ "Active organization"
    assert allowed_html =~ "Allowed Org"
    assert allowed_html =~ allowed_customer.id

    assert {:error, {:redirect, %{to: "/billing/customers?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/customers/#{denied_customer.id}?org=allowed-org")

    assert %{"error" => "You don't have access to billing for this organization."} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert redirect
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      metadata: %{},
      data: %{},
      preferred_locale: "en"
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      organization_display_name: "Allowed Org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
