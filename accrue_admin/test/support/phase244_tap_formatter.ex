defmodule AccrueAdmin.Test.Phase244TAPFormatter do
  use GenServer

  def init(_opts) do
    IO.puts("TAP version 13")
    {:ok, %{index: 0}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, state) do
    index = state.index + 1
    name = test.name |> to_string() |> String.replace("#", "")

    case test.state do
      nil -> IO.puts("ok #{index} - #{name}")
      {:failed, failures} ->
        IO.puts("not ok #{index} - #{name}")
        IO.puts("# error: #{inspect(failures, limit: :infinity, printable_limit: :infinity)}")
      {:skipped, reason} -> IO.puts("ok #{index} - #{name} # SKIP #{reason}")
      other -> IO.puts("not ok #{index} - #{name} # #{inspect(other)}")
    end

    {:noreply, %{state | index: index}}
  end

  def handle_cast({:suite_finished, _times}, state) do
    IO.puts("1..#{state.index}")
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}
end
