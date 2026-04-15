defmodule AccrueAdmin.CSPPlug do
  @moduledoc false

  import Plug.Conn

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    put_private(conn, :accrue_admin_csp, :pending)
  end
end
