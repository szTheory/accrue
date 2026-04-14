defmodule Accrue.ClockTest do
  use ExUnit.Case, async: false

  setup do
    prior = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :test)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    on_exit(fn ->
      if prior do
        Application.put_env(:accrue, :env, prior)
      else
        Application.delete_env(:accrue, :env)
      end
    end)

    :ok
  end

  test "utc_now/0 reads Accrue.Processor.Fake.now/0 in test env" do
    fake_now = Accrue.Processor.Fake.now()
    assert Accrue.Clock.utc_now() == fake_now
  end

  test "utc_now/0 advances when the Fake clock advances" do
    before = Accrue.Clock.utc_now()
    :ok = Accrue.Processor.Fake.advance(86_400)
    after_now = Accrue.Clock.utc_now()
    assert DateTime.compare(after_now, before) == :gt
    assert DateTime.diff(after_now, before, :second) == 86_400
  end

  test "utc_now/0 returns DateTime.utc_now/0 when env is not :test" do
    Application.put_env(:accrue, :env, :prod)
    real_before = DateTime.utc_now()
    now = Accrue.Clock.utc_now()
    real_after = DateTime.utc_now()
    assert DateTime.compare(now, real_before) in [:gt, :eq]
    assert DateTime.compare(now, real_after) in [:lt, :eq]
  end
end
