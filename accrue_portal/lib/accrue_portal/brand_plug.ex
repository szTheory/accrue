defmodule Accrue.Portal.BrandPlug do
  @moduledoc false

  import Plug.Conn

  @theme_cookie "accrue_theme"

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    brand =
      Accrue.Config.branding()
      |> Enum.into(%{})
      |> Map.take([
        :business_name,
        :logo_url,
        :accent_color,
        :secondary_color,
        :support_email
      ])

    conn
    |> assign(:accrue_portal_brand, brand)
    |> assign(:accrue_portal_theme, conn.cookies[@theme_cookie] || "system")
  end
end

defmodule AccruePortal.BrandPlug do
  @moduledoc false

  defdelegate init(opts), to: Accrue.Portal.BrandPlug
  defdelegate call(conn, opts), to: Accrue.Portal.BrandPlug
end
