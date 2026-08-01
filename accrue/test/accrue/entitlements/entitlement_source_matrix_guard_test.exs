defmodule Accrue.Entitlements.EntitlementSourceMatrixGuardTest do
  use ExUnit.Case, async: true

  @script "../scripts/ci/verify_entitlement_source_matrix.sh"

  test "the checked-in source contract passes the drift gate" do
    assert {output, 0} = System.cmd("bash", [@script], stderr_to_stdout: true)
    assert output =~ "verify_entitlement_source_matrix: OK"
  end
end
