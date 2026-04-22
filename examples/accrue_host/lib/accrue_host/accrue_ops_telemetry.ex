defmodule AccrueHost.AccrueOpsTelemetry do
  @moduledoc false

  # Maintenance: Mirrors `accrue/guides/telemetry.md` ## Cross-domain host subscription
  # (examples/accrue_host). Update handler id, event tuple, and logs with the guide.

  use GenServer

  require Logger

  @attach_id "accrue-host-ops-dlq-dead-lettered"
  @event [:accrue, :ops, :webhook_dlq, :dead_lettered]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  @impl true
  def init(_opts) do
    :ok = :telemetry.attach(@attach_id, @event, &__MODULE__.handle_event/4, nil)
    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@attach_id)
    :ok
  end

  def handle_event(@event, measurements, _metadata, _config) do
    count = Map.get(measurements, :count, 0)
    Logger.info("accrue_host accrue ops webhook_dlq dead_lettered count=#{count}")
  end
end
