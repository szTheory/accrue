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
# Phase 58 scope: multi-step dunning workflow + Signal bridge (D-01).
# `DunningNotifier.workflow/2` declares Email 1 → 48h wait_until → Email 2
# escalation. A waiting run is cancelled at runtime by an `invoice.paid` Signal
# (see `cancel_campaign/3`), not a declared key on the wait_until rule — Chimeway
# 1.0.0 rejects extra keys on `wait_until` (`:mixed_rule_shape`). `orchestration/2`
# remains `{:ok, :immediate}` — workflow runs are created independently via `workflow/2`.

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

    ## Phase 58 workflow + Signal bridge

    Email-only dunning with a two-step Chimeway workflow (initial email → 48h
    `wait_until` → escalation email). `DunningNotifier` implements `workflow/2`
    and `rendering/2` so `Chimeway.trigger/3` creates a durable `WorkflowRun`
    with explainable progression.

    Outcome Signal termination: `cancel_campaign/3` emits `Chimeway.Signal.track/4`
    with `event_name: "invoice.paid"` and `actor_id` equal to the durable identity
    selected by `DunningNotifier.recipients/1`. Chimeway versions exposing the
    privacy-safe recipient-reference boundary use a stable opaque customer reference;
    Chimeway 1.0 retains its legacy email identity for backward compatibility. Chimeway routes
    that `invoice.paid` signal to runs waiting on the wait step via
    `Workflows.route_signal/1` — no host callback glue.

    `orchestration/2` remains `{:ok, :immediate}` — email delivery planning is
    unchanged; workflow progression is driven by `workflow/2`.
    """

    @behaviour Accrue.Dunning.Engine
    @compile {:no_warn_undefined, [Chimeway, Chimeway.Signal]}

    alias Accrue.Billing.{Customer, Subscription}

    @doc false
    def customer_recipient_ref(%Customer{id: customer_id}),
      do: "cw_accrue_customer_" <> customer_id

    @doc false
    def privacy_safe_recipient_refs? do
      Code.ensure_loaded?(Chimeway.SafeEvidence) and
        function_exported?(Chimeway.SafeEvidence, :recipient_reference, 1)
    end

    @doc false
    def customer_recipient(%Customer{} = customer) do
      if privacy_safe_recipient_refs?() do
        %{
          recipient_ref: customer_recipient_ref(customer),
          recipient_identity: "user:" <> customer.email,
          recipient_type: "email"
        }
      else
        %{recipient_identity: customer.email, recipient_type: "email"}
      end
    end

    @doc false
    def customer_signal_actor(%Customer{} = customer) do
      if privacy_safe_recipient_refs?(),
        do: customer_recipient_ref(customer),
        else: customer.email
    end

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
    def cancel_campaign(%Subscription{} = sub, _iso_anchor, _opts) do
      customer = Accrue.Repo.repo().get!(Customer, sub.customer_id)

      # D-09: actor_id MUST match the durable identity selected by recipients/1;
      # event_name MUST be "invoice.paid" so route_signal/1 can match runs waiting
      # on the wait_until step. Phase 98-capable Chimeway uses the opaque ref while
      # Chimeway 1.0 retains the legacy email actor for compatibility.
      case Chimeway.Signal.track(
             sub.customer_id,
             customer_signal_actor(customer),
             "invoice.paid",
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
      email-channel recipient maps. Phase 98-capable Chimeway receives a stable opaque
      recipient reference plus transient `user:<email>` delivery identity; Chimeway 1.0
      receives its legacy email identity. Implements required callbacks plus
      `channels/2` (email-only), `orchestration/2` (`:immediate`), `workflow/2`
      (48h escalation per SEED-003), and `rendering/2` (email render keys).
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

            {:ok, [Accrue.Integrations.Chimeway.customer_recipient(customer)]}
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

      @impl Chimeway.Notifier
      def rendering(params, _recipient) do
        sub_id = params[:subscription_id] || params["subscription_id"]

        {:ok,
         %{
           assigns: %{
             "subscription_id" => sub_id,
             "subject" => "Payment reminder",
             "html_body" => "<p>Please update your payment method.</p>",
             "text_body" => "Please update your payment method."
           },
           channels: %{
             email: %{
               render_key: "accrue.dunning.initial_email",
               render_version: 1
             }
           }
         }}
      end

      @impl true
      def workflow(_params, _recipient) do
        {:ok,
         %{
           workflow_key: "accrue.dunning",
           workflow_version: 1,
           steps: [
             %{
               step_key: "initial_email",
               step_order: 1,
               channel: :email,
               config: %{
                 "progress" => [
                   %{
                     "kind" => "wait_until",
                     "anchor" => "prior_delivery_terminal_at",
                     "delay_seconds" => 172_800,
                     "to_step" => "escalation_email"
                   }
                 ]
               }
             },
             %{
               step_key: "escalation_email",
               step_order: 2,
               channel: :email,
               config: %{}
             }
           ]
         }}
      end
    end
  end
end
