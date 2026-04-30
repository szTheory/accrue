defmodule AccrueAdmin.CustomerLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Billing.{Charge, Customer, Invoice, PaymentMethod, Subscription}
  alias Accrue.Events
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Customers
  alias AccrueAdmin.TestRepo

  import Ecto.Query

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

    blocked_payment_method =
      TestRepo.insert!(
        PaymentMethod.changeset(%PaymentMethod{}, %{
          customer_id: customer.id,
          processor: "braintree",
          processor_id: "pm_blocked",
          type: "card",
          card_brand: "mastercard",
          card_last4: "5454",
          exp_month: 4,
          exp_year: 2034
        })
      )

    Fake.scripted_response(:retrieve_payment_method, {:ok, scripted_pm("pm_9999", "9999")})
    Fake.scripted_response(:attach_payment_method, {:ok, scripted_pm("pm_9999", "9999")})
    Fake.scripted_response(:detach_payment_method, {:ok, scripted_pm("pm_9999", "9999")})
    {:ok, deletable_payment_method} = Billing.attach_payment_method(customer, "pm_9999")

    subscription =
      subscription
      |> Subscription.changeset(%{
        processor: "braintree",
        data: Map.put(subscription.data || %{}, "payment_method_token", blocked_payment_method.processor_id)
      })
      |> TestRepo.update!()

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

    {:ok,
     customer: customer,
     blocked_payment_method: blocked_payment_method,
     default_payment_method: payment_method,
     deletable_payment_method: deletable_payment_method}
  end

  test "renders customer tabs for subscriptions, events, and metadata", %{
    conn: conn,
    customer: customer
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/customers/#{customer.id}")
    # UX-02: single ax-page shell on customer detail
    assert Regex.scan(~r/class="ax-page"/, html) |> length() == 1
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

    assert %{"error" => denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert denied == Copy.Locked.owner_access_denied()

    assert redirect
  end

  test "invoices tab links invoice identifiers to scoped invoice detail", %{
    conn: conn,
    customer: customer
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    invoice =
      TestRepo.one!(
        from(i in Invoice,
          where: i.customer_id == ^customer.id,
          order_by: [desc: i.id],
          limit: 1,
          select: i
        )
      )

    assert {:ok, _view, html} = live(conn, "/billing/customers/#{customer.id}?tab=invoices")

    assert html =~ ~s(href="/billing/invoices/#{invoice.id}")
    assert html =~ "INV-001"
  end

  test "shows Copy-backed empty invoices line when customer has no invoices", %{conn: conn} do
    %{customer: bare_customer} = Factory.customer(%{email: "bare-invoices@example.com"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{bare_customer.id}?tab=invoices")

    assert html =~ "No invoices for this customer yet."
    assert html =~ Copy.customer_detail_no_invoices()
  end

  test "payment_methods tab shows Copy-backed heading and fixture card last4", %{
    conn: conn,
    customer: customer
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=payment_methods")

    assert html =~ Copy.customer_payment_methods_section_heading()
    assert html =~ Copy.customer_payment_methods_card_last4_mask()
    assert html =~ "4242"
    assert html =~ "visa"
  end

  test "payment_methods tab exposes only server-driven operator controls and host-handoff copy", %{
    conn: conn,
    customer: customer,
    deletable_payment_method: deletable_payment_method
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=payment_methods")

    assert html =~ "Sync payment methods"
    assert html =~ "Set default payment method"
    assert html =~ "Delete payment method"
    assert html =~ "Replace payment method in host billing"
    refute html =~ "Card number"
    refute html =~ "Drop-in"
    refute html =~ "Hosted Fields"

    html =
      render_click(
        element(
          view,
          "[data-role='prepare-delete-payment-method'][data-payment-method-id='#{deletable_payment_method.id}']"
        )
      )

    assert html =~ Copy.customer_payment_methods_cancel_action()
  end

  test "payment_methods tab runs set default and sync through LiveView events", %{
    conn: conn,
    customer: customer,
    deletable_payment_method: payment_method
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/customers/#{customer.id}?tab=payment_methods")

    html =
      render_click(
        element(
          view,
          "[data-role='set-default-payment-method'][data-payment-method-id='#{payment_method.id}']"
        )
      )

    assert html =~ "Default payment method updated."
    assert TestRepo.get!(Customer, customer.id).default_payment_method_id == payment_method.id

    html = render_click(element(view, "[data-role='sync-payment-methods']"))

    assert html =~ "Payment methods synced."
  end

  test "payment_methods tab shows guarded delete states and only confirms safe deletes", %{
    conn: conn,
    customer: customer,
    blocked_payment_method: blocked_payment_method,
    deletable_payment_method: deletable_payment_method
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/customers/#{customer.id}?tab=payment_methods")

    html =
      render_click(
        element(
          view,
          "[data-role='prepare-delete-payment-method'][data-payment-method-id='#{blocked_payment_method.id}']"
        )
      )

    assert html =~ "This payment method still funds an active subscription."
    refute html =~ ~s(data-role="confirm-delete-payment-method")

    html =
      render_click(
        element(
          view,
          "[data-role='prepare-delete-payment-method'][data-payment-method-id='#{deletable_payment_method.id}']"
        )
      )

    assert html =~ "Delete payment method"
    assert html =~ "Review dependencies before you continue."

    html = render_click(element(view, "[data-role='confirm-delete-payment-method']"))

    assert html =~ "Payment method deleted."
    refute has_element?(
             view,
             "[data-role='prepare-delete-payment-method'][data-payment-method-id='#{deletable_payment_method.id}']"
           )
    assert TestRepo.get(PaymentMethod, deletable_payment_method.id) == nil
  end

  test "payment_methods tab empty state uses Copy when customer has no payment methods", %{
    conn: conn
  } do
    %{customer: bare_customer} = Factory.customer(%{email: "bare-pm@example.com"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{bare_customer.id}?tab=payment_methods")

    assert html =~ Copy.customer_payment_methods_empty_copy()
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

  defp scripted_pm(id, last4) do
    %{
      id: id,
      object: "payment_method",
      type: "card",
      card: %{
        fingerprint: "fp_" <> last4,
        brand: "discover",
        last4: last4,
        exp_month: 8,
        exp_year: 2036
      },
      customer: nil
    }
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
