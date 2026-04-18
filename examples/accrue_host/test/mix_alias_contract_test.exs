defmodule AccrueHost.MixAliasContractTest do
  use ExUnit.Case, async: true

  @mix_exs Path.expand("../mix.exs", __DIR__)
  @repo_root Path.expand("../../..", __DIR__)

  defp script!(name) do
    path = Path.join([@repo_root, "scripts", "ci", name])
    assert File.exists?(path), "expected verify script at #{path}"
    File.read!(path)
  end

  test "mix.exs wires verify to the bounded proof script listing locked test files" do
    source = File.read!(@mix_exs)

    assert source =~ ~s|"verify"|
    assert source =~ "accrue_host_verify_test_bounded.sh"

    bounded = script!("accrue_host_verify_test_bounded.sh")

    assert bounded =~ "test/install_boundary_test.exs"
    assert bounded =~ "test/accrue_host/billing_facade_test.exs"
    assert bounded =~ "test/accrue_host_web/subscription_flow_test.exs"
    assert bounded =~ "test/accrue_host_web/webhook_ingest_test.exs"
    assert bounded =~ "test/accrue_host_web/trust_smoke_test.exs"
    assert bounded =~ "test/accrue_host_web/admin_webhook_replay_test.exs"
    assert bounded =~ "test/accrue_host_web/admin_mount_test.exs"
    assert bounded =~ "test/accrue_host_web/org_billing_access_test.exs"
    assert bounded =~ "test/accrue_host_web/org_billing_live_test.exs"
  end

  test "mix.exs defines verify.full and scripts cover compile, assets, dev boot, and browser smoke" do
    source = File.read!(@mix_exs)

    assert source =~ ~s|"verify.full"|
    assert source =~ "compile --warnings-as-errors"
    assert source =~ "assets.build"
    assert source =~ "accrue_host_verify_dev_boot.sh"
    assert source =~ "accrue_host_verify_browser.sh"

    dev_boot = script!("accrue_host_verify_dev_boot.sh")
    browser = script!("accrue_host_verify_browser.sh")

    assert dev_boot =~ "mix phx.server"
    assert browser =~ "npm run e2e"

    assert dev_boot =~ "ACCRUE_HOST_SKIP_DEV_BOOT"
    assert browser =~ "ACCRUE_HOST_SKIP_BROWSER"
    assert dev_boot =~ "ACCRUE_HOST_PORT"
    assert browser =~ "ACCRUE_HOST_BROWSER_PORT"
  end
end
