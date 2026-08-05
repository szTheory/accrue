defmodule AccrueHost.AppleRatePolicyTest do
  use ExUnit.Case, async: false

  alias AccrueHost.AppleRatePolicy

  setup do
    server = String.to_atom("apple_rate_policy_#{System.unique_integer([:positive])}")
    prior_server = Application.get_env(:accrue_host, :apple_rate_policy_server)

    Application.put_env(:accrue_host, :apple_rate_policy_server, server)

    start_supervised!(
      {AppleRatePolicy,
       name: server,
       limit: 2,
       window_seconds: 10,
       clock: fn -> Process.get(:apple_rate_policy_time, 0) end}
    )

    on_exit(fn -> restore_env(:accrue_host, :apple_rate_policy_server, prior_server) end)
    :ok
  end

  test "allows a configured direct peer limit then temporarily denies it" do
    Process.put(:apple_rate_policy_time, 100)
    conn = Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 10})

    assert :allow = AppleRatePolicy.check(conn)
    assert :allow = AppleRatePolicy.check(conn)
    assert {:deny, 10} = AppleRatePolicy.check(conn)
  end

  test "keeps direct peers isolated and ignores forwarded headers" do
    Process.put(:apple_rate_policy_time, 100)

    first_peer =
      Plug.Test.conn(:post, "/webhooks/apple", "")
      |> Map.put(:remote_ip, {203, 0, 113, 10})
      |> Plug.Conn.put_req_header("x-forwarded-for", "198.51.100.99")

    second_peer = Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 11})

    assert :allow = AppleRatePolicy.check(first_peer)
    assert :allow = AppleRatePolicy.check(first_peer)
    assert {:deny, 10} = AppleRatePolicy.check(first_peer)
    assert :allow = AppleRatePolicy.check(second_peer)
  end

  test "resets a peer window with an injected monotonic clock" do
    conn = Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {203, 0, 113, 10})

    Process.put(:apple_rate_policy_time, 100)
    assert :allow = AppleRatePolicy.check(conn)
    assert :allow = AppleRatePolicy.check(conn)
    assert {:deny, 10} = AppleRatePolicy.check(conn)

    Process.put(:apple_rate_policy_time, 110)
    assert :allow = AppleRatePolicy.check(conn)
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
