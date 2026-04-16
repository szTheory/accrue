defmodule AccrueHost.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AccrueHostWeb.Telemetry,
      AccrueHost.Repo,
      {Oban, Application.fetch_env!(:accrue_host, Oban)},
      {DNSCluster, query: Application.get_env(:accrue_host, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AccrueHost.PubSub},
      # Start a worker by calling: AccrueHost.Worker.start_link(arg)
      # {AccrueHost.Worker, arg},
      # Start to serve requests, typically the last entry
      AccrueHostWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AccrueHost.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AccrueHostWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
