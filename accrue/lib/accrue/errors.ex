defmodule Accrue.Error do
  @moduledoc false
  @type t :: Exception.t()
end

defmodule Accrue.APIError do
  @moduledoc """
  Raised when a processor call fails for a reason that is neither a card
  error nor a rate limit (e.g., HTTP 500, unexpected payload). Pattern-match
  on `%Accrue.APIError{}` in retry logic.

  > ⚠️ `processor_error` may contain raw processor payload and MUST NOT be
  > logged verbatim — downstream logging sanitizer in Plan 06. Mitigates
  > T-FND-05.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :code, :http_status, :request_id, :processor_error]
end

defmodule Accrue.CardError do
  @moduledoc """
  Raised when the processor rejects a card (declined, expired, insufficient
  funds, etc.). Mirrors Stripe's card-error shape 1:1.

  > ⚠️ `processor_error` may contain raw processor payload and MUST NOT be
  > logged verbatim. Mitigates T-FND-05.
  """
  @type t :: %__MODULE__{}
  defexception [
    :message,
    :code,
    :decline_code,
    :param,
    :http_status,
    :request_id,
    :processor_error
  ]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{code: code, decline_code: decline, param: param}) do
    base = code || "card_error"
    decline_frag = if decline, do: " (#{decline})", else: ""
    param_frag = if param, do: " on #{param}", else: ""
    "#{base}#{decline_frag}#{param_frag}"
  end
end

defmodule Accrue.RateLimitError do
  @moduledoc """
  Raised when the processor returns a rate-limit response (HTTP 429). The
  `retry_after` field carries the server's suggested backoff in seconds.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :retry_after, :http_status, :request_id, :processor_error]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{retry_after: nil}), do: "rate limited by processor"
  def message(%__MODULE__{retry_after: secs}), do: "rate limited; retry after #{secs}s"
end

defmodule Accrue.IdempotencyError do
  @moduledoc """
  Raised when the processor rejects an idempotency key replay (e.g., same
  key used for a different request body). Pattern-match on
  `%Accrue.IdempotencyError{}` to surface a user-facing "this request was
  already processed" message.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :idempotency_key, :processor_error]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{idempotency_key: key}) when is_binary(key),
    do: "idempotency key #{inspect(key)} conflicted with a prior request"

  def message(_), do: "idempotency key conflict"
end

defmodule Accrue.DecodeError do
  @moduledoc """
  Raised when a processor response body cannot be decoded (malformed JSON,
  unexpected shape). The `payload` field holds the raw binary for
  debugging — treat as sensitive; do not log verbatim.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :payload]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(_), do: "failed to decode processor response"
end

