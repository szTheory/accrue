defmodule AccrueAdmin.DisplayComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias Accrue.Money
  alias AccrueAdmin.Components.{DetailDrawer, FilterChipBar, JsonViewer, KpiCard}
  alias AccrueAdmin.Components.{MoneyFormatter, Timeline}

  describe "FilterChipBar" do
    test "renders active server-driven filter chips and clear links" do
      html =
        render_component(&FilterChipBar.filter_chip_bar/1, %{
          label: "Webhook filters",
          items: [
            %{
              id: :status,
              label: "Status",
              value: "DLQ",
              remove_href: "/billing/webhooks?status=",
              tone: :amber
            },
            %{
              id: :provider,
              label: "Provider",
              value: "stripe",
              remove_href: "/billing/webhooks?provider=",
              tone: :cobalt
            },
            %{id: :ignored, label: "Ignored", value: "x", active: false}
          ]
        })

      assert html =~ "Webhook filters"
      assert html =~ ~s(data-filter="status")
      assert html =~ "DLQ"
      assert html =~ ~s(href="/billing/webhooks?status=")
      refute html =~ "Ignored"
    end
  end

  describe "DetailDrawer" do
    test "renders a page-agnostic drawer shell with mobile-ready close action" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <DetailDrawer.detail_drawer open title="Webhook event" subtitle="evt_123" close_href="/billing/webhooks">
            <:actions>
              <span class="ax-body">Queued retry</span>
            </:actions>
            Webhook payload content
            <:footer>
              <span class="ax-body">Footer actions</span>
            </:footer>
          </DetailDrawer.detail_drawer>
          """
        end)

      assert html =~ ~s(role="dialog")
      assert html =~ "Webhook event"
      assert html =~ "evt_123"
      assert html =~ "Queued retry"
      assert html =~ "Webhook payload content"
      assert html =~ "Footer actions"
      assert html =~ ~s(href="/billing/webhooks")
    end
  end

  describe "KpiCard" do
    test "renders KPI value, delta tone, and optional sparkline slot" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <KpiCard.kpi_card label="MRR" value="$12,450" delta="+12.5%" delta_tone="moss" trend="vs last month">
            <:meta>
              <span class="ax-body">12 active subscriptions</span>
            </:meta>
            <:sparkline>
              <svg aria-hidden="true"><path d="M0 10 L10 5" /></svg>
            </:sparkline>
          </KpiCard.kpi_card>
          """
        end)

      assert html =~ "MRR"
      assert html =~ "$12,450"
      assert html =~ "ax-kpi-delta-moss"
      assert html =~ "vs last month"
      assert html =~ "12 active subscriptions"
      assert html =~ "<svg"
    end
  end

  describe "Timeline" do
    test "renders escaped timeline items with expandable detail blocks" do
      html =
        render_component(&Timeline.timeline/1, %{
          items: [
            %{
              title: "Webhook received",
              at: "April 15, 2026",
              status: :queued,
              body: "<script>alert(1)</script>",
              details: "{error: false}",
              expanded: true
            },
            %{
              title: "Moved to DLQ",
              status: :dlq,
              meta: "Next retry requires manual action"
            }
          ]
        })

      assert html =~ "Webhook received"
      assert html =~ "April 15, 2026"
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ "<script>alert(1)</script>"
      assert html =~ "Inspect details"
      assert html =~ "Moved to DLQ"
      assert html =~ "Next retry requires manual action"
    end
  end

  describe "JsonViewer" do
    test "renders tree, raw, and copy surfaces with escaped structured payloads" do
      html =
        render_component(&JsonViewer.json_viewer/1, %{
          id: "payload",
          active_tab: "copy",
          payload: %{
            "id" => "evt_123",
            "nested" => [%{"kind" => "charge.succeeded"}],
            "script" => "<script>alert(1)</script>"
          }
        })

      assert html =~ "Payload"
      assert html =~ "Tree"
      assert html =~ "Raw"
      assert html =~ "Copy"
      assert html =~ "Copy payload"
      assert html =~ ~s(phx-hook="Clipboard")
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ "<script>alert(1)</script>"
    end

    test "normalizes structs to explicit type markers instead of dumping fields" do
      html =
        render_component(&JsonViewer.json_viewer/1, %{
          id: "payload",
          active_tab: "raw",
          payload: %Money{amount_minor: 1200, currency: :usd}
        })

      assert html =~ "__struct__"
      assert html =~ "Accrue.Money"
      refute html =~ "amount_minor"
    end
  end

  describe "MoneyFormatter" do
    test "formats minor-unit amounts using the explicit locale" do
      expected = Accrue.Invoices.Render.format_money(123_456, :usd, "en")

      html =
        render_component(&MoneyFormatter.money_formatter/1, %{
          amount_minor: 123_456,
          currency: :usd,
          locale: "en"
        })

      assert html =~ expected
      assert html =~ ~s(data-locale="en")
    end

    test "falls back to customer preferred locale when explicit locale is absent" do
      expected = Accrue.Invoices.Render.format_money(1_000, :eur, "fr")

      html =
        render_component(&MoneyFormatter.money_formatter/1, %{
          money: Money.new(1_000, :eur),
          customer: %{preferred_locale: "fr"}
        })

      assert html =~ expected
      assert html =~ ~s(data-locale="fr")
    end
  end
end
