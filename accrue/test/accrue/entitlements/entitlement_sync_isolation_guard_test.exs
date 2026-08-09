defmodule Accrue.Entitlements.EntitlementSyncIsolationGuardTest do
  use ExUnit.Case, async: true

  @script_path "../scripts/ci/verify_entitlement_sync_isolation.sh"

  @gate_files [
    "accrue/lib/accrue/entitlements.ex",
    "accrue/lib/accrue/entitlements/guard.ex",
    "accrue/lib/accrue/entitlements/resolver.ex",
    "accrue/lib/accrue/entitlements/resolver/local_map.ex"
  ]

  test "clean gate-path fixture passes the isolation guard" do
    tmp_dir = fixture_root!()

    assert {output, 0} = run_guard(tmp_dir)
    assert output =~ "verify_entitlement_sync_isolation: OK"
  end

  test "executable list_active_entitlements gate edge fails the isolation guard" do
    tmp_dir = fixture_root!()

    inject_before_comment!(
      tmp_dir,
      "accrue/lib/accrue/entitlements/resolver/local_map.ex",
      "def leak, do: Accrue.Processor.list_active_entitlements(\"cus_123\", [])"
    )

    {output, status} = run_guard(tmp_dir)

    assert status != 0
    assert output =~ "verify_entitlement_sync_isolation: FAIL"
    assert output =~ "list_active_entitlements"
  end

  test "executable Reconcile gate edge fails the isolation guard" do
    tmp_dir = fixture_root!()

    inject_before_comment!(
      tmp_dir,
      "accrue/lib/accrue/entitlements.ex",
      "def leak, do: Accrue.Entitlements.Reconcile.write(:gate)"
    )

    {output, status} = run_guard(tmp_dir)

    assert status != 0
    assert output =~ "verify_entitlement_sync_isolation: FAIL"
    assert output =~ "Reconcile"
  end

  test "comment and moduledoc mentions of new guard tokens pass" do
    tmp_dir = fixture_root!()

    write_gate_file!(
      tmp_dir,
      "accrue/lib/accrue/entitlements/resolver.ex",
      """
      defmodule Accrue.Entitlements.Resolver do
        @moduledoc \"\"\"
        Diagnostic prose may name list_active_entitlements and Accrue.Entitlements.Reconcile.
        \"\"\"

        # Comment prose may also name list_active_entitlements and Reconcile.
        def resolve(_billable, _opts), do: {:ok, %{}}
      end
      """
    )

    assert {output, 0} = run_guard(tmp_dir)
    assert output =~ "verify_entitlement_sync_isolation: OK"
  end

  @tag :guard_surface_red_path
  test "executable advisory references from guard fail the isolation guard" do
    forbidden_refs = [
      {"list_active_entitlements",
       "def leak, do: Accrue.Processor.list_active_entitlements(\"cus_123\", [])"},
      {"Reconcile", "def leak, do: Accrue.Entitlements.Reconcile.write(:gate)"},
      {"StripeSync", "def leak, do: Accrue.Entitlements.StripeSync.refresh(:gate)"},
      {"EntitlementSummary", "def leak, do: Accrue.Billing.EntitlementSummary"}
    ]

    Enum.each(forbidden_refs, fn {token, code} ->
      tmp_dir = fixture_root!()

      inject_before_comment!(
        tmp_dir,
        "accrue/lib/accrue/entitlements/guard.ex",
        code
      )

      {output, status} = run_guard(tmp_dir)

      assert status != 0
      assert output =~ "verify_entitlement_sync_isolation: FAIL"
      assert output =~ token
    end)
  end

  test "guard comment and moduledoc mentions of forbidden advisory symbols pass" do
    tmp_dir = fixture_root!()

    write_gate_file!(
      tmp_dir,
      "accrue/lib/accrue/entitlements/guard.ex",
      """
      defmodule Accrue.Entitlements.Guard do
        @moduledoc \"\"\"
        Guard prose may name Accrue.Processor.list_active_entitlements/2,
        Accrue.Entitlements.Reconcile, Accrue.Entitlements.StripeSync, and
        Accrue.Billing.EntitlementSummary while documenting the isolation rule.
        \"\"\"

        # Comments may name list_active_entitlements, Reconcile, StripeSync, and EntitlementSummary.
        def clean, do: :ok
      end
      """
    )

    assert {output, 0} = run_guard(tmp_dir)
    assert output =~ "verify_entitlement_sync_isolation: OK"
  end

  test "missing gate-path fixture still fails with the missing-file message" do
    tmp_dir = fixture_root!()
    File.rm!(Path.join(tmp_dir, "accrue/lib/accrue/entitlements/resolver.ex"))

    {output, status} = run_guard(tmp_dir)

    assert status != 0
    assert output =~ "verify_entitlement_sync_isolation: missing gate-path file"
  end

  defp fixture_root! do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "accrue-entitlement-sync-isolation-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(tmp_dir)
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    Enum.each(@gate_files, fn path ->
      write_gate_file!(
        tmp_dir,
        path,
        """
        defmodule #{module_for(path)} do
          @moduledoc false

          def clean, do: :ok
        end
        """
      )
    end)

    tmp_dir
  end

  defp inject_before_comment!(tmp_dir, relative_path, code) do
    path = Path.join(tmp_dir, relative_path)
    original = File.read!(path)

    File.write!(
      path,
      String.replace(original, "def clean, do: :ok", code <> "\n  def clean, do: :ok")
    )
  end

  defp write_gate_file!(tmp_dir, relative_path, contents) do
    path = Path.join(tmp_dir, relative_path)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end

  defp run_guard(tmp_dir) do
    System.cmd("bash", [@script_path],
      stderr_to_stdout: true,
      env: [{"ROOT_DIR", tmp_dir}]
    )
  end

  defp module_for("accrue/lib/accrue/entitlements.ex"), do: Accrue.Entitlements
  defp module_for("accrue/lib/accrue/entitlements/guard.ex"), do: Accrue.Entitlements.Guard
  defp module_for("accrue/lib/accrue/entitlements/resolver.ex"), do: Accrue.Entitlements.Resolver

  defp module_for("accrue/lib/accrue/entitlements/resolver/local_map.ex"),
    do: Accrue.Entitlements.Resolver.LocalMap
end
