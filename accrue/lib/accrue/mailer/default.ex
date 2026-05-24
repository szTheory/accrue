defmodule Accrue.Mailer.Default do
  @moduledoc """
  Default `Accrue.Mailer` adapter — enqueues an Oban job on the
  `:accrue_mailers` queue that a worker later turns into a delivered email.

  ## Pay-style override ladder

  This adapter implements a Pay-inspired four-rung override ladder:

  1. **Kill switch** (`:emails` config) — `Accrue.Mailer.deliver/2`
     short-circuits before this adapter is reached. Handled at the
     behaviour layer.
  2. MFA conditional (`:emails` value is `{Mod, :fun, args}`).
  3. **Template module override** (`:email_overrides` config) — resolved
     in `Accrue.Workers.Mailer.resolve_template/1`.
  4. Full pipeline replace (`:mailer` config pointing at a custom
     module) — already supported via `Accrue.Mailer.impl/0`.

  ## Oban args safety

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

    dedup_args(type, assigns, stringify_keys(scalar_assigns))
    |> Accrue.Workers.Mailer.new(unique: dedup_unique(type, assigns))
    |> Oban.insert()
  end

  # Builds the Oban args map per-type. For `:invoice_payment_failed` with a
  # usable `invoice_id`, the id is PROMOTED to a TOP-LEVEL Oban arg so the
  # `unique` `keys: [:type, :invoice_id]` actually discriminates per invoice
  # (Oban's `Map.take` on the `unique` keys operates on TOP-LEVEL stringified
  # arg keys only — NO recursion; verified against
  # `deps/oban/lib/oban/engines/basic.ex:514-525`). A nested-only `invoice_id`
  # under `assigns` would collapse EVERY invoice to one unique signature →
  # global suppression (worse than the bug being fixed). The promoted `invoice_id`
  # is the SAME scalar id that already lives inside `assigns` (the worker still
  # reads it from `assigns`; the extra top-level key is ignored by the worker's
  # `%{"type" => _, "assigns" => _}` match). Every OTHER type keeps the existing
  # `%{type:, assigns:}` shape with NO top-level invoice_id (no scope creep).
  defp dedup_args(:invoice_payment_failed, assigns, stringified_assigns) do
    case assigns[:invoice_id] do
      id when is_binary(id) and id != "" ->
        %{type: "invoice_payment_failed", invoice_id: id, assigns: stringified_assigns}

      _ ->
        # Degenerate / missing invoice_id — fall back to the non-promoted shape
        # so we never promote a nil/"" discriminator (which would re-introduce
        # global suppression). Mirrors the `dedup_unique/2` guard below.
        %{type: "invoice_payment_failed", assigns: stringified_assigns}
    end
  end

  defp dedup_args(type, _assigns, stringified_assigns) do
    %{type: Atom.to_string(type), assigns: stringified_assigns}
  end

  # Derives the Oban `unique` keyword for the enqueue. ONLY
  # `:invoice_payment_failed` (with a usable `invoice_id`) gets a unique —
  # keyed on `[:type, :invoice_id]` with `period: :infinity` (Stripe Smart
  # Retries span 1-4 weeks, so the window is never finite) and `:completed` in
  # `states` (a completed prior send must still block a week-2 redelivery).
  # `:cancelled`/`:discarded` are excluded so a cancelled send is re-sendable.
  # Every other type returns `false` (a no-op for `Oban.Worker.new/2`) — no
  # regression, no scope creep.
  defp dedup_unique(:invoice_payment_failed, %{invoice_id: id})
       when is_binary(id) and id != "" do
    [
      fields: [:worker, :args],
      keys: [:type, :invoice_id],
      period: :infinity,
      states: [:available, :scheduled, :executing, :retryable, :completed]
    ]
  end

  defp dedup_unique(_type, _assigns), do: false

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
            "Accrue.Mailer.Default moduledoc."
  end

  defp check_scalar!(v) when is_map(v) do
    Enum.each(v, fn {_k, inner} -> check_scalar!(inner) end)
    :ok
  end

  defp check_scalar!(v) do
    raise ArgumentError,
          "Accrue.Mailer.deliver/2 assigns must be Oban-safe (scalars only); " <>
            "got #{inspect(v)}. Pass entity IDs instead — see " <>
            "Accrue.Mailer.Default moduledoc."
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(v), do: v
end
