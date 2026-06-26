defmodule AccrueAdmin.OverlayComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.Detail
  alias AccrueAdmin.Components.DetailDrawer
  alias AccrueAdmin.Components.Overlay
  alias AccrueAdmin.Components.StepUpAuthModal
  alias AccrueAdmin.Layouts

  describe "Overlay portal and focus contract" do
    test "renders drawer presentation through the body-level overlay root" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Overlay.overlay
            id="subscription-action-drawer"
            open
            presentation={:drawer}
            title="Change plan"
            subtitle="Subscription sub_123"
            close_label="Close action drawer"
            close_event="close_subscription_drawer"
            close_target="#subscription-live"
          >
            <button type="button" data-focus-trap-initial>Save change</button>
          </Overlay.overlay>
          """
        end)

      assert html =~ ~s(data-phx-portal="#ax-overlay-root")
      assert html =~ ~s(data-ax-overlay-shell)
      assert html =~ ~s(data-ax-overlay-panel)
      assert html =~ ~s(data-ax-overlay-backdrop)
      assert html =~ ~s(data-presentation="drawer")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(phx-hook="Overlay")
      assert html =~ ~s(data-focus-trap-close-event="close_subscription_drawer")
      assert html =~ ~s(data-focus-trap-close-target="#subscription-live")
      assert html =~ ~s(data-focus-trap-fallback="#subscription-action-drawer-title")
      assert html =~ ~s(data-scroll-lock)
    end

    test "renders modal presentation with the same overlay substrate" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Overlay.overlay
            id="subscription-step-up"
            open
            presentation={:modal}
            title="Confirm your identity"
            close_label="Cancel"
            close_event="step_up_dismiss"
          >
            <input id="step-up-code" data-focus-trap-initial />
          </Overlay.overlay>
          """
        end)

      assert html =~ ~s(data-phx-portal="#ax-overlay-root")
      assert html =~ ~s(data-presentation="modal")
      assert html =~ ~s(data-ax-overlay-shell)
      assert html =~ ~s(data-ax-overlay-panel)
      assert html =~ ~s(data-ax-overlay-backdrop)
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(phx-hook="Overlay")
      assert html =~ ~s(data-focus-trap-close-event="step_up_dismiss")
      assert html =~ ~s(data-focus-trap-fallback="#subscription-step-up-title")
    end

    test "renders popover presentation without modal semantics" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <Overlay.overlay
            id="subscription-actions-popover"
            open
            presentation={:popover}
            title="More actions"
            close_label="Close actions"
            close_event="close_subscription_actions"
          >
            <button type="button" role="menuitem">Pause collection</button>
          </Overlay.overlay>
          """
        end)

      assert html =~ ~s(data-phx-portal="#ax-overlay-root")
      assert html =~ ~s(data-presentation="popover")
      assert html =~ ~s(data-ax-overlay-shell)
      assert html =~ ~s(data-ax-overlay-panel)
      assert html =~ ~s(role="menu")
      assert html =~ ~s(phx-hook="Overlay")
      refute html =~ ~s(aria-modal="true")
      refute html =~ ~s(data-scroll-lock)
      refute html =~ ~s(data-ax-overlay-backdrop)
    end
  end

  describe "root portal target" do
    test "renders exactly one body-level overlay root after inner content" do
      html =
        render_component(&Layouts.root/1, %{
          inner_content: Phoenix.HTML.raw(~s(<main id="admin-content">Billing</main>)),
          page_title: "Billing"
        })

      assert Regex.scan(~r/id="ax-overlay-root"/, html) |> length() == 1

      assert html =~
               ~r/<body[^>]*>.*<main id="admin-content">Billing<\/main>.*<div id="ax-overlay-root"><\/div>.*<style/s
    end
  end

  describe "Detail summary list" do
    test "renders a semantic summary-list dl with read-only and long value rows" do
      html =
        render_component(fn assigns ->
          assigns =
            assign(assigns, :rows, [
              %{label: "Status", value: "Active, renews normally"},
              %{
                label: "Customer",
                value:
                  Phoenix.HTML.raw(
                    ~s(<a class="ax-link" href="/billing/customers/cus_123">Acme Billing Operations With A Long Account Name</a>)
                  )
              }
            ])

          ~H"""
          <Detail.summary_list rows={@rows} />
          """
        end)

      assert html =~ ~s(<dl)
      assert html =~ ~s(data-ax-summary-list)
      assert html =~ ~s(<dt class="ax-summary-list-key">Status</dt>)
      assert html =~ "Active, renews normally"
      assert html =~ "Acme Billing Operations With A Long Account Name"
      assert html =~ ~s(href="/billing/customers/cus_123")
      refute html =~ ~s(class="ax-summary-list-actions")
    end

    test "renders Change and View row actions with hidden context" do
      html =
        render_component(fn assigns ->
          assigns =
            assign(assigns, :rows, [
              %{
                label: "Plan / price",
                value: "Growth / $49",
                action_label: "Change",
                action_event: "prepare_action",
                action_value: "swap_plan",
                action_target: "#subscription-live",
                action_context: "for subscription sub_123"
              },
              %{
                label: "Dunning",
                value: "No recovery campaign",
                action_label: "View",
                action_href: "#dunning-recovery",
                action_context: "dunning activity for subscription sub_123"
              }
            ])

          ~H"""
          <Detail.summary_list rows={@rows} />
          """
        end)

      assert html =~ ~s(data-ax-summary-list)
      assert html =~ ~s(<button type="button")
      assert html =~ ~s(phx-click="prepare_action")
      assert html =~ ~s(phx-target="#subscription-live")
      assert html =~ ~s(phx-value-action_type="swap_plan")
      assert html =~ ~s(<span>Change</span>)
      assert html =~ ~s(<span class="ax-visually-hidden"> for subscription sub_123</span>)
      assert html =~ ~s(href="#dunning-recovery")
      assert html =~ ~s(<span>View</span>)
      assert html =~
               ~s(<span class="ax-visually-hidden"> dunning activity for subscription sub_123</span>)
    end

    test "keeps detail_field_list available for read-only drill groups" do
      html =
        render_component(fn assigns ->
          assigns = assign(assigns, :fields, [%{label: "Processor", value: "stripe"}])

          ~H"""
          <Detail.detail_field_list fields={@fields} />
          """
        end)

      assert html =~ "ax-field-list"
      assert html =~ ~s(class="ax-field-label")
      assert html =~ ~s(class="ax-field-value")
    end
  end

  describe "Overlay CSS layer and geometry contract" do
    test "defines canonical shell, backdrop, and panel local ordering" do
      app_css = File.read!(app_css_path())

      assert app_css =~ ~r/\.ax-overlay-shell\s*\{[^}]*position: fixed;[^}]*inset: 0;[^}]*isolation: isolate;/s

      assert app_css =~
               ~r/\.ax-overlay-backdrop,\s*\.ax-detail-drawer-backdrop,\s*\.ax-step-up-modal-backdrop\s*\{[^}]*z-index: 0;/s

      assert app_css =~
               ~r/\.ax-overlay-panel\s*\{[^}]*z-index: 1;[^}]*overscroll-behavior: contain;/s
    end

    test "maps overlay presentations to the existing z-token scale" do
      app_css = File.read!(app_css_path())

      assert app_css =~
               ~r/\.ax-overlay-shell\[data-presentation="drawer"\],\s*\.ax-detail-drawer-shell\s*\{[^}]*z-index: var\(--ax-z-drawer\);/s

      assert app_css =~
               ~r/\.ax-overlay-shell\[data-presentation="modal"\],\s*\.ax-step-up-modal-shell\s*\{[^}]*z-index: var\(--ax-z-modal\);/s

      assert app_css =~
               ~r/\.ax-overlay-shell\[data-presentation="popover"\],\s*\.ax-overlay-popover-shell\s*\{[^}]*z-index: var\(--ax-z-popover\);/s
    end

    test "keeps drawer right-docked on desktop and bottom-sheeted below md" do
      app_css = File.read!(app_css_path())

      assert app_css =~
               ~r/@media \(min-width: 768px\).*?\.ax-detail-drawer\s*\{.*?inset: 0 0 0 auto;.*?width: min\(34rem, 92vw\);.*?border-left: 1px solid var\(--ax-border\);.*?border-radius: 0;.*?\}.*?\.ax-drawer-enter-from\s*\{.*?transform: translateX\(100%\);/s

      assert app_css =~
               ~r/@media \(max-width: 767\.98px\).*?\.ax-detail-drawer\s*\{.*?inset: auto 0 0 0;.*?width: 100%;.*?max-height: min\(42rem, calc\(100dvh - var\(--ax-space-lg\)\)\);.*?border-radius: var\(--ax-radius-lg\) var\(--ax-radius-lg\) 0 0;.*?\}.*?\.ax-drawer-enter-from\s*\{.*?transform: translateY\(100%\);/s
    end
  end

  describe "DetailDrawer focus and layer contract" do
    test "renders through Overlay with stable labels and fallback focus target" do
      html =
        render_component(fn assigns ->
          assigns = assigns

          ~H"""
          <DetailDrawer.detail_drawer
            id="webhook-drawer"
            open
            title="Webhook event"
            subtitle="evt_123 queued for retry"
            close_label="Close webhook drawer"
            phx-click="close_webhook_drawer"
            phx-target="#webhook-live"
          >
            Drawer payload content
          </DetailDrawer.detail_drawer>
          """
        end)

      assert html =~ ~s(data-phx-portal="#ax-overlay-root")
      assert html =~ ~s(data-ax-overlay-shell)
      assert html =~ ~s(data-ax-overlay-panel)
      assert html =~ ~s(data-ax-overlay-backdrop)
      assert html =~ ~s(data-presentation="drawer")
      assert html =~ ~s(data-component-group="drawer-form")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="webhook-drawer-title")
      assert html =~ ~s(aria-describedby="webhook-drawer-description")
      assert html =~ ~s(phx-hook="Overlay")
      assert html =~ ~s(data-focus-trap-close-event="close_webhook_drawer")
      assert html =~ ~s(data-focus-trap-close-target="#webhook-live")
      assert html =~ ~s(data-focus-trap-fallback="#webhook-drawer-title")
      assert html =~ ~s(id="webhook-drawer-title")
      assert html =~ ~s(tabindex="-1")
      assert html =~ ~s(data-focus-trap-fallback)
      assert html =~ ~s(class="ax-detail-drawer-backdrop")
      assert html =~ ~s(aria-hidden="true")
    end

    test "keeps drawer panel above its aria-hidden backdrop" do
      app_css = File.read!(app_css_path())

      assert app_css =~ ".ax-detail-drawer-shell"
      assert app_css =~ "z-index: var(--ax-z-drawer)"
      assert app_css =~ ".ax-detail-drawer-backdrop"
      assert app_css =~ "z-index: 0"
      assert app_css =~ ".ax-detail-drawer"
      assert app_css =~ "z-index: 1"
      assert app_css =~ "overflow: auto"
    end
  end

  describe "StepUpAuthModal focus and dismissal contract" do
    test "renders through Overlay as a modal with labelled input, cancel-before-submit order, and explicit dismissal target" do
      html =
        render_component(&StepUpAuthModal.step_up_auth_modal/1, %{
          pending: true,
          challenge: %{kind: :password, message: "Re-enter your password to void invoice in_123."},
          error: nil
        })

      assert html =~ ~s(data-phx-portal="#ax-overlay-root")
      assert html =~ ~s(data-ax-overlay-shell)
      assert html =~ ~s(data-ax-overlay-panel)
      assert html =~ ~s(data-ax-overlay-backdrop)
      assert html =~ ~s(data-presentation="modal")
      assert html =~ ~s(id="accrue-admin-step-up-dialog")
      assert html =~ ~s(data-component-group="modal-confirm")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="step-up-title")
      assert html =~ ~s(aria-describedby="step-up-description")
      assert html =~ ~s(phx-hook="Overlay")
      assert html =~ ~s(data-focus-trap-close-event="step_up_dismiss")
      assert html =~ ~s(data-focus-trap-fallback="#step-up-title")
      assert html =~ ~s(class="ax-step-up-modal-backdrop")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(phx-click="step_up_dismiss")
      assert html =~ ~s(id="step-up-title")
      assert html =~ ~s(tabindex="-1")
      assert html =~ ~s(<label class="ax-visually-hidden" for="step-up-code">)
      assert html =~ ~s(id="step-up-code")
      assert html =~ ~s(data-focus-trap-initial)
      assert String.match?(html, ~r/phx-click="step_up_dismiss".*type="submit"/s)
    end

    test "keeps step-up modal panel above its aria-hidden scrim" do
      app_css = File.read!(app_css_path())

      assert app_css =~ ".ax-step-up-modal-shell"
      assert app_css =~ "z-index: var(--ax-z-modal)"
      assert app_css =~ ".ax-step-up-modal-backdrop"
      assert app_css =~ "z-index: 0"
      assert app_css =~ ".ax-step-up-modal"
      assert app_css =~ "z-index: 1"
      assert app_css =~ "width: min(42rem, calc(100vw - 2rem))"
    end
  end

  defp app_css_path do
    Path.expand("../../../assets/css/app.css", __DIR__)
  end
end
