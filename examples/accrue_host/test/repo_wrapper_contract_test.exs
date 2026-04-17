defmodule AccrueHost.RepoWrapperContractTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../../scripts/ci/accrue_host_uat.sh", __DIR__)

  test "repo-root wrapper delegates to host-local verify.full and preserves env toggles" do
    script = File.read!(@script)

    assert script =~ "mix verify.full"
    assert script =~ "ACCRUE_HOST_PORT"
    assert script =~ "ACCRUE_HOST_BROWSER_PORT"
    assert script =~ "ACCRUE_HOST_SKIP_DEV_BOOT"
    assert script =~ "ACCRUE_HOST_SKIP_BROWSER"
  end

  test "repo-root wrapper no longer embeds the focused proof file list" do
    script = File.read!(@script)

    refute script =~ "test/install_boundary_test.exs"
    refute script =~ "test/accrue_host/billing_facade_test.exs"
    refute script =~ "test/accrue_host_web/subscription_flow_test.exs"
  end
end
