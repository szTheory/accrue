defmodule Accrue.Docs.OrganizationBillingOrg09MatrixTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defp repo_root, do: Path.expand("../../../..", __DIR__)

  test "ORG-09 adoption proof matrix script passes" do
    root = repo_root()
    script = Path.join(root, "scripts/ci/verify_adoption_proof_matrix.sh")
    assert File.exists?(script)

    assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
    assert output =~ "verify_adoption_proof_matrix: OK"
  end
end
