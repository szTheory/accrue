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
  attr(:phoenix_js_path, :string, default: nil)
  attr(:live_view_js_path, :string, default: nil)

  def root(assigns) do
    assigns =
      assigns
      |> assign(:brand_style_tag, brand_style_tag(assigns.brand, assigns.csp_nonce))
      |> assign(:brand_logo_url, sanitize_url(assigns.brand[:logo_url]))
      |> assign(:brand_wordmark, brand_wordmark(assigns.brand))

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
        {@brand_style_tag}
      </head>
      <body>
        <header class="portal-topbar">
          <div class="portal-topbar-inner">
            <img
              :if={@brand_logo_url}
              class="portal-logo"
              src={@brand_logo_url}
              alt={@brand_wordmark || "Billing"}
            />
            <span :if={!@brand_logo_url && @brand_wordmark} class="portal-wordmark">
              {@brand_wordmark}
            </span>
            <div class="portal-theme-picker" role="group" aria-label="Theme">
              <button
                type="button"
                data-portal-theme="system"
                aria-pressed={@theme == "system"}
                class={["portal-theme-option", @theme == "system" && "is-active"]}
                aria-label="Match system theme"
                title="System"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                  stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <rect x="3" y="4" width="18" height="12" rx="2" />
                  <path d="M8 20h8" />
                  <path d="M12 16v4" />
                </svg>
              </button>
              <button
                type="button"
                data-portal-theme="light"
                aria-pressed={@theme == "light"}
                class={["portal-theme-option", @theme == "light" && "is-active"]}
                aria-label="Light theme"
                title="Light"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                  stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <circle cx="12" cy="12" r="4" />
                  <path d="M12 2v2" />
                  <path d="M12 20v2" />
                  <path d="M4.93 4.93l1.41 1.41" />
                  <path d="M17.66 17.66l1.41 1.41" />
                  <path d="M2 12h2" />
                  <path d="M20 12h2" />
                  <path d="M4.93 19.07l1.41-1.41" />
                  <path d="M17.66 6.34l1.41-1.41" />
                </svg>
              </button>
              <button
                type="button"
                data-portal-theme="dark"
                aria-pressed={@theme == "dark"}
                class={["portal-theme-option", @theme == "dark" && "is-active"]}
                aria-label="Dark theme"
                title="Dark"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                  stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                  <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
                </svg>
              </button>
            </div>
          </div>
        </header>
        <%= @inner_content %>
        <script :if={@phoenix_js_path} defer src={@phoenix_js_path}></script>
        <script :if={@live_view_js_path} defer src={@live_view_js_path}></script>
        <script :if={@assets_js_path} defer src={@assets_js_path}></script>
      </body>
    </html>
    """
  end

  # Build the CSP-safe nonce'd `<style>` element as a raw safe string. HEEx
  # treats `<style>` bodies as verbatim text (no `{}` interpolation), so the
  # whole tag is assembled here and emitted via `{@brand_style_tag}` in the
  # head. Returns "" (empty safe string) when there is nothing to override.
  defp brand_style_tag(brand, nonce) do
    case brand_overrides(brand) do
      "" ->
        Phoenix.HTML.raw("")

      css ->
        nonce_attr =
          case nonce do
            value when is_binary(value) -> ~s( nonce="#{Plug.HTML.html_escape(value)}")
            _ -> ""
          end

        Phoenix.HTML.raw("<style#{nonce_attr}>#{css}</style>")
    end
  end

  # Build a CSP-safe `:root {}` override from host brand config. Emits a
  # declaration only for present, sanitized values so the neutral-Accrue
  # defaults in brand.css remain the fallback. Returns "" when nothing to emit.
  defp brand_overrides(brand) when is_map(brand) do
    declarations =
      [
        {"--accrue-brand-accent", sanitize_color(brand[:accent_color])},
        {"--accrue-brand-secondary", sanitize_color(brand[:secondary_color])},
        {"--accrue-brand-font", sanitize_font(brand[:font_stack])}
      ]
      |> Enum.reject(fn {_token, value} -> is_nil(value) end)

    case declarations do
      [] ->
        ""

      decls ->
        body = Enum.map_join(decls, "", fn {token, value} -> "#{token}:#{value};" end)
        ":root{#{body}}"
    end
  end

  defp brand_overrides(_brand), do: ""

  # Colors are already config-validated hex, but sanitize anyway (defense in
  # depth) before raw-emitting into the inline style.
  defp sanitize_color(value) when is_binary(value) do
    if Regex.match?(~r/^#[0-9a-fA-F]{3,8}$/, value), do: value, else: nil
  end

  defp sanitize_color(_value), do: nil

  # Restrict the font stack to a safe declaration charset — strip anything
  # that could break out of the CSS declaration (`<>{};:` etc.).
  defp sanitize_font(value) when is_binary(value) do
    cleaned =
      value
      |> String.replace(~r/[^A-Za-z0-9 ,\-'".]/, "")
      |> String.trim()

    if cleaned == "", do: nil, else: cleaned
  end

  defp sanitize_font(_value), do: nil

  # Only allow http(s), root-relative, or data: image URLs into the logo src.
  defp sanitize_url(value) when is_binary(value) do
    trimmed = String.trim(value)

    if Regex.match?(~r{^(https?://|/|data:image/)}i, trimmed), do: trimmed, else: nil
  end

  defp sanitize_url(_value), do: nil

  defp brand_wordmark(brand) when is_map(brand) do
    case brand[:business_name] do
      name when is_binary(name) ->
        case String.trim(name) do
          "" -> nil
          trimmed -> trimmed
        end

      _ ->
        nil
    end
  end

  defp brand_wordmark(_brand), do: nil
end
