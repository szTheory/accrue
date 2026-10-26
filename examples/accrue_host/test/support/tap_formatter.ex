defmodule AccrueHost.TapFormatter do
  @moduledoc false
  use GenServer

  @impl GenServer
  def init(_opts), do: {:ok, %{tests: [], report_path: System.get_env("GSD_TAP_REPORT")}}

  @impl GenServer
  def handle_cast({:test_finished, test}, state),
    do: {:noreply, %{state | tests: [test | state.tests]}}

  def handle_cast({:suite_finished, _times}, %{tests: tests, report_path: report_path} = state) do
    tests = Enum.reverse(tests)

    report =
      ["TAP version 13", "1..#{length(tests)}"] ++
        Enum.flat_map(Enum.with_index(tests, 1), fn {test, index} ->
          result =
            if test.state in [nil, :passed] or match?({:excluded, _}, test.state),
              do: "ok",
              else: "not ok"

          assertion = ["#{result} #{index} - #{test.name}"]

          case test.state do
            {:failed, failures} -> assertion ++ failure_diagnostics(failures)
            _ -> assertion
          end
        end)

    if is_binary(report_path), do: File.write!(report_path, Enum.join(report, "\n") <> "\n")

    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp failure_diagnostics(failures) do
    Enum.flat_map(failures, fn
      {kind, reason, stack} ->
        Exception.format_banner(kind, reason, stack)
        |> String.split("\n")
        |> Enum.map(&("# " <> &1))

      other ->
        ["# failure detail: #{inspect(other)}"]
    end)
  end
end
