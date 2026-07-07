defmodule Mix.Tasks.AccrueAdmin.Ui.RoundTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.AccrueAdmin.Ui.Round

  @foundation_csv "component-kitchen,dashboard,subscription-detail,subscriptions"
  @next_round_marker "test-results/ui-ratchet/.round-next"
  @round_status_marker "test-results/ui-ratchet/.round-status"
  @playwright_output_dir "test-results/playwright-ui-round"

  # A FakeRunner that never spawns node/npx/mix. `run/3` records each pipeline
  # call and returns success; `capture/3` recognizes the `load_slices!` node -e
  # SLICES read and returns canned JSON, so the JS-read resolution path is
  # exercised without a live subprocess, server, PNGs, or an API key.
  defmodule FakeRunner do
    @behaviour Round.Runner

    @impl true
    def run(command, args, opts) do
      send(self(), {:runner_call, command, args, opts[:env]})
      {:ok, 0}
    end

    @impl true
    def capture("node", args, _opts) do
      if Enum.any?(
           args,
           &(String.contains?(&1, "baseline-manifest.js") and String.contains?(&1, "SLICES"))
         ) do
        {:ok, 0,
         ~s({"foundation":["component-kitchen","dashboard","subscription-detail","subscriptions"]})}
      else
        {:ok, 0, "{}"}
      end
    end
  end

  setup do
    Mix.Task.reenable("accrue_admin.ui.round")

    prior = Application.get_env(:accrue_admin, :accrue_admin_ui_round_runner)
    Application.put_env(:accrue_admin, :accrue_admin_ui_round_runner, FakeRunner)

    root = File.cwd!()
    File.mkdir_p!(Path.join(root, "test-results/ui-ratchet"))

    on_exit(fn ->
      Mix.Task.reenable("accrue_admin.ui.round")

      File.rm_rf!(Path.join(root, @next_round_marker))
      File.rm_rf!(Path.join(root, @round_status_marker))

      if prior do
        Application.put_env(:accrue_admin, :accrue_admin_ui_round_runner, prior)
      else
        Application.delete_env(:accrue_admin, :accrue_admin_ui_round_runner)
      end
    end)

    {:ok, root: root}
  end

  # Pre-seeds the marker files the real pipeline would produce (FakeRunner does
  # not run the node scripts that write them).
  defp seed(root, round, status) do
    File.write!(Path.join(root, @next_round_marker), to_string(round))
    File.write!(Path.join(root, @round_status_marker), status)
  end

  # Pulls the oldest :runner_call in strict FIFO order.
  defp next_call do
    receive do
      {:runner_call, cmd, args, env} -> {cmd, args, env}
    after
      0 -> flunk("expected a :runner_call message but the mailbox was empty")
    end
  end

  test "sequences all 7 pipeline steps in the exact documented order", %{root: root} do
    seed(root, 4, "continue")

    capture_io(fn -> Round.run([]) end)

    assert {"node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--next-round"], _} = next_call()
    assert {"mix", ["accrue_admin.assets.build"], _} = next_call()
    assert {"npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], _} = next_call()
    assert {"node", ["e2e/ratchet/ratchet-propose.mjs"], _} = next_call()
    assert {"node", ["e2e/ratchet/ratchet-verify.mjs"], _} = next_call()
    assert {"node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--seal-round"], _} = next_call()
    assert {"node", ["e2e/ratchet/ratchet-digest.mjs"], _} = next_call()
  end

  test "unscoped run threads no RATCHET_SURFACES into any step", %{root: root} do
    seed(root, 4, "continue")

    capture_io(fn -> Round.run([]) end)

    for _ <- 1..7 do
      {_cmd, _args, env} = next_call()
      refute env && List.keymember?(env, "RATCHET_SURFACES", 0)
    end
  end

  test "--slice foundation resolves via the JS SLICES SSOT and threads RATCHET_SURFACES into capture/propose/seal-round only",
       %{root: root} do
    seed(root, 4, "continue")

    capture_io(fn -> Round.run(["--slice", "foundation"]) end)

    # next-round — no surfaces
    {"node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--next-round"], env} = next_call()
    refute env && List.keymember?(env, "RATCHET_SURFACES", 0)

    # assets.build — no surfaces
    {"mix", ["accrue_admin.assets.build"], env} = next_call()
    refute env && List.keymember?(env, "RATCHET_SURFACES", 0)

    # capture — surfaces present
    {"npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], env} = next_call()
    assert {"RATCHET_SURFACES", @foundation_csv} in env
    assert {"PLAYWRIGHT_OUTPUT_DIR", @playwright_output_dir} in env

    # propose — surfaces present
    {"node", ["e2e/ratchet/ratchet-propose.mjs"], env} = next_call()
    assert {"RATCHET_SURFACES", @foundation_csv} in env

    # verify — no surfaces
    {"node", ["e2e/ratchet/ratchet-verify.mjs"], env} = next_call()
    refute List.keymember?(env, "RATCHET_SURFACES", 0)

    # seal-round — surfaces present
    {"node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--seal-round"], env} = next_call()
    assert {"RATCHET_SURFACES", @foundation_csv} in env

    # digest — no surfaces
    {"node", ["e2e/ratchet/ratchet-digest.mjs"], env} = next_call()
    refute env && List.keymember?(env, "RATCHET_SURFACES", 0)
  end

  test "--surface list is threaded verbatim with no slice-map lookup", %{root: root} do
    seed(root, 4, "continue")

    capture_io(fn -> Round.run(["--surface", "dashboard,subscriptions"]) end)

    next_call()
    next_call()
    {"npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], env} = next_call()
    assert {"RATCHET_SURFACES", "dashboard,subscriptions"} in env
    assert {"PLAYWRIGHT_OUTPUT_DIR", @playwright_output_dir} in env
  end

  test "a pre-seeded .round-next of 3 drives RATCHET_ROUND=3 for propose/verify/seal-round", %{
    root: root
  } do
    seed(root, 3, "continue")

    capture_io(fn -> Round.run([]) end)

    # next-round, assets.build, capture
    next_call()
    next_call()
    next_call()

    {"node", ["e2e/ratchet/ratchet-propose.mjs"], env} = next_call()
    assert {"RATCHET_ROUND", "3"} in env

    {"node", ["e2e/ratchet/ratchet-verify.mjs"], env} = next_call()
    assert {"RATCHET_ROUND", "3"} in env

    {"node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--seal-round"], env} = next_call()
    assert {"RATCHET_ROUND", "3"} in env
  end

  test "cap-reached runs the digest step THEN raises Mix.Error", %{root: root} do
    seed(root, 6, "cap-reached")

    assert_raise Mix.Error, fn ->
      capture_io(fn -> Round.run([]) end)
    end

    # The digest runner_call must have fired before the raise.
    assert_received {:runner_call, "node", ["e2e/ratchet/ratchet-digest.mjs"], _}
  end

  test "continue status completes without raising", %{root: root} do
    seed(root, 2, "continue")

    assert capture_io(fn -> Round.run([]) end) =~ "Round 2 complete"
  end

  test "converged status completes without raising", %{root: root} do
    seed(root, 2, "converged")

    assert capture_io(fn -> Round.run([]) end) =~ "status=converged"
  end

  test "--slice and --surface together raise before any pipeline subprocess", %{root: root} do
    seed(root, 4, "continue")

    assert_raise Mix.Error, ~r/mutually exclusive/, fn ->
      Round.run(["--slice", "foundation", "--surface", "dashboard"])
    end

    refute_received {:runner_call, _cmd, _args, _env}
  end

  test "an unknown --slice raises naming the JS-loaded known slice keys before any pipeline step",
       %{root: root} do
    seed(root, 4, "continue")

    assert_raise Mix.Error, ~r/foundation/, fn ->
      Round.run(["--slice", "not-a-real-slice"])
    end

    refute_received {:runner_call, _cmd, _args, _env}
  end
end
