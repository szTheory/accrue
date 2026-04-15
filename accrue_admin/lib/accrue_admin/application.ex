defmodule AccrueAdmin.Application do
  @moduledoc """
  OTP application entry point for the `:accrue_admin` package.

  The admin package is a mountable library, not a standalone Phoenix app.
  It starts no host-owned infrastructure and only validates that the package
  can boot with its own local config.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one, name: AccrueAdmin.Supervisor)
  end
end
