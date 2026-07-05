defmodule Mix.Tasks.AccrueAdmin.Ui.Fix do
  @shortdoc "Apply the round's batch decisions, rebuild+commit CSS, probe, and finalize guard-mints"
  @moduledoc """
  The ORCH-03/ORCH-04 MUTATION half of the UI-ratchet loop.

  `ui.fix` is the maintainer's second and final formal interaction per round (after
  they batch-approve/reject the digest's `decisions.json`). It NEVER generates a CSS
  fix itself — the maintainer (or their coding assistant) has ALREADY hand-edited the
  CSS/component files between `ui.round` and `ui.fix`, guided by the digest. This task
  automates "rebuild it, prove it, lock it in":

      apply-decisions -> assets.build -> git add priv/static -> git commit
        -> recapture -> probe -> finalize-fixes

  This task is a thin orchestrator: it reimplements zero ratchet logic, it only
  sequences `System.cmd` calls through a swappable `Runner` behaviour (twinning
  `mix accrue_admin.ui.round`'s `Runner`/`ShellRunner` idiom). It:

    * commits ONLY `priv/static` right after `assets.build`, BEFORE re-capture — the
      committed-CSS-bundle discipline (a `--allow-empty` commit keeps the sequence
      total even when the maintainer's hand-edit produced no net bundle change).
    * reads the round + scope from the `.fix-context.json` that `ratchet-fix.mjs
      --apply-decisions` wrote — it never re-derives either itself.
    * runs NO evaluator fan-out. There is no propose/verify step; the "did the fix
      stick?" decision is made ONLY by the scoped `ratchet-fix-probe.spec.js`, so
      `ui.fix` can create ZERO net-new `open` rows (D-50).

  ## Examples

      # Apply the latest sealed round's decisions and finalize
      mix accrue_admin.ui.fix

      # Preview only — runs apply-decisions --dry-run and stops (no build/commit/probe)
      mix accrue_admin.ui.fix --dry-run

      # Target an explicit round
      mix accrue_admin.ui.fix --round 5
  """

  use Mix.Task

  @runner_env_key :accrue_admin_ui_fix_runner
  @fix_context_marker "test-results/ui-ratchet/.fix-context.json"

  defmodule Runner do
    @moduledoc false
    @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
  end

  defmodule ShellRunner do
    @moduledoc false
    @behaviour Runner

    @impl true
    def run(command, args, opts) do
      {_, status} =
        System.cmd(command, args,
          cd: Keyword.fetch!(opts, :cd),
          env: Keyword.get(opts, :env, []),
          stderr_to_stdout: true,
          into: IO.stream(:stdio, :line)
        )

      {:ok, status}
    rescue
      error -> {:error, error}
    end
  end

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("loadpaths")

    root = File.cwd!()
    runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)

    {opts, _rest, _invalid} =
      OptionParser.parse(argv, strict: [round: :integer, dry_run: :boolean], aliases: [])

    round_args = if opts[:round], do: ["--round", Integer.to_string(opts[:round])], else: []
    dry_run_args = if opts[:dry_run], do: ["--dry-run"], else: []

    # Step 1 — validated batch apply. Always runs (dry-run included).
    run_step!(
      runner,
      "apply-decisions",
      "node",
      ["e2e/ratchet/ratchet-fix.mjs", "--apply-decisions"] ++ round_args ++ dry_run_args,
      cd: root
    )

    if opts[:dry_run] do
      Mix.shell().info("Dry run complete — no files mutated.")
      :ok
    else
      %{"round" => round, "scope" => scope} =
        root
        |> Path.join(@fix_context_marker)
        |> File.read!()
        |> Jason.decode!()

      surfaces_env = if scope in [nil, "all"], do: [], else: [{"RATCHET_SURFACES", scope}]

      # Step 2 — rebuild the committed CSS/JS bundle from the maintainer's hand-edited source.
      run_step!(runner, "assets.build", "mix", ["accrue_admin.assets.build"], cd: root)

      # Steps 3-4 — commit ONLY priv/static, BEFORE re-capture (committed-CSS-bundle discipline).
      run_step!(runner, "git-add", "git", ["add", "priv/static"], cd: root)

      run_step!(
        runner,
        "git-commit",
        "git",
        ["commit", "-m", "chore(ui-ratchet): rebuild CSS bundle for round #{round}", "--allow-empty"],
        cd: root
      )

      # Step 5 — re-capture the (scoped) surfaces against the freshly-committed bundle.
      run_step!(runner, "recapture", "npx", ["playwright", "test", "e2e/admin-visuals.spec.js"],
        cd: root,
        env: surfaces_env
      )

      # Step 6 — scoped per-resolved-finding probe (NOT an evaluator fan-out; zero net-new opens).
      run_step!(runner, "probe", "npx", ["playwright", "test", "e2e/ratchet-fix-probe.spec.js"],
        cd: root
      )

      # Step 7 — mint guards + promote probe-confirmed fixes to verified-closed.
      run_step!(runner, "finalize-fixes", "node", ["e2e/ratchet/ratchet-fix.mjs", "--finalize-fixes"],
        cd: root
      )

      Mix.shell().info(
        "ui.fix complete for round #{round}. " <>
          "Findings the probe confirmed fixed now carry a minted guard."
      )

      :ok
    end
  end

  defp run_step!(runner, label, command, args, opts) do
    case runner.run(command, args, opts) do
      {:ok, 0} ->
        :ok

      {:ok, status} ->
        Mix.raise("#{label} step failed with exit status #{status}")

      {:error, reason} ->
        Mix.raise("#{label} step failed: #{Exception.message(reason)}")
    end
  end
end
