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

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_portal"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_portal/mix.exs", tmp_dir)
    copy_fixture!("accrue/guides/release-notes.md", tmp_dir)

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
end
