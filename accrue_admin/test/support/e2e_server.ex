defmodule AccrueAdmin.E2E.Server do
  @moduledoc false

  alias AccrueAdmin.TestRepo

  def start! do
    unless Mix.env() == :test do
      Mix.raise("accrue_admin.e2e.server must run with MIX_ENV=test")
    end

    configure_runtime!()

    case phase252_identity_from_env!() do
      nil ->
        migrate!()
        start_repo!()
        start_oban!()
        start_fake_processor!()
        start_endpoint!()

      identity ->
        verify_runner_configuration!(identity)
        verify_database_identity!(identity)

        Application.put_env(
          :accrue_admin,
          :phase252_e2e_identity,
          health_identity(identity, false)
        )

        start_endpoint!(identity)
        verify_endpoint_identity!(identity)
        migrate!()
        start_repo!(identity)
        start_oban!()
        start_fake_processor!()

        Application.put_env(
          :accrue_admin,
          :phase252_e2e_identity,
          health_identity(identity, true)
        )
    end

    port = endpoint_port()
    IO.puts("AccrueAdmin E2E server listening on http://127.0.0.1:#{port}")
    Process.sleep(:infinity)
  end

  @doc false
  def phase252_identity_from_env! do
    env = %{
      nonce: System.get_env("PHASE252_E2E_NONCE"),
      database: System.get_env("PHASE252_E2E_DATABASE"),
      role: System.get_env("PHASE252_E2E_ROLE"),
      address: System.get_env("PHASE252_E2E_ADDRESS"),
      pg_host: System.get_env("PHASE252_E2E_PGHOST"),
      port: System.get_env("PHASE252_E2E_PORT"),
      partition: System.get_env("PHASE252_E2E_PARTITION"),
      lane: System.get_env("PHASE252_E2E_LANE"),
      parent_pid: System.get_env("PHASE252_E2E_PARENT_PID")
    }

    present? = Enum.any?(Map.values(env), &(is_binary(&1) and &1 != ""))

    if present? do
      if Enum.any?(Map.values(env), &(not is_binary(&1) or &1 == "")) do
        Mix.raise("Phase 252 E2E identity is incomplete; refusing migration and endpoint startup")
      end

      unless Regex.match?(~r/^\d{8,16}$/, env.partition) and
               env.database == "accrue_admin_test#{env.partition}" and
               env.role == "postgres" and server_address?(env.address) and
               env.pg_host in ["127.0.0.1", "localhost", "::1"] and
               env.lane in ["admin-test", "admin-review"] and
               String.match?(env.port, ~r/^\d{1,5}$/) and
               String.match?(env.parent_pid, ~r/^\d+$/) do
        Mix.raise(
          "Phase 252 E2E identity is unsafe or inconsistent; refusing migration and endpoint startup"
        )
      end

      Map.update!(env, :port, &String.to_integer/1)
      |> Map.update!(:parent_pid, &String.to_integer/1)
    else
      nil
    end
  end

  defp configure_runtime! do
    Application.put_env(:accrue, :env, :test)
    Application.put_env(:accrue, :auth_adapter, AccrueAdmin.E2E.AuthAdapter)
    Application.put_env(:accrue, :repo, TestRepo)
    Application.put_env(:accrue, :processor, Accrue.Processor.Fake)
    Application.put_env(:accrue_admin, :cursor_secret, "accrue-admin-e2e-cursor-secret")

    Application.put_env(:accrue, :branding,
      business_name: "Accrue Ops",
      from_email: "noreply@example.test",
      support_email: "support@example.test",
      logo_url: "https://example.test/logo.svg",
      accent_color: "#5D79F6"
    )

    endpoint_config =
      :accrue_admin
      |> Application.get_env(AccrueAdmin.TestEndpoint, [])
      |> Keyword.merge(
        http: [ip: {127, 0, 0, 1}, port: endpoint_port()],
        check_origin: false,
        server: true
      )

    Application.put_env(:accrue_admin, AccrueAdmin.TestEndpoint, endpoint_config)
  end

  defp migrate! do
    case TestRepo.__adapter__().storage_up(TestRepo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
    end

    migrations_path = Path.expand("../../../accrue/priv/repo/migrations", __DIR__)

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
      end)
  end

  defp start_repo!(phase252_identity \\ nil) do
    case TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} when is_nil(phase252_identity) ->
        :ok

      {:error, {:already_started, _pid}} ->
        Mix.raise(
          "Phase 252 E2E refuses an already-started Repo; database ownership cannot be proven"
        )
    end

    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, {:shared, self()})
  end

  defp start_oban! do
    case Oban.start_link(
           repo: TestRepo,
           testing: :manual,
           queues: false,
           plugins: false,
           notifier: Oban.Notifiers.PG
         ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp start_fake_processor! do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    Accrue.Processor.Fake.reset()
  end

  defp start_endpoint!(phase252_identity \\ nil) do
    case AccrueAdmin.TestEndpoint.start_link() do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} when is_nil(phase252_identity) ->
        :ok

      {:error, {:already_started, _pid}} ->
        Mix.raise("Phase 252 E2E refuses an already-started endpoint; identity cannot be proven")
    end
  end

  defp endpoint_port do
    System.get_env("ACCRUE_ADMIN_E2E_PORT", "4017")
    |> String.to_integer()
  end

  defp verify_runner_configuration!(identity) do
    repo = TestRepo.config()

    actual = %{
      database: Keyword.get(repo, :database),
      role: Keyword.get(repo, :username),
      address: Keyword.get(repo, :hostname),
      port: Keyword.get(repo, :port, 5432),
      partition: System.get_env("MIX_TEST_PARTITION"),
      endpoint_port: endpoint_port()
    }

    expected = %{
      database: identity.database,
      role: identity.role,
      address: identity.pg_host,
      port: Keyword.get(repo, :port, 5432),
      partition: identity.partition,
      endpoint_port: identity.port
    }

    unless actual == expected do
      Mix.raise(
        "Phase 252 runner identity does not match the compiled test repository or endpoint config"
      )
    end
  end

  defp health_identity(identity, ready?) do
    identity
    |> Map.take([:nonce, :database, :role, :address, :port, :partition])
    |> Map.put(:pid, String.to_integer(System.pid()))
    |> Map.put(:ready, ready?)
  end

  defp loopback_address?(address) when is_binary(address) do
    case :inet.parse_address(String.to_charlist(address)) do
      {:ok, {127, _, _, _}} -> true
      {:ok, {0, 0, 0, 0, 0, 0, 0, 1}} -> true
      _ -> false
    end
  end

  # Mirrors scripts/dev/phase252_lab.mjs acceptedServerAddress/2: strict loopback everywhere,
  # plus the RFC 1918 IPv4 blocks only when GITHUB_ACTIONS=true (a hosted runner's PostgreSQL
  # service container reports its bridge address). Public addresses are never accepted.
  defp server_address?(address) when is_binary(address) do
    loopback_address?(address) or
      (System.get_env("GITHUB_ACTIONS") == "true" and private_range_address?(address))
  end

  defp server_address?(_), do: false

  defp private_range_address?(address) do
    case :inet.parse_address(String.to_charlist(address)) do
      {:ok, {10, _, _, _}} -> true
      {:ok, {172, second, _, _}} when second in 16..31 -> true
      {:ok, {192, 168, _, _}} -> true
      _ -> false
    end
  end

  defp verify_database_identity!(identity) do
    repo = TestRepo.config()

    postgres_options =
      Keyword.take(repo, [
        :hostname,
        :username,
        :password,
        :database,
        :port,
        :ssl,
        :timeout,
        :parameters
      ])

    {:ok, connection} = Postgrex.start_link(postgres_options)
    Process.unlink(connection)

    try do
      case Postgrex.query(
             connection,
             "SELECT current_database(), current_user, host(inet_server_addr())",
             []
           ) do
        {:ok, %{rows: [[database, role, address]]}}
        when database == identity.database and role == identity.role and
               address == identity.address ->
          :ok

        {:ok, _result} ->
          Mix.raise("Phase 252 PostgreSQL connection identity mismatch; refusing migration")

        {:error, error} ->
          Mix.raise(
            "Phase 252 PostgreSQL identity query failed before migration: #{Exception.message(error)}"
          )
      end
    after
      GenServer.stop(connection, :normal, 5_000)
    end
  end

  defp verify_endpoint_identity!(identity) do
    {:ok, socket} =
      :gen_tcp.connect({127, 0, 0, 1}, identity.port, [:binary, active: false], 2_000)

    try do
      request =
        "GET /__e2e__/health HTTP/1.1\r\n" <>
          "Host: 127.0.0.1\r\nConnection: close\r\n\r\n"

      :ok = :gen_tcp.send(socket, request)
      response = receive_http_response!(socket, <<>>)
      [_, body] = String.split(response, "\r\n\r\n", parts: 2)
      {:ok, health} = Jason.decode(body)

      expected = %{
        "ok" => true,
        "nonce" => identity.nonce,
        "database" => identity.database,
        "role" => identity.role,
        "address" => identity.address,
        "port" => identity.port,
        "partition" => identity.partition,
        "pid" => String.to_integer(System.pid()),
        "ready" => false
      }

      unless Enum.all?(expected, fn {key, value} -> Map.get(health, key) == value end) do
        Mix.raise("Phase 252 endpoint health identity mismatch; refusing migration")
      end
    after
      :gen_tcp.close(socket)
    end
  end

  defp receive_http_response!(socket, buffered) do
    case String.split(buffered, "\r\n\r\n", parts: 2) do
      [headers, body] ->
        content_length =
          case Regex.run(~r/content-length:\s*(\d+)/i, headers) do
            [_, length] -> String.to_integer(length)
            _ -> 0
          end

        if byte_size(body) >= content_length do
          buffered
        else
          {:ok, chunk} = :gen_tcp.recv(socket, 0, 2_000)
          receive_http_response!(socket, buffered <> chunk)
        end

      _ ->
        {:ok, chunk} = :gen_tcp.recv(socket, 0, 2_000)
        receive_http_response!(socket, buffered <> chunk)
    end
  end
end
