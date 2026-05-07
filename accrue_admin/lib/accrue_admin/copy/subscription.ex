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
  def subscription_action_pause_collection, do: "Pause collection"
  def subscription_action_create_comp_replacement, do: "Create comp replacement"
  def subscription_action_default_guidance, do: "Default to cancel renewal and keep access through the paid-through date."
  def subscription_action_exception_guidance, do: "Use Cancel now only for explicit hard-stop, support-led, or compliance flows."
  def subscription_action_braintree_guidance, do: "Braintree keeps mounted host-owned lifecycle semantics. Do not imply native pause, unpause, or reversible cancellation support where the action layer rejects it."
  def subscription_action_stripe_guidance, do: "Stripe can natively schedule end-of-period cancellation and resume that scheduled end when the subscription remains active."
  def subscription_lifecycle_ended_label, do: "ended"

  def subscription_page_title, do: "Subscription"
end
