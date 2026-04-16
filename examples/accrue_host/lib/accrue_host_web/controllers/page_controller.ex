defmodule AccrueHostWeb.PageController do
  use AccrueHostWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
