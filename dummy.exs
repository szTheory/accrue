defmodule Dummy do
  def run do
    if Code.ensure_loaded?(Phoenix.Ecto.SQL.Sandbox) do
      IO.puts("Sandbox available")
    else
      IO.puts("Sandbox missing")
    end
  end
end
Dummy.run()
