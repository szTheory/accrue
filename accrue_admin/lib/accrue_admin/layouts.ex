defmodule AccrueAdmin.Layouts do
  @moduledoc """
  Root layout for mounted admin LiveViews.
  """

  use Phoenix.Component

  attr(:inner_content, :any, required: true)
  attr(:page_title, :string, default: "Billing")

  attr(:brand, :map,
    default: %{
      app_name: "Billing",
      logo_url: nil,
      accent_hex: "#5D79F6",
      accent_contrast_hex: "#FFFFFF"
    }
  )

  attr(:theme, :string, default: "system")
  attr(:csp_nonce, :string, default: nil)
  attr(:brand_css_path, :string, default: nil)
  attr(:assets_css_path, :string, default: nil)
  attr(:assets_js_path, :string, default: nil)

  def root(assigns) do
    assigns =
      assign(assigns,
        anti_fouc_script: anti_fouc_script(),
        runtime_theme_style: runtime_theme_style(assigns.brand)
      )

    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="accrue-admin">
      <head>
        <meta charset="utf-8" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <script nonce={@csp_nonce}><%= Phoenix.HTML.raw(@anti_fouc_script) %></script>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><%= @page_title %></title>
        <link rel="icon" href={favicon_data_uri()} type="image/svg+xml" />
        <link :if={@brand_css_path} rel="stylesheet" href={@brand_css_path} />
        <link :if={@assets_css_path} rel="stylesheet" href={@assets_css_path} />
      </head>
      <body class="accrue-admin-shell">
        <%= @inner_content %>
        <div id="ax-overlay-root"></div>
        <style nonce={@csp_nonce}><%= Phoenix.HTML.raw(@runtime_theme_style) %></style>
        <script :if={@assets_js_path} defer src={@assets_js_path}></script>
      </body>
    </html>
    """
  end

  @spec anti_fouc_script() :: String.t()
  def anti_fouc_script do
    """
    (() => {
      const key = "accrue_theme";
      const allowed = new Set(["light", "dark", "system"]);
      const safeDecodeTheme = (value) => {
        try {
          return decodeURIComponent(value);
        } catch (_error) {
          return null;
        }
      };
      const fromCookie = document.cookie.split("; ").find((chunk) => chunk.startsWith(`${key}=`));
      const cookieValue = fromCookie ? safeDecodeTheme(fromCookie.split("=").slice(1).join("=")) : null;
      const storedValue = window.localStorage.getItem(key);
      const theme = allowed.has(cookieValue) ? cookieValue : allowed.has(storedValue) ? storedValue : "system";
      document.documentElement.dataset.theme = theme;
      window.localStorage.setItem(key, theme);
    })();
    """
  end

  # Inline SVG favicon: the Accrue brand mark (ascending stepped bars, moss accent
  # bar) on the brand ink square for small-size legibility. Mirrors
  # brandbook/logo/favicon.svg. Inlined as a data URI (CSP `img-src` allows
  # `data:`) so no extra route or static file is needed.
  @favicon_svg ~s(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40"><rect width="40" height="40" rx="8" fill="#111418"/><path fill="#FAFBFC" d="M4 31h7v6H4Zm7-7h7v13h-7Zm7-7h7v20h-7Zm7-7h7v27h-7Z"/><path fill="#5E9E84" d="M25 10h7v27h-7Z"/></svg>)
  @favicon_data_uri "data:image/svg+xml;base64," <> Base.encode64(@favicon_svg)

  @spec favicon_data_uri() :: String.t()
  def favicon_data_uri, do: @favicon_data_uri

  defp runtime_theme_style(brand) do
    """
    :root {
      --ax-accent: #{brand[:accent_hex] || "#5D79F6"};
      --ax-accent-contrast: #{brand[:accent_contrast_hex] || "#FFFFFF"};
    }
    """
  end
end
