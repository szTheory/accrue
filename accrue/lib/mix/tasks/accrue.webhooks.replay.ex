defmodule Mix.Tasks.Accrue.Webhooks.Replay do
  @shortdoc "Requeue dead-lettered webhook events"
  @moduledoc """
  Requeue dead-lettered webhook events from the command line.

  Thin wrapper over `Accrue.Webhooks.DLQ` so ops engineers can replay
  events without dropping into `iex -S mix`.

  ## Usage

      mix accrue.webhooks.replay <event_id>
      mix accrue.webhooks.replay --since 2026-04-01 --type invoice.payment_failed
      mix accrue.webhooks.replay --since 2026-04-01 --type invoice.payment_failed --dry-run
      mix accrue.webhooks.replay --all-dead --yes

  ## Flags

    * `--since DATE` — only events on/after the given ISO date (UTC midnight)
    * `--until DATE` — only events on/before the given ISO date (UTC midnight)
    * `--type EVENT_TYPE` — restrict by Stripe event type (e.g. `invoice.payment_failed`)
    * `--dry-run` — report row count without mutation
    * `--all-dead` — bulk replay; prompts for confirmation when count > 10 unless `--yes`
    * `--yes` — skip confirmation prompts (CI / non-interactive use)
    * `--force` — bypass `dlq_replay_max_rows` cap
  """

  use Mix.Task

  @switches [
    since: :string,
    until: :string,
    type: :string,
    dry_run: :boolean,
    all_dead: :boolean,
    yes: :boolean,
    force: :boolean
  ]

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, args, _invalid} = OptionParser.parse(argv, strict: @switches)

    case args do
      [event_id] ->
        single_replay(event_id)

      [] ->
        bulk_replay(opts)

      _ ->
        Mix.raise(
          "Usage: mix accrue.webhooks.replay [<event_id>] [--since DATE --type T --dry-run --all-dead --yes --force]"
        )
    end
  end

  defp single_replay(event_id) do
    case Accrue.Webhooks.DLQ.requeue(event_id) do
      {:ok, row} ->
        Mix.shell().info("Requeued #{row.id} (#{row.type})")

      {:error, reason} ->
        Mix.raise("Requeue failed: #{inspect(reason)}")
    end
  end

  defp bulk_replay(opts) do
    filter = build_filter(opts)

    replay_opts = [
      dry_run: opts[:dry_run] || false,
      force: opts[:force] || false
    ]

    confirm_if_nuclear!(opts, filter)

    case Accrue.Webhooks.DLQ.requeue_where(filter, replay_opts) do
      {:ok, %{requeued: n} = result} ->
        Mix.shell().info("Replay result: #{inspect(result)} (requeued=#{n})")

      {:error, :replay_too_large} ->
        Mix.raise("Replay exceeds dlq_replay_max_rows. Re-run with --force to override.")
    end
  end

  defp build_filter(opts) do
    []
    |> maybe_put(:since, opts[:since], &parse_date/1)
    |> maybe_put(:until, opts[:until], &parse_date/1)
    |> maybe_put(:type, opts[:type], & &1)
  end

  defp maybe_put(filter, _key, nil, _fun), do: filter
  defp maybe_put(filter, key, value, fun), do: Keyword.put(filter, key, fun.(value))

  defp parse_date(s) do
    case DateTime.from_iso8601(s <> "T00:00:00Z") do
      {:ok, dt, _} -> dt
      {:error, reason} -> Mix.raise("Invalid date #{inspect(s)}: #{inspect(reason)}")
    end
  end

  defp confirm_if_nuclear!(opts, filter) do
    if opts[:all_dead] == true and opts[:yes] != true do
      count = Accrue.Webhooks.DLQ.count(filter)

      if count > 10 do
        response =
          Mix.shell().prompt("This will requeue #{count} dead-lettered events. Continue? [y/N]")

        unless String.trim(response) in ["y", "Y", "yes", "YES"] do
          Mix.raise("Aborted by user.")
        end
      end
    end
  end
end
