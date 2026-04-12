defmodule Accrue.Mailer.Default do
  @moduledoc """
  Default `Accrue.Mailer` adapter — enqueues an Oban job on the
  `:accrue_mailers` queue that a worker later turns into a delivered email.

  ## Pay-style override ladder (D-23)

  This adapter documents the Pay-inspired four-rung override ladder but
  Phase 1 implements only rungs 1 and 3. The full catalog lands in Phase 6.

  1. **Kill switch** (`:emails` config) — `Accrue.Mailer.deliver/2`
     short-circuits before this adapter is reached. Handled at the
     behaviour layer.
  2. MFA conditional (`:emails` value is `{Mod, :fun, args}`) — Phase 6.
  3. **Template module override** (`:email_overrides` config) — resolved
     in `Accrue.Workers.Mailer.resolve_template/1`.
  4. Full pipeline replace (`:mailer` config pointing at a custom
     module) — already supported via `Accrue.Mailer.impl/0`.

  ## Oban args safety (D-27, Pitfall #5, T-MAIL-01)

  Oban persists job `args` as JSONB. The `assigns` map MUST contain only
  scalars (no structs, pids, functions, refs) so a worker crash mid-job
  doesn't corrupt the queue and so sensitive structs don't leak into the
  `oban_jobs` table. `only_scalars!/1` walks the map and raises
  `ArgumentError` on any non-primitive value. The convention is:
  **pass entity IDs, not entity structs**. The worker rehydrates at
  delivery time.
  """

  @behaviour Accrue.Mailer

  @impl true
  def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
    scalar_assigns = only_scalars!(assigns)

    %{type: Atom.to_string(type), assigns: stringify_keys(scalar_assigns)}
    |> Accrue.Workers.Mailer.new()
    |> Oban.insert()
  end

  @doc """
  Walks `map` and raises `ArgumentError` if any value is not
  Oban-JSON-safe. Returns the map unchanged on success.

  Allowed leaf types: `nil`, atom, binary, number, boolean. Maps and
  lists are recursed.
  """
  @spec only_scalars!(map()) :: map()
  def only_scalars!(map) when is_map(map) do
    Enum.each(map, fn {_k, v} -> check_scalar!(v) end)
    map
  end

  defp check_scalar!(nil), do: :ok
  defp check_scalar!(v) when is_atom(v) or is_binary(v) or is_number(v) or is_boolean(v), do: :ok

  defp check_scalar!(v) when is_list(v) do
    Enum.each(v, &check_scalar!/1)
    :ok
  end

  defp check_scalar!(%_{} = v) do
    raise ArgumentError,
          "Accrue.Mailer.deliver/2 assigns must be Oban-safe (scalars only); " <>
            "got struct #{inspect(v.__struct__)}. Pass entity IDs instead — see " <>
            "Accrue.Mailer.Default moduledoc (T-MAIL-01, D-27)."
  end

  defp check_scalar!(v) when is_map(v) do
    Enum.each(v, fn {_k, inner} -> check_scalar!(inner) end)
    :ok
  end

  defp check_scalar!(v) do
    raise ArgumentError,
          "Accrue.Mailer.deliver/2 assigns must be Oban-safe (scalars only); " <>
            "got #{inspect(v)}. Pass entity IDs instead — see " <>
            "Accrue.Mailer.Default moduledoc (T-MAIL-01, D-27)."
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(v), do: v
end
