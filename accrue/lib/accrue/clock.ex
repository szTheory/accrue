defmodule Accrue.Clock do
  @moduledoc """
  Canonical time source for Accrue.

  All code inside Accrue that needs "now" calls `Accrue.Clock.utc_now/0`
  instead of `DateTime.utc_now/0`. In the test environment (`:accrue, :env`
  set to `:test`) this delegates to `Accrue.Processor.Fake.now/0`, which is
  backed by the Fake processor's in-memory test clock. In any other
  environment it delegates to the BEAM's `DateTime.utc_now/0`.

  This indirection is the mechanism that makes time-sensitive billing logic
  testable without sleeping or monkeypatching. Trial expiry, dunning grace
  windows, and expiring-card notices can all be exercised deterministically
  by advancing `Accrue.Test.Clock` in your tests rather than waiting for
  wall-clock time to pass.

  ## Why application env, not compile env

  The `:env` flag is read at runtime via `Application.get_env/3` so host
  apps can flip it in tests without recompiling Accrue. Production never
  reaches the Fake branch because the default is `:prod` and host apps
  never set `:accrue, :env` to anything but `:test`.
  """

  @spec utc_now() :: DateTime.t()
  def utc_now do
    case Application.get_env(:accrue, :env, :prod) do
      :test -> Accrue.Processor.Fake.now()
      _ -> DateTime.utc_now()
    end
  end
end
