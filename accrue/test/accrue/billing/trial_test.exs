defmodule Accrue.Billing.TrialTest do
  @moduledoc """
  D3-38: `trial_end` normalizer that rejects the "pass a unix int" footgun
  and accepts `:now | %DateTime{} | {:days, N} | %Duration{}`.
  """
  use ExUnit.Case, async: false

  alias Accrue.Billing.Trial

  setup do
    # Make sure Clock reads Fake (the Trial normalizer calls Clock.utc_now/0)
    prior_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :test)

    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    on_exit(fn ->
      if prior_env do
        Application.put_env(:accrue, :env, prior_env)
      else
        Application.delete_env(:accrue, :env)
      end
    end)

    :ok
  end

  test ":now → \"now\" string" do
    assert Trial.normalize_trial_end(:now) == "now"
  end

  test "DateTime → unix int" do
    dt = ~U[2026-05-01 00:00:00.000000Z]
    assert Trial.normalize_trial_end(dt) == DateTime.to_unix(dt)
  end

  test "{:days, 14} uses Accrue.Clock (test clock)" do
    now = Accrue.Clock.utc_now()
    expected = DateTime.to_unix(DateTime.add(now, 14 * 86_400, :second))
    assert Trial.normalize_trial_end({:days, 14}) == expected
  end

  test "integer raises" do
    assert_raise ArgumentError, ~r/unix ints rejected/, fn ->
      Trial.normalize_trial_end(1_800_000_000)
    end
  end

  test ":trial_period_days raises" do
    assert_raise ArgumentError, ~r/use \{:days, N\}/, fn ->
      Trial.normalize_trial_end(:trial_period_days)
    end
  end
end
