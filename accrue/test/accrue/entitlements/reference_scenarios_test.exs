defmodule Accrue.Entitlements.ReferenceScenariosTest do
  use ExUnit.Case, async: true

  alias Accrue.Entitlements.ReferenceScenarios
  alias Accrue.Entitlements.ReferenceScenarios.Markdown

  @repo_root Path.expand("../../../..", __DIR__)

  test "public contract renders a deterministic, evidence-lane-aware matrix" do
    assert {:ok, matrix} = Markdown.render(@repo_root)
    assert matrix == elem(Markdown.render(@repo_root), 1)

    for claim <- [
          "Legacy hosts remain compatible.",
          "Apple subscriptions are externally managed.",
          "No cross-rail lifecycle, migration, refund, or proration mutation occurs.",
          "Stale access preserves downloaded study and local progress only; expansion waits for reconnect.",
          "No raw transaction data, signed proof material, tokens, or PII is exposed.",
          "`apple_purchase_to_web_login`",
          "`stripe_purchase_to_ios_login`",
          "`deterministic_conformance`",
          "`runtime_capability`",
          "`advisory_parity`",
          "mix accrue.entitlements.reference_scenarios --check",
          "`feasibility_blocked`"
        ] do
      assert matrix =~ claim
    end
  end

  test "deterministic action kinds remain a closed command inventory" do
    scenario = ReferenceScenarios.fetch!("refund_revocation")
    [action | rest] = scenario.actions

    refute ReferenceScenarios.valid?(%{
             scenario
             | actions: [%{action | kind: "grant_everything"} | rest]
           })

    refute ReferenceScenarios.valid?(%{scenario | actions: [%{action | order: 9} | rest]})
  end

  test "closed payloads reject missing, extra, and cross-family command shapes" do
    scenario = ReferenceScenarios.fetch!("refund_revocation")
    [grant, refund] = scenario.actions

    refute ReferenceScenarios.valid?(%{
             scenario
             | actions: [
                 %{
                   refund
                   | command: %{
                       refund.command
                       | payload: Map.delete(refund.command.payload, :provider_event_id)
                     }
                 }
                 | [grant]
               ]
           })

    refute ReferenceScenarios.valid?(%{
             scenario
             | actions: [
                 %{
                   refund
                   | command: %{
                       refund.command
                       | payload: Map.put(refund.command.payload, :secret, "never")
                     }
                 }
                 | [grant]
               ]
           })

    refute ReferenceScenarios.valid?(%{
             scenario
             | actions: [%{refund | command: %{grant.command | kind: refund.kind}} | [grant]]
           })
  end

  @tag :action_contract
  test "every deterministic action requires its own closed command and expected transition" do
    for scenario <- ReferenceScenarios.deterministic_scenarios(), action <- scenario.actions do
      remaining = List.delete(scenario.actions, action)

      refute ReferenceScenarios.valid?(%{
               scenario
               | actions: [%{action | command: nil} | remaining]
             })

      refute ReferenceScenarios.valid?(%{
               scenario
               | actions: [%{action | expected_transition: nil} | remaining]
             })
    end
  end

  @tag :special_dispatch
  test "special action families retain a declared production seam" do
    seams =
      for scenario <- ReferenceScenarios.deterministic_scenarios(),
          action <- scenario.actions,
          action.kind in [
            "apple_verified_purchase",
            "stripe_verified_purchase",
            "purchase_preflight",
            "offline_proof_stale",
            "offline_expansion_request",
            "signed_deny",
            "rollback_proof",
            "rotated_key_proof",
            "empty_evidence",
            "device_replace"
          ],
          into: %{},
          do: {action.kind, action.expected_transition.seam}

    assert seams == %{
             "apple_verified_purchase" => "apple_admission",
             "stripe_verified_purchase" => "observation_projector",
             "purchase_preflight" => "purchase_decision",
             "offline_proof_stale" => "offline_verify_policy",
             "offline_expansion_request" => "offline_verify_policy",
             "signed_deny" => "offline_verify_policy",
             "rollback_proof" => "offline_verify_policy",
             "rotated_key_proof" => "verification_key_retention",
             "empty_evidence" => "offline_verify",
             "device_replace" => "offline_replace_device"
           }
  end

  @tag :special_dispatch
  test "ordering and resume rows declare complete delivery and recovery commands" do
    equal_order = ReferenceScenarios.fetch!("equal_order_stability") |> hd_action()
    repeat = ReferenceScenarios.fetch!("repeat_idempotency") |> hd_action()
    parallel = ReferenceScenarios.fetch!("parallel_execution") |> hd_action()
    interruption = ReferenceScenarios.fetch!("interrupted_resume") |> hd_action()

    resume =
      ReferenceScenarios.fetch!("interrupted_resume").actions
      |> List.last()
      |> Map.fetch!(:command)

    assert equal_order.command.payload.permutations == [[0, 1], [1, 0]]
    assert length(equal_order.command.payload.deliveries) == 2
    assert repeat.command.payload.repeat_count == 3
    assert length(repeat.command.payload.deliveries) == 1
    assert parallel.command.payload.workers == [0, 0]
    assert length(parallel.command.payload.deliveries) == 1
    assert interruption.command.payload.interruption_hook == "after_admission"
    assert resume.payload.request_ref == interruption.command.payload.request_ref
  end

  test "write and check reject stale generated output" do
    root = fixture_root!()

    assert :ok = Markdown.write(root)
    assert :ok = Markdown.check(root)

    matrix_path = Path.join(root, "examples/accrue_host/docs/capability-limits-matrix.md")
    File.write!(matrix_path, "stale output\n")

    assert {:error, [^matrix_path]} = Markdown.check(root)
  end

  test "public contract rejects private fields, broken scenario bindings, and runtime promotion" do
    root = fixture_root!()
    fixture_path = Path.join(root, "accrue/priv/entitlements/v1.59-public-contract.json")

    for mutation <- [
          fn fixture -> Map.put(fixture, "token", "secret") end,
          fn fixture -> put_in(fixture, ["scenario_ids"], ["unknown_scenario"]) end,
          fn fixture -> put_in(fixture, ["runtime_capability", "status"], "supported") end
        ] do
      fixture_path
      |> File.read!()
      |> Jason.decode!()
      |> mutation.()
      |> Jason.encode!(pretty: true)
      |> Kernel.<>("\n")
      |> then(&File.write!(fixture_path, &1))

      assert {:error, _reason} = Markdown.render(root)
      copy_fixture_file!(root, "accrue/priv/entitlements/v1.59-public-contract.json")
    end
  end

  test "public contract rejects duplicate JSON keys and missing closed fields" do
    root = fixture_root!()
    fixture_path = Path.join(root, "accrue/priv/entitlements/v1.59-public-contract.json")

    File.write!(
      fixture_path,
      File.read!(fixture_path)
      |> String.replace(~s("version": "v1.59",), ~s("version": "v1.59",\n  "version": "v1.59",),
        global: false
      )
    )

    assert {:error, _reason} = Markdown.render(root)
    copy_fixture_file!(root, "accrue/priv/entitlements/v1.59-public-contract.json")

    fixture_path
    |> File.read!()
    |> Jason.decode!()
    |> Map.delete("privacy_exclusions")
    |> Jason.encode!(pretty: true)
    |> Kernel.<>("\n")
    |> then(&File.write!(fixture_path, &1))

    assert {:error, _reason} = Markdown.render(root)
  end

  test "release gate fails closed on every prohibited public claim family" do
    for {claim, failure} <- [
          {"Crosswake runtime is supported.", "runtime-capability inflation"},
          {"Apple lifecycle control is available.", "Apple lifecycle control"},
          {"Cross-rail refund mutation is supported.", "cross-rail mutation"},
          {"Stale access permits premium expansion.", "stale premium expansion"},
          {"Raw transaction data and signed proof material are exposed.", "private-data claim"}
        ] do
      root = gate_fixture_root!()
      matrix = Path.join(root, "examples/accrue_host/docs/capability-limits-matrix.md")
      File.write!(matrix, File.read!(matrix) <> "\n#{claim}\n")

      {output, status} = run_gate(root)
      assert status != 0
      assert output =~ failure
    end
  end

  test "release gate requires its pull-request CI invocation and current generated output" do
    root = gate_fixture_root!()
    workflow = Path.join(root, ".github/workflows/ci.yml")

    File.write!(
      workflow,
      File.read!(workflow)
      |> String.replace("bash scripts/ci/verify_reference_scenario_contract.sh", "true",
        global: false
      )
    )

    {output, status} = run_gate(root)
    assert status != 0
    assert output =~ "docs-contracts-shift-left invocation"

    root = gate_fixture_root!()
    matrix = Path.join(root, "examples/accrue_host/docs/capability-limits-matrix.md")
    File.write!(matrix, "stale generated output\n")

    {output, status} = run_gate(root)
    assert status != 0
    assert output =~ "generated matrix drift"
  end

  defp fixture_root! do
    root =
      Path.join(System.tmp_dir!(), "reference-scenarios-#{System.unique_integer([:positive])}")

    File.rm_rf!(root)
    on_exit(fn -> File.rm_rf(root) end)

    for path <- [
          "accrue/priv/entitlements/v1.59-public-contract.json",
          "accrue/priv/entitlements/v1.59-reference-scenarios.json",
          "examples/crosswake_tracer/capability-report.json"
        ] do
      copy_fixture_file!(root, path)
    end

    root
  end

  defp copy_fixture_file!(root, path) do
    destination = Path.join(root, path)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(Path.join(@repo_root, path), destination)
  end

  defp gate_fixture_root! do
    root = fixture_root!()

    for path <- [
          "examples/accrue_host/docs/capability-limits-matrix.md",
          "examples/crosswake_tracer/physical-device-evidence.md",
          ".github/workflows/ci.yml"
        ] do
      copy_fixture_file!(root, path)
    end

    root
  end

  defp run_gate(root) do
    System.cmd(
      "bash",
      [Path.join(@repo_root, "scripts/ci/verify_reference_scenario_contract.sh")],
      env: [{"ROOT_DIR", root}, {"ACCRUE_DIR", Path.join(@repo_root, "accrue")}],
      stderr_to_stdout: true
    )
  end

  defp hd_action(scenario), do: hd(scenario.actions)
end
