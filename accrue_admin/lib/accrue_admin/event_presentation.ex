defmodule AccrueAdmin.EventPresentation do
  @moduledoc """
  Shared operator labels and visual cues for recorded billing events.

  This is a presentation catalogue, not a restriction on ledger event names.
  Unknown events remain neutral. Tones describe recorded outcomes, never an
  inferred action requirement or the success of a generic admin result event.
  """

  # The trial_ended key is also emitted for trial_will_end by the webhook handler;
  # its label deliberately does not claim that the trial has already ended.
  @events %{
    "customer.created" => {"Customer created", :customer, :slate},
    "customer.updated" => {"Customer updated", :customer, :slate},
    "customer.local_updated" => {"Customer record updated locally", :customer, :slate},
    "customer.default_payment_method_changed" =>
      {"Default payment method changed", :customer, :slate},
    "subscription.created" => {"Subscription created", :subscription, :slate},
    "subscription.updated" => {"Subscription updated", :subscription, :slate},
    "subscription.trial_started" => {"Subscription trial started", :subscription, :slate},
    "subscription.trial_ended" => {"Subscription trial status recorded", :subscription, :slate},
    "subscription.canceled" => {"Subscription canceled", :subscription, :slate},
    "subscription.resumed" => {"Subscription resumed", :subscription, :slate},
    "subscription.paused" => {"Subscription paused", :subscription, :slate},
    "subscription.plan_swapped" => {"Subscription plan changed", :subscription, :slate},
    "subscription.comped" => {"Subscription made complimentary", :subscription, :slate},
    "subscription.item_added" => {"Subscription item added", :subscription, :slate},
    "subscription.item_removed" => {"Subscription item removed", :subscription, :slate},
    "subscription.item_quantity_updated" =>
      {"Subscription quantity changed", :subscription, :slate},
    "subscription_schedule.created" => {"Subscription schedule created", :subscription, :slate},
    "subscription_schedule.updated" => {"Subscription schedule updated", :subscription, :slate},
    "subscription_schedule.released" => {"Subscription schedule released", :subscription, :slate},
    "subscription_schedule.canceled" => {"Subscription schedule canceled", :subscription, :slate},
    "admin.subscription.action.completed" =>
      {"Subscription action result recorded", :subscription, :slate},
    "invoice.created" => {"Invoice created", :invoice, :slate},
    "invoice.finalized" => {"Invoice finalized", :invoice, :slate},
    "invoice.paid" => {"Invoice paid", :invoice, :moss},
    "invoice.payment_failed" => {"Invoice payment failed", :invoice, :amber},
    "invoice.voided" => {"Invoice voided", :invoice, :slate},
    "invoice.marked_uncollectible" => {"Invoice marked uncollectible", :invoice, :amber},
    "admin.invoice.action.completed" => {"Invoice action result recorded", :invoice, :slate},
    "charge.succeeded" => {"Payment succeeded", :payment, :moss},
    "charge.failed" => {"Payment failed", :payment, :amber},
    "charge.refunded" => {"Payment refunded", :payment, :slate},
    "refund.created" => {"Refund created", :payment, :slate},
    "refund.updated" => {"Refund updated", :payment, :slate},
    "refund.fees_settled" => {"Refund fees settled", :payment, :slate},
    "admin.charge.refund.completed" => {"Refund action result recorded", :payment, :slate},
    "dunning.campaign_started" => {"Payment recovery started", :recovery, :slate},
    "dunning.step_sent" => {"Payment reminder sent", :recovery, :slate},
    "dunning.recovered" => {"Payment recovered", :recovery, :moss},
    "dunning.exhausted" => {"Payment recovery ended", :recovery, :amber},
    "payment_method.attached" => {"Payment method added", :payment_method, :slate},
    "payment_method.detached" => {"Payment method removed", :payment_method, :slate},
    "payment_method.updated" => {"Payment method updated", :payment_method, :slate},
    "card.expiring_soon" => {"Card expiring soon", :payment_method, :amber},
    "webhook.received" => {"Webhook received", :webhook, :slate},
    "webhook.replay_requested" => {"Webhook replay requested", :webhook, :slate},
    "admin.webhook.replay.completed" => {"Webhook replay result recorded", :webhook, :slate},
    "admin.webhook.bulk_replay.completed" =>
      {"Bulk webhook replay results recorded", :webhook, :slate},
    "connect.account.updated" => {"Connected account updated", :connect, :slate},
    "connect.account.application.authorized" =>
      {"Account connection authorized", :connect, :slate},
    "connect.account.application.deauthorized" =>
      {"Account connection revoked", :connect, :amber},
    "connect.capability.updated" => {"Account capability updated", :connect, :slate},
    "admin.connect.platform_fee_override.updated" =>
      {"Platform fee override result recorded", :connect, :slate}
  }

  @icons %{
    customer: :users,
    subscription: :subscriptions,
    invoice: :invoices,
    payment: :payments,
    recovery: :recovery,
    payment_method: :payments,
    webhook: :webhooks,
    connect: :connect
  }

  def for(type) do
    case Map.get(@events, type) do
      {label, family, tone} ->
        %{label: label, family: family, icon: Map.fetch!(@icons, family), tone: tone}

      nil ->
        label =
          if is_binary(type) and type != "",
            do: "Billing event",
            else: "Event details unavailable"

        %{label: label, family: :other, icon: :events, tone: :slate}
    end
  end
end
