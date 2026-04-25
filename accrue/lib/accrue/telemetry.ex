defmodule Accrue.Telemetry do
  @moduledoc """
  Telemetry conventions and helpers for Accrue.

  ## When you attach handlers

  Attach to Accrue telemetry events to feed your metrics pipeline —
  Prometheus, DataDog, StatsD, or any `:telemetry`-compatible reporter.
  For example, to count subscription creations in Prometheus:

      :telemetry.attach(
        "my-app-subscription-created",
        [:accrue, :billing, :subscription, :create, :stop],
        &MyApp.Metrics.handle_event/4,
        nil
      )

  You can also use `Telemetry.Metrics` definitions and a reporter like
  `TelemetryMetricsPrometheus` to declare metrics declaratively rather
  than attaching individual handlers.

  ## Event naming

  All Accrue telemetry events follow a **4-level name** plus a phase suffix:

      [:accrue, :domain, :resource, :action, :start | :stop | :exception]

  The **second element** is the domain layer. Domains currently emitted
  are `:billing`, `:connect`, `:mailer`, `:pdf`, `:processor`, and
  `:storage`. Concrete examples:

      [:accrue, :billing, :subscription, :create, :start]
      [:accrue, :billing, :meter_event, :report_usage, :start]
      [:accrue, :mailer, :deliver, :payment_succeeded, :stop]
      [:accrue, :pdf, :render, :invoice, :exception]

  This mirrors Ecto's `[:ecto, :repo, :query]` and Phoenix's
  `[:phoenix, :endpoint, :start]` depth conventions.

  ## span/3

  `span/3` is a thin wrapper over `:telemetry.span/3` that accepts a
  zero-arity callable and emits `:start`, `:stop`, and `:exception`
  events. The fun's return value is passed through to the caller
  unchanged — the helper does the metadata plumbing.

  > ⚠️ `span/3` does NOT auto-include raw arguments in metadata — only
  > the explicit metadata map you pass. Raw Stripe API responses are
  > never inserted into span metadata.

  ## OpenTelemetry bridge

  `current_trace_id/0` returns the active OTel trace id as a hex string
  when `:opentelemetry` is loaded, and `nil` otherwise. The optional
  dependency compiles to a no-op when `:opentelemetry` is absent, so no
  warnings appear in environments without it.
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
