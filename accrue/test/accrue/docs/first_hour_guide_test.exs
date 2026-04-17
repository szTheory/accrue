defmodule Accrue.Docs.FirstHourGuideTest do
  use ExUnit.Case, async: true

  @guide "guides/first_hour.md"
  @public_surfaces [
    "MyApp.Billing",
    "use Accrue.Webhook.Handler",
    "use Accrue.Test",
    "AccrueAdmin.Router.accrue_admin/2",
    "Accrue.ConfigError",
    "config :accrue, :webhook_signing_secrets, %{",
    ~s|stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")|
  ]
  @forbidden_surfaces [
    "Accrue.Billing.Customer",
    "Accrue.Billing.Subscription",
    "Accrue.Webhook.WebhookEvent",
    "Accrue.Events.Event",
    "GenServer.call",
    "worker internals"
  ]

  test "first hour guide preserves the manifest-backed host boundary contract" do
    guide = File.read!(@guide)
    manifest = command_manifest()
    first_run = manifest.first_run
    seeded_history = manifest.seeded_history
    command_labels = command_labels()

    assert_order!(
      guide,
      [
        first_run.label,
        "MyApp.Billing.subscribe",
        hd(manifest.story_artifacts),
        Enum.at(manifest.story_artifacts, 2),
        Enum.at(command_labels, 1),
        seeded_history.label,
        Enum.at(command_labels, 2)
      ]
    )

    Enum.each(@public_surfaces, fn surface ->
      assert guide =~ surface
    end)

    Enum.each(@forbidden_surfaces, fn surface ->
      refute guide =~ surface
    end)

    assert guide =~ "First run"
    assert guide =~ "Seeded history"
    assert guide =~ "mix verify.full"
    refute guide =~ ~r/webhook_signing_secret(?!s)/
  end

  defp command_manifest do
    module = load_manifest_module(Path.expand("../../../../examples/accrue_host/demo/command_manifest.exs", __DIR__))
    apply(module, :manifest, [])
  end

  defp command_labels do
    module = load_manifest_module(Path.expand("../../../../examples/accrue_host/demo/command_manifest.exs", __DIR__))
    apply(module, :command_labels, [])
  end

  defp load_manifest_module(path) do
    Code.require_file(path)
    AccrueHost.Demo.CommandManifest
  end

  defp assert_order!(guide, [first | rest]) do
    Enum.reduce(rest, index_of(guide, first), fn step, previous_index ->
      current_index = index_of(guide, step, previous_index + 1)
      assert current_index
      assert previous_index
      assert previous_index < current_index
      current_index
    end)
  end

  defp index_of(binary, pattern, offset \\ 0) do
    length = byte_size(binary) - offset

    case :binary.match(binary, pattern, [{:scope, {offset, length}}]) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
