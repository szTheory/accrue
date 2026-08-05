defmodule AccrueHost.AppleRatePolicy do
  @moduledoc """
  A process-local backstop for Apple notification ingress.

  It intentionally keys only on Phoenix's direct peer address. Deployment edge
  controls, not this process, remain the authority for shared or multi-node
  rate enforcement.
  """

  use GenServer

  @default_limit 120
  @default_window_seconds 60
  @default_max_peers 10_000

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def check(conn) do
    server = Application.get_env(:accrue_host, :apple_rate_policy_server, __MODULE__)
    GenServer.call(server, {:check, normalized_peer(conn)})
  end

  @impl GenServer
  def init(opts) do
    {:ok,
     %{
       clock: Keyword.get(opts, :clock, fn -> System.monotonic_time(:second) end),
       limit: positive_option!(opts, :limit, @default_limit),
       window_seconds: positive_option!(opts, :window_seconds, @default_window_seconds),
       max_peers: positive_option!(opts, :max_peers, @default_max_peers),
       peers: %{}
     }}
  end

  @impl GenServer
  def handle_call({:check, peer}, _from, state) do
    now = state.clock.()
    window = div(now, state.window_seconds)

    peers =
      Map.filter(state.peers, fn {_peer, {entry_window, _count}} -> entry_window == window end)

    {reply, peers} = check_peer(peers, peer, window, state)
    {:reply, reply, %{state | peers: peers}}
  end

  defp check_peer(peers, peer, window, %{limit: limit, window_seconds: window_seconds} = state) do
    case Map.get(peers, peer) do
      {^window, count} when count >= limit ->
        {{:deny, window_seconds}, peers}

      {^window, count} ->
        {:allow, Map.put(peers, peer, {window, count + 1})}

      nil ->
        {:allow, Map.put(trim_peers(peers, state.max_peers), peer, {window, 1})}
    end
  end

  defp trim_peers(peers, max_peers) when map_size(peers) < max_peers, do: peers

  defp trim_peers(peers, _max_peers) do
    {oldest_peer, _entry} = Enum.min_by(peers, fn {_peer, {window, count}} -> {window, count} end)
    Map.delete(peers, oldest_peer)
  end

  defp normalized_peer(%Plug.Conn{remote_ip: remote_ip}) when is_tuple(remote_ip) do
    remote_ip |> :inet.ntoa() |> to_string()
  end

  defp normalized_peer(_conn), do: "unknown-direct-peer"

  defp positive_option!(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      _ -> raise ArgumentError, "#{key} must be a positive integer"
    end
  end
end
