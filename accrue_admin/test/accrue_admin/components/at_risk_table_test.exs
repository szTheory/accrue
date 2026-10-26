defmodule AccrueAdmin.Components.AtRiskTableTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.AtRiskTable
  alias AccrueAdmin.OwnerScope

  describe "at_risk_table/1" do
    test "renders desktop table and mobile cards under the shared group contract" do
      html = render_component(&AtRiskTable.at_risk_table/1, rows: rows(), base_path: "/billing")

      assert html =~ ~s(data-component-group="table-empty-loading-error-pagination")
      assert html =~ ~s(data-state="no-pagination")
      assert html =~ ~s(class="ax-at-risk-grid")
      assert html =~ ~s(class="ax-at-risk-scroll-region")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="At-risk subscriptions table")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(class="ax-at-risk-cards")

      assert html =~ "Northwind Finance"
      assert html =~ "Subscription status"
      assert html =~ "Past due"
      assert html =~ "$320.00"
      assert html =~ "Past due 9 days"
      assert html =~ "Step 2"
      document = Floki.parse_document!(html)
      timestamps = Floki.find(document, "[data-time-display]")
      assert length(timestamps) == 2
      assert Enum.all?(timestamps, &(Floki.attribute(&1, "data-iso") == ["2026-04-20T15:30:00Z"]))
      ids = Enum.flat_map(timestamps, &Floki.attribute(&1, "id"))
      assert length(Enum.uniq(ids)) == 2
      assert html =~ "card_declined"

      assert html =~
               ~s(href="/billing/analytics/recovery/subscriptions/sub_123?return_to=%2Fbilling%2Fanalytics%2Frecovery%3Fwindow%3D30d")

      assert html =~ ~s(aria-label="Open recovery campaign for Northwind Finance")
    end

    test "preserves organization scope in campaign and pagination links" do
      owner_scope = organization_owner_scope("org_allowed")

      html =
        render_component(&AtRiskTable.at_risk_table/1,
          rows: rows(),
          base_path: "/billing",
          owner_scope: owner_scope,
          current_window: "7d",
          next_cursor: "cursor-2"
        )

      assert html =~
               ~s(href="/billing/analytics/recovery/subscriptions/sub_123?org=allowed-org&amp;return_to=)

      assert html =~ "%26window%3D7d"
      assert html =~ "org=allowed-org"

      assert html =~
               ~r/href="\/billing\/analytics\/recovery\?(?:cursor=cursor-2&amp;org=allowed-org|org=allowed-org&amp;cursor=cursor-2)"/
    end

    test "missing currency does not imply USD for at-risk amounts" do
      row = %{hd(rows()) | currency: nil}

      html = render_component(&AtRiskTable.at_risk_table/1, rows: [row])

      assert html =~ "Amount unavailable"
      refute html =~ "$320.00"
    end

    test "renders distinct empty, loading, error, no-pagination, and has-pagination states" do
      loading_html = render_component(&AtRiskTable.at_risk_table/1, rows: [], loading: true)
      assert loading_html =~ ~s(data-state="loading")
      assert loading_html =~ "Loading at-risk subscriptions"
      refute loading_html =~ "subscriptions with active payment retries in this window"

      error_html =
        render_component(&AtRiskTable.at_risk_table/1,
          rows: [],
          error: "Dunning query timed out"
        )

      assert error_html =~ ~s(data-state="error")
      assert error_html =~ "Dunning query timed out"
      refute error_html =~ "subscriptions with active payment retries in this window"

      empty_html = render_component(&AtRiskTable.at_risk_table/1, rows: [])
      assert empty_html =~ ~s(data-state="empty")
      assert empty_html =~ "No subscriptions currently need payment retry"
      assert empty_html =~ "0 subscriptions with active payment retries in this window"
      refute empty_html =~ ~s(data-role="load-more")

      no_pagination_html =
        render_component(&AtRiskTable.at_risk_table/1, rows: rows(), next_cursor: nil)

      assert no_pagination_html =~ ~s(data-state="no-pagination")
      refute no_pagination_html =~ ~s(data-role="load-more")

      has_pagination_html =
        render_component(&AtRiskTable.at_risk_table/1,
          rows: rows(),
          next_cursor: "cursor-2"
        )

      assert has_pagination_html =~ ~s(data-state="has-pagination")
      assert has_pagination_html =~ ~s(data-role="load-more")
      assert has_pagination_html =~ "Load more"
    end

    test "module docs describe AtRiskTable as the Recovery work queue before the supporting funnel" do
      source = File.read!("lib/accrue_admin/components/at_risk_table.ex")

      assert source =~ "Recovery work queue"
      assert source =~ "before the supporting funnel"
      refute source =~ "below the Recovery Funnel"
    end

    test "css keeps inactive desktop or mobile layout hidden at each breakpoint" do
      app_css = File.read!(app_css_path())

      assert app_css =~ ".ax-at-risk-grid"
      assert app_css =~ ".ax-at-risk-cards"
      assert app_css =~ "@media (min-width: 768px) { /* --ax-bp-md ↑ */"
      assert app_css =~ ".ax-at-risk-grid {\n    display: table;"
      assert app_css =~ ".ax-at-risk-cards {\n    display: none;"
    end
  end

  defp rows do
    [
      %{
        subscription_id: "sub_123",
        customer_id: "cus_123",
        customer_label: "Northwind Finance",
        current_status: :past_due,
        amount_due_minor: 32_000,
        currency: "usd",
        days_in_campaign: 9,
        current_step: 2,
        next_step_eta: ~U[2026-04-20 15:30:00Z],
        failure_reason: %{"failure_code" => "card_declined"}
      }
    ]
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

  defp app_css_path, do: Path.expand("../../../assets/css/app.css", __DIR__)
end
