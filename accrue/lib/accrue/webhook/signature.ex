defmodule Accrue.Webhook.Signature do
  @moduledoc """
  Webhook signature verification. Delegates entirely to
  `LatticeStripe.Webhook.construct_event!/4` (D2-22).

  Accrue does NOT implement HMAC verification -- lattice_stripe handles
  timing-safe compare, replay tolerance, and multi-secret rotation.
  """

  @doc """
  Verifies the webhook signature and returns the parsed
  `%LatticeStripe.Event{}`.

  Raises `Accrue.SignatureError` on failure.

  `secrets` may be a single string or a list of strings for key
  rotation (D2-05, T-2-05).

  ## Options

    * `:tolerance` - max age in seconds for replay protection
      (default: 300, matching Stripe's default window)
  """
  @spec verify!(binary(), String.t() | nil, String.t() | [String.t()], keyword()) ::
          LatticeStripe.Event.t()
  def verify!(raw_body, sig_header, secrets, opts \\ []) do
    tolerance = Keyword.get(opts, :tolerance, 300)

    LatticeStripe.Webhook.construct_event!(raw_body, sig_header, secrets, tolerance: tolerance)
  rescue
    e in LatticeStripe.Webhook.SignatureVerificationError ->
      reraise Accrue.SignatureError, [reason: Exception.message(e)], __STACKTRACE__
  end
end
