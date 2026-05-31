defmodule AccrueHost.RecoveryWiringTest do
  @moduledoc """
  Phase 158 Plan 01 — PROOF-06: host-level recovery wiring config proof.
  """

  use AccrueHost.AccrueCase, async: false

  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Jobs.DetectExpiringCards
  alias Accrue.Jobs.MeteredRenewalReconciler
  alias Accrue.Jobs.MeterEventsReconciler

  describe "base config wiring proof" do
    test "base Oban config validates and includes required recovery cron workers" do
      oban_config = base_oban_config()

      assert :ok = Oban.Config.validate(oban_config)

      workers = cron_workers(oban_config)

      assert DunningSweeper in workers
      assert DetectExpiringCards in workers
      assert MeterEventsReconciler in workers
      assert MeteredRenewalReconciler in workers
    end

    test "base Oban config includes required host queues" do
      names = queue_names(base_oban_config())

      assert :accrue_webhooks in names
      assert :accrue_mailers in names
      assert :accrue_dunning in names
      assert :accrue_meters in names
      assert :accrue_scheduled in names
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

  defp cron_workers(oban_config) do
    oban_config
    |> Keyword.fetch!(:plugins)
    |> Enum.find_value(fn
      {Oban.Plugins.Cron, cron_opts} -> Keyword.get(cron_opts, :crontab, [])
      _ -> nil
    end)
    |> case do
      nil -> []
      crontab -> Enum.map(crontab, fn {_schedule, worker} -> worker end)
    end
  end

  defp queue_names(oban_config) do
    oban_config
    |> Keyword.fetch!(:queues)
    |> Keyword.keys()
  end
end
