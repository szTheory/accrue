defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
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

  test "renders the six-band detail structure with one related resources strip", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert page_wrapper_count(html) == 1
    assert heading_count(html, "h1") == 1

    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-action-band") == 1
    assert data_attr_count(html, "data-ax-primary-action") <= 2
    assert data_attr_count(html, "data-ax-action-overflow-menu") >= 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1
    assert data_attr_count(html, "data-ax-drill-section") >= 3

    refute has_element?(view, "[data-ax-action-band] form")
    refute has_element?(view, "[data-role='subscription-related-billing']")
    refute has_element?(view, "[data-role='subscription-dunning-state']")
    refute has_element?(view, "[data-role='confirm-panel']")
    refute html =~ ~s(class="ax-kpi-grid")
    refute html =~ Copy.subscription_kpi_canonical_predicates_label()

    assert html =~ "/billing/customers/#{subscription.customer_id}"
    assert html =~ "subscription_id=#{subscription.id}"
    assert html =~ "subject_type=Subscription"
    assert html =~ "subject_id=#{subscription.id}"
    assert html =~ "Subscription events"
    assert html =~ "Subscription invoice queue"
    assert html =~ "Work the open-invoice queue filtered to this subscription"
    assert html =~ "Debug this subscription&#39;s failed webhooks"
    assert html =~ "failed/dead subscription.created deliveries"
    assert html =~ "Open failed-webhook debugger"
    assert html =~ "Open queue"
    assert html =~ "Open full audit event log"
  end

  test "summary and drill bands replace page-level KPI and predicate noise", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Billing &amp; items"
    assert html =~ "Dunning &amp; recovery"
    assert html =~ "Tax &amp; compliance"
    assert html =~ "invoice.payment_failed"
    assert html =~ "Billing health summary"
    assert html =~ "Not healthy yet"
    assert html =~ "ax-detail-health-summary-amber"
    assert html =~ "ax-detail-health-answer"
    assert html =~ "No - billing is not healthy until setup is complete"
    assert html =~ "Billing is not healthy until setup is complete"
    assert html =~ "Billing health verdict"
    assert html =~ "MRR"
    assert html =~ "Amount is not confirmed in admin"
    assert html =~ "missing setup details"
    assert html =~ "Resolve missing billing setup"
    assert html =~ "Open customer billing profile"
    assert html =~ "Review setup audit events"
    assert html =~ "Watch dunning funnel and at-risk accounts"
    assert html =~ "Open this subscription invoice queue"
    refute html =~ "Work global invoice queue to zero"
    assert html =~ "Open this subscription&#39;s invoice queue"
    assert html =~ "Open audit event log"
    assert html =~ "Who did what, when"
    assert html =~ "Latest audit event summary"
    assert html =~ "Actor"
    assert html =~ "Open full audit event log"
    refute html =~ ">Unknown<"

    refute html =~ Copy.subscription_kpi_status_label() <> "</"
    refute html =~ Copy.subscription_kpi_canonical_predicates_label()
    refute html =~ Copy.subscription_kpi_timeline_rows_label()
    refute html =~ Copy.dunning_panel_title()
    refute html =~ "Default to cancel renewal and keep access through the paid-through date."
    refute html =~ "Use Cancel now only for explicit hard-stop, support-led, or compliance flows."

    refute html =~
             "Update the customer tax location in the host app, then retry recurring tax on this subscription."
  end

  test "renders default action hierarchy with two primary actions and grouped overflow",
       %{
         conn: conn,
         subscription: subscription
       } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")
    subscription_label = subscription.processor_id || subscription.id

    assert data_attr_count(html, "data-ax-primary-action") == 2
    assert data_attr_count(html, "data-ax-action-overflow-menu") == 1

    assert has_element?(view, "[data-ax-primary-action]", "Change plan")
    assert has_element?(view, "[data-ax-primary-action]", "Cancel renewal")
    refute has_element?(view, "[data-ax-primary-action]", "Cancel immediately")
    refute has_element?(view, "[data-ax-primary-action]", "Comp this subscription")

    assert html =~ "Edit billing"
    assert html =~ "Collection"
    assert html =~ "Danger zone"
    assert html =~ "Cancel immediately"
    assert html =~ "Comp this subscription"

    assert_text_order(html, [
      "Edit billing",
      AccrueAdmin.Copy.Subscription.subscription_action_update_quantity(),
      AccrueAdmin.Copy.Subscription.subscription_action_add_item(),
      AccrueAdmin.Copy.Subscription.subscription_action_update_item_quantity(),
      AccrueAdmin.Copy.Subscription.subscription_action_remove_item(),
      "Collection",
      AccrueAdmin.Copy.Subscription.subscription_action_pause_collection(),
      AccrueAdmin.Copy.Subscription.subscription_action_resume(),
      "Danger zone",
      "Cancel immediately",
      "Comp this subscription"
    ])

    assert html =~ ~s(aria-label="Change plan for subscription #{subscription_label}")
    assert html =~ ~s(aria-label="Cancel renewal for subscription #{subscription_label}")
  end

  test "drawer-hosted destructive action preserves step-up and records admin audit linkage", %{
    conn: conn,
    subscription: subscription,
    source_event: source_event
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, subscription.id)

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
           )

    html =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
        ),
        %{"action_type" => "cancel_now", "source_event_id" => Integer.to_string(source_event.id)}
      )

    assert html =~ "Confirm action"

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='confirm-action']"
           )

    html =
      render_click(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='confirm-action']"
        )
      )

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

  test "drawer-hosted item removal requires step-up before deleting the item", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    item = List.first(subscription.subscription_items)
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, subscription.id)

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Remove item"))

    html =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
        ),
        %{
          "action_type" => "remove_item",
          "item_id" => item.id,
          "proration" => "create_prorations"
        }
      )

    assert html =~ "Confirm action"

    html =
      render_click(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='confirm-action']"
        )
      )

    assert html =~ "Step-up required"
    assert TestRepo.get!(SubscriptionItem, item.id)
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

  test "safe action selection opens drawer-hosted form and keeps confirm_action confirmation", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "[data-ax-primary-action]", "Change plan"))

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
           )

    html =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
        ),
        %{
          "action_type" => "swap_plan",
          "new_price_id" => "price_pro",
          "proration" => "create_prorations"
        }
      )

    assert html =~
             "Swap plan stages a preview before commit where the provider supports upcoming-invoice previews."

    assert html =~ "Preview upcoming invoice"
    assert html =~ "Preview total"
    assert html =~ "preview line(s) captured before commit."

    assert has_element?(
             view,
             "[data-ax-overlay-panel][data-presentation='drawer'] [data-role='confirm-action']"
           )
  end

  test "crafted supported action params are rejected before staging", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    item = List.first(subscription.subscription_items)

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    malformed_payloads = [
      %{
        "action_type" => "swap_plan",
        "new_price_id" => ["price_pro"],
        "proration" => "create_prorations"
      },
      %{
        "action_type" => "swap_plan",
        "new_price_id" => "price_pro",
        "proration" => "invalid"
      },
      %{
        "action_type" => "swap_plan",
        "new_price_id" => "price_pro",
        "proration" => ["create_prorations"]
      },
      %{"action_type" => "pause", "pause_behavior" => "invalid"},
      %{"action_type" => "pause", "pause_behavior" => ["void"]},
      %{
        "action_type" => "remove_item",
        "item_id" => [item.id],
        "proration" => "create_prorations"
      },
      %{
        "action_type" => "add_item",
        "new_price_id" => %{"id" => "price_addon"},
        "new_quantity" => "1",
        "proration" => "create_prorations"
      }
    ]

    for params <- malformed_payloads do
      html = render_submit(view, "prepare_action", params)

      refute html =~ "Confirm action"
      refute html =~ ~s(data-role="confirm-action")
      refute html =~ ~s(data-ax-action-drawer-form)
    end

    assert TestRepo.get!(SubscriptionItem, item.id)
  end

  test "subscription action relabels route through Copy and exported fixture" do
    labels = %{
      "subscription_action_swap_plan" => "Change plan",
      "subscription_action_cancel_at_period_end" => "Cancel renewal",
      "subscription_action_cancel_now" => "Cancel immediately",
      "subscription_action_resume" => "Resume",
      "subscription_action_update_quantity" => "Update quantity",
      "subscription_action_add_item" => "Add item",
      "subscription_action_update_item_quantity" => "Update item quantity",
      "subscription_action_remove_item" => "Remove item",
      "subscription_action_pause_collection" => "Pause collection",
      "subscription_action_create_comp_replacement" => "Comp this subscription"
    }

    fixture = copy_fixture()

    for {function_name, expected} <- labels do
      function = String.to_existing_atom(function_name)

      assert apply(Copy, function, []) == expected
      assert fixture[function_name] == expected
    end
  end

  test "copy fixture exposes all drawer action labels for browser anti-drift checks" do
    fixture = copy_fixture()

    expected = %{
      "subscription_action_swap_plan" => Copy.subscription_action_swap_plan(),
      "subscription_action_cancel_at_period_end" =>
        Copy.subscription_action_cancel_at_period_end(),
      "subscription_action_cancel_now" => Copy.subscription_action_cancel_now(),
      "subscription_action_resume" => Copy.subscription_action_resume(),
      "subscription_action_update_quantity" => Copy.subscription_action_update_quantity(),
      "subscription_action_add_item" => Copy.subscription_action_add_item(),
      "subscription_action_update_item_quantity" =>
        Copy.subscription_action_update_item_quantity(),
      "subscription_action_remove_item" => Copy.subscription_action_remove_item(),
      "subscription_action_pause_collection" => Copy.subscription_action_pause_collection(),
      "subscription_proration_none" => Copy.subscription_proration_none(),
      "subscription_proration_always_invoice" => Copy.subscription_proration_always_invoice(),
      "subscription_action_create_comp_replacement" =>
        Copy.subscription_action_create_comp_replacement(),
      "subscription_action_default_guidance" => Copy.subscription_action_default_guidance(),
      "subscription_action_exception_guidance" => Copy.subscription_action_exception_guidance(),
      "subscription_action_braintree_guidance" => Copy.subscription_action_braintree_guidance(),
      "subscription_action_braintree_swap_setup_guidance" =>
        Copy.subscription_action_braintree_swap_setup_guidance(),
      "subscription_action_braintree_quantity_item_guidance" =>
        Copy.subscription_action_braintree_quantity_item_guidance(),
      "subscription_action_stripe_guidance" => Copy.subscription_action_stripe_guidance(),
      "subscription_action_supported_change_guidance" =>
        Copy.subscription_action_supported_change_guidance(),
      "subscription_action_preview_heading" => Copy.subscription_action_preview_heading(),
      "subscription_action_preview_total_label" => Copy.subscription_action_preview_total_label(),
      "subscription_action_item_id_label" => Copy.subscription_action_item_id_label(),
      "subscription_action_quantity_label" => Copy.subscription_action_quantity_label(),
      "subscription_action_single_item_quantity_guidance" =>
        Copy.subscription_action_single_item_quantity_guidance()
    }

    assert Map.take(fixture, Map.keys(expected)) == expected
  end

  test "cancel renewal action still renders provider-honest confirmation copy in the drawer", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "[data-ax-primary-action]", "Cancel renewal"))

    html =
      render_submit(
        element(
          view,
          "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
        ),
        %{
          "action_type" => "cancel_at_period_end"
        }
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

    assert data_attr_count(html, "data-ax-action-overflow-menu") == 1
    assert html =~ "Cancel immediately"
    assert html =~ "Danger zone"

    refute has_element?(view, "[data-ax-primary-action]", "Cancel renewal")
    refute html =~ "Cancel at period end"
    refute html =~ "Cancel renewal"
    refute html =~ "Change plan"
    refute html =~ "Swap plan"
    refute html =~ "Pause collection"
    refute html =~ "Resume"
    refute html =~ "Update quantity"
    refute html =~ "Add item"
    refute html =~ "Update item quantity"
    refute html =~ "Remove item"
    refute html =~ ~s(phx-value-action_type="swap_plan")
    refute html =~ ~s(phx-value-action_type="update_quantity")
    refute has_element?(view, "[data-role='swap-plan-unavailable']")
    refute has_element?(view, "[data-role='quantity-item-unsupported']")

    assert html =~
             "Braintree supports immediate cancellation through Accrue.Billing.cancel/2 and bounded first-party plan swaps when the host configures :plan_resolver."

    assert html =~ "Preview is unavailable for this provider"

    assert html =~
             "Configure :plan_resolver before exposing Braintree swap_plan/3 through admin."

    assert html =~
             "Braintree does not expose first-party quantity or subscription-item mutations through Accrue."
  end

  test "crafted Braintree action events are rejected server-side", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    customer =
      insert_customer(%{
        owner_id: "subscription-detail-braintree-crafted",
        processor: "braintree",
        processor_id: "cus_bt_crafted"
      })

    subscription =
      insert_subscription(customer, %{
        processor: "braintree",
        processor_id: "sub_bt_crafted"
      })

    item =
      %SubscriptionItem{}
      |> SubscriptionItem.changeset(%{
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "si_bt_crafted",
        price_id: "price_bt_basic",
        quantity: 1
      })
      |> TestRepo.insert!()

    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    html = render_click(view, "open_action_drawer", %{"action_type" => "update_quantity"})

    refute html =~ ~s(data-action-type="update_quantity")
    refute html =~ ~s(data-ax-action-drawer-form)

    html = render_click(view, "open_action_drawer", %{})

    refute html =~ ~s(data-ax-action-drawer-form)
    refute html =~ ~s(data-role="confirm-action")

    html =
      render_submit(view, "prepare_action", %{
        "action_type" => "remove_item",
        "item_id" => item.id,
        "proration" => "create_prorations"
      })

    refute html =~ "Confirm Remove item"
    refute html =~ ~s(data-role="confirm-action")

    html = render_submit(view, "prepare_action", %{})

    refute html =~ "Confirm action"
    refute html =~ ~s(data-role="confirm-action")
    assert TestRepo.get!(SubscriptionItem, item.id)
  end

  describe "dunning state inside summary and drill sections" do
    test "subscription with no campaign renders the dunning drill without a standalone card", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      refute Subscription.dunning_campaign_active?(subscription)

      {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

      assert has_element?(view, "[data-ax-drill-section='dunning-recovery']")
      refute has_element?(view, "[data-role='subscription-dunning-state']")
      assert html =~ "Dunning &amp; recovery"
      assert html =~ Copy.dunning_empty_state_body()
      assert html =~ Copy.dunning_state_none()
    end

    test "active campaign opens dunning recovery drill with resolver-derived next action", %{
      conn: conn,
      subscription: subscription
    } do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      active =
        subscription
        |> Subscription.changeset(%{dunning_campaign_started_at: DateTime.utc_now()})
        |> TestRepo.update!()

      assert Subscription.dunning_campaign_active?(active)

      {:ok, view, html} = live(conn, "/billing/subscriptions/#{active.id}")

      assert has_element?(view, "[data-ax-drill-section='dunning-recovery'][open]")
      refute has_element?(view, "[data-role='subscription-dunning-state']")
      assert html =~ "Dunning &amp; recovery"
      assert html =~ Copy.dunning_state_active()
      assert html =~ Copy.dunning_next_action_label()
      assert html =~ "reminder"
      refute html =~ Copy.dunning_empty_state_body()
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

  defp data_attr_count(html, attr) do
    attr
    |> Regex.escape()
    |> then(&Regex.compile!("\\b" <> &1 <> "(?:\\s|=|>)"))
    |> Regex.scan(html)
    |> length()
  end

  defp page_wrapper_count(html) do
    ~r/class="([^"]*)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.count(fn [classes] ->
      classes
      |> String.split()
      |> Enum.member?("ax-page")
    end)
  end

  defp heading_count(html, tag) do
    tag
    |> Regex.escape()
    |> then(&Regex.compile!("<" <> &1 <> "\\b"))
    |> Regex.scan(html)
    |> length()
  end

  defp assert_text_order(html, labels) do
    positions =
      Enum.map(labels, fn label ->
        case :binary.match(html, label) do
          :nomatch -> flunk("expected #{inspect(label)} to be present in rendered HTML")
          {position, _length} -> {label, position}
        end
      end)

    positions
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [{left_label, left_position}, {right_label, right_position}] ->
      assert left_position < right_position,
             "expected #{inspect(left_label)} to render before #{inspect(right_label)}"
    end)
  end

  defp copy_fixture do
    "../../../../examples/accrue_host/e2e/generated/copy_strings.json"
    |> Path.expand(__DIR__)
    |> File.read!()
    |> Jason.decode!()
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
