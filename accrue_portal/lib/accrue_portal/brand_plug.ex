defmodule Accrue.Portal.BrandPlug do
  @moduledoc false

  import Plug.Conn

  @theme_cookie "accrue_theme"
  @valid_themes ~w(system light dark)

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    branding = Accrue.Config.branding()

    brand =
      branding
      |> Enum.into(%{})
      |> Map.take([
        :business_name,
        :logo_url,
        :accent_color,
        :secondary_color,
        :font_stack,
        :support_email
      ])

    {effective, locked} = resolve_theme(branding, conn.cookies[@theme_cookie])

    conn
    |> assign(:accrue_portal_brand, brand)
    |> assign(:accrue_portal_theme, effective)
    |> assign(:accrue_portal_theme_locked, locked)
  end

  # Adopter policy wins: `:light`/`:dark` force the mode server-side (cookie
  # ignored) and lock the picker. `:system` keeps the cookie-driven choice,
  # sanitizing the raw cookie value before it reaches `data-theme`.
  defp resolve_theme(branding, cookie) do
    case Keyword.get(branding, :theme, :system) do
      policy when policy in [:light, :dark] ->
        {Atom.to_string(policy), true}

      _system ->
        {sanitize_theme(cookie), false}
    end
  end

  defp sanitize_theme(value) when value in @valid_themes, do: value
  defp sanitize_theme(_value), do: "system"
end

defmodule AccruePortal.BrandPlug do
  @moduledoc false

  defdelegate init(opts), to: Accrue.Portal.BrandPlug
  defdelegate call(conn, opts), to: Accrue.Portal.BrandPlug
end
