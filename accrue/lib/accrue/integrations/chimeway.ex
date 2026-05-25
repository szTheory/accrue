# Accrue.Integrations.Chimeway — conditionally compiled (DUN-03, D-04).
#
# Follows CLAUDE.md's 4-pattern conditional compile exactly:
#
#   1. Optional dep in `deps/0`:
#      `{:chimeway, "~> 1.0", optional: true}` in accrue/mix.exs.
#      When the host does NOT add {:chimeway, "~> 1.0"} to their deps,
#      `Code.ensure_loaded?(Chimeway)` returns false at compile time and
#      the entire `defmodule` block is elided —
#      `Accrue.Integrations.Chimeway` is never defined.
#
#   2. `@compile {:no_warn_undefined, [...]}` silences compiler warnings
#      about `Chimeway` and `Chimeway.Signal` whose resolution is deferred
#      to runtime when the host's Chimeway is present.
#
#   3. Integration module is guarded at `defmodule` time via
#      `Code.ensure_loaded?(Chimeway)` — the scaffolding disappears
#      entirely in the without-chimeway matrix.
#
#   4. Runtime dispatch by config (not compile-time aliasing) — hosts
#      flip `config :accrue, dunning: [engine: Accrue.Integrations.Chimeway]`
#      at runtime to activate this adapter. `Config.dunning_engine/0`
#      resolves the adapter via `Application.get_env/3` at call time,
#      so this module only needs to exist; wiring is host-owned.
#
# v1.40 scope: email-only, :immediate orchestration path.
# `workflow/2` is intentionally OMITTED — with `orchestration/2 -> {:ok, :immediate}`
# and no `workflow/2`, `Chimeway.trigger/3` delivers the email immediately,
# creates no WorkflowRun, and `Signal.track("payment_recovered")` routes to
# zero runs (a safe no-op). Cancel-on-recovery is already guaranteed by
# Accrue's anchor-clear preventing future `start_campaign` calls.
# The workflow/2 optional callback is intentionally omitted for the v1.40 email-only path.

if Code.ensure_loaded?(Chimeway) do
  defmodule Accrue.Integrations.Chimeway do
    @moduledoc """
    Off-by-default Chimeway dunning engine adapter for Accrue (DUN-03).

    Conditionally compiled: when the optional `:chimeway` dep is absent
    (the default build), this `defmodule` block is elided entirely and
    `Accrue.Integrations.Chimeway` is never defined. See the file header
    comment for the full 4-pattern rationale.

    ## Opting in

    Add to the host `mix.exs`:

        {:chimeway, "~> 1.0"}

    Then configure in `config/config.exs`:

        config :accrue, dunning: [engine: Accrue.Integrations.Chimeway]

    The host must also start Chimeway in their supervision tree and run
    Chimeway's own migrations per Chimeway's install guide.

    ## v1.40 scope

    Email-only, `:immediate` orchestration. `DunningNotifier.workflow/2` is
    intentionally omitted — with `:immediate` orchestration, `Chimeway.trigger/3`
    delivers the dunning email immediately with no WorkflowRun created.
    `Signal.track("payment_recovered")` is a safe no-op in this mode
    (correct because Accrue's anchor-clear prevents future `start_campaign` calls).

    Multi-channel and multi-step workflow orchestration are deferred to a
    future v1.x minor.
    """

    @behaviour Accrue.Dunning.Engine
    @compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}

    alias Accrue.Billing.Subscription

    @impl Accrue.Dunning.Engine
    def start_campaign(%Subscription{} = sub, %DateTime{} = anchor, _opts) do
      iso_anchor = DateTime.to_iso8601(anchor)
      # Stable, unique-per-campaign key: prevents duplicate triggers from
      # concurrent webhooks (T-131-07 — mirrors Phase 128 CAS semantics).
      idempotency_key = "accrue.dunning:" <> sub.id <> ":" <> iso_anchor

      case Chimeway.trigger(
             __MODULE__.DunningNotifier,
             %{subscription_id: sub.id, customer_id: sub.customer_id, anchor: iso_anchor},
             idempotency_key: idempotency_key,
             tenant_id: sub.customer_id
           ) do
        {:ok, _result} -> :ok
        # Idempotency contract: duplicate trigger is a no-op (T-131-07).
        {:duplicate, _event} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end

    @impl Accrue.Dunning.Engine
    def cancel_campaign(%Subscription{} = sub, iso_anchor, _opts) when is_binary(iso_anchor) do
      # Signal.track/4 arg order: (tenant_id, actor_id, event_name, payload)
      # sub.customer_id is the tenant_id; "accrue.dunning" is the system actor_id.
      # With :immediate orchestration and no workflow/2, this signal routes to
      # zero WorkflowRuns — a safe no-op. Anchor-clear in Accrue prevents
      # future start_campaign calls (T-131-08, T-131-09).
      case Chimeway.Signal.track(
             sub.customer_id,
             "accrue.dunning",
             "payment_recovered",
             %{subscription_id: sub.id}
           ) do
        {:ok, _signal} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end

    defmodule DunningNotifier do
      @moduledoc """
      Bundled `Chimeway.Notifier` implementation for Accrue dunning notifications.

      Resolves Accrue domain models (Subscription → Customer) to produce
      email-channel recipient maps. Implements only the 4 required callbacks
      plus `channels/2` (email-only) and `orchestration/2` (:immediate).

      `workflow/2` is intentionally omitted for the v1.40 email-only :immediate
      path — see `Accrue.Integrations.Chimeway` moduledoc for rationale.
      """

      @behaviour Chimeway.Notifier
      @compile {:no_warn_undefined, [Chimeway.Notifier]}

      @impl Chimeway.Notifier
      def notification_key, do: "accrue.dunning"

      @impl Chimeway.Notifier
      def version, do: 1

      @impl Chimeway.Notifier
      def recipients(params) do
        subscription_id = params[:subscription_id] || params["subscription_id"]

        case Accrue.Repo.repo().get(Accrue.Billing.Subscription, subscription_id) do
          nil ->
            {:error, :subscription_not_found}

          sub ->
            customer = Accrue.Repo.repo().get!(Accrue.Billing.Customer, sub.customer_id)
            {:ok, [%{recipient_identity: customer.email, recipient_type: "email"}]}
        end
      end

      @impl Chimeway.Notifier
      def build(params, _recipient) do
        {:ok, %{subscription_id: params[:subscription_id] || params["subscription_id"]}}
      end

      @impl Chimeway.Notifier
      def channels(_params, _recipient), do: {:ok, [:email]}

      @impl Chimeway.Notifier
      def orchestration(_params, _recipient), do: {:ok, :immediate}
    end
  end
end
