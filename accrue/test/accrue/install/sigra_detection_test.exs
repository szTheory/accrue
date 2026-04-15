defmodule Accrue.Install.SigraDetectionTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Accrue.Test.InstallFixture

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  @tag :install_patches
  test "Sigra dependency patches auth adapter only when detected" do
    app = InstallFixture.tmp_app!(:sigra_detected)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}",
      "{:sigra, \"~> 0.1\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])

    assert InstallFixture.assert_contains!(
             app,
             "config/config.exs",
             "config :accrue, :auth_adapter, Accrue.Integrations.Sigra"
           )
  end

  @tag :install_patches
  test "fallback auth adapter is generated when Sigra is absent" do
    app = InstallFixture.tmp_app!(:sigra_absent)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])

    assert InstallFixture.assert_contains!(
             app,
             "config/config.exs",
             "config :accrue, :auth_adapter, Accrue.Auth.Default"
           )

    InstallFixture.refute_contains!(app, "config/config.exs", "Accrue.Integrations.Sigra")
  end

  @tag :install_orchestration
  test "installer orchestration reports Sigra wiring and supported community auth path" do
    app = InstallFixture.tmp_app!(:sigra_orchestration)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}",
      "{:sigra, \"~> 0.1\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output = run_install(app, ["--dry-run", "--yes"])

    assert output =~ "Sigra"
    assert output =~ "Accrue.Integrations.Sigra"
    assert output =~ "Accrue.Auth.Default"
    assert output =~ "community"
  end

  defp run_install(app, argv) do
    Mix.Task.clear()

    capture_io(fn ->
      File.cd!(app, fn ->
        apply(Mix.Tasks.Accrue.Install, :run, [argv])
      end)
    end)
  end
end
