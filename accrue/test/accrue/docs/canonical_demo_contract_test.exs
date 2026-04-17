defmodule Accrue.Docs.CanonicalDemoContractTest do
  use ExUnit.Case, async: true

  @host_readme Path.expand("../../../../examples/accrue_host/README.md", __DIR__)
  @guide "guides/first_hour.md"
  @package_readme "README.md"
  @wrapper_path Path.expand("../../../../scripts/ci/accrue_host_uat.sh", __DIR__)

  test "manifest labels stay in parity across the host docs and wrapper references" do
    manifest = command_manifest()
    host_readme = File.read!(@host_readme)
    guide = File.read!(@guide)
    package_readme = File.read!(@package_readme)
    wrapper = File.read!(@wrapper_path)

    assert_order!(host_readme, [manifest.first_run.label, manifest.seeded_history.label])
    assert_order!(guide, [manifest.first_run.label, manifest.seeded_history.label])

    Enum.each(locked_labels(manifest), fn label ->
      assert host_readme =~ label
      assert guide =~ label
    end)

    assert package_readme =~ "examples/accrue_host"

    Enum.each(["mix verify", "mix verify.full", "bash scripts/ci/accrue_host_uat.sh"], fn label ->
      assert package_readme =~ label
      assert wrapper =~ label
    end)
  end

  test "parity contract reports exact doc drift in a copied fixture tree" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-canonical-demo-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    for relative_path <- [
          "examples/accrue_host/README.md",
          "accrue/guides/first_hour.md",
          "accrue/README.md",
          "scripts/ci/accrue_host_uat.sh"
        ] do
      copy_fixture!(relative_path, tmp_dir)
    end

    broken_guide_path = Path.join(tmp_dir, "accrue/guides/first_hour.md")

    broken_guide_path
    |> File.read!()
    |> String.replace("Seeded history", "Seeded replay")
    |> then(&File.write!(broken_guide_path, &1))

    manifest = command_manifest()
    host_readme = File.read!(Path.join(tmp_dir, "examples/accrue_host/README.md"))
    guide = File.read!(broken_guide_path)

    assert_raise ExUnit.AssertionError, ~r/Seeded history/, fn ->
      Enum.each(locked_labels(manifest), fn label ->
        assert host_readme =~ label
        assert guide =~ label
      end)
    end
  end

  defp command_manifest do
    module = load_manifest_module(Path.expand("../../../../examples/accrue_host/demo/command_manifest.exs", __DIR__))
    apply(module, :manifest, [])
  end

  defp locked_labels(manifest) do
    [
      manifest.first_run.label,
      manifest.seeded_history.label,
      "mix verify",
      "mix verify.full",
      "bash scripts/ci/accrue_host_uat.sh"
    ]
  end

  defp copy_fixture!(relative_path, tmp_dir) do
    destination = Path.join(tmp_dir, relative_path)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
  end

  defp load_manifest_module(path) do
    Code.require_file(path)
    AccrueHost.Demo.CommandManifest
  end

  defp assert_order!(binary, [first | rest]) do
    Enum.reduce(rest, index_of(binary, first), fn needle, previous_index ->
      current_index = index_of(binary, needle, previous_index + 1)
      assert previous_index
      assert current_index
      assert previous_index < current_index
      current_index
    end)
  end

  defp index_of(binary, pattern, offset \\ 0) do
    length = byte_size(binary) - offset

    case :binary.match(binary, pattern, [{:scope, {offset, length}}]) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end
end
