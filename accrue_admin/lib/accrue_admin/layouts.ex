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
        <link :if={@brand_css_path} rel="stylesheet" href={@brand_css_path} />
        <link :if={@assets_css_path} rel="stylesheet" href={@assets_css_path} />
      </head>
      <body class="accrue-admin-shell">
        <%= @inner_content %>
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
      const fromCookie = document.cookie.split("; ").find((chunk) => chunk.startsWith(`${key}=`));
      const cookieValue = fromCookie ? decodeURIComponent(fromCookie.split("=").slice(1).join("=")) : null;
      const storedValue = window.localStorage.getItem(key);
      const theme = allowed.has(cookieValue) ? cookieValue : allowed.has(storedValue) ? storedValue : "system";
      document.documentElement.dataset.theme = theme;
      window.localStorage.setItem(key, theme);
    })();
    """
  end

  defp runtime_theme_style(brand) do
    """
    :root {
      --ax-accent: #{brand[:accent_hex] || "#5D79F6"};
      --ax-accent-contrast: #{brand[:accent_contrast_hex] || "#FFFFFF"};
    }
    """
  end
end
