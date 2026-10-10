defmodule AccrueAdmin.SubscriptionLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription, SubscriptionItem}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Invoices
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
    assert has_element?(view, "[data-ax-related-resources] [aria-label='Related billing']")
    refute has_element?(view, "[data-role='subscription-dunning-state']")
    refute has_element?(view, "[data-role='confirm-panel']")
    refute html =~ ~s(class="ax-kpi-grid")
    refute html =~ Copy.subscription_kpi_canonical_predicates_label()

    assert html =~ "/billing/customers/#{subscription.customer_id}"
    assert html =~ "subject_type=Subscription"
    assert html =~ "subject_id=#{subscription.id}"
    assert html =~ "Subscription events"
    assert html =~ "Open invoices for this customer"
    assert html =~ "All open invoices in global scope"
    assert html =~ "Customer-wide results; open status"
    refute html =~ "subscription_id=#{subscription.id}"
    refute html =~ "Filter this subscription&#39;s invoices"
    refute html =~ "Global invoice queue workspace"
    refute html =~ "Global open-invoice queue rows"
    refute html =~ "subscription-related-billing"
    refute html =~ "Recovery workspace button"
    assert html =~ "Open dunning funnel and at-risk analytics"
    assert html =~ "Open Events audit log with subscription filter"
    assert html =~ "Audit event table: Actor / Action / Timestamp"

    customer_invoice_href = link_href(view, "Open invoices for this customer")

    customer_invoice_query =
      customer_invoice_href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert URI.parse(customer_invoice_href).path == "/billing/invoices"
    assert customer_invoice_query["status"] == "open"
    assert customer_invoice_query["customer_id"] == subscription.customer_id

    scope_invoice_href = link_href(view, "All open invoices in global scope")

    scope_invoice_query =
      scope_invoice_href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert URI.parse(scope_invoice_href).path == "/billing/invoices"
    assert scope_invoice_query["status"] == "open"
    refute Map.has_key?(scope_invoice_query, "customer_id")
    refute Map.has_key?(scope_invoice_query, "subscription_id")
  end

  test "subscription detail returns to the validated originating list in the current organization scope",
       %{
         conn: conn
       } do
    %{subscription: subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: "journey-org",
        email: "phase234-return@example.com"
      })

    conn =
      Phoenix.ConnTest.init_test_session(
        conn,
        admin_token: "admin",
        active_organization_id: "journey-org",
        active_organization_slug: "journey-org",
        admin_organization_ids: ["journey-org"]
      )

    return_to =
      URI.encode(
        "/billing/subscriptions?org=foreign-org&view=all&status=active&q=phase234",
        &URI.char_unreserved?/1
      )

    assert {:ok, view, html} =
             live(
               conn,
               "/billing/subscriptions/#{subscription.id}?org=journey-org&return_to=#{return_to}"
             )

    assert html =~ "Back to subscriptions"
    assert html =~ "All open invoices for journey-org"

    scoped_invoice_href = link_href(view, "All open invoices for journey-org")

    scoped_invoice_query =
      scoped_invoice_href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert URI.parse(scoped_invoice_href).path == "/billing/invoices"
    assert scoped_invoice_query["org"] == "journey-org"
    assert scoped_invoice_query["status"] == "open"

    back_path =
      view
      |> element("a", "Back to subscriptions")
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> hd()

    back_query = back_path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    assert URI.parse(back_path).path == "/billing/subscriptions"
    assert back_query["org"] == "journey-org"
    assert back_query["view"] == "all"
    assert back_query["status"] == "active"
    assert back_query["q"] == "phase234"
    refute html =~ "foreign-org"

    assert {:ok, returned_view, returned_html} = live(conn, back_path)
    assert has_element?(returned_view, "[name='q'][value='phase234']")
    assert returned_html =~ subscription.processor_id
  end

  test "subscription detail returns to the matching customer's query-free subscriptions tab", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    origin = "/billing/customers/#{subscription.customer_id}?tab=subscriptions"

    assert {:ok, detail_view, _html} =
             live(
               conn,
               "/billing/subscriptions/#{subscription.id}?return_to=#{URI.encode_www_form(origin)}"
             )

    back_path = link_href(detail_view, "Back to customer subscriptions")
    assert URI.parse(back_path).path == "/billing/customers/#{subscription.customer_id}"
    assert URI.decode_query(URI.parse(back_path).query)["tab"] == "subscriptions"

    assert {:ok, customer_view, customer_html} = live(conn, back_path)

    assert has_element?(
             customer_view,
             "[aria-label='Customer peer record sets'] .ax-tab-active",
             "Subscriptions"
           )

    assert customer_html =~ subscription.processor_id

    detail_path = link_href(customer_view, subscription.processor_id)
    assert URI.decode_query(URI.parse(detail_path).query)["return_to"] == back_path

    assert {:ok, repeated_detail_view, _html} = live(conn, detail_path)
    assert has_element?(repeated_detail_view, "a", "Back to customer subscriptions")
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
    assert html =~ "Lifecycle"
    assert html =~ "Active"
    refute html =~ "Setup required now"
    assert html =~ "ax-detail-health-summary-moss"
    assert html =~ "ax-detail-health-answer"
    assert html =~ "Charge amount not shown"

    refute html =~ "Billing health right now"
    assert html =~ "MRR"
    assert html =~ "Charge amount not shown"
    assert html =~ "Billing setup gaps"
    assert html =~ "Lifecycle state"
    assert html =~ "Open invoices for this customer"
    assert html =~ "Global dunning funnel"
    assert html =~ "recovery analytics still shows at-risk accounts and funnel trends."
    assert html =~ "All open invoices in global scope"
    assert html =~ "Audit event table: Actor / Action / Timestamp"
    assert html =~ "Latest audit event summary"
    assert html =~ "Actor"
    assert html =~ "Open Events audit log with subscription filter"
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

  test "active lifecycle remains active when price and period observations are unavailable", %{
    conn: conn,
    subscription: subscription
  } do
    long_subscription_id = "sub_" <> String.duplicate("long-identifier-", 12)
    long_customer_name = String.duplicate("Northstar billing account ", 8)

    subscription
    |> Subscription.changeset(%{
      processor_id: long_subscription_id,
      current_period_start: nil,
      current_period_end: nil
    })
    |> TestRepo.update!()

    TestRepo.get!(Customer, subscription.customer_id)
    |> Customer.changeset(%{name: long_customer_name})
    |> TestRepo.update!()

    TestRepo.delete_all(
      from(item in SubscriptionItem, where: item.subscription_id == ^subscription.id)
    )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    assert html =~ "Lifecycle"
    assert html =~ "Subscription is active"
    assert html =~ long_subscription_id
    assert html =~ long_customer_name
    assert html =~ "Price is not confirmed in admin"
    assert html =~ "Current period is not shown in admin"
    assert html =~ "Amount is not confirmed in admin"
    refute html =~ "$0.00"
    refute html =~ "0.00 USD"
    refute html =~ "Setup incomplete - active billing unverified"
    refute html =~ "Billing is not active"
    refute html =~ "Due now"

    assert has_element?(view, "[data-ax-action-band]")
    assert has_element?(view, "[data-ax-related-resources]")
    refute html =~ "0 open invoices"

    {invoice_rows, _cursor} =
      Invoices.list(
        filter:
          Invoices.decode_filter(%{
            "customer_id" => subscription.customer_id,
            "status" => "open"
          }),
        limit: 20
      )

    assert invoice_rows == []

    invoice_href = link_href(view, "Open invoices for this customer")
    invoice_query = invoice_href |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
    assert invoice_query["customer_id"] == subscription.customer_id
    assert invoice_query["status"] == "open"
  end

  test "lifecycle states stay distinct from scheduled cancellation and collection pause", %{
    conn: conn,
    subscription: subscription
  } do
    scheduled_end = DateTime.add(DateTime.utc_now(), 86_400, :second)

    cases = [
      {:trialing, %{}, "Trialing"},
      {:incomplete, %{}, "Incomplete"},
      {:incomplete_expired, %{}, "Incomplete expired"},
      {:past_due, %{}, "Past due"},
      {:unpaid, %{}, "Unpaid"},
      {:canceled, %{}, "Canceled"},
      {:active, %{cancel_at_period_end: true, current_period_end: scheduled_end}, "Active"},
      {:active, %{pause_collection: %{"behavior" => "void"}}, "Active"}
    ]

    for {status, fields, lifecycle} <- cases do
      TestRepo.get!(Subscription, subscription.id)
      |> Subscription.force_status_changeset(Map.merge(fields, %{status: status}))
      |> TestRepo.update!()

      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")
      assert html =~ lifecycle

      case fields do
        %{cancel_at_period_end: true} ->
          assert html =~ "Scheduled for"

        %{pause_collection: _pause} ->
          assert html =~ "Collection"
          assert html =~ "Paused"

        _ ->
          :ok
      end
    end
  end

  test "subscription identity and lifecycle precede actions and raw disclosure", %{
    conn: conn,
    subscription: subscription
  } do
    subscription
    |> Subscription.changeset(%{
      data: Map.put(subscription.data || %{}, "payment_method_token", "secret_token_value")
    })
    |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, view, html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    {identity, _} = :binary.match(html, "detail-header-metadata-actions")
    {lifecycle, _} = :binary.match(html, "Subscription lifecycle summary")
    {action, _} = :binary.match(html, "data-ax-action-band")
    {related, _} = :binary.match(html, "data-ax-related-resources")
    {billing, _} = :binary.match(html, "data-ax-drill-section=\"billing-items\"")
    {raw, _} = :binary.match(html, "data-ax-lazy-json")
    assert identity < lifecycle
    assert lifecycle < action
    assert action < related
    assert related < billing
    assert billing < raw

    html = render_click(view, "load_raw_json", %{})
    refute html =~ "payment_method_token"
    refute html =~ "secret_token_value"
    assert html =~ "Cancellation"
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

  test "repeated confirmation and delayed step-up submission dispatch one cancellation", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    assert render_click(element(view, "[data-role='confirm-action']")) =~ "Step-up required"
    assert render_click(view, "confirm_action") =~ "Step-up required"

    assert render_submit(view, "step_up_submit", %{"code" => "123456"}) =~
             "Subscription action recorded"

    render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert Accrue.Processor.Fake.call_count(:cancel_subscription) == 1

    assert length(
             TestRepo.all(from(event in Event, where: event.type == "subscription.canceled"))
           ) == 1
  end

  test "reloading a pending confirmation does not replay the mutation", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    path = "/billing/subscriptions/#{subscription.id}"
    {:ok, first_view, _html} = live(conn, path)
    render_click(element(first_view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        first_view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    assert render_click(element(first_view, "[data-role='confirm-action']")) =~ "Step-up required"

    {:ok, reconnected_view, html} = live(conn, path)

    refute html =~ "Step-up required"
    refute has_element?(reconnected_view, "[data-role='confirm-action']")
    assert Accrue.Processor.Fake.call_count(:cancel_subscription) == 0
    refute TestRepo.get_by(Event, type: "subscription.canceled", subject_id: subscription.id)
  end

  test "changing the staged action while step-up is open discards the old continuation", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    assert render_click(element(view, "[data-role='confirm-action']")) =~ "Step-up required"

    render_click(view, "prepare_action", %{"action_type" => "cancel_at_period_end"})
    render_submit(view, "step_up_submit", %{"code" => "123456"})

    refute TestRepo.get_by(Event, type: "subscription.canceled", subject_id: subscription.id)
    assert Accrue.Processor.Fake.call_count(:cancel_subscription) == 0
    assert Accrue.Processor.Fake.call_count(:update_subscription) == 0
  end

  test "possibly submitted timeout stays uncertain and offers only scoped evidence", %{
    conn: conn
  } do
    %{subscription: scoped_subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: "uncertain-org",
        email: "uncertain@example.com"
      })

    Accrue.Processor.Fake.scripted_response(:cancel_subscription, {:error, :timeout})

    conn =
      Phoenix.ConnTest.init_test_session(
        conn,
        admin_token: "admin",
        active_organization_id: "uncertain-org",
        active_organization_slug: "uncertain-org",
        admin_organization_ids: ["uncertain-org"]
      )

    {:ok, view, _html} =
      live(conn, "/billing/subscriptions/#{scoped_subscription.id}?org=uncertain-org")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    render_click(element(view, "[data-role='confirm-action']"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Outcome not confirmed"
    assert html =~ "Open scoped subscription activity"
    assert html =~ "org=uncertain-org"
    refute has_element?(view, "[data-role='confirm-action']")
    refute html =~ ":timeout"
    assert Accrue.Processor.Fake.call_count(:cancel_subscription) == 1

    blocked = render_click(view, "open_action_drawer", %{"action_type" => "cancel_now"})
    assert blocked =~ "Check scoped subscription activity before starting another action"
    refute has_element?(view, "[data-role='confirm-action']")

    html = render_click(view, "cancel_pending_action")
    assert html =~ "Outcome not confirmed"
  end

  test "definitive provider rejection is distinct from an ambiguous timeout", %{
    conn: conn,
    subscription: subscription
  } do
    Accrue.Processor.Fake.scripted_response(
      :cancel_subscription,
      {:error,
       %Accrue.APIError{message: "invalid request", code: "invalid_request", http_status: 422}}
    )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")
    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    render_click(element(view, "[data-role='confirm-action']"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "The provider rejected the action. No change was accepted."
    assert html =~ "Open scoped subscription activity"
    refute html =~ "Outcome not confirmed"
    refute has_element?(view, "[data-role='confirm-action']")
    refute html =~ "invalid request"
  end

  test "compensation result links only to the scoped replacement and keeps the original", %{
    conn: conn
  } do
    %{subscription: subscription} =
      Factory.active_subscription(%{
        owner_type: "Organization",
        owner_id: "compensation-org",
        email: "compensation@example.com"
      })

    conn =
      Phoenix.ConnTest.init_test_session(
        conn,
        admin_token: "admin",
        active_organization_id: "compensation-org",
        active_organization_slug: "compensation-org",
        admin_organization_ids: ["compensation-org"]
      )

    {:ok, view, _html} =
      live(conn, "/billing/subscriptions/#{subscription.id}?org=compensation-org")

    render_click(element(view, "button[role='menuitem']", "Comp this subscription"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "comp_subscription", "new_price_id" => "price_basic"}
    )

    render_click(element(view, "[data-role='confirm-action']"))
    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Compensation created a replacement subscription"
    assert html =~ "Open replacement subscription"
    assert html =~ "org=compensation-org"
    assert html =~ subscription.id
    refute html =~ "foreign-org"
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
             live(
               conn,
               "/billing/subscriptions/#{denied_subscription.id}?org=allowed-org&return_to=https%3A%2F%2Fforeign.example%2Fadmin%2Fsubscriptions%3Forg%3Dorg_denied%26view%3Dall"
             )

    assert %{"error" => denied} =
             Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

    assert denied == Copy.Locked.owner_access_denied()
    refute denied =~ denied_subscription.processor_id
    refute denied =~ "org_denied"

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

  test "terminated subscriptions do not offer lifecycle or billing mutation actions", %{
    conn: conn,
    subscription: subscription
  } do
    subscription =
      subscription
      |> Subscription.changeset(%{status: :canceled, ended_at: DateTime.utc_now()})
      |> TestRepo.update!()

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    refute has_element?(view, "[data-ax-primary-action]", "Change plan")
    refute has_element?(view, "[data-ax-primary-action]", "Cancel renewal")

    for action_type <- ["pause", "resume", "update_quantity", "add_item", "remove_item"] do
      html = render_click(view, "open_action_drawer", %{"action_type" => action_type})
      refute html =~ ~s(data-action-type="#{action_type}")
      refute html =~ ~s(data-role="confirm-action")
    end
  end

  test "confirmation rejects a subscription whose lifecycle changed after review", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    assert render_click(element(view, "[data-role='confirm-action']")) =~ "Step-up required"

    current = TestRepo.get!(Subscription, subscription.id)
    current |> Subscription.changeset(%{status: :canceled}) |> TestRepo.update!()

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Review the action again"
    refute html =~ "Step-up required"
    refute TestRepo.get_by(Event, type: "subscription.canceled", subject_id: subscription.id)
  end

  test "unrelated metadata changes preserve a reviewed action through fresh step-up", %{
    conn: conn,
    subscription: subscription
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Cancel immediately"))

    render_submit(
      element(
        view,
        "[data-ax-overlay-panel][data-presentation='drawer'] form[phx-submit='prepare_action']"
      ),
      %{"action_type" => "cancel_now"}
    )

    current = TestRepo.get!(Subscription, subscription.id)
    current |> Subscription.changeset(%{metadata: %{"note" => "unrelated"}}) |> TestRepo.update!()

    html = render_click(element(view, "[data-role='confirm-action']"))
    assert html =~ "Step-up required"

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})
    assert html =~ "Subscription action recorded"
    assert TestRepo.get_by(Event, type: "subscription.canceled", subject_id: subscription.id)
  end

  test "confirmation rejects a removed or changed item after review", %{
    conn: conn,
    subscription: subscription
  } do
    item = List.first(subscription.subscription_items)
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    {:ok, view, _html} = live(conn, "/billing/subscriptions/#{subscription.id}")

    render_click(element(view, "button[role='menuitem']", "Remove item"))

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

    current_item = TestRepo.get!(SubscriptionItem, item.id)
    current_item |> SubscriptionItem.changeset(%{quantity: 2}) |> TestRepo.update!()

    html = render_click(element(view, "[data-role='confirm-action']"))

    assert html =~ "Review the action again"
    refute html =~ "Step-up required"
    assert TestRepo.get!(SubscriptionItem, item.id).quantity == 2
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

  defp link_href(view, label) do
    view
    |> element("a", label)
    |> render()
    |> Floki.parse_document!()
    |> Floki.find("a")
    |> Floki.attribute("href")
    |> hd()
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
