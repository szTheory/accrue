defmodule AccruePortal.Copy do
  @moduledoc false

  alias Accrue.Billing.Subscription

  def checkout_page_title, do: "Checkout"
  def checkout_heading, do: "Checkout"
  def checkout_leave_cta, do: "Leave checkout"
  def checkout_processing_cta, do: "Processing payment..."
  def checkout_missing_nonce_error, do: "Secure card entry did not finish loading. Try again."
  def checkout_session_missing_error, do: "Checkout session not found."
  def checkout_session_expired_title, do: "This checkout link has expired"
  def checkout_session_expired_body, do: "Return to Accrue and start a new subscription."
  def checkout_retry_help, do: "Check the card number, expiration, and CVV, then try again."
  def checkout_promo_label, do: "Promotion code"
  def checkout_promo_hint, do: "Preview savings before you pay."
  def checkout_promo_ready, do: "Discount ready."

  def checkout_promo_preview_notice,
    do: "Preview only. Final total is confirmed after secure submit."

  def checkout_promo_invalid, do: "This code is unavailable. Check the code and try again."
  def checkout_promo_temporarily_unavailable, do: "This promotion is temporarily unavailable."
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

  def home_page_title, do: "Billing portal"
  def home_eyebrow, do: "Customer billing"
  def home_heading, do: "Billing portal"
  def home_body, do: "Review your account and manage subscriptions from one place."
  def home_manage_subscriptions_cta, do: "Manage subscriptions"
  def home_manage_payment_methods_cta, do: "Payment methods"
  def home_manage_invoices_cta, do: "Invoices"
  def home_summary_heading, do: "Account overview"
  def home_subscription_count_label, do: "Subscriptions"
  def home_payment_method_count_label, do: "Payment methods"
  def home_invoice_count_label, do: "Invoices"
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
    "Plan changes stay host-managed for this Braintree subscription."
  end

  def subscriptions_plan_change_host_managed(_subscription) do
    "Open details to review supported plan-change options."
  end

  def subscriptions_cancel_success(%Subscription{processor: "braintree"}),
    do: "Subscription canceled now. Review access changes in your host app."

  def subscriptions_cancel_success(_subscription),
    do: "Cancel renewal scheduled. Access stays on until the current billing period ends."

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
    "Preview the next invoice before you confirm a supported plan change. Quantity, item management, and other billing policy still stay outside this portal."
  end

  def subscription_plan_change_current_label, do: "Current plan"
  def subscription_plan_change_target_label, do: "New plan reference"

  def subscription_plan_change_target_hint,
    do: "Use the host app's plan reference, such as price_pro."

  def subscription_plan_change_preview_cta, do: "Preview plan change"
  def subscription_plan_change_commit_cta, do: "Confirm plan change"
  def subscription_plan_change_reset_cta, do: "Choose a different plan"
  def subscription_plan_change_preview_heading, do: "Preview upcoming invoice"
  def subscription_plan_change_preview_total_label, do: "Preview total"

  def subscription_plan_change_preview_body do
    "This preview is a snapshot before commit. Final billing still follows the provider's current invoice state."
  end

  def subscription_plan_change_preview_unavailable_heading,
    do: "Plan changes stay host-managed here"

  def subscription_plan_change_preview_unavailable_body(%Subscription{processor: "braintree"}) do
    "Braintree plan changes can stay bounded to host-managed next steps. This mounted portal does not preview upcoming invoices for Braintree or offer direct self-serve swaps here."
  end

  def subscription_plan_change_preview_unavailable_body(_subscription) do
    "This subscription does not expose a self-serve plan-change preview from the mounted portal."
  end

  def subscription_plan_change_preview_error do
    "We couldn't preview that plan change. Check the plan reference in your host app and try again."
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
    "Enter the host app's plan reference to preview the change."
  end

  def subscription_cancel_heading(%Subscription{processor: "braintree"}),
    do: "Need to stop now?"

  def subscription_cancel_heading(_subscription), do: "Need to stop renewing?"

  def subscription_cancel_body(%Subscription{processor: "braintree"}) do
    "Braintree supports Cancel now through Accrue.Billing.cancel/2. If you need end-of-term non-renewal instead, keep that softer policy in your host app."
  end

  def subscription_cancel_body(_subscription),
    do:
      "End at period end to turn off renewal now and keep access through the current billing period."

  def subscription_cancel_cta(%Subscription{processor: "braintree"}), do: "Cancel now"
  def subscription_cancel_cta(_subscription), do: "Cancel renewal"
  def subscription_keep_cta, do: "Keep subscription"

  def subscription_cancel_success(%Subscription{processor: "braintree"}),
    do: "Subscription canceled now. Review access changes in your host app."

  def subscription_cancel_success(_subscription),
    do: "Cancel renewal scheduled. Access stays on until the current billing period ends."

  def subscription_cancel_error(%Subscription{processor: "braintree"}),
    do: "Unable to cancel subscription now."

  def subscription_cancel_error(_subscription), do: "Unable to cancel subscription."
  def subscription_not_found_title, do: "Page not found"
  def subscription_not_found_body, do: "We couldn't find that subscription."
  def subscription_back_home_cta, do: "Go to your account home"

  def payment_methods_page_title, do: "Payment Methods"
  def payment_methods_heading, do: "Payment methods"
  def payment_methods_add_cta, do: "Add a card"
  def payment_methods_empty_title, do: "No payment methods on file"

  def payment_methods_empty_body do
    "Add a card to subscribe to plans or update an existing subscription's payment method."
  end

  def payment_methods_default_badge, do: "Default"
  def payment_methods_card_fallback, do: "Card"
  def payment_methods_set_default_cta, do: "Set default"
  def payment_methods_delete_cta, do: "Delete card"

  def payment_methods_delete_success, do: "Payment method deleted."
  def payment_methods_delete_error, do: "Unable to delete payment method."
  def payment_methods_default_success, do: "Default payment method updated."
  def payment_methods_default_error, do: "Unable to update default payment method."

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

  def invoices_page_title, do: "Invoices"
  def invoices_heading, do: "Invoices"
  def invoices_empty_title, do: "No invoices yet"

  def invoices_empty_body do
    "When your first invoice is issued, it will appear here. Paid and open invoices are kept for at least 7 years."
  end

  def invoices_status_label, do: "Status"
  def invoices_open_cta, do: "Open invoice"

  def subscription_lifecycle_label(%Subscription{} = subscription) do
    cond do
      Subscription.canceling?(subscription) -> "Canceling"
      Subscription.paused?(subscription) -> "Paused"
      Subscription.past_due?(subscription) -> "Past due"
      Subscription.canceled?(subscription) -> "Ended"
      Subscription.active?(subscription) -> "Active"
      true -> "Unknown"
    end
  end

  def subscription_lifecycle_summary(%Subscription{} = subscription) do
    cond do
      Subscription.canceling?(subscription) ->
        "Cancel renewal scheduled. Access ends at the current period end."

      Subscription.paused?(subscription) ->
        "Paused. Billing collection is stopped until the subscription is unpaused."

      Subscription.past_due?(subscription) ->
        "Past due. Access may change if payment recovery does not complete."

      Subscription.canceled?(subscription) ->
        "Ended. This subscription is no longer renewing."

      Subscription.active?(subscription) ->
        "Active and renewing."

      true ->
        "Lifecycle status unavailable."
    end
  end

  def subscription_access_timing(%Subscription{} = subscription) do
    cond do
      subscription.processor == "braintree" and not Subscription.canceled?(subscription) ->
        "Braintree immediate cancellation can end access now. Softer end-of-term handling belongs in your host app."

      Subscription.canceling?(subscription) ->
        "Access ends on the current period end date shown below."

      Subscription.canceled?(subscription) ->
        "Access has already ended."

      true ->
        "Changes can take a moment to converge across local projection and provider updates."
    end
  end
end
