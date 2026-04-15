defmodule AccrueAdmin.BrandPlug do
  @moduledoc false

  alias Accrue.Config

  import Plug.Conn

  @theme_cookie "accrue_theme"
  @allowed_themes ~w(light dark system)

  @spec theme_cookie_name() :: String.t()
  def theme_cookie_name, do: @theme_cookie

  @spec sanitize_theme(term()) :: String.t()
  def sanitize_theme(theme) when theme in @allowed_themes, do: theme
  def sanitize_theme(_theme), do: "system"

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    theme =
      conn
      |> fetch_cookies()
      |> Map.get(:cookies, %{})
      |> Map.get(@theme_cookie)
      |> sanitize_theme()

    conn
    |> assign(:accrue_admin_theme, theme)
    |> assign(:accrue_admin_brand, build_brand())
  end

  defp build_brand do
    branding = Config.branding()
    accent_hex = branding[:accent_color] || "#5D79F6"

    %{
      app_name: present_or(branding[:business_name], "Billing"),
      logo_url: present_or_nil(branding[:logo_url]),
      accent_hex: accent_hex,
      accent_contrast_hex: pick_contrast(accent_hex)
    }
  end

  defp present_or_nil(value) when value in [nil, ""], do: nil
  defp present_or_nil(value), do: value

  defp present_or(value, fallback) when value in [nil, ""], do: fallback
  defp present_or(value, _fallback), do: value

  defp pick_contrast(hex) do
    if relative_luminance(hex) > 0.45, do: "#111418", else: "#FAFBFC"
  end

  defp relative_luminance("#" <> hex) do
    [r, g, b] =
      hex
      |> expand_hex()
      |> String.codepoints()
      |> Enum.chunk_every(2)
      |> Enum.map(fn [high, low] ->
        <<value::8>> = Base.decode16!(high <> low, case: :mixed)
        channel_luminance(value / 255)
      end)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp expand_hex(hex) when byte_size(hex) == 3 do
    hex
    |> String.codepoints()
    |> Enum.map_join(&(&1 <> &1))
  end

  defp expand_hex(hex), do: String.slice(hex, 0, 6)

  defp channel_luminance(channel) when channel <= 0.03928, do: channel / 12.92
  defp channel_luminance(channel), do: :math.pow((channel + 0.055) / 1.055, 2.4)
end
