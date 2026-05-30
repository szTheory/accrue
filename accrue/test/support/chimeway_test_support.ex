if Code.ensure_loaded?(Chimeway) do
  defmodule Accrue.ChimewayTestSupport do
    @moduledoc false

    @repo_started :accrue_chimeway_test_repo_started

    def ensure_repo_started! do
      case :persistent_term.get(@repo_started, false) do
        true ->
          :ok

        false ->
          start_repo!()
          :persistent_term.put(@repo_started, true)
          :ok
      end
    end

    defp start_repo! do
      stop_repo_if_running!()

      repo_config = [
        database: "chimeway_test#{System.get_env("MIX_TEST_PARTITION")}",
        pool: Ecto.Adapters.SQL.Sandbox,
        pool_size: 10,
        username: System.get_env("PGUSER", "postgres"),
        password: System.get_env("PGPASSWORD", "postgres"),
        hostname: System.get_env("PGHOST", "localhost")
      ]

      Application.put_env(:chimeway, Chimeway.Repo, repo_config)

      Application.put_env(:chimeway, Oban,
        repo: Chimeway.Repo,
        testing: :manual,
        queues: [chimeway_signals: 5]
      )

      case Ecto.Adapters.Postgres.storage_up(repo_config) do
        :ok -> :ok
        {:error, :already_up} -> :ok
      end

      case Chimeway.Repo.start_link() do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      migrations_path =
        :chimeway
        |> :code.priv_dir()
        |> Path.join("repo/migrations")

      {:ok, _, _} =
        Ecto.Migrator.with_repo(Chimeway.Repo, fn repo ->
          Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
        end)

      case Oban.start_link(
             name: Accrue.ChimewayTestSupport.Oban,
             repo: Chimeway.Repo,
             testing: :manual,
             queues: false,
             plugins: false,
             notifier: Oban.Notifiers.PG
           ) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end

      Ecto.Adapters.SQL.Sandbox.mode(Chimeway.Repo, :manual)
      :ok
    end

    defp stop_repo_if_running! do
      if pid = Process.whereis(Chimeway.Repo) do
        _ = GenServer.stop(pid, :normal, 5_000)
      end

      if pid = Process.whereis(Accrue.ChimewayTestSupport.Oban) do
        _ = GenServer.stop(pid, :normal, 5_000)
      end

      :ok
    end
  end
end
