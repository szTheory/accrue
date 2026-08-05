defmodule AccrueHost.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AccrueHostWeb.Telemetry,
      {AccrueHost.AccrueOpsTelemetry, []},
      AccrueHost.Repo,
      {Oban, Application.fetch_env!(:accrue_host, Oban)},
      {DNSCluster, query: Application.get_env(:accrue_host, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AccrueHost.PubSub},
      {AccrueHost.AppleRatePolicy, Application.get_env(:accrue_host, :apple_rate_policy, [])},
      # Start a worker by calling: AccrueHost.Worker.start_link(arg)
      # {AccrueHost.Worker, arg},
      # Start to serve requests, typically the last entry
      AccrueHostWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AccrueHost.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, _pid} = ok ->
        # Rehydrate the in-memory Fake processor from seeded DB rows so billing
        # actions (subscribe/change/cancel) work on the seeded personas. Runs
        # after the Repo is up; no-ops unless the Fake is the configured
        # processor; never blocks boot on failure.
        AccrueHost.FakeHydration.run()
        # Dev-only native launch banner; suppressed under Docker. Best-effort.
        AccrueHostWeb.DevBanner.maybe_print()
        ok

      other ->
        other
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AccrueHostWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
