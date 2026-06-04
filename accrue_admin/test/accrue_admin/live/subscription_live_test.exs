defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Subscriptions
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

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify admin action"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, action) do
      case Application.get_env(:accrue_admin, :expected_step_up_subject_id) do
        nil -> :ok
        expected when action.subject_id == expected -> :ok
        _expected -> {:error, :wrong_subject_id}
      end
    end

    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)
    end)

    %{subscription: subscription} =
      Factory.active_subscription(%{owner_id: "subscription-detail"})

    subscription =
      subscription
      |> Subscription.changeset(%{automatic_tax_disabled_reason: "requires_location_inputs"})
      |> TestRepo.update!()

    {:ok, source_event} =
      Events.record(%{
        type: "invoice.payment_failed",
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system"
      })

    {:ok,
     subscription: Repo.preload(subscription, [:customer, :subscription_items]),
     source_event: source_event}
  end

  test "renders RelatedResources card with customer and events links", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related")
    # Customer link in related resources
    assert html =~ "/billing/customers/#{subscription.customer_id}"
    # Invoices filtered by subscription_id in related resources
    assert html =~ "subscription_id=#{subscription.id}"
    # Events filtered by Subscription subject in related resources
    assert html =~ "subject_type=Subscription"
    assert html =~ "subject_id=#{subscription.id}"
  end

  test "renders canonical predicate summary and subscription timeline", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    # UX-02: one outer ax-page only (Regex counts HEEx class="ax-page" occurrences in rendered HTML)
    assert Regex.scan(~r/class="ax-page"/, html) |> length() == 1

    assert html =~ "Tax &amp; ownership"
    assert html =~ "Canonical predicates"
    assert html =~ "active"
    assert html =~ "invoice.payment_failed"
    assert html =~ "Automatic tax is currently disabled"
    assert html =~ "Local reason: Requires Location Inputs."
    assert html =~ "Default to cancel renewal and keep access through the paid-through date."
    assert html =~ "Use Cancel now only for explicit hard-stop, support-led, or compliance flows."
    assert html =~ "Stripe can natively schedule end-of-period cancellation"

    assert html =~
             "Stripe and Fake support preview-backed plan swaps plus operator-managed quantity and subscription-item changes"

    assert html =~
             "Update the customer tax location in the host app, then retry recurring tax on this subscription."
  end

  test "stages preview-backed swap-plan confirmation and exposes supported quantity and item actions",
       %{
         conn: conn,
         subscription: subscription
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert has_element?(view, "[data-role='swap-plan-form']")
    assert has_element?(view, "[data-role='quantity-update-form']")
    assert has_element?(view, "[data-role='item-add-form']")
    assert has_element?(view, "[data-role='item-quantity-form']")
    assert has_element?(view, "[data-role='item-remove-form']")
    assert html =~ "Quantity changes apply to the single-item subscription lane."

    html =
      render_submit(element(view, "[data-role='swap-plan-form']"), %{
        "action_type" => "swap_plan",
        "new_price_id" => "price_pro",
        "proration" => "create_prorations"
      })

    assert html =~
             "Swap plan stages a preview before commit where the provider supports upcoming-invoice previews."

    assert html =~ "Preview upcoming invoice"
    assert html =~ "Preview total"
    assert html =~ "preview line(s) captured before commit."
  end

  test "cancel now requires step-up and records admin audit linkage", %{
    conn: conn,
    subscription: subscription,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, subscription.id)

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    html =
      render_submit(
        element(view, "[data-role='cancel-now-form']"),
        %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
      )

    assert html =~ "Confirm action"

    html = render_click(element(view, "[data-role='confirm-action']"))
    assert html =~ "Step-up required"

    html =
      render_submit(element(view, "form[phx-submit='step_up_submit']"), %{"code" => "123456"})

    assert html =~ Copy.subscription_action_recorded_info()

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.subscription.action.completed" and
              event.caused_by_event_id == ^source_event.id
        )
      )

    assert audit_event.actor_type == "admin"

    canceled = TestRepo.get!(Subscription, subscription.id)
    assert Accrue.Billing.Subscription.canceled?(canceled)
  end

  test "subscription loader denies rows outside the active organization" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_subscription = insert_subscription(allowed_customer)
    denied_subscription = insert_subscription(denied_customer)
    allowed_subscription_id = allowed_subscription.id

    owner_scope = organization_owner_scope("org_allowed")

    assert {:ok, %{id: ^allowed_subscription_id}} =
             Subscriptions.detail(allowed_subscription.id, owner_scope)

    assert :not_found = Subscriptions.detail(denied_subscription.id, owner_scope)
  end

  test "drill breadcrumbs and related links use ScopedPath with org scope and honest customer_id filters",
       %{conn: conn} do
    org_id = Ecto.UUID.generate()

    %{customer: customer, subscription: subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: org_id,
        email: "phase49-drill-admin@example.com"
      })

    subscription = Repo.preload(subscription, [:customer, :subscription_items])

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "phase49-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} =
             live(conn, "/billing/subscriptions/#{subscription.id}?org=phase49-org")

    assert html =~ "/customers/#{customer.id}"
    assert html =~ "org="
    assert html =~ "customer_id=#{customer.id}"
    assert html =~ Copy.subscription_drill_related_card_title()
    assert html =~ "/events"
  end

  test "out-of-scope subscription route redirects with denial flash before rendering detail", %{
    conn: conn
  } do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_subscription = insert_subscription(allowed_customer)
    denied_subscription = insert_subscription(denied_customer)

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: "org_allowed",
        active_organization_slug: "allowed-org",
        admin_organization_ids: ["org_allowed"]
      )

    assert {:ok, _view, allowed_html} =
             live(conn, "/billing/subscriptions/#{allowed_subscription.id}?org=allowed-org")

    assert allowed_html =~ allowed_subscription.processor_id

    assert {:error,
            {:redirect, %{to: "/billing/subscriptions?org=allowed-org", flash: flash_token}}} =
             redirect =
             live(conn, "/billing/subscriptions/#{denied_subscription.id}?org=allowed-org")

    assert %{"error" => denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert denied == Copy.Locked.owner_access_denied()

    assert redirect
  end

  test "renders provider-honest confirmation copy for cancel now and cancel at period end", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    html =
      render_submit(element(view, "[data-role='cancel-now-form']"), %{
        "action_type" => "cancel_now"
      })

    assert html =~ "Cancel now will execute against the local billing projection"

    html =
      render_submit(
        element(view, "[data-role='cancel-at-period-end-form']"),
        %{"action_type" => "cancel_at_period_end"}
      )

    assert html =~ "turn off renewal now and preserve access through the current billing period"
  end

  test "renders explicit Braintree action boundaries for immediate versus scheduled cancellation",
       %{
         conn: conn
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    customer =
      insert_customer(%{
        owner_id: "subscription-detail-braintree",
        processor: "braintree",
        processor_id: "cus_bt_admin_detail"
      })

    subscription =
      insert_subscription(customer, %{
        processor: "braintree",
        processor_id: "sub_bt_admin_detail",
        current_period_start: DateTime.add(DateTime.utc_now(), -86_400, :second),
        current_period_end: DateTime.add(DateTime.utc_now(), 2_592_000, :second)
      })

    {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Cancel now"
    refute html =~ "Cancel at period end"
    refute html =~ "Pause collection"
    refute html =~ "Resume"
    assert has_element?(view, "[data-role='cancel-now-form']")
    refute has_element?(view, "[data-role='cancel-at-period-end-form']")
    refute has_element?(view, "[data-role='pause-form']")
    refute has_element?(view, "[data-role='resume-form']")
    refute has_element?(view, "[data-role='swap-plan-form']")
    refute has_element?(view, "[data-role='quantity-update-form']")
    refute has_element?(view, "[data-role='item-add-form']")
    refute has_element?(view, "[data-role='item-quantity-form']")
    refute has_element?(view, "[data-role='item-remove-form']")
    assert has_element?(view, "[data-role='swap-plan-unavailable']")
    assert has_element?(view, "[data-role='quantity-item-unsupported']")

    assert html =~
             "Braintree supports immediate cancellation through Accrue.Billing.cancel/2 and bounded first-party plan swaps when the host configures :plan_resolver."

    assert html =~ "Preview is unavailable for this provider"

    assert html =~
             "Configure :plan_resolver before exposing Braintree swap_plan/3 through admin."

    assert html =~
             "Braintree does not expose first-party quantity or subscription-item mutations through Accrue."
  end

  describe "read-only dunning-state panel (DUN-07)" do
    test "always renders the dunning-state panel as a state surface", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      assert has_element?(view, "[data-role='subscription-dunning-state']")
      assert html =~ Copy.dunning_panel_title()
      assert html =~ Copy.dunning_panel_eyebrow()
    end

    test "the dunning-state panel is strictly read-only (no mutating controls)", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      refute has_element?(view, "[data-role='subscription-dunning-state'] button")
      refute has_element?(view, "[data-role='subscription-dunning-state'] form")
      refute has_element?(view, "[data-role='subscription-dunning-state'] [phx-click]")
      refute has_element?(view, "[data-role='subscription-dunning-state'] [phx-submit]")
    end

    test "active campaign shows the active badge and a resolver-derived next action", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      active =
        subscription
        |> Subscription.changeset(%{dunning_campaign_started_at: DateTime.utc_now()})
        |> TestRepo.update!()

      assert Subscription.dunning_campaign_active?(active)

      {:ok, _view, html} = live(conn, "/billing/subscriptions/#{active.id}")

      assert html =~ Copy.dunning_state_active()
      assert html =~ Copy.dunning_next_action_label()
      # Day-0 active campaign resolves the first configured step (key surfaced).
      assert html =~ "reminder"
      refute html =~ Copy.dunning_empty_state_body()
    end

    test "subscription with no campaign renders the empty-state body", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      refute Subscription.dunning_campaign_active?(subscription)

      {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      assert has_element?(view, "[data-role='subscription-dunning-state']")
      assert html =~ Copy.dunning_empty_state_body()
      assert html =~ Copy.dunning_state_none()
    end

    test "every visible panel string routes through Copy (Started + Next scheduled action)", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      assert html =~ Copy.dunning_started_label()
      assert html =~ Copy.dunning_next_action_label()
    end
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "fake",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer) do
    insert_subscription(customer, %{})
  end

  defp insert_subscription(customer, attrs) do
    %Subscription{}
    |> Subscription.changeset(
      Map.merge(
        %{
          customer_id: customer.id,
          processor: customer.processor || "fake",
          processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
          status: :active,
          currency: "usd"
        },
        attrs
      )
    )
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
