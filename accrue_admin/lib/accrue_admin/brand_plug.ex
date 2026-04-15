defmodule AccrueAdmin.BrandPlug do
  @moduledoc false

  import Plug.Conn

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    assign(conn, :accrue_admin_branding, Application.get_env(:accrue, :branding, []))
  end
end
