defmodule Mix.Tasks.AccrueAdmin.E2e.Server do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config")
    Mix.Task.run("compile")
    Mix.Task.run("app.start")

    server = Module.concat([AccrueAdmin, E2E, Server])
    apply(server, :start!, [])
  end
end
