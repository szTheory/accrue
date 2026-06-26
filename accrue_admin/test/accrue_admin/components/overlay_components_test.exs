defmodule AccrueAdmin.OverlayComponentsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias AccrueAdmin.Components.DetailDrawer
  alias AccrueAdmin.Components.Overlay
  alias AccrueAdmin.Components.StepUpAuthModal

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
