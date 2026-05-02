defmodule AccruePortal.CSPPlug do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    nonce = 18 |> :crypto.strong_rand_bytes() |> Base.encode64(padding: false)

    policy =
      [
        "default-src 'self'",
        "script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com",
        "style-src 'self' 'nonce-#{nonce}'",
        "img-src 'self' data: https:",
        "connect-src 'self' https://api.braintreegateway.com https://client-analytics.braintreegateway.com",
        "frame-src https://assets.braintreegateway.com https://payments.braintree-api.com",
        "font-src 'self' data:"
      ]
      |> Enum.join("; ")

    conn
    |> put_resp_header("content-security-policy", policy)
    |> assign(:accrue_portal_csp_nonce, nonce)
    |> put_private(:accrue_portal_csp_nonce, nonce)
  end
end
