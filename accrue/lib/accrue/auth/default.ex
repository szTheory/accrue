defmodule Accrue.Auth.Default do
  @moduledoc """
  Dev-permissive, prod-refuse-to-boot default `Accrue.Auth` adapter (D-40).

  ## Environment behaviour

  - **`:dev` / `:test`** — `current_user/1` returns a stubbed
    `%{id: "dev", email: "dev@localhost", role: :admin}`. `boot_check!/0`
    is a no-op. The `require_admin_plug/0` function is a pass-through.
    This is deliberately wide-open so getting started is frictionless.
  - **`:prod`** — `boot_check!/0` raises `Accrue.ConfigError` with a
    message pointing at install docs, **as long as `:auth_adapter` is
    still pointing at this module** (the default). Plan 06's
    `Accrue.Application.start/2` calls `boot_check!/0` BEFORE any
    supervisor starts, so a production deploy with no auth fails loud.

  A host that configures a real adapter (`config :accrue, :auth_adapter,
  MyApp.Auth`) bypasses the refusal entirely because `boot_check!/0`
  checks the currently-configured adapter before raising.

  ## Test seam: `do_boot_check!/1`

  `boot_check!/0` is the public API — it reads the env via
  `Application.get_env(:accrue, :env, Mix.env())` and delegates to a
  private/testable `do_boot_check!/1` helper. The helper is exposed
  (`def`, not `defp`, with `@doc false`) so tests can simulate the
  `:prod` branch without tampering with `Application.put_env(:accrue,
  :env, :prod)` (which bleeds between async tests and has been a source
  of Heisenbugs historically).
  """

  @behaviour Accrue.Auth

  @dev_user %{id: "dev", email: "dev@localhost", role: :admin}

  @doc """
  Public API — validates that this dev-permissive adapter is not the
  active auth adapter in `:prod`. Plan 06's `Accrue.Application.start/2`
  calls this before the supervision tree boots.

  Returns `:ok` in `:dev` / `:test`, or in `:prod` when a non-default
  adapter is configured. Raises `Accrue.ConfigError` in `:prod` when
  `:auth_adapter` still points at this module.
  """
  @spec boot_check!() :: :ok
  def boot_check! do
    env = Application.get_env(:accrue, :env, Mix.env())
    do_boot_check!(env)
  end

  @doc false
  @spec do_boot_check!(:dev | :test | :prod | atom()) :: :ok
  def do_boot_check!(:prod) do
    if Application.get_env(:accrue, :auth_adapter, __MODULE__) == __MODULE__ do
      diagnostic =
        Accrue.SetupDiagnostic.auth_adapter(
          details: "configured auth adapter: #{inspect(__MODULE__)}"
        )

      raise Accrue.ConfigError,
        key: :auth_adapter,
        diagnostic: diagnostic
    end

    :ok
  end

  def do_boot_check!(env) when env in [:dev, :test], do: :ok
  # Any other atom (e.g., host-defined :staging) is treated as non-prod
  # by this default adapter — hosts that want stricter behaviour should
  # supply their own adapter.
  def do_boot_check!(_other), do: :ok

  @impl Accrue.Auth
  def current_user(_conn) do
    case Application.get_env(:accrue, :env, Mix.env()) do
      env when env in [:dev, :test] -> @dev_user
      :prod -> nil
      _ -> @dev_user
    end
  end

  @impl Accrue.Auth
  def require_admin_plug do
    case Application.get_env(:accrue, :env, Mix.env()) do
      env when env in [:dev, :test] ->
        fn conn, _opts -> conn end

      _ ->
        diagnostic =
          Accrue.SetupDiagnostic.auth_adapter(
            details: "require_admin_plug/0 called with #{inspect(__MODULE__)} outside dev/test"
          )

        fn _conn, _opts ->
          raise Accrue.ConfigError, key: :auth_adapter, diagnostic: diagnostic
        end
    end
  end

  @impl Accrue.Auth
  def user_schema, do: nil

  @impl Accrue.Auth
  def log_audit(_user, _event), do: :ok

  @impl Accrue.Auth
  def actor_id(user) when is_map(user) do
    Map.get(user, :id) || Map.get(user, "id")
  end

  def actor_id(_), do: nil

  @impl Accrue.Auth
  def step_up_challenge(_user, _action) do
    case Application.get_env(:accrue, :env, Mix.env()) do
      env when env in [:dev, :test] ->
        %{kind: :auto, provider: :default, message: "Auto-approved in #{env}"}

      _ ->
        raise Accrue.Auth.StepUpUnconfigured,
          message:
            "Accrue.Auth.Default step-up is dev/test only; configure a real :auth_adapter for production admin actions."
    end
  end

  @impl Accrue.Auth
  def verify_step_up(_user, _params, _action) do
    case Application.get_env(:accrue, :env, Mix.env()) do
      env when env in [:dev, :test] -> :ok
      _ -> {:error, :step_up_not_configured}
    end
  end
end
