defmodule Accrue.Processor.Stripe.ErrorMapper do
  @moduledoc """
  Translates raw `LatticeStripe` error shapes into `Accrue.Error` subtypes
  (D-07, PROC-07, OBS-06).

  This is one of only two modules in the entire Accrue codebase allowed to
  reference `LatticeStripe` — the other is `Accrue.Processor.Stripe`. The
  facade-lockdown test in `test/accrue/processor/stripe_test.exs` enforces
  this at CI time (T-PROC-02 mitigation).

  ## Mapping table

  | LatticeStripe.Error.type       | Accrue error            |
  | :----------------------------- | :---------------------- |
  | `:card_error`                  | `%Accrue.CardError{}`   |
  | `:rate_limit_error`            | `%Accrue.RateLimitError{}` |
  | `:idempotency_error`           | `%Accrue.IdempotencyError{}` |
  | `:invalid_request_error`       | `%Accrue.APIError{}`    |
  | `:authentication_error`        | `%Accrue.APIError{}`    |
  | `:api_error`                   | `%Accrue.APIError{}`    |
  | `:connection_error`            | `%Accrue.APIError{}`    |
  | anything else                  | `%Accrue.APIError{code: "unknown"}` |

  ## SignatureError raises, never returns

  Per D-08, any webhook signature verification failure is raised, never
  returned as a tuple. Both the typed
  `%LatticeStripe.Webhook.SignatureVerificationError{}` struct and an
  `invalid_request_error` with code `"signature_verification_failed"`
  trigger an `Accrue.SignatureError` raise.

  ## Metadata preservation

  The full raw error term is stashed in the Accrue error's `:processor_error`
  field so operators can debug the original response. Per T-PROC-01, this
  field MUST NOT be logged verbatim — downstream logging sanitizer is a
  Plan 06 concern.
  """

  @compile {:no_warn_undefined,
            [LatticeStripe.Error, LatticeStripe.Webhook.SignatureVerificationError]}

  @doc """
  Maps an arbitrary term (typically a `%LatticeStripe.Error{}`) to an
  `Accrue.Error` subtype. Raises `Accrue.SignatureError` for signature
  verification failures (never returns them).
  """
  @spec to_accrue_error(term()) :: Exception.t()

  # Webhook signature verification failure — RAISE, never return (D-08).
  def to_accrue_error(%LatticeStripe.Webhook.SignatureVerificationError{} = raw) do
    raise Accrue.SignatureError,
      reason: Map.get(raw, :reason),
      message: Map.get(raw, :message) || "webhook signature verification failed"
  end

  def to_accrue_error(
        %LatticeStripe.Error{
          type: :invalid_request_error,
          code: "signature_verification_failed"
        } = raw
      ) do
    raise Accrue.SignatureError,
      message: raw.message || "webhook signature verification failed",
      reason: :signature_verification_failed
  end

  def to_accrue_error(%LatticeStripe.Error{type: :card_error} = raw) do
    %Accrue.CardError{
      message: raw.message,
      code: raw.code,
      decline_code: raw.decline_code,
      param: raw.param,
      http_status: raw.status,
      request_id: raw.request_id,
      processor_error: raw
    }
  end

  def to_accrue_error(%LatticeStripe.Error{type: :rate_limit_error} = raw) do
    %Accrue.RateLimitError{
      message: raw.message,
      retry_after: retry_after_from(raw),
      http_status: raw.status,
      request_id: raw.request_id,
      processor_error: raw
    }
  end

  def to_accrue_error(%LatticeStripe.Error{type: :idempotency_error} = raw) do
    %Accrue.IdempotencyError{
      message: raw.message,
      idempotency_key: nil,
      processor_error: raw
    }
  end

  def to_accrue_error(%LatticeStripe.Error{type: type} = raw)
      when type in [
             :invalid_request_error,
             :authentication_error,
             :api_error,
             :connection_error
           ] do
    %Accrue.APIError{
      message: raw.message,
      code: raw.code,
      http_status: raw.status,
      request_id: raw.request_id,
      processor_error: raw
    }
  end

  # Unknown LatticeStripe.Error type — still wrap in APIError.
  def to_accrue_error(%LatticeStripe.Error{} = raw) do
    %Accrue.APIError{
      message: raw.message,
      code: raw.code || "unknown",
      http_status: raw.status,
      request_id: raw.request_id,
      processor_error: raw
    }
  end

  # Defensive fallback — anything that isn't a LatticeStripe struct.
  def to_accrue_error(raw) do
    %Accrue.APIError{
      message: "unknown processor error",
      code: "unknown",
      processor_error: raw
    }
  end

  # --- internals ------------------------------------------------------------

  defp retry_after_from(%LatticeStripe.Error{raw_body: %{"retry_after" => v}}), do: v
  defp retry_after_from(_), do: nil
end
