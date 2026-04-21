defmodule Accrue.Docs.Phase33CiAdvisoryContractTest do
  @moduledoc false

  # ADOPT-06 / plan 33-03: stable job ids + merge-blocking vs advisory language at repo root.
  use ExUnit.Case, async: true

  defp repo_root do
    Path.expand("../../../../", __DIR__)
  end

  test "ci workflow and root readme preserve phase 33 advisory vs merge-blocking contract" do
    ci = File.read!(Path.join(repo_root(), ".github/workflows/ci.yml"))
    readme = File.read!(Path.join(repo_root(), "README.md"))

    assert String.contains?(ci, "release-gate")
    assert String.contains?(ci, "host-integration")
    assert String.contains?(ci, "live-stripe")
    assert Regex.match?(~r/job id|merge-blocking|advisory/i, ci)

    assert readme =~ "`host-integration`"
    assert readme =~ "`live-stripe`"
    assert readme =~ "advisory"
  end
end
