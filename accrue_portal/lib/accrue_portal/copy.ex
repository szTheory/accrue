defmodule AccruePortal.Copy do
  @moduledoc false

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
  def checkout_promo_preview_notice, do: "Preview only. Final total is confirmed after secure submit."
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
  def subscriptions_view_cta, do: "View details"
  def subscriptions_manage_cta, do: "Manage subscriptions"

  def subscriptions_cancel_success,
    do: "Subscription will cancel at the end of the current billing period."

  def subscriptions_cancel_error, do: "Unable to cancel subscription."
  def subscriptions_unknown_error, do: "Subscription not found."

  def subscription_page_title, do: "Subscription"
  def subscription_heading, do: "Subscription details"
  def subscription_status_label, do: "Status"
  def subscription_period_end_label, do: "Current period ends"
  def subscription_identifier_label, do: "Reference"
  def subscription_cancel_heading, do: "Need to stop renewing?"

  def subscription_cancel_body,
    do: "Cancel at period end to keep access through the current billing period."

  def subscription_cancel_cta, do: "Cancel subscription"
  def subscription_keep_cta, do: "Keep subscription"

  def subscription_cancel_success,
    do: "Subscription will cancel at the end of the current billing period."

  def subscription_cancel_error, do: "Unable to cancel subscription."
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
end
