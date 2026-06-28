defmodule AccrueAdmin.Components.AtRiskTableTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.AtRiskTable

  describe "at_risk_table/1" do
    test "renders desktop table and mobile cards under the shared group contract" do
      html = render_component(&AtRiskTable.at_risk_table/1, rows: rows(), base_path: "/billing")

      assert html =~ ~s(data-component-group="table-empty-loading-error-pagination")
      assert html =~ ~s(data-state="no-pagination")
      assert html =~ ~s(class="ax-at-risk-grid")
      assert html =~ ~s(class="ax-at-risk-cards")

      assert html =~ "Northwind Finance"
      assert html =~ "$320.00"
      assert html =~ "Past due 9 days"
      assert html =~ "Step 2"
      assert html =~ "2026-04-20 15:30 UTC"
      assert html =~ "card_declined"
      assert html =~ ~s(href="/billing/analytics/recovery/subscriptions/sub_123")
      assert html =~ ~s(aria-label="Open recovery campaign for Northwind Finance")
    end

    test "renders distinct empty, loading, error, no-pagination, and has-pagination states" do
      loading_html = render_component(&AtRiskTable.at_risk_table/1, rows: [], loading: true)
      assert loading_html =~ ~s(data-state="loading")
      assert loading_html =~ "Loading at-risk subscriptions"

      error_html =
        render_component(&AtRiskTable.at_risk_table/1,
          rows: [],
          error: "Dunning query timed out"
        )

      assert error_html =~ ~s(data-state="error")
      assert error_html =~ "Dunning query timed out"

      empty_html = render_component(&AtRiskTable.at_risk_table/1, rows: [])
      assert empty_html =~ ~s(data-state="empty")
      assert empty_html =~ "No active dunning campaigns"
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
        amount_due_minor: 32_000,
        currency: "usd",
        days_in_campaign: 9,
        current_step: 2,
        next_step_eta: ~U[2026-04-20 15:30:00Z],
        failure_reason: %{"failure_code" => "card_declined"}
      }
    ]
  end

  defp app_css_path, do: Path.expand("../../../assets/css/app.css", __DIR__)
end
