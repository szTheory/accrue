defmodule Accrue.Webhook.CachingBodyReader do
  @moduledoc """
  Custom body reader for `Plug.Parsers` that tees the raw body into
  `conn.assigns[:raw_body]` for webhook signature verification.

  Only used inside the `:accrue_webhook_raw_body` pipeline -- never
  globally. This ensures that non-webhook routes are unaffected by
  raw-body capture.

  ## Usage

      pipeline :accrue_webhook_raw_body do
        plug Plug.Parsers,
          parsers: [:json],
          pass: ["*/*"],
          json_decoder: Jason,
          body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []},
          length: 1_000_000
      end

  ## Implementation

  Chunks are prepended (O(1) cons) during streaming reads and reversed
  at flatten time in the consuming plug. This avoids quadratic binary
  concatenation when the body arrives in multiple chunks.
  """

  @doc """
  Reads the request body and tees it into `conn.assigns[:raw_body]`.

  Returns `{:ok, body, conn}`, `{:more, body, conn}`, or `{:error, reason}`
  matching the `Plug.Conn.read_body/2` contract expected by `Plug.Parsers`.
  """
  @spec read_body(Plug.Conn.t(), keyword()) ::
          {:ok, binary(), Plug.Conn.t()}
          | {:more, binary(), Plug.Conn.t()}
          | {:error, term()}
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:ok, body, conn}

      {:more, body, conn} ->
        conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
        {:more, body, conn}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
