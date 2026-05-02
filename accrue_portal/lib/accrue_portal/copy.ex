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
end
