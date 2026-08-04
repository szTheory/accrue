defmodule Accrue.Docs.V159ReleaseContractTest do
  use ExUnit.Case, async: true

  @adoption_script "../scripts/ci/verify_adoption_proof_matrix.sh"
  @release_script "../scripts/ci/verify_release_contract.sh"

  test "v1.59 adoption and release gates succeed on the checked-in contract" do
    {adoption_output, adoption_status} =
      System.cmd("bash", [@adoption_script], stderr_to_stdout: true)

    {release_output, release_status} =
      System.cmd("bash", [@release_script], stderr_to_stdout: true)

    assert adoption_status == 0, adoption_output
    assert adoption_output =~ "verify_adoption_proof_matrix: v1.59 OK"
    assert release_status == 0, release_output
    assert release_output =~ "verify_release_contract: v1.59 OK"
  end

  test "v1.59 release gate rejects inflated runtime claims in an isolated guide copy" do
    tmp_dir = release_fixture_dir!()
    seed_v159_fixture!(tmp_dir)

    guide = Path.join(tmp_dir, "accrue/guides/multi-rail-offline-release.md")

    guide
    |> File.read!()
    |> String.replace(
      "The Crosswake\ntracer remains `feasibility_blocked`",
      "Crosswake runtime is supported. The tracer remains `feasibility_blocked`",
      global: false
    )
    |> then(&File.write!(guide, &1))

    {output, status} = run_release_contract(tmp_dir)

    assert status != 0
    assert output =~ "accrue/guides/multi-rail-offline-release.md"
    assert output =~ "runtime-capability inflation"
  end

  test "v1.59 release gate rejects backend-first wording outside explanatory prohibitions" do
    tmp_dir = release_fixture_dir!()
    seed_v159_fixture!(tmp_dir)

    runbooks = Path.join(tmp_dir, "accrue/guides/operator-runbooks.md")

    runbooks
    |> File.read!()
    |> String.replace(
      "## v1.59 multi-rail and offline runbooks",
      "## v1.59 multi-rail and offline runbooks\n\nInspect the worker queue before stating the operator's job.",
      global: false
    )
    |> then(&File.write!(runbooks, &1))

    {output, status} = run_release_contract(tmp_dir)

    assert status != 0
    assert output =~ "accrue/guides/operator-runbooks.md"
    assert output =~ "backend-first procedure wording"
  end

  test "v1.59 release gate rejects each remaining additive-contract contradiction" do
    cases = [
      {"Apple subscriptions management is supported.", "Apple-owned lifecycle claim"},
      {"Cross-rail ownership migration is automatic.", "automatic cross-rail mutation claim"},
      {"Stale offline access permits premium expansion.", "stale premium expansion claim"},
      {"Raw transaction data is exposed in release evidence.", "private-data visibility claim"}
    ]

    Enum.each(cases, fn {claim, expected_failure} ->
      tmp_dir = release_fixture_dir!()
      seed_v159_fixture!(tmp_dir)
      guide = Path.join(tmp_dir, "accrue/guides/multi-rail-offline-release.md")
      File.write!(guide, File.read!(guide) <> "\n#{claim}\n")

      {output, status} = run_release_contract(tmp_dir)
      assert status != 0, output
      assert output =~ "accrue/guides/multi-rail-offline-release.md"
      assert output =~ expected_failure
    end)
  end

  test "v1.59 release gate rejects missing App Review and incident procedures" do
    tmp_dir = release_fixture_dir!()
    seed_v159_fixture!(tmp_dir)

    release_guide = Path.join(tmp_dir, "accrue/guides/multi-rail-offline-release.md")

    File.write!(
      release_guide,
      String.replace(File.read!(release_guide), "## Evidence and App Review", "## Evidence")
    )

    {app_review_output, app_review_status} = run_release_contract(tmp_dir)
    assert app_review_status != 0
    assert app_review_output =~ "accrue/guides/multi-rail-offline-release.md"
    assert app_review_output =~ "App Review"

    seed_v159_fixture!(tmp_dir)
    runbooks = Path.join(tmp_dir, "accrue/guides/operator-runbooks.md")

    File.write!(
      runbooks,
      String.replace(File.read!(runbooks), "V159-RUN-APP-REVIEW", "V159-RUN-REMOVED",
        global: false
      )
    )

    {runbook_output, runbook_status} = run_release_contract(tmp_dir)
    assert runbook_status != 0
    assert runbook_output =~ "accrue/guides/operator-runbooks.md"
    assert runbook_output =~ "V159-RUN-APP-REVIEW"

    seed_v159_fixture!(tmp_dir)
    watchlist = Path.join(tmp_dir, ".planning/research/v1.59-WATCHLIST.md")

    File.write!(
      watchlist,
      String.replace(File.read!(watchlist), "V159-WL-PRIVACY", "V159-WL-REMOVED", global: false)
    )

    {watchlist_output, watchlist_status} = run_release_contract(tmp_dir)
    assert watchlist_status != 0
    assert watchlist_output =~ ".planning/research/v1.59-WATCHLIST.md"
    assert watchlist_output =~ "V159-WL-PRIVACY"
  end

  defp run_release_contract(tmp_dir) do
    System.cmd("bash", [@release_script],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}, {"V159_SOURCE_ROOT", Path.expand("../../../..", __DIR__)}]
    )
  end

  defp release_fixture_dir! do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-v159-release-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    tmp_dir
  end

  defp seed_v159_fixture!(tmp_dir) do
    File.rm_rf!(tmp_dir)

    for path <- [
          "accrue/guides/entitlements.md",
          "accrue/guides/multi-rail-offline-release.md",
          "accrue/guides/operator-runbooks.md",
          "accrue/guides/release-notes.md",
          "accrue/priv/entitlements/v1.59-public-contract.json",
          "accrue/priv/entitlements/v1.59-reference-scenarios.json",
          "examples/accrue_host/docs/adoption-proof-matrix.md",
          "examples/accrue_host/docs/capability-limits-matrix.md",
          "examples/crosswake_tracer/README.md",
          "examples/crosswake_tracer/capability-report.json",
          ".planning/research/v1.59-WATCHLIST.md"
        ] do
      copy_fixture!(path, tmp_dir)
    end
  end

  defp copy_fixture!(relative_path, tmp_dir) do
    source = Path.expand("../../../../#{relative_path}", __DIR__)
    destination = Path.join(tmp_dir, relative_path)
    destination |> Path.dirname() |> File.mkdir_p!()
    File.cp!(source, destination)
  end
end
