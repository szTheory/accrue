defmodule Accrue.Portal.CSPPlug do
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
        "connect-src 'self' https://api.braintreegateway.com https://client-analytics.braintreegateway.com https://payments.braintree-api.com",
        "font-src 'self' data:",
        "frame-ancestors 'self'",
        "frame-src 'self' https://assets.braintreegateway.com https://payments.braintree-api.com",
        "img-src 'self' data: https:",
        "object-src 'none'",
        "script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com",
        "style-src 'self' 'nonce-#{nonce}'"
      ]
      |> Enum.join("; ")

    conn
    |> assign(:accrue_portal_csp_nonce, nonce)
    |> put_private(:accrue_portal_csp_nonce, nonce)
    |> put_resp_header("content-security-policy", policy)
  end
end

defmodule AccruePortal.CSPPlug do
  @moduledoc false

  defdelegate init(opts), to: Accrue.Portal.CSPPlug
  defdelegate call(conn, opts), to: Accrue.Portal.CSPPlug
end
