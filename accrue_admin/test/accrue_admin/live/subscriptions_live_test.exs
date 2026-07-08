defmodule AccrueAdmin.SubscriptionsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy

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

    %{subscription: paused_subscription} = Factory.active_subscription(%{owner_id: "sub-paused"})

    {:ok, _paused_processor} =
      Fake.pause_subscription_collection(paused_subscription.processor_id, :void, %{}, [])

    %{subscription: active_subscription} = Factory.active_subscription(%{owner_id: "sub-active"})
    {:ok, _canceling_subscription} = Billing.cancel_at_period_end(active_subscription)

    :ok
  end

  test "filters subscription rows and renders lifecycle-safe links", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=canceling")

    assert html =~ Copy.subscriptions_index_heading()

    assert html =~
             "Open customer detail, invoice worklists, dunning, and actor audit from each row."

    assert html =~ "Canceling at period end"
    assert html =~ "/billing/subscriptions/"
    assert html =~ "ax-chip ax-label"
  end

  test "renders filtered-empty copy when search excludes all subscriptions", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/subscriptions?q=___accrue_empty_fixture___")

    assert html =~ Copy.subscriptions_list_filtered_empty_title()
    assert html =~ Copy.subscriptions_list_filtered_empty_body()
  end

  test "bare navigation push_patches to default queue status past_due,canceling", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=past_due,canceling")

    # FilterChipBar renders queue chip (cobalt) and All chip (slate)
    assert html =~ "ax-filter-chip-cobalt"
    assert html =~ "ax-filter-chip-slate"
    assert html =~ "?view=all"
  end

  test "renders Subscriptions through PageHeader with exactly one h1", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?view=all")

    assert html =~ ~s(data-ax-page-header)
    assert html =~ ~s(data-ax-page-title)
    assert html =~ ~s(data-component-group="page-header-actions-breadcrumbs")
    assert html =~ ~s(data-ax-page-filter-toolbar)
    assert html =~ ~s(data-ax-page-actions)
    assert html =~ "Find customer"
    assert html =~ "Billing health:"
    assert html =~ "Work open invoices"
    assert html =~ "Watch dunning funnel"
    assert html =~ "Who did what, when?"
    assert html =~ "Debug webhook failures"
    assert html =~ "Debug failed webhooks end-to-end"
    assert html =~ "Billing health"
    assert html =~ "Dunning funnel"
    assert_one_h1(html)

    assert html
           |> Floki.parse_document!()
           |> Floki.find(~s([data-role="filter-form"]))
           |> length() == 1
  end

  test "bare subscriptions route represents the default At risk queue without first-run flash", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions")

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ "At risk"
    assert html =~ "All"
    assert html =~ "Open-invoice worklist"
    assert html =~ "Primary queue"
    assert html =~ "Work open-invoice queue to zero"
    assert html =~ "Watch dunning funnel"
    assert html =~ "Who did what, when?"
    assert html =~ ~s(data-ax-state="filtered-empty") or html =~ ~s(data-ax-state="populated")
    refute html =~ "No subscriptions yet."
  end

  test "default queue chip clears to view all while preserving organization scope", %{conn: conn} do
    org_id = Ecto.UUID.generate()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: org_id,
        active_organization_slug: "allowed-org",
        admin_organization_ids: [org_id]
      )

    assert {:ok, _view, html} =
             live(conn, "/billing/subscriptions?org=allowed-org&status=past_due,canceling")

    assert html =~ ~s(data-ax-clear-all)
    assert html =~ ~s(href="/billing/subscriptions?org=allowed-org&amp;view=all")
    assert html =~ "At risk"
    assert html =~ "All"
  end

  test "renders chip row result count and clear-all markers for active filters", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=canceling")

    assert html =~ ~s(data-ax-filter-chips)
    assert html =~ ~s(data-ax-result-count)
    assert html =~ "Showing"
    assert html =~ "subscriptions"
    assert html =~ ~s(data-ax-clear-all)
  end

  test "distinguishes populated, first-run-empty, filtered-empty, queue-empty, and loading states",
       %{conn: conn} do
    populated_conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    assert {:ok, _view, populated_html} = live(populated_conn, "/billing/subscriptions?view=all")
    assert populated_html =~ ~s(data-ax-list="subscriptions")
    assert populated_html =~ ~s(data-ax-state="populated")

    empty_org = "org-empty-#{System.unique_integer([:positive])}"

    first_run_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: empty_org,
        active_organization_slug: "empty-org",
        admin_organization_ids: [empty_org]
      )

    assert {:ok, _view, first_run_html} =
             live(first_run_conn, "/billing/subscriptions?org=empty-org&view=all")

    assert first_run_html =~ ~s(data-ax-state="first-run-empty")
    assert first_run_html =~ ~s(data-ax-empty-reason="first-run")
    assert first_run_html =~ "No subscriptions yet."
    refute first_run_html =~ ~s(data-ax-clear-all)

    filtered_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, filtered_html} =
             live(filtered_conn, "/billing/subscriptions?view=all&q=___phase196_no_match___")

    assert filtered_html =~ ~s(data-ax-state="filtered-empty")
    assert filtered_html =~ ~s(data-ax-empty-reason="filter")
    assert filtered_html =~ "No subscriptions match these filters."
    assert filtered_html =~ ~s(data-ax-clear-all)

    queue_org = "org-queue-#{System.unique_integer([:positive])}"
    Factory.active_subscription(%{owner_type: "Organization", owner_id: queue_org})

    queue_conn =
      Phoenix.ConnTest.build_conn()
      |> Phoenix.ConnTest.init_test_session(
        admin_token: "admin",
        active_organization_id: queue_org,
        active_organization_slug: "queue-org",
        admin_organization_ids: [queue_org]
      )

    assert {:ok, _view, queue_html} =
             live(queue_conn, "/billing/subscriptions?org=queue-org&status=past_due,canceling")

    assert queue_html =~ ~s(data-ax-state="filtered-empty")
    assert queue_html =~ ~s(data-ax-empty-reason="queue")
    assert queue_html =~ "Nothing at risk."
    assert queue_html =~ "View All to see every subscription."

    loading_conn =
      Phoenix.ConnTest.init_test_session(Phoenix.ConnTest.build_conn(), admin_token: "admin")

    assert {:ok, _view, loading_html} =
             live(loading_conn, "/billing/subscriptions?phase196_state=loading-skeleton")

    assert loading_html =~ ~s(data-ax-state="loading-skeleton")
    assert loading_html =~ ~s(aria-busy="true")

    assert loading_html
           |> Floki.parse_document!()
           |> Floki.find(~s([data-role="loading-skeleton"] [role="status"]))
           |> length() == 1

    assert loading_html =~ Copy.subscriptions_list_loading_label()
  end

  test "loading skeleton fixture is ignored outside test runtime", %{conn: conn} do
    prior = Application.get_env(:accrue_admin, :env)
    Application.put_env(:accrue_admin, :env, :prod)
    on_exit(fn -> Application.put_env(:accrue_admin, :env, prior) end)

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/subscriptions?phase196_state=loading-skeleton")

    refute html =~ ~s(data-ax-state="loading-skeleton")
    refute html =~ ~s(aria-busy="true")
  end

  test "prioritizes identity, state, plan amount, time, and signals columns", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?view=all")

    assert html =~ "Open invoice exposure"
    assert html =~ "Work this subscription invoice queue"
    assert html =~ "Open all open invoices"
    assert html =~ "Open subscription audit log"
    assert html =~ "Owner: User"
    assert html =~ "Tax: Off"
    assert html =~ "Who"
    assert html =~ "Did"
    assert html =~ "Find customer"
    assert html =~ "Debug failed webhooks end-to-end"
    assert html =~ "amount not projected locally"
    assert html =~ "target $0.00"

    assert_table_headings_in_order(html, [
      "Customer and subscription IDs",
      "State",
      "Plan / amount",
      "Renews / ends",
      "Signals"
    ])
  end

  test "uses customer identity before raw subscription or processor IDs", %{conn: conn} do
    %{subscription: subscription} =
      Factory.active_subscription(%{email: "phase196-primary@example.com"})

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?view=all")

    assert html =~ "phase196-primary@example.com"
    assert html =~ "Customer ID"
    assert html =~ subscription.customer_id
    assert html =~ "Subscription"
    assert html =~ subscription.processor_id
    assert_before(html, "phase196-primary@example.com", subscription.processor_id)
  end

  # Shared SPA-filter contract smoke (260621-io6): proves the parent-targeted
  # data_table_filter form drives a push_patch on a SECOND page beyond customers.
  test "submitting the shared filter form push_patches the table path with filter params", %{
    conn: conn
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, _html} = live(conn, "/billing/subscriptions?view=all")

    view
    |> form(~s([data-role="filter-form"]), %{"q" => "acme"})
    |> render_submit()

    to = assert_patch(view)
    assert to =~ "/billing/subscriptions"
    assert to =~ "q=acme"
  end

  defp assert_one_h1(html) do
    assert html |> Floki.parse_document!() |> Floki.find("h1") |> length() == 1
  end

  defp assert_table_headings_in_order(html, labels) do
    text =
      html
      |> Floki.parse_document!()
      |> Floki.find("th")
      |> Enum.map_join(" ", &Floki.text/1)

    assert_in_order(text, labels)
  end

  defp assert_before(html, left, right), do: assert_in_order(html, [left, right])

  defp assert_in_order(text, labels) do
    positions =
      Enum.map(labels, fn label ->
        {label, :binary.match(text, label)}
      end)

    missing =
      for {label, :nomatch} <- positions do
        label
      end

    assert missing == []

    positions
    |> Enum.map(fn {label, {position, _length}} -> {label, position} end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [{left_label, left_position}, {right_label, right_position}] ->
      assert left_position < right_position,
             "expected #{inspect(left_label)} to render before #{inspect(right_label)}"
    end)
  end
end
