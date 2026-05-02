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
end
