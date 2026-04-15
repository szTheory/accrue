defmodule AccrueAdmin.CSPPlug do
  @moduledoc false

  import Plug.Conn

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    policy =
      [
        "default-src 'self'",
        "base-uri 'self'",
        "connect-src 'self' ws: wss:",
        "font-src 'self' data:",
        "img-src 'self' data: https:",
        "object-src 'none'",
        "script-src 'self' 'nonce-#{nonce}'",
        "style-src 'self' 'nonce-#{nonce}'",
        "frame-ancestors 'self'"
      ]
      |> Enum.join("; ")

    conn
    |> assign(:accrue_admin_csp_nonce, nonce)
    |> put_private(:accrue_admin_csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy)
  end
end
