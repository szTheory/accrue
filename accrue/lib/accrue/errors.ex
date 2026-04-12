defmodule Accrue.APIError do
  @moduledoc """
  Raised when a processor call fails for a reason that is neither a card
  error nor a rate limit (e.g., HTTP 500, unexpected payload). Pattern-match
  on `%Accrue.APIError{}` in retry logic.

  > ⚠️ `processor_error` may contain raw processor payload and MUST NOT be
  > logged verbatim — downstream logging sanitizer in Plan 06. Mitigates
  > T-FND-05.
  """
  defexception [:message, :code, :http_status, :request_id, :processor_error]
end

defmodule Accrue.CardError do
  @moduledoc """
  Raised when the processor rejects a card (declined, expired, insufficient
  funds, etc.). Mirrors Stripe's card-error shape 1:1.

  > ⚠️ `processor_error` may contain raw processor payload and MUST NOT be
  > logged verbatim. Mitigates T-FND-05.
  """
  defexception [:message, :code, :decline_code, :param, :http_status, :request_id, :processor_error]

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
  defexception [:message, :key]

  @impl true
  def message(%__MODULE__{message: m}) when is_binary(m) and m != "", do: m
  def message(%__MODULE__{key: key}), do: "missing accrue config key: #{inspect(key)}"
end
