defmodule AccruePortal.Layouts do
  @moduledoc false

  use Phoenix.Component

  attr(:inner_content, :any, required: true)
  attr(:page_title, :string, default: "Billing Portal")
  attr(:brand, :map, default: %{})
  attr(:theme, :string, default: "system")
  attr(:csp_nonce, :string, default: nil)
  attr(:brand_css_path, :string, default: nil)
  attr(:assets_css_path, :string, default: nil)
  attr(:assets_js_path, :string, default: nil)

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" data-theme={@theme}>
      <head>
        <meta charset="utf-8" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@page_title}</title>
        <link :if={@brand_css_path} rel="stylesheet" href={@brand_css_path} />
        <link :if={@assets_css_path} rel="stylesheet" href={@assets_css_path} />
        <script nonce={@csp_nonce} src="https://js.braintreegateway.com/web/3.132.0/js/client.min.js"></script>
        <script nonce={@csp_nonce} src="https://js.braintreegateway.com/web/3.132.0/js/hosted-fields.min.js"></script>
      </head>
      <body>
        <%= @inner_content %>
        <script :if={@assets_js_path} defer src={@assets_js_path}></script>
      </body>
    </html>
    """
  end
end
