defmodule Accrue.Plug.PutOperationId do
  @moduledoc """
  Sets `Accrue.Actor` operation_id from `conn.assigns[:request_id]` (D3-63).

  Run AFTER `Plug.RequestId` in the host endpoint pipeline so that the
  request_id assign is populated:

      plug Plug.RequestId
      plug Accrue.Plug.PutOperationId

  The operation_id propagates into outbound Stripe idempotency keys
  (via `Accrue.Actor.current_operation_id!/0`) so retries of the same
  HTTP request converge to the same Stripe-side call.

  ## Fallback order

    1. `conn.assigns[:request_id]` — set by `Plug.RequestId`
    2. `x-request-id` header (if RequestId plug is not wired)
    3. Randomly generated `http-<16hex>` sentinel

  The third branch is NOT written back to the header — it is only used
  as a process-local seed. Wire `Plug.RequestId` for deterministic
  request tracing.

  ## Security

  The `x-request-id` header is untrusted attacker input. It is used
  ONLY as the idempotency seed (T-03-07-05) — never for authorization.
  An attacker pinning a value at worst causes their own retries to
  converge to the same Stripe call, which is correct.
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    id =
      conn.assigns[:request_id] ||
        conn |> get_req_header("x-request-id") |> List.first() |> sanitize_header_id() ||
        "http-" <> random_id()

    Accrue.Actor.put_operation_id(id)
    conn
  end

  # WR-07: sanitize attacker-controlled x-request-id header. The plug
  # doc acknowledges the value is untrusted, but the SHA256 input +
  # Oban pdict + accrue_events.data.operation_id + Stripe idempotency
  # key all benefit from length + charset bounds. Invalid → drop to
  # the random fallback.
  defp sanitize_header_id(nil), do: nil

  defp sanitize_header_id(id) when is_binary(id) do
    sanitized = String.replace(id, ~r/[^a-zA-Z0-9_\-]/, "")

    if byte_size(sanitized) in 1..128 do
      "untrusted-" <> sanitized
    else
      nil
    end
  end

  defp sanitize_header_id(_), do: nil

  defp random_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
