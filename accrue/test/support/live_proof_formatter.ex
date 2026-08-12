defmodule Accrue.Test.LiveProofFormatter do
  @moduledoc false

  use GenServer

  @manifest_schema_version 1

  # ExUnit invokes formatter modules as GenServer-style callbacks. The state
  # intentionally contains only aggregate counters and timestamps: test data,
  # exception text, environment values, and provider responses never cross the
  # live-suite boundary into a durable record.
  def init(options) do
    path = Keyword.get(options, :path, System.get_env("ACCRUE_PROVIDER_MANIFEST"))
    now = Keyword.get(options, :now, &DateTime.utc_now/0)

    state = %{
      path: path,
      now: now,
      started_at: now.(),
      selected_count: 0,
      passed_count: 0,
      skipped_count: 0,
      failed_count: 0
    }

    {:ok, state}
  end

  def handle_cast({:suite_started, _options}, state), do: {:noreply, state}

  def handle_cast({:test_finished, %{state: test_state}}, state) do
    {:noreply, increment(state, test_state)}
  end

  def handle_cast({:suite_finished, _times}, %{path: path} = state) when is_binary(path) and path != "" do
    write_manifest!(path, manifest(state, state.now.()))
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _times}, state), do: {:noreply, state}
  def handle_cast(_event, state), do: {:noreply, state}

  defp increment(state, nil), do: %{state | selected_count: state.selected_count + 1, passed_count: state.passed_count + 1}

  defp increment(state, {:skipped, _reason}),
    do: %{state | selected_count: state.selected_count + 1, skipped_count: state.skipped_count + 1}

  defp increment(state, {:excluded, _reason}), do: state

  defp increment(state, _failure),
    do: %{state | selected_count: state.selected_count + 1, failed_count: state.failed_count + 1}

  defp manifest(state, finished_at) do
    %{
      schema_version: @manifest_schema_version,
      selected_count: state.selected_count,
      passed_count: state.passed_count,
      skipped_count: state.skipped_count,
      failed_count: state.failed_count,
      started_at: iso8601_milliseconds(state.started_at),
      finished_at: iso8601_milliseconds(finished_at)
    }
  end

  defp iso8601_milliseconds(datetime), do: datetime |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()

  defp write_manifest!(path, manifest) do
    directory = Path.dirname(path)
    File.mkdir_p!(directory)
    temporary = "#{path}.tmp-#{System.unique_integer([:positive])}"

    try do
      File.write!(temporary, Jason.encode!(manifest))
      File.rename!(temporary, path)
    after
      File.rm(temporary)
    end
  end
end
