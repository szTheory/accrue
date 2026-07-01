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

  def subscription_action_cancel_now, do: "Cancel immediately"
  def subscription_action_cancel_at_period_end, do: "Cancel renewal"
  def subscription_action_resume, do: "Resume"
  def subscription_action_swap_plan, do: "Change plan"
  def subscription_action_update_quantity, do: "Update quantity"
  def subscription_action_add_item, do: "Add item"
  def subscription_action_update_item_quantity, do: "Update item quantity"
  def subscription_action_remove_item, do: "Remove item"
  def subscription_action_pause_collection, do: "Pause collection"
  def subscription_action_create_comp_replacement, do: "Comp this subscription"
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

  def subscription_confirm_workflow_message(action_type, opts) do
    subscription_id =
      subscription_reference(Keyword.get(opts, :subscription_id, "this subscription"))

    customer_id = Keyword.get(opts, :customer_id, "this customer")
    source_event_id = Keyword.get(opts, :source_event_id)
    source = source_suffix(source_event_id)

    "#{subscription_action_label(action_type)} #{subscription_id}: This will #{subscription_billing_effect(action_type)} for customer #{customer_id} and record an admin audit row.#{source} Confirm subscription change."
  end

  def subscription_lifecycle_ended_label, do: "ended"

  def subscription_page_title, do: "Subscription"

  def subscriptions_list_first_run_empty_title, do: "No subscriptions yet."

  def subscriptions_list_first_run_empty_body,
    do: "Subscriptions appear after a customer completes checkout."

  def subscriptions_list_queue_empty_title, do: "Nothing at risk."

  def subscriptions_list_queue_empty_body,
    do: "No past-due or canceling subscriptions. View All to see every subscription."

  def subscriptions_list_filtered_empty_title, do: "No subscriptions match these filters."

  def subscriptions_list_filtered_empty_body,
    do: "Clear filters or adjust the search to see subscriptions."

  def subscriptions_list_loading_label, do: "Loading subscriptions."

  def subscriptions_list_plan_amount_unavailable, do: "Plan and amount unavailable"

  defp subscription_action_label("cancel_now"), do: "Cancel immediately"
  defp subscription_action_label("cancel_at_period_end"), do: "Cancel renewal"
  defp subscription_action_label("pause"), do: "Pause subscription collection"
  defp subscription_action_label("resume"), do: "Resume subscription"
  defp subscription_action_label("swap_plan"), do: "Change plan"
  defp subscription_action_label("update_quantity"), do: "Update subscription quantity"
  defp subscription_action_label("add_item"), do: "Add subscription item"
  defp subscription_action_label("update_item_quantity"), do: "Update subscription item quantity"
  defp subscription_action_label("remove_item"), do: "Remove subscription item"
  defp subscription_action_label("comp_subscription"), do: "Comp this subscription"
  defp subscription_action_label(action_type), do: "Run #{humanize_action(action_type)}"

  defp subscription_reference("this subscription"), do: "this subscription"

  defp subscription_reference(subscription_id) do
    value = to_string(subscription_id)

    if String.starts_with?(value, "subscription ") do
      value
    else
      "subscription #{value}"
    end
  end

  defp subscription_billing_effect("cancel_now"),
    do:
      "Cancel now will execute against the local billing projection and end the current billing period immediately where the provider supports immediate cancellation"

  defp subscription_billing_effect("cancel_at_period_end"),
    do:
      "turn off renewal now and preserve access through the current billing period where the processor supports that semantic"

  defp subscription_billing_effect("pause"),
    do: "pause collection without deleting the subscription record"

  defp subscription_billing_effect("resume"),
    do: "resume billing from the current subscription state"

  defp subscription_billing_effect("swap_plan"),
    do:
      "Swap plan stages a preview before commit where the provider supports upcoming-invoice previews. This will change the plan and apply the selected proration behavior"

  defp subscription_billing_effect("update_quantity"),
    do: "change the top-level subscription quantity"

  defp subscription_billing_effect("add_item"),
    do: "add a subscription item to the billing schedule"

  defp subscription_billing_effect("update_item_quantity"),
    do: "change the selected subscription item quantity"

  defp subscription_billing_effect("remove_item"),
    do: "remove the selected subscription item from future billing"

  defp subscription_billing_effect(action_type),
    do: "run #{humanize_action(action_type)} through the subscription workflow"

  defp source_suffix(nil), do: ""
  defp source_suffix(""), do: ""
  defp source_suffix(source_event_id), do: " Source event ##{source_event_id} will be linked."

  defp humanize_action(action_type) do
    action_type
    |> to_string()
    |> String.replace("_", " ")
  end
end
