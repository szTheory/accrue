defmodule Accrue.Test.ClockTest do
  use ExUnit.Case, async: false

  setup do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()
    :ok
  end

  test "advance_clock/2 accepts readable month and day durations" do
    start = Accrue.Processor.Fake.now()

    assert {:ok, _effects} =
             Accrue.Test.Clock.advance_clock("1 month", processor: Accrue.Processor.Fake)

    assert DateTime.diff(Accrue.Processor.Fake.now(), start, :day) in 28..31

    assert {:ok, _effects} =
             Accrue.Test.Clock.advance_clock("30 days", processor: Accrue.Processor.Fake)

    assert DateTime.compare(Accrue.Processor.Fake.now(), start) == :gt
  end

  test "advance_clock/2 accepts precise keyword durations" do
    start = Accrue.Processor.Fake.now()

    assert {:ok, _effects} =
             Accrue.Test.Clock.advance_clock([months: 1], processor: Accrue.Processor.Fake)

    assert DateTime.compare(Accrue.Processor.Fake.now(), start) == :gt

    assert {:ok, _effects} =
             Accrue.Test.Clock.advance_clock([seconds: 86_400], processor: Accrue.Processor.Fake)
  end

  test "implementation drives Fake clock and never sleeps" do
    clock_source = File.read!("lib/accrue/test/clock.ex")

    assert clock_source =~ "Accrue.Processor.Fake"
    refute clock_source =~ "Process.sleep"
  end
end
