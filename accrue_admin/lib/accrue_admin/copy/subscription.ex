defmodule AccrueAdmin.Copy.Subscription do
  @moduledoc false

  # Subscription detail (SubscriptionLive) — Phase 50, ADM-04

  def subscription_breadcrumb_subscriptions, do: "Subscriptions"

  def subscription_detail_eyebrow, do: "Subscription detail"

  def subscription_kpi_section_aria_label, do: "Subscription lifecycle summary"

  def subscription_proration_create, do: "Create prorations"
  def subscription_proration_none, do: "No proration"
  def subscription_proration_always_invoice, do: "Always invoice"

  def subscription_kpi_status_label, do: "Status"
  def subscription_kpi_canonical_predicates_label, do: "Canonical predicates"
  def subscription_kpi_timeline_rows_label, do: "Timeline rows"

  def subscription_action_cancel_now, do: "Cancel now"
  def subscription_action_cancel_at_period_end, do: "Cancel at period end"
  def subscription_action_resume, do: "Resume"
  def subscription_action_swap_plan, do: "Swap plan"
  def subscription_action_update_quantity, do: "Update quantity"
  def subscription_action_add_item, do: "Add item"
  def subscription_action_update_item_quantity, do: "Update item quantity"
  def subscription_action_remove_item, do: "Remove item"
  def subscription_action_pause_collection, do: "Pause collection"
  def subscription_action_create_comp_replacement, do: "Create comp replacement"
  def subscription_action_preview_heading, do: "Preview upcoming invoice"
  def subscription_action_preview_total_label, do: "Preview total"
  def subscription_action_item_id_label, do: "Subscription item"
  def subscription_action_quantity_label, do: "Quantity"

  def subscription_action_supported_change_guidance,
    do:
      "Stripe and Fake support preview-backed plan swaps plus operator-managed quantity and subscription-item changes on the official active-subscription-change lane."

  def subscription_action_single_item_quantity_guidance,
    do:
      "Quantity changes apply to the single-item subscription lane. Once add-on items exist, use item-level actions instead of the top-level quantity mutation."

  def subscription_action_default_guidance,
    do: "Default to cancel renewal and keep access through the paid-through date."

  def subscription_action_exception_guidance,
    do: "Use Cancel now only for explicit hard-stop, support-led, or compliance flows."

  def subscription_action_braintree_guidance,
    do:
      "Braintree supports immediate cancellation through Accrue.Billing.cancel/2 and bounded first-party plan swaps when the host configures :plan_resolver. Preview is unavailable for this provider, and scheduled end-of-period, reversible cancellation, pause, and unpause semantics remain host-owned or unsupported."

  def subscription_action_braintree_swap_setup_guidance,
    do:
      "Configure :plan_resolver before exposing Braintree swap_plan/3 through admin. Accrue needs host-owned plan metadata to resolve the target Braintree plan id and amount."

  def subscription_action_braintree_quantity_item_guidance,
    do:
      "Braintree does not expose first-party quantity or subscription-item mutations through Accrue. Keep those adjustments host-owned or move the customer onto a provider that supports the official active-subscription-change lane."

  def subscription_action_stripe_guidance,
    do:
      "Stripe can natively schedule end-of-period cancellation and resume that scheduled end when the subscription remains active. Fake mirrors the supported change flow locally for merge-blocking operator proof."

  def subscription_lifecycle_ended_label, do: "ended"

  def subscription_page_title, do: "Subscription"
end
