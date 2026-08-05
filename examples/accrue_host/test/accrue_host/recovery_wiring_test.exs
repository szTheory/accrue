defmodule AccrueHost.RecoveryWiringTest do
  @moduledoc """
  Phase 158 Plan 01 — PROOF-06: host-level recovery wiring config proof.
  """

  use AccrueHost.AccrueCase, async: false

  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Jobs.DetectExpiringCards
  alias Accrue.Jobs.MeteredRenewalReconciler
  alias Accrue.Jobs.MeterEventsReconciler
  alias Accrue.Entitlements.Apple.ReconciliationSweeper
  alias Accrue.Entitlements.Offline.ReconnectSweeper

  describe "base config wiring proof" do
    test "base Oban config validates and preserves every recovery cron worker" do
      oban_config = base_oban_config()

      assert :ok = Oban.Config.validate(oban_config)

      crontab = cron_entries(oban_config)
      workers = Enum.map(crontab, &elem(&1, 1))

      assert DunningSweeper in workers
      assert DetectExpiringCards in workers
      assert MeterEventsReconciler in workers
      assert MeteredRenewalReconciler in workers
      assert ReconciliationSweeper in workers
      assert ReconnectSweeper in workers

      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconciliationSweeper})) == 1
      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconnectSweeper})) == 1
    end

    test "base Oban config preserves host queues and adds the Apple repair queue" do
      queues = Keyword.fetch!(base_oban_config(), :queues)
      names = Keyword.keys(queues)

      assert :accrue_webhooks in names
      assert :accrue_mailers in names
      assert :accrue_pdf in names
      assert :accrue_dunning in names
      assert :accrue_meters in names
      assert :accrue_scheduled in names
      assert :accrue_entitlements in names
      assert Keyword.fetch!(queues, :accrue_entitlements) == 10
    end

    test "reconciliation keeps PostgreSQL ownership while Oban only coalesces work" do
      reconciliation = apple_source("reconciliation.ex")

      assert reconciliation =~ "PostgreSQL row locking, rather than Oban uniqueness"
      assert reconciliation =~ "The row lock, not Oban uniqueness"
      assert reconciliation =~ "Oban uniqueness"
    end

    test "reconcile worker reads the shared production client and admission configuration" do
      runtime = File.read!(Path.expand("../../config/runtime.exs", __DIR__))
      worker = apple_source("reconcile_worker.ex")

      assert worker =~ "Application.get_env(:accrue, :apple_reconciliation)"
      assert runtime =~ "config :accrue, :apple_reconciliation"
      assert runtime =~ "client:"
      assert runtime =~ "admission: ["
      assert runtime =~ "verifier_config: verifier_config"
      assert runtime =~ "verifier_version: \"apple-production-v1\""
      assert runtime =~ "config_version: System.fetch_env!(\"APPLE_VERIFIER_CONFIG_VERSION\")"
    end

    test "durable ingress wakeups drain through the scheduled existing recovery workers" do
      ingress_test =
        File.read!(Path.expand("../accrue_host_web/apple_notification_ingest_test.exs", __DIR__))

      sweeper = apple_source("reconciliation_sweeper.ex")
      worker = apple_source("reconcile_worker.ex")
      crontab = cron_entries(base_oban_config())

      assert ingress_test =~ "preserves exact bytes before durable intake and wakeup"
      assert ingress_test =~ "Repo.one!(ReconciliationWakeup)"
      assert sweeper =~ "queue: :accrue_entitlements"
      assert worker =~ "queue: :accrue_entitlements"
      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconciliationSweeper})) == 1
    end
  end

  describe "runtime test safety config" do
    test "test env keeps Oban queues/plugins disabled and manual testing mode" do
      runtime_oban_config = Application.fetch_env!(:accrue_host, Oban)

      assert false == Keyword.get(runtime_oban_config, :plugins)
      assert false == Keyword.get(runtime_oban_config, :queues)
      assert :manual == Keyword.get(runtime_oban_config, :testing)
    end
  end

  defp base_oban_config do
    config_path = Path.expand("../../config/config.exs", __DIR__)

    config_path
    |> Config.Reader.read!(env: :dev)
    |> get_in([:accrue_host, Oban])
  end

  defp cron_entries(oban_config) do
    oban_config
    |> Keyword.fetch!(:plugins)
    |> Enum.find_value(fn
      {Oban.Plugins.Cron, cron_opts} -> Keyword.get(cron_opts, :crontab, [])
      _ -> nil
    end)
    |> case do
      nil -> []
      crontab -> crontab
    end
  end

  defp apple_source(filename),
    do:
      File.read!(
        Path.expand("../../../../accrue/lib/accrue/entitlements/apple/#{filename}", __DIR__)
      )
end
