defmodule AccrueHost.AppleRatePolicyTest do
  use ExUnit.Case, async: false

  alias AccrueHost.AppleRatePolicy

  setup do
    server = String.to_atom("apple_rate_policy_#{System.unique_integer([:positive])}")
    clock = start_supervised!({Agent, fn -> 0 end})
    prior_server = Application.get_env(:accrue_host, :apple_rate_policy_server)

    Application.put_env(:accrue_host, :apple_rate_policy_server, server)

    start_supervised!(
      {AppleRatePolicy,
       name: server, limit: 2, window_seconds: 10, clock: fn -> Agent.get(clock, & &1) end}
    )

    on_exit(fn -> restore_env(:accrue_host, :apple_rate_policy_server, prior_server) end)
    {:ok, clock: clock}
  end

  test "allows a configured direct peer limit then temporarily denies it", %{clock: clock} do
    Agent.update(clock, fn _ -> 100 end)
    conn = Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 10})

    assert :allow = AppleRatePolicy.check(conn)
    assert :allow = AppleRatePolicy.check(conn)
    assert {:deny, 10} = AppleRatePolicy.check(conn)
  end

  test "keeps direct peers isolated and ignores forwarded headers", %{clock: clock} do
    Agent.update(clock, fn _ -> 100 end)

    first_peer =
      Plug.Test.conn(:post, "/webhooks/apple", "")
      |> Map.put(:remote_ip, {203, 0, 113, 10})
      |> Plug.Conn.put_req_header("x-forwarded-for", "198.51.100.99")

    second_peer =
      Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 11})

    assert :allow = AppleRatePolicy.check(first_peer)
    assert :allow = AppleRatePolicy.check(first_peer)
    assert {:deny, 10} = AppleRatePolicy.check(first_peer)
    assert :allow = AppleRatePolicy.check(second_peer)
  end

  test "resets a peer window with an injected monotonic clock", %{clock: clock} do
    conn = Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 10})

    Agent.update(clock, fn _ -> 100 end)
    assert :allow = AppleRatePolicy.check(conn)
    assert :allow = AppleRatePolicy.check(conn)
    assert {:deny, 10} = AppleRatePolicy.check(conn)

    Agent.update(clock, fn _ -> 110 end)
    assert :allow = AppleRatePolicy.check(conn)
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
