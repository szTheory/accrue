defmodule Accrue.Docs.PackageDocsVerifierTest do
  use ExUnit.Case, async: true

  test "package docs verifier succeeds" do
    {output, status} = System.cmd("bash", ["../scripts/ci/verify_package_docs.sh"], stderr_to_stdout: true)

    assert status == 0
    assert output =~ "package docs verified for accrue 0.1.2 and accrue_admin 0.1.2"
  end
end
