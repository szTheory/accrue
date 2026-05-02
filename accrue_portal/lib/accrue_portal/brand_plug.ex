defmodule AccruePortal.BrandPlug do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
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
    |> assign(:accrue_portal_theme, conn.cookies["accrue_theme"] || "system")
  end
end
