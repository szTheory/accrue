defmodule AccruePortal.CSPPlugTest do
  use AccruePortal.ConnCase, async: true

  test "emits the D-22 Braintree allowlist and threads the nonce" do
    conn = Accrue.Portal.CSPPlug.call(build_conn(), [])
    [policy] = Plug.Conn.get_resp_header(conn, "content-security-policy")
    nonce = conn.assigns.accrue_portal_csp_nonce

    assert is_binary(nonce)
    assert byte_size(nonce) > 10

    assert policy =~ "default-src 'self'"
    assert policy =~ "connect-src 'self' https://api.braintreegateway.com"
    assert policy =~ "https://client-analytics.braintreegateway.com"
    assert policy =~ "https://payments.braintree-api.com"
    assert policy =~ "frame-src 'self' https://assets.braintreegateway.com"
    assert policy =~ "script-src 'self' 'nonce-#{nonce}' https://js.braintreegateway.com"
    assert conn.private[:accrue_portal_csp_nonce] == nonce
  end
end
