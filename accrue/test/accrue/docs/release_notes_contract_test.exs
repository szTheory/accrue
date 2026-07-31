defmodule Accrue.Docs.ReleaseNotesContractTest do
  use ExUnit.Case, async: true

  @script_path "../scripts/ci/verify_release_notes_contract.sh"

  test "release notes contract succeeds" do
    {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
    version = extract_version!(Path.expand("../../../../accrue/mix.exs", __DIR__))

    assert status == 0
    assert output =~ "verify_release_notes_contract: OK (#{version})"
  end

  test "release notes contract rejects missing current-version section" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    version = extract_version!(Path.join(tmp_dir, "accrue/mix.exs"))

    drifted_notes =
      tmp_dir
      |> Path.join("accrue/guides/release-notes.md")
      |> File.read!()
      |> String.replace("### #{version}", "### stale-#{version}", global: false)

    File.write!(Path.join(tmp_dir, "accrue/guides/release-notes.md"), drifted_notes)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "release-notes.md must describe #{version}"
  end

  test "release notes contract rejects missing and misplaced Unreleased changelog ownership" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    core_changelog = Path.join(tmp_dir, "accrue/CHANGELOG.md")

    drifted_core =
      File.read!(core_changelog)
      |> String.replace("## Unreleased\n\n", "")

    File.write!(core_changelog, drifted_core)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "accrue/CHANGELOG.md missing top-level Unreleased before latest release"

    setup_release_fixture!(tmp_dir)

    admin_changelog = Path.join(tmp_dir, "accrue_admin/CHANGELOG.md")

    misplaced_admin =
      File.read!(admin_changelog)
      |> String.replace("## Unreleased\n\n", "")
      |> String.replace("## [1.4.0]", "## [1.4.0]\n\n## Unreleased", global: false)

    File.write!(admin_changelog, misplaced_admin)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "accrue_admin/CHANGELOG.md missing top-level Unreleased before latest release"
  end

  test "release notes contract rejects package ownership inversions" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    admin_changelog = Path.join(tmp_dir, "accrue_admin/CHANGELOG.md")

    drifted_admin =
      File.read!(admin_changelog)
      |> String.replace(
        "Compatibility only:",
        "New admin-owned advisory entitlement workflow:",
        global: false
      )

    File.write!(admin_changelog, drifted_admin)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "accrue_admin/CHANGELOG.md must remain compatibility-only"
  end

  test "release notes contract rejects manual numbered 1.5.0 changelog sections" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    portal_changelog = Path.join(tmp_dir, "accrue_portal/CHANGELOG.md")

    manually_numbered =
      File.read!(portal_changelog)
      |> String.replace("## Unreleased", "## Unreleased\n\n## [1.5.0]", global: false)

    File.write!(portal_changelog, manually_numbered)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "Release Please owns numbered 1.5.0 changelog sections"
  end

  test "release notes contract rejects missing portal changelog link" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    notes = Path.join(tmp_dir, "accrue/guides/release-notes.md")

    drifted_notes =
      File.read!(notes)
      |> String.replace(
        "- [`accrue_portal/CHANGELOG.md`](https://github.com/szTheory/accrue/blob/main/accrue_portal/CHANGELOG.md) — same for the customer portal package\n",
        ""
      )

    File.write!(notes, drifted_notes)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "release-notes.md missing accrue_portal changelog link"
  end

  test "release notes contract rejects missing next-release 1.5.0 story" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "accrue-release-notes-#{System.unique_integer([:positive])}")

    setup_release_fixture!(tmp_dir)

    notes = Path.join(tmp_dir, "accrue/guides/release-notes.md")

    drifted_notes =
      File.read!(notes)
      |> String.replace(
        "### 1.5.0\n\n**lattice_stripe 2.x plus observational Stripe-native entitlement sync.**\n\n`1.5.0` is the next linked feature release. The core `accrue` package moves to `lattice_stripe ~> 2.0` and adds an optional, default-off Stripe-native entitlement refresh for diagnostics and admin read surfaces. The local plan-to-feature map remains the only Accrue grant gate, so Stripe-native advisory data never changes `entitled?/2`, plugs, or LiveView guards.\n\n`accrue_admin` and `accrue_portal` ship compatibility-only updates in the same linked version family; they do not add package-owned workflows or authorization behavior for this slice.\n\n",
        ""
      )

    File.write!(notes, drifted_notes)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "verify_release_notes_contract:"
    assert output =~ "release-notes.md missing next-release 1.5.0 story"
  end

  defp extract_version!(file) do
    content = File.read!(file)

    Regex.run(~r/@version "([^"]+)"/, content, capture: :all_but_first)
    |> case do
      [version] -> version
      _ -> raise "could not extract version from #{file}"
    end
  end

  defp copy_fixture!(relative_path, tmp_dir) do
    source = Path.expand("../../../../#{relative_path}", __DIR__)
    destination = Path.join(tmp_dir, relative_path)
    destination |> Path.dirname() |> File.mkdir_p!()
    File.cp!(source, destination)
  end

  defp setup_release_fixture!(tmp_dir) do
    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    for path <- [
          "accrue/mix.exs",
          "accrue_admin/mix.exs",
          "accrue_portal/mix.exs",
          "accrue/CHANGELOG.md",
          "accrue_admin/CHANGELOG.md",
          "accrue_portal/CHANGELOG.md",
          "accrue/guides/release-notes.md"
        ] do
      copy_fixture!(path, tmp_dir)
    end
  end
end
