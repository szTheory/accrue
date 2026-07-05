defmodule Mix.Tasks.AccrueAdmin.Ui.Round do
  @shortdoc "Run one full UI-ratchet round (capture -> propose -> verify -> seal -> digest)"
  @moduledoc """
  The ORCH-01 one-command measurement pipeline.

  Sequences the entire "run a round" interaction in the exact order:

      next-round -> assets.build -> capture -> propose -> verify -> seal-round -> digest

  This task is a thin orchestrator: it reimplements zero ratchet logic, it only
  sequences `System.cmd` calls through a swappable `Runner` behaviour (twinning
  `mix accrue_admin.assets.build`'s `Runner`/`ShellRunner` idiom). It:

    * reads the round number and final convergence status from the two marker
      files `phase-ratchet-ledger.mjs` writes (`.round-next` / `.round-status`) —
      it never re-derives the round number or the convergence status itself.
    * resolves `--slice NAME` by reading `e2e/baseline-manifest.js`'s `SLICES`
      map DIRECTLY (via a captured `node -e` call) — the surface names live only
      in that JS single-source-of-truth, never as a hardcoded Elixir copy.
    * ALWAYS renders the digest before deciding whether to raise, so a maintainer
      gets a rendered digest even on the 6-round cap-reached escalation.

  ## Examples

      # Full configured surface set (unscoped)
      mix accrue_admin.ui.round

      # A named slice (surfaces read from baseline-manifest.js's SLICES)
      mix accrue_admin.ui.round --slice foundation

      # An explicit surface list (no slice-map lookup)
      mix accrue_admin.ui.round --surface dashboard,subscriptions

  `--slice` and `--surface` are mutually exclusive.
  """

  use Mix.Task

  @runner_env_key :accrue_admin_ui_round_runner
  @default_slice "foundation"

  @next_round_marker "test-results/ui-ratchet/.round-next"
  @round_status_marker "test-results/ui-ratchet/.round-status"

  defmodule Runner do
    @moduledoc false
    # `run/3` streams stdout/stderr and returns only the exit status (the 7
    # pipeline steps). `capture/3` returns captured stdout — used solely for the
    # `load_slices!` `node -e` SLICES read.
    @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
    @callback capture(String.t(), [String.t()], keyword()) ::
                {:ok, integer(), String.t()} | {:error, term()}
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

    @impl true
    def capture(command, args, opts) do
      {output, status} =
        System.cmd(command, args,
          cd: Keyword.fetch!(opts, :cd),
          env: Keyword.get(opts, :env, [])
        )

      {:ok, status, output}
    rescue
      error -> {:error, error}
    end
  end

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("loadpaths")

    root = File.cwd!()
    runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)

    # Resolve --slice/--surface into the shared RATCHET_SURFACES env BEFORE any
    # pipeline subprocess runs — a mutual-exclusivity or unknown-slice error must
    # abort before the first pipeline step (D-52).
    surfaces_env = resolve_surfaces_env!(argv, root, runner)

    run_step!(runner, "next-round", "node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--next-round"],
      cd: root
    )

    round =
      root
      |> Path.join(@next_round_marker)
      |> File.read!()
      |> String.trim()
      |> String.to_integer()

    round_str = Integer.to_string(round)

    run_step!(runner, "assets.build", "mix", ["accrue_admin.assets.build"], cd: root)

    run_step!(runner, "capture", "npx", ["playwright", "test", "e2e/admin-visuals.spec.js"],
      cd: root,
      env: surfaces_env
    )

    run_step!(runner, "propose", "node", ["e2e/ratchet/ratchet-propose.mjs"],
      cd: root,
      env: [{"RATCHET_ROUND", round_str} | surfaces_env]
    )

    run_step!(runner, "verify", "node", ["e2e/ratchet/ratchet-verify.mjs"],
      cd: root,
      env: [{"RATCHET_ROUND", round_str}]
    )

    run_step!(runner, "seal-round", "node", ["e2e/ratchet/phase-ratchet-ledger.mjs", "--seal-round"],
      cd: root,
      env: [{"RATCHET_ROUND", round_str} | surfaces_env]
    )

    # ALWAYS runs, unconditionally, before the status marker is consulted.
    run_step!(runner, "digest", "node", ["e2e/ratchet/ratchet-digest.mjs"], cd: root)

    status =
      root
      |> Path.join(@round_status_marker)
      |> File.read!()
      |> String.trim()

    Mix.shell().info(
      "Round #{round} complete — status=#{status}. " <>
        "Open test-results/ui-ratchet/round-#{String.pad_leading(round_str, 2, "0")}/digest.html"
    )

    case status do
      "cap-reached" ->
        Mix.raise(
          "UI ratchet round #{round}: 6-round cap reached without convergence — " <>
            "see the digest for the next action."
        )

      _ ->
        :ok
    end
  end

  # Returns [] when unscoped, or [{"RATCHET_SURFACES", csv}] otherwise. Raises on
  # mutual exclusivity or an unknown slice name before any pipeline step.
  defp resolve_surfaces_env!(argv, root, runner) do
    {opts, _rest, _invalid} =
      OptionParser.parse(argv, strict: [slice: :string, surface: :string], aliases: [])

    surface = Keyword.get(opts, :surface)

    slice =
      case Keyword.get(opts, :slice) do
        # Bare `--slice` (no value) is parse-invalid under strict :string, but the
        # flag is still present in argv — default it to "foundation".
        nil -> if "--slice" in argv, do: @default_slice, else: nil
        "" -> @default_slice
        value -> value
      end

    cond do
      slice != nil and surface != nil ->
        Mix.raise("--slice and --surface are mutually exclusive; pass at most one.")

      surface != nil ->
        [{"RATCHET_SURFACES", surface}]

      slice != nil ->
        slices = load_slices!(root, runner)

        case Map.fetch(slices, slice) do
          {:ok, list} ->
            [{"RATCHET_SURFACES", Enum.join(list, ",")}]

          :error ->
            known = slices |> Map.keys() |> Enum.sort() |> Enum.join(", ")
            Mix.raise("Unknown --slice #{inspect(slice)}. Known slices: #{known}")
        end

      true ->
        []
    end
  end

  # Reads baseline-manifest.js's SLICES map DIRECTLY (the single source of truth)
  # via a captured `node -e` call — no hand-mirrored Elixir copy of the slice
  # contents, so there is no duplicated closed-constant to drift.
  defp load_slices!(root, runner) do
    args = ["-e", "console.log(JSON.stringify(require('./e2e/baseline-manifest.js').SLICES))"]

    case runner.capture("node", args, cd: root) do
      {:ok, 0, output} ->
        Jason.decode!(output)

      {:ok, status, _output} ->
        Mix.raise("slice manifest load failed with exit status #{status}")

      {:error, reason} ->
        Mix.raise("slice manifest load failed: #{Exception.message(reason)}")
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
