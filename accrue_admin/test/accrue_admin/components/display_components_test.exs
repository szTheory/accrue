defmodule AccrueAdmin.DisplayComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias Accrue.Money
  alias AccrueAdmin.Components.{Detail, DetailDrawer, FilterChipBar, JsonViewer, KpiCard}
  alias AccrueAdmin.Components.{MoneyFormatter, RelatedResources, Timeline}
  alias AccrueAdmin.Components.StepUpAuthModal

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

    test "defines drawer/form dialog structure with title description body and footer" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <DetailDrawer.detail_drawer
            id="webhook-drawer"
            open
            title="Webhook event"
            subtitle="evt_123 queued for retry"
            close_href="/billing/webhooks"
          >
            Drawer payload content
            <:footer>
              <button type="button" class="ax-button ax-button-ghost">Cancel</button>
              <button type="submit" class="ax-button ax-button-primary">Save webhook</button>
            </:footer>
          </DetailDrawer.detail_drawer>
          """
        end)

      assert html =~ ~s(data-component-group="drawer-form")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="webhook-drawer-title")
      assert html =~ ~s(aria-describedby="webhook-drawer-description")
      assert html =~ ~s(id="webhook-drawer-title")
      assert html =~ ~s(id="webhook-drawer-description")
      assert html =~ ~s(class="ax-detail-drawer-body")
      assert html =~ ~s(class="ax-detail-drawer-footer")

      app_css = File.read!(app_css_path())
      assert app_css =~ ".ax-detail-drawer-shell"
      assert app_css =~ "z-index: var(--ax-z-drawer)"
      assert app_css =~ "grid-template-rows: auto minmax(0, 1fr) auto"
      assert app_css =~ ".ax-detail-drawer-body"
      assert app_css =~ "overflow: auto"
    end
  end

  describe "StepUpAuthModal" do
    test "defines modal-confirm dialog structure and neutral-before-primary actions" do
      html =
        render_component(&StepUpAuthModal.step_up_auth_modal/1, %{
          pending: true,
          challenge: %{kind: :password, message: "Re-enter your password to void invoice in_123."},
          error: nil
        })

      assert html =~ ~s(data-component-group="modal-confirm")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="step-up-title")
      assert html =~ ~s(aria-describedby="step-up-description")
      assert html =~ ~s(id="step-up-title")
      assert html =~ ~s(id="step-up-description")
      assert html =~ ~s(<label class="ax-visually-hidden" for="step-up-code">)
      assert html =~ ~s(id="step-up-code")
      assert html =~ ~s(aria-invalid="false")
      assert html =~ ~s(aria-describedby="step-up-description")
      assert html =~ ~s(class="ax-step-up-modal-actions")
      assert html =~ "Re-enter your password to void invoice in_123."
      assert String.match?(html, ~r/step_up_dismiss.*type="submit"/s)

      app_css = File.read!(app_css_path())
      assert app_css =~ ".ax-step-up-modal"
      assert app_css =~ "z-index: var(--ax-z-modal)"
      assert app_css =~ "width: min(42rem, calc(100vw - 2rem))"
    end

    test "connects challenge errors to the modal input" do
      html =
        render_component(&StepUpAuthModal.step_up_auth_modal/1, %{
          pending: true,
          challenge: %{kind: :totp, message: "Enter a current verification code."},
          error: "The verification code expired."
        })

      assert html =~ ~s(id="step-up-error")
      assert html =~ "The verification code expired."
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(aria-describedby="step-up-description step-up-error")
      assert html =~ ~s(<label class="ax-visually-hidden" for="step-up-code">)
      assert html =~ "Verification code"
    end

    test "keeps Phase 191 dismissal and page-flow behavior out of this phase" do
      drawer_source = File.read!("lib/accrue_admin/components/detail_drawer.ex")
      modal_source = File.read!("lib/accrue_admin/components/step_up_auth_modal.ex")
      app_css = File.read!(app_css_path())

      refute drawer_source =~ "phx-window-keydown"
      refute drawer_source =~ "phx-click-away"
      refute modal_source =~ "phx-window-keydown"
      refute modal_source =~ "phx-click-away"
      refute app_css =~ "overflow: hidden !important"
      refute app_css =~ "data-scroll-lock"
      refute app_css =~ "focus-trap"
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

    test "can expose the KPI/chart/table group locator without losing slots" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <KpiCard.kpi_card
            label="Recovered MRR"
            value="$12,450"
            delta="+12.5%"
            delta_tone="moss"
            component_group="kpi-chart-table"
          >
            <:meta>
              <span class="ax-body">Money saved</span>
            </:meta>
            <:sparkline>
              <svg aria-hidden="true"><path d="M0 12 L12 4" /></svg>
            </:sparkline>
          </KpiCard.kpi_card>
          """
        end)

      assert html =~ ~s(data-component-group="kpi-chart-table")
      assert html =~ "Recovered MRR"
      assert html =~ "Money saved"
      assert html =~ "<svg"
    end
  end

  describe "Detail" do
    test "summary card exposes detail-header group locator and preserves slots" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Detail.summary_card eyebrow="Invoice" title="in_123456789012345678901234567890">
            <:status>
              <span class="ax-status-badge-slate">Draft</span>
            </:status>
            <:facts>
              <span>Customer: Northwind Finance</span>
              <span>External reference: ext_123456789012345678901234567890</span>
            </:facts>
            <:actions>
              <a href="/billing/invoices/in_123" class="ax-button ax-button-secondary">Open invoice</a>
            </:actions>
          </Detail.summary_card>
          """
        end)

      assert html =~ ~s(data-component-group="detail-header-metadata-actions")
      assert html =~ "Invoice"
      assert html =~ "Draft"
      assert html =~ "Northwind Finance"
      assert html =~ "Open invoice"
    end

    test "metadata values wrap and detail sections avoid decorative nested card framing" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Detail.detail_section title="Timeline">
            <Detail.detail_field_list fields={[
              %{label: "External ID", value: "cus_1234567890123456789012345678901234567890"}
            ]} />
            <Timeline.timeline
              items={[
                %{title: "Webhook received", status: :queued, body: "Queued for delivery"}
              ]}
            />
          </Detail.detail_section>
          """
        end)

      assert html =~ "ax-field-value"
      assert html =~ "cus_1234567890123456789012345678901234567890"
      assert html =~ "ax-timeline-card"
      refute html =~ ~s(class="ax-card ax-detail-section")

      app_css = File.read!(app_css_path())
      assert app_css =~ ".ax-field-value"
      assert app_css =~ "overflow-wrap: anywhere;"
      assert app_css =~ ".ax-summary-title"
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

      # one ax-timeline-item per item (two fixture items)
      assert length(String.split(html, "ax-timeline-item")) - 1 == 2
      # status renders via the shared StatusBadge
      assert html =~ "ax-status-badge"
      # timestamp renders in a semantic <time> element
      assert html =~ "<time"
      assert html =~ "ax-timeline-time"
      # dedicated empty-state class no longer borrows the filter-chip empty style
      refute html =~ "ax-filter-chip-empty"
    end

    test "renders a dedicated calm empty state with no items" do
      html = render_component(&Timeline.timeline/1, %{items: [], empty_label: "No events yet"})

      assert html =~ "ax-timeline-empty"
      assert html =~ "No events yet"
      refute html =~ "ax-filter-chip-empty"
      refute html =~ "ax-timeline-item"
    end

    test "related resources keep item rhythm without turning each link into a nested card" do
      html =
        render_component(&RelatedResources.related_resources/1, %{
          items: [
            %{
              icon: :users,
              label: "Customer",
              value: "Northwind Finance with a deliberately long external owner reference",
              href: "/billing/customers/cus_123"
            }
          ]
        })

      assert html =~ ~s(class="ax-card ax-related")
      assert html =~ ~s(class="ax-related-item")
      refute html =~ ~s(class="ax-card ax-related-item")
      assert html =~ "Northwind Finance"
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

  defp app_css_path, do: Path.expand("../../../assets/css/app.css", __DIR__)
end
