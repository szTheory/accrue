defmodule Accrue.Docs.V159AuthorityDocsTest do
  use ExUnit.Case, async: true

  @script_path "scripts/ci/verify_v159_authority.sh"
  @fixture_files [
    ".planning/research/RESEARCH-INDEX.md",
    ".planning/research/v1.59-AUTHORITY.md",
    ".planning/research/v1.59-AMENDMENTS.md",
    ".planning/research/v1.59-WATCHLIST.md"
  ]

  test "v1.59 authority verifier accepts the canonical repository bundle" do
    assert {output, 0} = run_verifier(repo_root())
    assert output =~ "verify_v159_authority: OK"
  end

  test "v1.59 authority verifier rejects missing authority and precedence drift" do
    fixture = fixture_root!()
    File.rm!(Path.join(fixture, ".planning/research/v1.59-AUTHORITY.md"))
    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "missing authority manifest"

    fixture = fixture_root!()

    replace!(
      fixture,
      ".planning/research/RESEARCH-INDEX.md",
      "- [v1.59-AUTHORITY.md](v1.59-AUTHORITY.md)",
      "- [v1.59-SUMMARY.md](v1.59-SUMMARY.md)"
    )

    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "first v1.59 index entry"
  end

  test "v1.59 authority verifier rejects malformed ledger claims" do
    fixture = fixture_root!()

    replace!(
      fixture,
      ".planning/research/v1.59-AMENDMENTS.md",
      "V159-CLAIM-RAIL-001",
      "V159-CLAIM-OFFLINE-001"
    )

    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "duplicate claim_id"

    fixture = fixture_root!()

    replace!(
      fixture,
      ".planning/research/v1.59-AMENDMENTS.md",
      "no independent 72-hour cutoff",
      "72-hour cutoff"
    )

    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "no-72-hour claim"
  end

  test "v1.59 authority verifier rejects incomplete, null, and duplicate watchlist tuples" do
    fixture = fixture_root!()
    replace!(fixture, ".planning/research/v1.59-WATCHLIST.md", "| Apple PKI/x5c/OCSP |", "|  |")
    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "watchlist row"

    fixture = fixture_root!()

    replace!(
      fixture,
      ".planning/research/v1.59-WATCHLIST.md",
      "Phase 218 Apple observer and repair runbook",
      "null"
    )

    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "null"

    fixture = fixture_root!()

    apple_row =
      fixture
      |> Path.join(".planning/research/v1.59-WATCHLIST.md")
      |> File.read!()
      |> String.split("\n")
      |> Enum.find(&String.starts_with?(&1, "| V159-WL-APPLE-API |"))
      |> String.split("|", parts: 3)
      |> List.last()
      |> then(&("| V159-WL-DUPLICATE |" <> &1))

    append!(fixture, ".planning/research/v1.59-WATCHLIST.md", "\n" <> apple_row)
    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "duplicate watchlist tuple"
  end

  test "v1.59 authority verifier requires dated reassessment behavior and all owned categories" do
    fixture = fixture_root!()
    replace_all!(fixture, ".planning/research/v1.59-WATCHLIST.md", "dated reassessment", "review")
    assert {output, status} = run_verifier(fixture)
    assert status != 0
    assert output =~ "dated reassessment"
  end

  defp repo_root, do: Path.expand("../../../..", __DIR__)

  defp fixture_root! do
    fixture =
      Path.join(System.tmp_dir!(), "accrue-v159-authority-#{System.unique_integer([:positive])}")

    File.rm_rf!(fixture)
    on_exit(fn -> File.rm_rf(fixture) end)

    Enum.each(@fixture_files, fn path ->
      source = Path.join(repo_root(), path)
      destination = Path.join(fixture, path)
      File.mkdir_p!(Path.dirname(destination))
      File.cp!(source, destination)
    end)

    fixture
  end

  defp run_verifier(root) do
    System.cmd("bash", [Path.expand(@script_path, repo_root())],
      cd: root,
      env: [{"ROOT_DIR", root}],
      stderr_to_stdout: true
    )
  end

  defp replace!(root, relative_path, needle, replacement) do
    path = Path.join(root, relative_path)
    File.write!(path, String.replace(File.read!(path), needle, replacement, global: false))
  end

  defp replace_all!(root, relative_path, needle, replacement) do
    path = Path.join(root, relative_path)
    File.write!(path, String.replace(File.read!(path), needle, replacement))
  end

  defp append!(root, relative_path, contents),
    do: File.write!(Path.join(root, relative_path), contents, [:append])
end
