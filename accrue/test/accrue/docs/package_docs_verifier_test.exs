defmodule Accrue.Docs.PackageDocsVerifierTest do
  use ExUnit.Case, async: true

  @script_path "../scripts/ci/verify_package_docs.sh"

  test "package docs verifier succeeds" do
    {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)

    assert status == 0
    assert output =~ "package docs verified for accrue 0.1.2 and accrue_admin 0.1.2"
  end

  test "package docs verifier rejects singular webhook signing secret drift" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))

    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)

    singular_guide =
      tmp_dir
      |> Path.join("accrue/guides/first_hour.md")
      |> File.read!()
      |> String.replace(":webhook_signing_secrets", ":webhook_signing_secret")

    File.write!(Path.join(tmp_dir, "accrue/guides/first_hour.md"), singular_guide)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "first_hour.md"
    assert output =~ "webhook_signing_secret"
  end

  defp copy_fixture!(relative_path, tmp_dir) do
    destination = Path.join(tmp_dir, relative_path)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
  end
end
