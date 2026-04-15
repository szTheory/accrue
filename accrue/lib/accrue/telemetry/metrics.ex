if Code.ensure_loaded?(Telemetry.Metrics) do
  defmodule Accrue.Telemetry.Metrics do
    @moduledoc """
    Default `Telemetry.Metrics` recipe for SRE teams (OBS-05).

    This module is conditionally compiled — it is only available when the
    optional `:telemetry_metrics` dependency is present.

    Host apps wire this into their own metrics supervisor:

        defmodule MyApp.Telemetry do
          use Supervisor
          import Telemetry.Metrics

          def init(_arg) do
            children = [
              {TelemetryMetricsPrometheus, [metrics: metrics()]}
            ]
            Supervisor.init(children, strategy: :one_for_one)
          end

          defp metrics do
            [
              counter("my_app.request.count")
              # ... host metrics ...
            ] ++ Accrue.Telemetry.Metrics.defaults()
          end
        end

    Distributions and percentile summaries beyond the defaults below are
    host-choice — Accrue does not prescribe binning strategies.

    ## Cardinality discipline (T-04-08-03)

    Tags on the default counters are restricted to low-cardinality fields
    (`:status`, `:source`, `:type`, `:stripe_status`). Customer ID,
    subscription ID, and other unbounded identifiers are NEVER promoted to
    metric tags — those belong on spans, not metrics.
    """
    import Telemetry.Metrics

    @doc """
    Returns the default Accrue metric definitions.

    Append to your host metric list. See module doc for full host wiring
    example.
    """
    @spec defaults() :: [struct()]
    def defaults do
      [
        # --- Billing context counters ---
        counter("accrue.billing.subscription.create.count"),
        counter("accrue.billing.charge.create.count", tags: [:status]),
        counter("accrue.billing.report_usage.count", tags: [:stripe_status]),

        # --- Webhook pipeline ---
        counter("accrue.webhooks.received.count", tags: [:type]),
        counter("accrue.webhooks.dispatched.count", tags: [:status]),
        last_value("accrue.webhooks.queue_depth"),
        summary("accrue.webhooks.dispatch.duration",
          unit: {:native, :millisecond}
        ),

        # --- Ops namespace (high-signal, low-cardinality) ---
        counter("accrue.ops.webhook_dlq.dead_lettered.count"),
        counter("accrue.ops.webhook_dlq.replay.count"),
        counter("accrue.ops.webhook_dlq.prune.dead_deleted"),
        counter("accrue.ops.dunning_exhaustion.count", tags: [:source]),
        counter("accrue.ops.meter_reporting_failed.count", tags: [:source]),
        counter("accrue.ops.charge_failed.count"),
        counter("accrue.ops.revenue_loss.count"),
        counter("accrue.ops.incomplete_expired.count")
      ]
    end
  end
else
  defmodule Accrue.Telemetry.Metrics do
    @moduledoc false

    @doc false
    def defaults do
      raise """
      Accrue.Telemetry.Metrics.defaults/0 requires the optional :telemetry_metrics dep.

      Add to your mix.exs:

          {:telemetry_metrics, "~> 1.1"}

      Then re-run `mix deps.get` and recompile.
      """
    end
  end
end
