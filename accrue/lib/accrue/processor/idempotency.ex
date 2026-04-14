defmodule Accrue.Processor.Idempotency do
  @moduledoc """
  Deterministic idempotency key and subject UUID derivation for Phase 3
  processor operations (D3-60, D3-61, D3-64).

  Same `(op, subject_id, operation_id, sequence)` tuple → same key →
  retries converge without side channel. Unlike
  `Accrue.Processor.Stripe.compute_idempotency_key/3` (which produces the
  short `accr_<22b64>` form for Stripe's `Idempotency-Key` HTTP header,
  D2-11), this module exposes:

  - `key/4` — deterministic 64-hex-char SHA256 key prefixed with the op
    name. Used by Wave 2 billing context functions that need to derive a
    stable idempotency token from `(op, subject_id, operation_id,
    sequence)` before calling the processor (D3-60).
  - `subject_uuid/2` — deterministic Ecto.UUID-shape string derived from
    `(op, operation_id)`. Used when the caller needs a stable v4-shaped
    UUID for a new primary key before the processor call commits
    (D3-61).

  ## Examples

      iex> Accrue.Processor.Idempotency.key(:create_subscription, "sub_123", "op_abc")
      "create_subscription_" <> _

      iex> uuid = Accrue.Processor.Idempotency.subject_uuid(:create_subscription, "op_abc")
      iex> {:ok, _} = Ecto.UUID.cast(uuid)

  ## Security

  SHA256 over a canonical `op|subject|operation|seq` tuple; collision
  probability is negligible. The key is NOT secret — it is safe to log —
  but it MUST NOT be used as an authorization token.
  """

  @type op :: atom() | String.t()

  @doc """
  Derives a deterministic idempotency key from `(op, subject_id,
  operation_id, sequence)`.

  Output format: `"\#{op}_\#{sha256_hex}"` where `sha256_hex` is the
  64-character lowercase hex encoding of
  `SHA256("\#{op}|\#{subject_id}|\#{operation_id}|\#{sequence}")`.
  """
  @spec key(op(), String.t(), String.t(), non_neg_integer()) :: String.t()
  def key(op, subject_id, operation_id, sequence \\ 0)
      when is_binary(subject_id) and is_binary(operation_id) and is_integer(sequence) and
             sequence >= 0 do
    op_str = to_string(op)

    hash =
      :sha256
      |> :crypto.hash("#{op_str}|#{subject_id}|#{operation_id}|#{sequence}")
      |> Base.encode16(case: :lower)

    "#{op_str}_#{hash}"
  end

  @doc """
  Derives a deterministic Ecto.UUID v4-shaped string from `(op,
  operation_id)`. Useful when a caller needs to pre-allocate a stable
  primary key before the processor call commits (D3-61).

  The result passes `Ecto.UUID.cast/1` and has the v4 version nibble and
  RFC 4122 variant bits set so it is spec-conformant.
  """
  @spec subject_uuid(op(), String.t()) :: String.t()
  def subject_uuid(op, operation_id) when is_binary(operation_id) do
    op_str = to_string(op)

    raw =
      :crypto.hash(:sha256, "#{op_str}|#{operation_id}")
      |> binary_part(0, 16)

    # Force v4 UUID shape: set version nibble to 4 and variant to 10xx.
    <<a::48, _ver::4, b::12, _var::2, c::62>> = raw
    bin = <<a::48, 4::4, b::12, 2::2, c::62>>
    Ecto.UUID.cast!(bin)
  end
end
