defmodule Mix.Tasks.AccrueAdmin.Ui.FixTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.AccrueAdmin.Ui.Fix

  @fix_context_marker "test-results/ui-ratchet/.fix-context.json"

  # A FakeRunner that never spawns node/npx/mix/git. Every step records its command,
  # args, and env, then returns success — so the full sequence is exercised without a
  # live subprocess, server, PNGs, git history mutation, or an API key.
  defmodule FakeRunner do
    @behaviour Fix.Runner

    @impl true
    def run(command, args, opts) do
      send(self(), {:runner_call, command, args, opts[:env]})
      {:ok, 0}
    end
  end

  setup do
    Mix.Task.reenable("accrue_admin.ui.fix")

    prior = Application.get_env(:accrue_admin, :accrue_admin_ui_fix_runner)
    Application.put_env(:accrue_admin, :accrue_admin_ui_fix_runner, FakeRunner)

    root = File.cwd!()
    File.mkdir_p!(Path.join(root, "test-results/ui-ratchet"))

    on_exit(fn ->
      Mix.Task.reenable("accrue_admin.ui.fix")
      File.rm_rf!(Path.join(root, @fix_context_marker))

      if prior do
        Application.put_env(:accrue_admin, :accrue_admin_ui_fix_runner, prior)
      else
        Application.delete_env(:accrue_admin, :accrue_admin_ui_fix_runner)
      end
    end)

    {:ok, root: root}
  end

  # Pre-seeds the .fix-context.json marker that ratchet-fix.mjs --apply-decisions would
  # write (the FakeRunner does not run the node script that emits it).
  defp seed_fix_context(root, round, scope) do
    File.write!(
      Path.join(root, @fix_context_marker),
      Jason.encode!(%{"round" => round, "scope" => scope})
    )
  end

  defp next_call do
    receive do
      {:runner_call, cmd, args, env} -> {cmd, args, env}
    after
      0 -> flunk("expected a :runner_call message but the mailbox was empty")
    end
  end

  test "sequences apply-decisions -> assets.build -> git-add -> git-commit -> recapture -> probe -> finalize-fixes in order",
       %{root: root} do
    seed_fix_context(root, 3, "dashboard,subscriptions")

    capture_io(fn -> Fix.run([]) end)

    assert {"node", ["e2e/ratchet/ratchet-fix.mjs", "--apply-decisions"], _} = next_call()
    assert {"mix", ["accrue_admin.assets.build"], _} = next_call()
    assert {"git", ["add", "priv/static"], _} = next_call()

    {"git", commit_args, _} = next_call()
    assert ["commit", "-m", msg, "--allow-empty", "--", "priv/static"] = commit_args
    assert msg =~ "round 3"

    {"npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], recapture_env} = next_call()
    assert {"RATCHET_SURFACES", "dashboard,subscriptions"} in recapture_env

    assert {"npx", ["playwright", "test", "e2e/ratchet-fix-probe.spec.js"], _} = next_call()
    assert {"node", ["e2e/ratchet/ratchet-fix.mjs", "--finalize-fixes"], _} = next_call()
  end

  test "NO step ever invokes the evaluator fan-out (ratchet-propose / ratchet-verify) — D-50", %{
    root: root
  } do
    seed_fix_context(root, 3, "dashboard,subscriptions")

    capture_io(fn -> Fix.run([]) end)

    for _ <- 1..7 do
      {_cmd, args, _env} = next_call()

      refute Enum.any?(args, &String.contains?(&1, "ratchet-propose")),
             "no ui.fix step may invoke ratchet-propose.mjs (D-50)"

      refute Enum.any?(args, &String.contains?(&1, "ratchet-verify")),
             "no ui.fix step may invoke ratchet-verify.mjs (D-50)"
    end
  end

  test "the git commit step stages exactly priv/static and never a ledger/spec path", %{
    root: root
  } do
    seed_fix_context(root, 3, "dashboard,subscriptions")

    capture_io(fn -> Fix.run([]) end)

    next_call()
    next_call()
    {"git", add_args, _} = next_call()
    assert add_args == ["add", "priv/static"]
    refute Enum.any?(add_args, &String.contains?(&1, "e2e/ratchet"))
    refute Enum.any?(add_args, &String.contains?(&1, "ledger"))

    {"git", commit_args, _} = next_call()
    assert ["commit", "-m", msg, "--allow-empty", "--", "priv/static"] = commit_args
    assert msg =~ "round 3"
    refute Enum.any?(commit_args, &String.contains?(&1, "e2e/ratchet"))
    refute Enum.any?(commit_args, &String.contains?(&1, "ledger"))
  end

  test "--dry-run runs ONLY apply-decisions --dry-run and no other step", %{root: _root} do
    # No .fix-context.json seeded on purpose: --dry-run must never read it.
    output = capture_io(fn -> Fix.run(["--dry-run"]) end)

    assert {"node", ["e2e/ratchet/ratchet-fix.mjs", "--apply-decisions", "--dry-run"], _} =
             next_call()

    refute_received {:runner_call, _cmd, _args, _env}
    assert output =~ "Dry run complete"
  end

  test "--round 5 threads --round 5 into the apply-decisions step", %{root: root} do
    seed_fix_context(root, 5, "all")

    capture_io(fn -> Fix.run(["--round", "5"]) end)

    assert {"node", ["e2e/ratchet/ratchet-fix.mjs", "--apply-decisions", "--round", "5"], _} =
             next_call()
  end

  test "an unscoped (scope=all) round threads NO RATCHET_SURFACES into recapture", %{root: root} do
    seed_fix_context(root, 2, "all")

    capture_io(fn -> Fix.run([]) end)

    # apply-decisions, assets.build, git-add, git-commit
    next_call()
    next_call()
    next_call()
    next_call()

    {"npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], recapture_env} = next_call()
    refute recapture_env && List.keymember?(recapture_env, "RATCHET_SURFACES", 0)
  end
end
