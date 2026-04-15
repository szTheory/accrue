defmodule AccrueAdmin.Queries.Cursor do
  @moduledoc """
  Opaque signed cursor tokens for admin list pagination.

  Cursors encode `{timestamp, id}` tuples and are HMAC-signed so tampered
  values fail closed.
  """

  @secret_key {__MODULE__, :secret}
  @salt "accrue_admin:queries:cursor"

  @type value :: {DateTime.t(), Ecto.UUID.t()}

  @spec encode(DateTime.t(), Ecto.UUID.t()) :: binary()
  def encode(%DateTime{} = timestamp, id) when is_binary(id) do
    payload =
      {DateTime.to_iso8601(DateTime.truncate(timestamp, :microsecond)), id}
      |> :erlang.term_to_binary()

    signature = sign(payload)

    [Base.url_encode64(payload, padding: false), Base.url_encode64(signature, padding: false)]
    |> Enum.join(".")
  end

  @spec decode(binary() | nil) :: {:ok, value()} | :error
  def decode(nil), do: :error
  def decode(""), do: :error

  def decode(cursor) when is_binary(cursor) do
    with [payload_token, signature_token] <- String.split(cursor, ".", parts: 2),
         {:ok, payload} <- Base.url_decode64(payload_token, padding: false),
         {:ok, signature} <- Base.url_decode64(signature_token, padding: false),
         true <- Plug.Crypto.secure_compare(signature, sign(payload)),
         {timestamp, id} <- :erlang.binary_to_term(payload, [:safe]),
         {:ok, datetime, _offset} <- DateTime.from_iso8601(timestamp),
         true <- is_binary(id) do
      {:ok, {DateTime.truncate(datetime, :microsecond), id}}
    else
      _ -> :error
    end
  end

  defp sign(payload) do
    :crypto.mac(:hmac, :sha256, secret(), @salt <> payload)
  end

  defp secret do
    case :persistent_term.get(@secret_key, nil) do
      nil ->
        secret =
          case Application.get_env(:accrue_admin, :cursor_secret) do
            value when is_binary(value) and byte_size(value) > 0 -> value
            _ -> :crypto.strong_rand_bytes(32)
          end

        :persistent_term.put(@secret_key, secret)
        secret

      secret ->
        secret
    end
  end
end
