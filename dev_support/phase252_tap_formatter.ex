defmodule Accrue.Test.Phase252TapFormatter do
  use GenServer

  def init(_opts), do: {:ok, []}

  def handle_cast({:test_finished, test}, tests), do: {:noreply, [test | tests]}

  def handle_cast({:suite_finished, _times}, tests) do
    tests = Enum.reverse(tests)
    IO.puts("TAP version 13")

    tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, index} ->
      identity = "#{inspect(test.module)}::#{test.name}"
      name = String.replace(identity, ~r/[\r\n]+/u, " ")

      case test.state do
        nil ->
          IO.puts("ok #{index} - #{name}")

        {:skipped, _reason} ->
          IO.puts("ok #{index} - #{name} # SKIP")

        {:failed, _failures} ->
          IO.puts("not ok #{index} - #{name}")

        _ ->
          IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, tests), do: {:noreply, tests}
end
