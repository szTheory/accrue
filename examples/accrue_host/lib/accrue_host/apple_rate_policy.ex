defmodule AccrueHost.AppleRatePolicy do
  @moduledoc """
  A process-local backstop for Apple notification ingress.

  It keys by a direct peer unless that peer is explicitly configured as a
  trusted proxy. Deployment edge controls, not this process, remain the
  authority for shared or multi-node rate enforcement.
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
    GenServer.call(server, {:check, conn})
  end

  def parse_trusted_proxies!(""), do: []

  def parse_trusted_proxies!(declaration) when is_binary(declaration) do
    declaration
    |> String.split(",", trim: false)
    |> Enum.map(&parse_ip!/1)
  end

  def parse_trusted_proxies!(_),
    do: raise(ArgumentError, "APPLE_TRUSTED_PROXY_IPS must contain numeric IP addresses")

  @impl GenServer
  def init(opts) do
    {:ok,
     %{
       clock: Keyword.get(opts, :clock, fn -> System.monotonic_time(:second) end),
       limit: positive_option!(opts, :limit, @default_limit),
       window_seconds: positive_option!(opts, :window_seconds, @default_window_seconds),
       max_peers: positive_option!(opts, :max_peers, @default_max_peers),
       trusted_proxies: trusted_proxies!(Keyword.get(opts, :trusted_proxies, [])),
       peers: %{}
     }}
  end

  @impl GenServer
  def handle_call({:check, conn}, _from, state) do
    case normalized_peer(conn, state.trusted_proxies) do
      {:ok, peer} ->
        now = state.clock.()
        window = div(now, state.window_seconds)

        peers =
          Map.filter(state.peers, fn {_peer, {entry_window, _count}} -> entry_window == window end)

        {reply, peers} = check_peer(peers, peer, window, state)
        {:reply, reply, %{state | peers: peers}}

      :error ->
        {:reply, {:deny, state.window_seconds}, state}
    end
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

  defp normalized_peer(%Plug.Conn{remote_ip: remote_ip} = conn, trusted_proxies)
       when is_tuple(remote_ip) do
    if remote_ip in trusted_proxies do
      with [forwarded_for] <- Plug.Conn.get_req_header(conn, "x-forwarded-for"),
           {:ok, forwarded_ip} <- parse_ip(forwarded_for) do
        {:ok, {:forwarded, forwarded_ip}}
      else
        _ -> :error
      end
    else
      if valid_ip?(remote_ip), do: {:ok, {:direct, remote_ip}}, else: :error
    end
  end

  defp normalized_peer(_conn, _trusted_proxies), do: :error

  defp trusted_proxies!(proxies) when is_list(proxies) do
    if Enum.all?(proxies, &valid_ip?/1) do
      proxies
    else
      raise ArgumentError, "trusted_proxies must be a finite list of IP addresses"
    end
  end

  defp trusted_proxies!(_),
    do: raise(ArgumentError, "trusted_proxies must be a finite list of IP addresses")

  defp parse_ip!(value) do
    case parse_ip(value) do
      {:ok, ip} -> ip
      :error -> raise ArgumentError, "APPLE_TRUSTED_PROXY_IPS must contain numeric IP addresses"
    end
  end

  defp parse_ip(value) when is_binary(value) and byte_size(value) > 0 do
    if String.trim(value) == value do
      case :inet.parse_address(String.to_charlist(value)) do
        {:ok, ip} when is_tuple(ip) -> if(valid_ip?(ip), do: {:ok, ip}, else: :error)
        _ -> :error
      end
    else
      :error
    end
  end

  defp parse_ip(_), do: :error

  defp valid_ip?(ip) when tuple_size(ip) == 4 do
    ip |> Tuple.to_list() |> Enum.all?(&(is_integer(&1) and &1 >= 0 and &1 <= 255))
  end

  defp valid_ip?(ip) when tuple_size(ip) == 8 do
    ip |> Tuple.to_list() |> Enum.all?(&(is_integer(&1) and &1 >= 0 and &1 <= 65_535))
  end

  defp valid_ip?(_), do: false

  defp positive_option!(opts, key, default) do
    case Keyword.get(opts, key, default) do
      value when is_integer(value) and value > 0 -> value
      _ -> raise ArgumentError, "#{key} must be a positive integer"
    end
  end
end
