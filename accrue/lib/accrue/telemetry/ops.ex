defmodule Accrue.Telemetry.Ops do
  @moduledoc """
  Ops-grade telemetry emit helper.

  High-signal events go under `[:accrue, :ops, :*]`. SREs subscribe to this
  namespace for alertable conditions. The firehose `[:accrue, :*]` namespace
  contains every public entry point (via `Accrue.Telemetry.span/3`) and is
  too noisy for paging.

  ## Canonical ops events

      [:accrue, :ops, :revenue_loss]
      [:accrue, :ops, :dunning_exhaustion]
      [:accrue, :ops, :incomplete_expired]
      [:accrue, :ops, :charge_failed]
      [:accrue, :ops, :meter_reporting_failed]
      [:accrue, :ops, :webhook_dlq, :dead_lettered]
      [:accrue, :ops, :webhook_dlq, :replay]
      [:accrue, :ops, :webhook_dlq, :prune]

  ## Integrity notes

    * **Tampering** — the `[:accrue, :ops]` prefix is hardcoded.
      Callers cannot inject events outside the namespace via this helper.
    * **Correlation** — `operation_id` is auto-merged from
      `Accrue.Actor.current_operation_id/0` via `Map.put_new_lazy/3` when the
      caller does not supply one explicitly.

  See `guides/telemetry.md` for the full namespace conventions, span naming
  rules, and PII exclusion contract.
  """

  @type suffix :: atom() | [atom()]

  @doc """
  Emits a `[:accrue, :ops | suffix]` telemetry event.

  `suffix` is either an atom (single-segment) or a list of atoms
  (multi-segment, e.g. `[:webhook_dlq, :replay]`). The `[:accrue, :ops]`
  prefix is hardcoded and cannot be overridden — callers wanting other
  namespaces should use `:telemetry.execute/3` directly.

  `metadata` is auto-merged with `operation_id` from
  `Accrue.Actor.current_operation_id/0` when the caller does not supply one.
  """
  @spec emit(suffix(), map(), map()) :: :ok
  def emit(suffix, measurements, metadata \\ %{})

  def emit(suffix, measurements, metadata) when is_atom(suffix) do
    emit([suffix], measurements, metadata)
  end

  def emit(suffix, measurements, metadata)
      when is_list(suffix) and is_map(measurements) and is_map(metadata) do
    event = [:accrue, :ops] ++ suffix

    merged_metadata =
      Map.put_new_lazy(metadata, :operation_id, fn ->
        Accrue.Actor.current_operation_id()
      end)

    :telemetry.execute(event, measurements, merged_metadata)
    :ok
  end
end
