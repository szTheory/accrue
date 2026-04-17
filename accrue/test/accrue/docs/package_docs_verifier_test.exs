defmodule Accrue.Docs.PackageDocsVerifierTest do
  use ExUnit.Case, async: true

  @script_path "../scripts/ci/verify_package_docs.sh"

  test "package docs verifier succeeds" do
    {output, status} = System.cmd("bash", [@script_path], stderr_to_stdout: true)
    accrue_version = extract_version!("accrue/mix.exs")
    accrue_admin_version = extract_version!("accrue_admin/mix.exs")

    assert status == 0

    assert output =~
             "package docs verified for accrue #{accrue_version} and accrue_admin #{accrue_admin_version}"

    assert output =~ "README.md"
    assert output =~ "RELEASING.md"
    assert output =~ "First run"
    assert output =~ "15-TRUST-REVIEW.md"
    assert output =~ "STRIPE_TEST_SECRET_KEY"
    assert output =~ "retain-on-failure"
    assert output =~ "only-on-failure"
  end

  test "package docs verifier rejects missing canonical verification labels" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("README.md", tmp_dir)
    copy_fixture!("RELEASING.md", tmp_dir)
    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/playwright.config.js", tmp_dir)
    copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
    copy_fixture!("scripts/ci/accrue_host_uat.sh", tmp_dir)

    drifted_readme =
      tmp_dir
      |> Path.join("examples/accrue_host/README.md")
      |> File.read!()
      |> String.replace("mix verify.full", "mix verify all")

    File.write!(Path.join(tmp_dir, "examples/accrue_host/README.md"), drifted_readme)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "examples/accrue_host/README.md"
    assert output =~ "mix verify.full"
  end

  test "package docs verifier rejects missing release guidance invariants" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("README.md", tmp_dir)
    copy_fixture!("RELEASING.md", tmp_dir)
    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/playwright.config.js", tmp_dir)
    copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
    copy_fixture!("scripts/ci/accrue_host_uat.sh", tmp_dir)

    drifted_releasing =
      tmp_dir
      |> Path.join("RELEASING.md")
      |> File.read!()
      |> String.replace("provider-parity checks", "optional checks")

    File.write!(Path.join(tmp_dir, "RELEASING.md"), drifted_releasing)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "RELEASING.md"
    assert output =~ "provider-parity checks"
  end

  test "package docs verifier rejects missing trust review invariant" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("README.md", tmp_dir)
    copy_fixture!("RELEASING.md", tmp_dir)
    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/playwright.config.js", tmp_dir)
    copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
    copy_fixture!("scripts/ci/accrue_host_uat.sh", tmp_dir)
    drifted_releasing =
      tmp_dir
      |> Path.join("RELEASING.md")
      |> File.read!()
      |> String.replace("15-TRUST-REVIEW.md", "trust-review.md")

    File.write!(Path.join(tmp_dir, "RELEASING.md"), drifted_releasing)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "15-TRUST-REVIEW.md"
  end

  test "package docs verifier rejects drift in retained artifact policy" do
    tmp_dir = Path.join(System.tmp_dir!(), "accrue-docs-verifier-#{System.unique_integer([:positive])}")

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)
    File.mkdir_p!(Path.join(tmp_dir, "accrue/guides"))
    File.mkdir_p!(Path.join(tmp_dir, "accrue_admin"))
    File.mkdir_p!(Path.join(tmp_dir, "examples/accrue_host"))
    File.mkdir_p!(Path.join(tmp_dir, "scripts/ci"))

    copy_fixture!("README.md", tmp_dir)
    copy_fixture!("RELEASING.md", tmp_dir)
    copy_fixture!("accrue/mix.exs", tmp_dir)
    copy_fixture!("accrue/README.md", tmp_dir)
    copy_fixture!("accrue/guides/first_hour.md", tmp_dir)
    copy_fixture!("accrue/guides/troubleshooting.md", tmp_dir)
    copy_fixture!("accrue_admin/mix.exs", tmp_dir)
    copy_fixture!("accrue_admin/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/README.md", tmp_dir)
    copy_fixture!("examples/accrue_host/playwright.config.js", tmp_dir)
    copy_fixture!("guides/testing-live-stripe.md", tmp_dir)
    copy_fixture!("scripts/ci/accrue_host_uat.sh", tmp_dir)

    drifted_config =
      tmp_dir
      |> Path.join("examples/accrue_host/playwright.config.js")
      |> File.read!()
      |> String.replace(~s(trace: "retain-on-failure"), ~s(trace: "on"))

    File.write!(Path.join(tmp_dir, "examples/accrue_host/playwright.config.js"), drifted_config)

    {output, status} =
      System.cmd("bash", [@script_path],
        stderr_to_stdout: true,
        env: [{"ROOT_DIR", tmp_dir}]
      )

    assert status != 0
    assert output =~ "retain-on-failure"
  end

  defp copy_fixture!(relative_path, tmp_dir) do
    destination = Path.join(tmp_dir, relative_path)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.expand("../../../../" <> relative_path, __DIR__), destination)
  end

  defp extract_version!(relative_path) do
    "../../../../#{relative_path}"
    |> Path.expand(__DIR__)
    |> File.read!()
    |> then(fn content ->
      Regex.run(~r/@version "([^"]+)"/, content, capture: :all_but_first)
    end)
    |> case do
      [version] -> version
      _ -> flunk("could not parse @version from #{relative_path}")
    end
  end
end
