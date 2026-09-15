defmodule Accrue.Env do
  @moduledoc false

  # Internal seam. This is the ONLY module in `accrue/lib` that may reference
  # the build-tool module directly.
  #
  # Why this exists: `Application.get_env(:accrue, :env, Mix.env())` looks
  # safe, but it is not — Elixir evaluates function-call arguments before the
  # call itself, so `Mix.env()` runs unconditionally even when `:env` IS
  # configured. In an OTP release the build-tool application is not present
  # at all, so that eager evaluation raises `UndefinedFunctionError` and
  # crashes the node before the supervision tree starts. `current/0` avoids
  # this by only calling `mix_env/0` when `:env` is actually unset, and
  # `mix_env/0` itself never raises — it rescues to `:prod` (fail-closed) so
  # the prod refuse-to-boot guard still trips correctly with no build tool
  # present.

  @doc false
  @spec mix_env() :: atom()
  def mix_env do
    # <!-- planner-discipline-allow: Mix.env -->
    try do
      Mix.env()
    rescue
      _ -> :prod
    end
  end

  @doc false
  @spec current() :: atom()
  def current do
    case Application.fetch_env(:accrue, :env) do
      {:ok, env} -> env
      :error -> mix_env()
    end
  end
end
