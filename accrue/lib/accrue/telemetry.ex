defmodule Accrue.Telemetry do
  @moduledoc """
  Telemetry conventions and helpers for Accrue (D-17, D-18, OBS-01).

  ## Event naming

  All Accrue telemetry events follow a **4-level name** plus a phase suffix:

      [:accrue, :domain, :resource, :action, :start | :stop | :exception]

  The domain layer is one of `:billing`, `:events`, `:webhooks`, `:mail`,
  `:pdf`, `:processor`. Concrete examples:

      [:accrue, :billing, :subscription, :create, :start]
      [:accrue, :mail, :deliver, :payment_succeeded, :stop]
      [:accrue, :pdf, :render, :invoice, :exception]

  This mirrors Ecto's `[:ecto, :repo, :query]` and Phoenix's
  `[:phoenix, :endpoint, :start]` depth conventions.

  ## span/3

  `span/3` is a thin wrapper over `:telemetry.span/3` that accepts a
  zero-arity callable and emits `:start`, `:stop`, and `:exception`
  events. The fun's return value is passed through to the caller
  unchanged — the helper does the metadata plumbing.

  > ⚠️ `span/3` does NOT auto-include raw arguments in metadata — only
  > the explicit metadata map you pass. Plan 04's Stripe processor MUST
  > NOT shove raw `lattice_stripe` responses into span metadata. Mitigates
  > T-OBS-01.

  ## OpenTelemetry bridge

  `current_trace_id/0` returns the active OTel trace id as a hex string
  when `:opentelemetry` is loaded, and `nil` otherwise. The conditional
  compile pattern (CLAUDE.md §Conditional Compilation) keeps the
  `without_opentelemetry` CI matrix warning-free.
  """

  @compile {:no_warn_undefined, [:otel_tracer, :otel_span]}

  @type event_name :: [atom()]

  @doc """
  Wraps `fun` in a `:telemetry.span/3` call.

  `fun` is a zero-arity callable that returns the result value. This
  wrapper handles the `{result, metadata}` contract expected by
  `:telemetry.span/3` internally so call sites stay clean.

  The initial `metadata` map is merged with the current actor
  (`Accrue.Actor.current/0`) when present under the `:actor` key.
  """
  @spec span(event_name(), map(), (-> result)) :: result when result: var
  def span(event, metadata \\ %{}, fun)
      when is_list(event) and is_map(metadata) and is_function(fun, 0) do
    base_metadata = maybe_put_actor(metadata)
    otel_event = event_without_span_suffix(event)

    :telemetry.span(event, base_metadata, fn ->
      result = Accrue.Telemetry.OTel.span(otel_event, base_metadata, fn -> fun.() end)
      {result, base_metadata}
    end)
  end

  @doc """
  Returns the current OpenTelemetry trace id as a hex string, or `nil`
  when `:opentelemetry` is not loaded.
  """
  @spec current_trace_id() :: String.t() | nil
  if Code.ensure_loaded?(:otel_tracer) do
    def current_trace_id do
      case :otel_tracer.current_span_ctx() do
        :undefined ->
          nil

        ctx ->
          trace_id = :otel_span.trace_id(ctx)

          if trace_id == 0 do
            nil
          else
            trace_id |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(32, "0")
          end
      end
    rescue
      _ -> nil
    end
  else
    def current_trace_id, do: nil
  end

  # --- internals --------------------------------------------------------

  defp maybe_put_actor(metadata) do
    case Accrue.Actor.current() do
      nil -> metadata
      actor -> Map.put_new(metadata, :actor, actor)
    end
  end

  defp event_without_span_suffix(event) do
    case List.last(event) do
      suffix when suffix in [:start, :stop, :exception] -> Enum.drop(event, -1)
      _ -> event
    end
  end
end
