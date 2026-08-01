defmodule Accrue.Entitlements.EntitlementSourceMatrixGuardTest do
  use ExUnit.Case, async: true

  @script "../scripts/ci/verify_entitlement_source_matrix.sh"

  test "the checked-in source contract passes the drift gate" do
    assert {output, 0} = System.cmd("bash", [@script], stderr_to_stdout: true)
    assert output =~ "verify_entitlement_source_matrix: OK"
  end

  test "each forbidden Apple-to-processor mutation family fails the non-vacuous gate" do
    for operation <- [
          "cancel_subscription",
          "dunning",
          "retry",
          "swap",
          "proration",
          "create_invoice",
          "payment_method"
        ] do
      fixture = fixture_root!()
      registry = Path.join(fixture, "accrue/lib/accrue/entitlements/source/registry.ex")

      File.write!(
        registry,
        File.read!(registry) <> "\ndef leak, do: Accrue.Processor.#{operation}(:apple)\n"
      )

      {output, status} =
        System.cmd("bash", [@script], stderr_to_stdout: true, env: [{"ROOT_DIR", fixture}])

      assert status != 0
      assert output =~ "processor mutation edge"
    end
  end

  defp fixture_root! do
    fixture =
      Path.join(System.tmp_dir!(), "accrue-source-gate-#{System.unique_integer([:positive])}")

    File.rm_rf!(fixture)
    on_exit(fn -> File.rm_rf(fixture) end)

    repo = Path.expand("..", File.cwd!())

    for path <- [
          ".planning/entitlement-source-capability-matrix.md",
          "accrue/guides/entitlements.md",
          "accrue/priv/entitlements/v1.59-source-capabilities.json",
          "accrue/lib/accrue/entitlements/source/registry.ex"
        ] do
      destination = Path.join(fixture, path)
      File.mkdir_p!(Path.dirname(destination))
      File.cp!(Path.join(repo, path), destination)
    end

    fixture
  end
end