defmodule Accrue.SignatureError do
  @moduledoc """
  Raised when a webhook signature fails verification. Per D-08, this is
  NEVER returned as a tuple — a bad signature is either a misconfiguration
  or an attacker, and neither is recoverable at the call site. The webhook
  plug translates this raise into an HTTP 400.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :reason]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{reason: nil}), do: "webhook signature verification failed"
  def message(%__MODULE__{reason: reason}), do: "webhook signature verification failed: #{reason}"
end

defmodule Accrue.ConfigError do
  @moduledoc """
  Raised when `Accrue.Config` validation fails, or when a key is looked up
  that is neither set at runtime nor has a schema default.
  """
  @type t :: %__MODULE__{}
  defexception [:message, :key]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{key: key}), do: "missing accrue config key: #{inspect(key)}"
end

defmodule Accrue.Auth.StepUpUnconfigured do
  @moduledoc """
  Raised when a destructive admin action requires step-up verification but
  the configured auth adapter does not implement the optional callbacks.
  """
  @type t :: %__MODULE__{}
  defexception [:message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(_), do: "admin step-up auth is not configured"
end

defmodule Accrue.Error.MultiItemSubscription do
  @moduledoc """
  Raised when a Phase 3 convenience call (e.g., `update_quantity/3`) is
  made against a subscription that has more than one `SubscriptionItem`.
  Multi-item subscriptions are a Phase 4 concern; Phase 3 enforces the
  single-item invariant and points callers at the Phase 4 surface.
  """
  @type t :: %__MODULE__{}
  defexception [:subscription_id, :item_count, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{subscription_id: sub_id, item_count: count}) do
    "subscription #{inspect(sub_id)} has #{count} items; " <>
      "use Accrue.Billing.update_items/3 (Phase 4) for multi-item subscriptions"
  end
end

defmodule Accrue.Error.InvalidState do
  @moduledoc """
  Raised when a state-machine transition is attempted from an illegal
  source state (e.g., `pay_invoice/2` on a `:void` invoice, `resume/2`
  on an `:active` subscription).
  """
  @type t :: %__MODULE__{}
  defexception [:current, :attempted, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{current: current, attempted: attempted}) do
    "invalid state transition: cannot #{inspect(attempted)} from #{inspect(current)}"
  end
end

defmodule Accrue.Error.NotAttached do
  @moduledoc """
  Raised when a payment method is referenced for a customer it is not
  attached to (e.g., `set_default_payment_method/3` with a `pm_id` that
  belongs to a different customer).
  """
  @type t :: %__MODULE__{}
  defexception [:customer_id, :payment_method_id, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{customer_id: cus_id, payment_method_id: pm_id}) do
    "payment method #{inspect(pm_id)} is not attached to customer #{inspect(cus_id)}"
  end
end

defmodule Accrue.Error.NoDefaultPaymentMethod do
  @moduledoc """
  Raised when a charge or subscription call requires a default payment
  method and the customer has none set. Callers should surface a
  user-facing "add a payment method" prompt.
  """
  @type t :: %__MODULE__{}
  defexception [:customer_id, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{customer_id: cus_id}) do
    "customer #{inspect(cus_id)} has no default payment method"
  end
end

defmodule Accrue.ActionRequiredError do
  @moduledoc """
  Raised when a Stripe PaymentIntent or SetupIntent transitions to
  `requires_action` (SCA / 3DS). The `:payment_intent` field carries the
  full PaymentIntent payload so callers can extract `client_secret` and
  drive the Stripe.js confirmation flow on the frontend.

  This is a distinct exception from `Accrue.CardError` because it is NOT
  a failure — the charge is still recoverable, it just needs the
  customer to complete an authentication step.
  """
  @type t :: %__MODULE__{}
  defexception [:payment_intent, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{}),
    do: "Stripe requires customer action (SCA/3DS); inspect :payment_intent"
end

defmodule Accrue.PDF.RenderFailed do
  @moduledoc """
  Raised from `Accrue.Workers.Mailer.perform/1` when
  `Accrue.Billing.render_invoice_pdf/2` returns a non-terminal
  `{:error, reason}` (i.e., not `%Accrue.Error.PdfDisabled{}` and not
  `:chromic_pdf_not_started`). Raising this exception lets Oban backoff
  handle transient render failures — the mailer job is retried per its
  `max_attempts` setting.

  Terminal errors (Null adapter + missing ChromicPDF supervisor child)
  are NOT wrapped in this exception — they route to the hosted-invoice
  URL fallback per D6-04.
  """

  @type t :: %__MODULE__{}
  defexception [:reason, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{reason: r}), do: "PDF render failed: #{inspect(r)}"
end

defmodule Accrue.Error.PdfDisabled do
  @moduledoc """
  Raised / returned when the configured PDF adapter is `Accrue.PDF.Null`
  (D6-06). Expected and terminal — callers MUST pattern-match and fall
  through to a non-PDF path (e.g., link to `hosted_invoice_url` instead
  of attaching a rendered binary). Oban workers MUST NOT treat this as
  a transient retry; it is a stable adapter configuration, not a
  failure.
  """

  @type t :: %__MODULE__{}
  defexception [:reason, :docs_url, :message]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m

  def message(%__MODULE__{}),
    do: "PDF rendering disabled on this Accrue instance (Accrue.PDF.Null configured)"
end
