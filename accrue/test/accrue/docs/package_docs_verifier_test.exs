defmodule Accrue.Docs.PackageDocsVerifierTest do
  use ExUnit.Case, async: true

  test "package docs verifier scaffold is callable and exits cleanly" do
    {output, status} = System.cmd("bash", ["../scripts/ci/verify_package_docs.sh"], stderr_to_stdout: true)

    assert status == 0
    assert output =~ "Phase 12 plan 07 activates package-doc drift checks"
  end
end
