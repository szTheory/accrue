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

  test "trusted proxies isolate strict forwarded client identities", %{clock: clock} do
    Agent.update(clock, fn _ -> 100 end)

    with_rate_policy([trusted_proxies: [{192, 0, 2, 1}]], fn ->
      first_client = proxy_conn({192, 0, 2, 1}, "198.51.100.10")
      second_client = proxy_conn({192, 0, 2, 1}, "198.51.100.11")

      assert :allow = AppleRatePolicy.check(first_client)
      assert :allow = AppleRatePolicy.check(first_client)
      assert {:deny, 10} = AppleRatePolicy.check(first_client)
      assert :allow = AppleRatePolicy.check(second_client)
    end)
  end

  test "untrusted peers ignore forwarded identities and cannot consume proxy client buckets", %{
    clock: clock
  } do
    Agent.update(clock, fn _ -> 100 end)

    with_rate_policy([trusted_proxies: [{192, 0, 2, 1}]], fn ->
      trusted_client = proxy_conn({192, 0, 2, 1}, "198.51.100.10")
      untrusted_peer = proxy_conn({203, 0, 113, 10}, "198.51.100.10")

      assert :allow = AppleRatePolicy.check(trusted_client)
      assert :allow = AppleRatePolicy.check(untrusted_peer)
      assert :allow = AppleRatePolicy.check(untrusted_peer)
      assert {:deny, 10} = AppleRatePolicy.check(untrusted_peer)
      assert :allow = AppleRatePolicy.check(trusted_client)
      assert {:deny, 10} = AppleRatePolicy.check(trusted_client)
    end)
  end

  test "trusted proxies deny missing or ambiguous forwarded identities", %{clock: clock} do
    Agent.update(clock, fn _ -> 100 end)

    with_rate_policy([trusted_proxies: [{192, 0, 2, 1}]], fn ->
      for conn <- [
            Plug.Test.conn(:post, "/webhooks/apple", "") |> Map.put(:remote_ip, {192, 0, 2, 1}),
            proxy_conn({192, 0, 2, 1}, "198.51.100.10, 198.51.100.11"),
            proxy_conn({192, 0, 2, 1}, " "),
            proxy_conn({192, 0, 2, 1}, "client.example.test"),
            proxy_conn({192, 0, 2, 1}, "not-an-ip"),
            repeated_proxy_conn({192, 0, 2, 1})
          ] do
        assert {:deny, 10} = AppleRatePolicy.check(conn)
      end
    end)
  end

  test "trusted proxy declarations accept only explicit numeric IPs" do
    assert [] = AppleRatePolicy.parse_trusted_proxies!("")

    assert [{192, 0, 2, 1}, {8193, 3512, 0, 0, 0, 0, 0, 1}] =
             AppleRatePolicy.parse_trusted_proxies!("192.0.2.1,2001:db8::1")

    for declaration <- ["client.example.test", "192.0.2.1,", " 192.0.2.1"] do
      assert_raise ArgumentError,
                   "APPLE_TRUSTED_PROXY_IPS must contain numeric IP addresses",
                   fn ->
                     AppleRatePolicy.parse_trusted_proxies!(declaration)
                   end
    end
  end

  defp with_rate_policy(opts, fun) do
    server = String.to_atom("trusted_apple_rate_policy_#{System.unique_integer([:positive])}")
    prior_server = Application.fetch_env!(:accrue_host, :apple_rate_policy_server)

    start_supervised!(
      {AppleRatePolicy, Keyword.merge([name: server, limit: 2, window_seconds: 10], opts)},
      id: server
    )

    Application.put_env(:accrue_host, :apple_rate_policy_server, server)

    try do
      fun.()
    after
      Application.put_env(:accrue_host, :apple_rate_policy_server, prior_server)
    end
  end

  defp proxy_conn(remote_ip, forwarded_for) do
    Plug.Test.conn(:post, "/webhooks/apple", "")
    |> Map.put(:remote_ip, remote_ip)
    |> Plug.Conn.put_req_header("x-forwarded-for", forwarded_for)
  end

  defp repeated_proxy_conn(remote_ip) do
    %{
      proxy_conn(remote_ip, "198.51.100.10")
      | req_headers: [
          {"x-forwarded-for", "198.51.100.10"},
          {"x-forwarded-for", "198.51.100.11"}
        ]
    }
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
