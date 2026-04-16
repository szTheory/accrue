defmodule AccrueAdmin.E2E.Server do
  @moduledoc false

  alias AccrueAdmin.TestRepo

  def start! do
    unless Mix.env() == :test do
      Mix.raise("accrue_admin.e2e.server must run with MIX_ENV=test")
    end

    configure_runtime!()
    migrate!()
    start_repo!()
    start_oban!()
    start_fake_processor!()
    start_endpoint!()

    port = endpoint_port()
    IO.puts("AccrueAdmin E2E server listening on http://127.0.0.1:#{port}")
    Process.sleep(:infinity)
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

  defp start_repo! do
    case TestRepo.start_link(pool: Ecto.Adapters.SQL.Sandbox) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
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

  defp start_endpoint! do
    case AccrueAdmin.TestEndpoint.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp endpoint_port do
    System.get_env("ACCRUE_ADMIN_E2E_PORT", "4017")
    |> String.to_integer()
  end
end
