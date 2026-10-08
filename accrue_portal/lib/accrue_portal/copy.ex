defmodule AccruePortal.Copy do
  @moduledoc false

  alias Accrue.Billing.Subscription

  def breadcrumb_home, do: "Account"

  def checkout_page_title, do: "Checkout"
  def checkout_heading, do: "Checkout"
  def checkout_leave_cta, do: "Leave checkout"
  def checkout_processing_cta, do: "Processing payment..."
  def checkout_missing_nonce_error, do: "Secure card entry did not finish loading. Try again."
  def checkout_session_missing_error, do: "Checkout session not found."
  def checkout_session_expired_title, do: "This checkout link has expired"
  def checkout_session_expired_body, do: "Return to your account and start a new subscription."
  def checkout_retry_help, do: "Check the card number, expiration, and CVV, then try again."
  def checkout_promo_label, do: "Promotion code"
  def checkout_promo_hint, do: "Preview savings before you pay."
  def checkout_promo_ready, do: "Discount ready."

  def checkout_promo_preview_notice,
    do: "Preview only. Final total is confirmed after secure submit."

  def checkout_promo_invalid, do: "This code is unavailable. Check the code and try again."
  def checkout_promo_temporarily_unavailable, do: "This promotion is temporarily unavailable."
  def checkout_promo_unavailable, do: "This promotion is unavailable. No payment was submitted."
  def checkout_discount_amount_label(amount_text), do: "Estimated savings: " <> amount_text
  def checkout_estimated_total_label(amount_text), do: "Estimated total: " <> amount_text

  def checkout_pay_cta(amount_text) when is_binary(amount_text), do: "Pay " <> amount_text

  def checkout_card_error(message) when is_binary(message) and message != "" do
    "We couldn't process that card. " <> message
  end

  def checkout_card_error(_message), do: "We couldn't process that card."

  def checkout_subscription_error do
    "Your card was charged but we couldn't activate the subscription."
  end

  def home_page_title, do: "#{brand_name()} billing"
  def home_eyebrow, do: "Customer billing"
  def home_heading, do: home_summary_heading()

  def home_body,
    do: "Review your #{brand_name()} account and manage subscriptions from one place."

  def home_manage_subscriptions_cta, do: "Manage subscriptions"
  def home_manage_payment_methods_cta, do: "Payment methods"
  def home_manage_invoices_cta, do: "Invoices"
  def home_summary_heading, do: "Account overview"
  def home_subscription_count_label, do: "Subscriptions"
  def home_payment_method_count_label, do: "Payment methods"
  def home_invoice_count_label, do: "Recent invoices (up to 20)"
  def home_invoice_count_note, do: "Up to 20 recent invoices are shown."
  def home_dashboard_unavailable, do: "Billing data is unavailable. Try again later."
  def home_recent_subscriptions_heading, do: "Recent subscriptions"
  def home_empty_title, do: "Welcome"
  def home_empty_body, do: "You don't have a subscription yet."
  def home_status_prefix, do: "Status"

  def subscriptions_page_title, do: "Subscriptions"
  def subscriptions_heading, do: "Subscriptions"
  def subscriptions_empty_title, do: "No active subscriptions"

  def subscriptions_empty_body do
    "You don't have any active subscriptions on this account. When you subscribe to a plan, it will appear here."
  end

  def subscriptions_status_label, do: "Status"
  def subscriptions_summary_label, do: "Lifecycle"
  def subscriptions_view_cta, do: "View details"
  def subscriptions_manage_cta, do: "Manage subscriptions"

  def subscriptions_plan_change_ready,
    do: "Preview supported plan changes from details before you confirm."

  def subscriptions_plan_change_host_managed(%Subscription{processor: "braintree"}) do
    "Plan changes for this subscription are handled by your account team."
  end

  def subscriptions_plan_change_host_managed(_subscription) do
    "Open details to review available plan-change options."
  end

  def subscriptions_cancel_success(%Subscription{processor: "braintree"}),
    do: "Subscription canceled now. Ask your app host about application access."

  def subscriptions_cancel_success(_subscription),
    do: "Cancel renewal scheduled to stop at the current billing period end."

  def subscriptions_cancel_error(%Subscription{processor: "braintree"}),
    do: "Unable to cancel subscription now."

  def subscriptions_cancel_error(_subscription), do: "Unable to cancel subscription."
  def subscriptions_unknown_error, do: "Subscription not found."

  def subscription_page_title, do: "Subscription"
  def subscription_heading, do: "Subscription details"
  def subscription_status_label, do: "Status"
  def subscription_summary_label, do: "Lifecycle summary"
  def subscription_period_end_label, do: "Current period ends"
  def subscription_identifier_label, do: "Reference"
  def subscription_plan_change_heading, do: "Need to change plans?"

  def subscription_plan_change_body(_subscription) do
    "Preview the next invoice before you confirm a supported plan change."
  end

  def subscription_plan_change_current_label, do: "Current plan"
  def subscription_plan_change_target_label, do: "New plan reference"

  def subscription_plan_change_target_hint,
    do: "Use the plan reference from your workspace billing screen."

  def subscription_plan_change_preview_cta, do: "Preview plan change"
  def subscription_plan_change_commit_cta, do: "Confirm plan change"
  def subscription_plan_change_reset_cta, do: "Choose a different plan"
  def subscription_plan_change_preview_heading, do: "Preview upcoming invoice"
  def subscription_plan_change_preview_total_label, do: "Preview total"

  def subscription_plan_change_preview_body do
    "This preview is a snapshot before commit. Final billing still follows the provider's current invoice state."
  end

  def subscription_plan_change_preview_unavailable_heading,
    do: "Plan changes are not self-serve here"

  def subscription_plan_change_preview_unavailable_body(%Subscription{processor: "braintree"}) do
    "This subscription does not offer direct self-serve invoice previews in the portal."
  end

  def subscription_plan_change_preview_unavailable_body(_subscription) do
    "This subscription does not expose a self-serve plan-change preview from the mounted portal."
  end

  def subscription_plan_change_preview_error do
    "We couldn't preview that plan change. Check the plan reference and try again."
  end

  def subscription_plan_change_commit_success do
    "Plan updated. Review the refreshed billing summary below."
  end

  def subscription_plan_change_commit_error do
    "We couldn't confirm that plan change."
  end

  def subscription_plan_change_requires_preview do
    "Preview the plan change before confirming it."
  end

  def subscription_plan_change_missing_reference do
    "Enter a plan reference to preview the change."
  end

  def subscription_cancel_heading(%Subscription{processor: "braintree"}),
    do: "Need to stop now?"

  def subscription_cancel_heading(_subscription), do: "Need to stop renewing?"

  def subscription_cancel_body(%Subscription{processor: "braintree"}) do
    "Braintree cancels this subscription immediately. Ask your app host about application access."
  end

  def subscription_cancel_body(_subscription),
    do: "End at period end to turn off renewal now and keep billing through the current period."

  def subscription_cancel_cta(%Subscription{processor: "braintree"}), do: "Cancel now"
  def subscription_cancel_cta(_subscription), do: "Cancel renewal"
  def subscription_keep_cta, do: "Keep subscription"

  def subscription_cancel_success(%Subscription{processor: "braintree"}),
    do: "Subscription canceled now. Ask your app host about application access."

  def subscription_cancel_success(_subscription),
    do: "Cancel renewal scheduled to stop at the current billing period end."

  def subscription_cancel_error(%Subscription{processor: "braintree"}),
    do: "Unable to cancel subscription now."

  def subscription_cancel_error(_subscription), do: "Unable to cancel subscription."
  def subscription_recovery_heading, do: "Your payment didn't go through"

  def subscription_recovery_body do
    "We couldn't process your most recent payment. Update your payment method to keep your subscription active."
  end

  def subscription_recovery_cta, do: "Update payment method"

  def subscription_not_found_title, do: "Page not found"
  def subscription_not_found_body, do: "We couldn't find that subscription."
  def subscription_unavailable_title, do: "Subscription unavailable"

  def subscription_unavailable_body,
    do: "Subscription details could not be loaded. Try again in a moment."

  def subscriptions_unavailable_title, do: "Subscriptions unavailable"

  def subscription_cancel_requires_confirmation,
    do: "Confirm the displayed cancellation before submitting it."

  def subscription_cancel_unavailable,
    do: "Cancellation is no longer available for this subscription. Refresh and try again."

  def subscription_cancel_not_available,
    do: "Cancellation isn't available for this provider or observed subscription state."

  def subscriptions_unavailable_body do
    "Subscriptions could not be loaded for this account. Try again in a moment."
  end

  def subscription_back_home_cta, do: "Go to your account home"

  def subscription_cancel_confirmation(billed_identity, subscription_reference) do
    "Billing for #{billed_identity}: confirm cancellation of subscription #{subscription_reference}."
  end

  def payment_methods_page_title, do: "Payment Methods"
  def payment_methods_heading, do: "Payment methods"
  def payment_methods_add_cta, do: "Add a card"
  def payment_methods_empty_title, do: "No payment methods on file"

  def payment_methods_empty_body do
    "Add a card to subscribe to plans or update an existing subscription's payment method."
  end

  def payment_methods_empty_read_only_body, do: "No payment methods are on file for this account."

  def payment_methods_unavailable_title, do: "Payment methods unavailable"

  def payment_methods_unavailable_body do
    "Payment methods are temporarily unavailable. Try again in a moment."
  end

  def payment_methods_unsupported_title, do: "Payment methods unavailable"

  def payment_methods_unsupported_body do
    "Saved payment method management isn't available for this billing provider."
  end

  def payment_methods_default_badge, do: "Default"
  def payment_methods_card_fallback, do: "Card"
  def payment_methods_set_default_cta, do: "Set default"
  def payment_methods_delete_cta, do: "Delete card"

  def payment_methods_delete_success, do: "Payment method deleted."
  def payment_methods_delete_error, do: "Unable to delete payment method."
  def payment_methods_default_success, do: "Default payment method updated."
  def payment_methods_default_error, do: "Unable to update default payment method."

  def payment_methods_set_default_confirmation(billed_identity, card_label) do
    "Set #{card_label} as the default payment method for #{billed_identity}? " <>
      "Future billing that uses the account default will use this card."
  end

  def payment_methods_default_removal_blocked,
    do: "Set another card as default before removing this one."

  def payment_methods_delete_confirmation(billed_identity, card_label) do
    "Remove #{card_label} from the saved payment methods for #{billed_identity}? " <>
      "Future payments that need this saved card may require another card."
  end

  def add_payment_method_page_title, do: "Add Payment Method"
  def add_payment_method_heading, do: "Add payment method"

  def add_payment_method_body do
    "Save a card for future subscriptions and billing updates."
  end

  def add_payment_method_card_number_label, do: "Card number"
  def add_payment_method_expiration_label, do: "Expiration"
  def add_payment_method_cvv_label, do: "CVV"
  def add_payment_method_save_cta, do: "Save card"
  def add_payment_method_discard_cta, do: "Discard card"
  def add_payment_method_save_success, do: "Payment method saved."
  def add_payment_method_save_error, do: "Unable to save payment method."
  def add_payment_method_nonce_error, do: "Payment method tokenization failed."
  def payment_method_create_denied, do: "You don't have permission to add payment methods."

  def payment_method_create_unavailable,
    do: "Card entry isn't available for this billing provider."

  def invoices_page_title, do: "Invoices"
  def invoices_heading, do: "Invoices"
  def invoices_empty_title, do: "No invoices yet"

  def invoices_empty_body do
    "When your first invoice is issued, it will appear here."
  end

  def invoices_empty_next_step, do: "Check back after an invoice is issued."
  def invoices_recent_note, do: "Showing up to 20 recent invoices."

  def invoices_unavailable_body,
    do: "Invoices are temporarily unavailable. Try again in a moment."

  def invoices_retry_cta, do: "Try again"

  def invoices_status_label, do: "Status"
  def invoices_open_cta, do: "Open invoice"

  def subscription_lifecycle_label(%Subscription{} = subscription) do
    cond do
      Subscription.canceling?(subscription) ->
        "Canceling"

      Subscription.canceled?(subscription) ->
        "Ended"

      Subscription.paused?(subscription) ->
        "Paused"

      subscription.status == :trialing ->
        "Trialing"

      subscription.status == :incomplete ->
        "Incomplete"

      subscription.status == :unpaid ->
        "Unpaid"

      subscription.status == :past_due ->
        "Past due"

      subscription.cancel_at_period_end == true or not is_nil(subscription.cancel_at) ->
        "Cancellation scheduled"

      subscription.status == :active ->
        "Active"

      true ->
        "Unknown"
    end
  end

  def subscription_lifecycle_summary(%Subscription{} = subscription) do
    cond do
      Subscription.canceling?(subscription) ->
        "Renewal is scheduled to stop at the current period end."

      Subscription.canceled?(subscription) ->
        "Billing reports that this subscription has ended."

      Subscription.paused?(subscription) ->
        "Billing reports this subscription as paused."

      subscription.status == :trialing ->
        "A trial is in progress."

      subscription.status == :incomplete ->
        "Subscription setup is incomplete."

      subscription.status == :unpaid ->
        "Billing reports this subscription as unpaid."

      Subscription.past_due?(subscription) ->
        "Payment is past due. Review billing details or update the payment method."

      subscription.cancel_at_period_end == true or not is_nil(subscription.cancel_at) ->
        "A cancellation is scheduled, but its effective date is unavailable."

      subscription.status == :active ->
        "Billing reports this subscription as active."

      true ->
        "Lifecycle status unavailable."
    end
  end

  def subscription_access_timing(%Subscription{} = subscription) do
    cond do
      Subscription.canceled?(subscription) ->
        "Billing reports this subscription has ended."

      Subscription.canceling?(subscription) ->
        "The current billing period ends at the displayed date."

      Subscription.paused?(subscription) ->
        "Billing reports this subscription as paused."

      subscription.processor == "braintree" and
        (Subscription.active?(subscription) or Subscription.past_due?(subscription)) and
        not Subscription.paused?(subscription) and subscription.cancel_at_period_end == false and
          is_nil(subscription.cancel_at) ->
        "Application access is controlled by your app host."

      subscription.cancel_at_period_end == true and is_nil(subscription.current_period_end) ->
        "A cancellation is scheduled, but the period end date is unavailable."

      true ->
        "Billing period details reflect the processor record. Application access is controlled by your app host."
    end
  end

  defp brand_name do
    Accrue.Config.branding(:business_name)
  rescue
    _ -> "Billing"
  end
end
