defmodule AccruePortal.TapFormatter do
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
        Enum.map(Enum.with_index(tests, 1), fn {test, index} ->
          name = to_string(test.name)

          result =
            case test.state do
              nil -> "ok"
              :passed -> "ok"
              {:excluded, _reason} -> "ok"
              _ -> "not ok"
            end

          "#{result} #{index} - #{name}"
        end)

    if is_binary(report_path), do: File.write!(report_path, Enum.join(report, "\n") <> "\n")

    {:noreply, state}
  end

  def handle_cast(_event, tests), do: {:noreply, tests}
end
