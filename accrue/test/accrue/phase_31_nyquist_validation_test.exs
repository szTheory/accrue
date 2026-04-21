defmodule Accrue.Phase31NyquistValidationTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defp repo_root, do: Path.expand("../../..", __DIR__)

  test "VERIFY-01 README contract script passes (INV-03, MOB-03, A11Y-03)" do
    root = repo_root()
    script = Path.join(root, "scripts/ci/verify_verify01_readme_contract.sh")
    assert File.exists?(script)

    assert {output, 0} = System.cmd("bash", [script], cd: root, stderr_to_stdout: true)
    assert output =~ "OK"
  end

  test "host package.json defines e2e:mobile per Phase 31 plan 01 (MOB-03)" do
    root = repo_root()
    path = Path.join(root, "examples/accrue_host/package.json")
    assert %{"scripts" => scripts} = Jason.decode!(File.read!(path))

    assert scripts["e2e:mobile"] ==
             "env -u NO_COLOR playwright test e2e/verify01-admin-mobile.spec.js"
  end
end
