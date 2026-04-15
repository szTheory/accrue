defmodule AccrueAdmin.ConnCase do
  @moduledoc """
  ExUnit case template for admin router and plug tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest, only: [build_conn: 0, build_conn: 2]

      @endpoint AccrueAdmin.TestEndpoint
    end
  end
end
