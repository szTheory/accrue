defmodule AccrueHost.MixAliasContractTest do
  use ExUnit.Case, async: true

  @mix_exs Path.expand("../mix.exs", __DIR__)

  test "mix.exs defines the focused verify alias with the locked proof files" do
    source = File.read!(@mix_exs)

    assert source =~ ~s|"verify"|
    assert source =~ "test/install_boundary_test.exs"
    assert source =~ "test/accrue_host/billing_facade_test.exs"
    assert source =~ "test/accrue_host_web/subscription_flow_test.exs"
    assert source =~ "test/accrue_host_web/webhook_ingest_test.exs"
    assert source =~ "test/accrue_host_web/trust_smoke_test.exs"
    assert source =~ "test/accrue_host_web/admin_webhook_replay_test.exs"
    assert source =~ "test/accrue_host_web/admin_mount_test.exs"
  end

  test "mix.exs defines the full verify alias with compile, assets, dev boot, and browser smoke" do
    source = File.read!(@mix_exs)

    assert source =~ ~s|"verify.full"|
    assert source =~ "compile --warnings-as-errors"
    assert source =~ "assets.build"
    assert source =~ "mix phx.server"
    assert source =~ "npm run e2e"
    assert source =~ "ACCRUE_HOST_SKIP_DEV_BOOT"
    assert source =~ "ACCRUE_HOST_SKIP_BROWSER"
    assert source =~ "ACCRUE_HOST_PORT"
    assert source =~ "ACCRUE_HOST_BROWSER_PORT"
  end
end
