alias AccrueHost.Repo
alias AccrueHost.OrdinarySeedBoundary

# These checks inspect the connection the Repo actually opened. Environment
# labels alone are not a database boundary: DATABASE_URL/PGHOST can be pointed
# at another stack while the Compose project name still looks correct.
[database, role, server_address] =
  case Repo.query!("SELECT current_database(), current_user, host(inet_server_addr())") do
    %{rows: [row]} -> row
    _ -> raise "ordinary preview seed refused: could not identify connected database"
  end

expected_address =
  case :inet.getaddr(~c"db", :inet) do
    {:ok, address} -> address |> :inet.ntoa() |> List.to_string()
    {:error, _} -> nil
  end

connected_target_allowed? =
  OrdinarySeedBoundary.allowed?(Mix.env(), database, role, server_address, expected_address)

unless connected_target_allowed? do
  raise "ordinary preview seed refused: connected Repo is not the isolated ordinary preview database " <>
          "(database=#{database} role=#{role} server_address=#{server_address})"
end

unless System.get_env("COMPOSE_PROJECT_NAME") == "accrue-host-phase245-ordinary" do
  raise "ordinary preview seed refused: unexpected COMPOSE_PROJECT_NAME"
end

unless System.get_env("ACCRUE_HOST_SKIP_SEEDS") == "1" do
  raise "ordinary preview seed refused: boot must use ACCRUE_HOST_SKIP_SEEDS=1"
end

unless Application.fetch_env!(:accrue, :processor) == Accrue.Processor.Fake do
  raise "ordinary preview seed refused: processor must be Accrue.Processor.Fake"
end

import Ecto.Query

# The Phase 191 route stress data and its browser-only e2e variants belong to
# isolated verification lanes. Older ordinary-preview volumes may contain
# them from a previous seed aggregator, so remove only their documented Fake
# processor namespaces before restoring the ordinary book of business.
alias Accrue.Billing.{
  Charge,
  Customer,
  Invoice,
  InvoiceCoupon,
  InvoiceItem,
  PaymentMethod,
  PromotionCode,
  Refund,
  Subscription,
  SubscriptionItem
}

alias Accrue.Connect.Account
alias Accrue.Events.Event
alias Accrue.Webhook.WebhookEvent

phase191_customer_ids =
  Repo.all(
    from(customer in Customer,
      where:
        customer.processor == "fake" and
          (like(customer.processor_id, "cus_phase191_host%") or
             like(customer.processor_id, "cus_e2e_phase191%")),
      select: customer.id
    )
  )

phase191_subscription_ids =
  Repo.all(
    from(subscription in Subscription,
      where:
        subscription.processor == "fake" and
          (like(subscription.processor_id, "sub_phase191_host%") or
             like(subscription.processor_id, "sub_e2e_phase191%") or
             subscription.customer_id in ^phase191_customer_ids),
      select: subscription.id
    )
  )

phase191_webhook_ids =
  Repo.all(
    from(webhook in WebhookEvent,
      where:
        like(webhook.processor_event_id, "evt_phase191_host%") or
          like(webhook.processor_event_id, "evt_e2e_phase191%"),
      select: webhook.id
    )
  )

phase191_invoice_ids =
  Repo.all(
    from(invoice in Invoice,
      where:
        invoice.processor == "fake" and
          (like(invoice.processor_id, "in_phase191_host%") or
             like(invoice.processor_id, "in_e2e_phase191%") or
             invoice.customer_id in ^phase191_customer_ids or
             invoice.subscription_id in ^phase191_subscription_ids),
      select: invoice.id
    )
  )

phase191_charge_ids =
  Repo.all(
    from(charge in Charge,
      where:
        charge.processor == "fake" and
          (like(charge.processor_id, "ch_phase191_host%") or
             like(charge.processor_id, "ch_e2e_phase191%") or
             charge.customer_id in ^phase191_customer_ids or
             charge.subscription_id in ^phase191_subscription_ids),
      select: charge.id
    )
  )

phase191_event_filter =
  from(event in Event,
    where:
      like(event.idempotency_key, "seed-phase191-%") or
        event.actor_id in ["phase191_host", "e2e_phase191"] or
        event.caused_by_webhook_event_id in ^phase191_webhook_ids or
        (event.subject_type == "Subscription" and event.subject_id in ^phase191_subscription_ids)
  )

if Repo.exists?(phase191_event_filter) do
  events_table = Accrue.Migration.qualified_table(:accrue_events)
  Repo.query!("ALTER TABLE #{events_table} DISABLE TRIGGER accrue_events_immutable_trigger")

  try do
    Repo.delete_all(phase191_event_filter)
  after
    Repo.query!("ALTER TABLE #{events_table} ENABLE TRIGGER accrue_events_immutable_trigger")
  end
end

Repo.delete_all(
  from(webhook in WebhookEvent,
    where:
      like(webhook.processor_event_id, "evt_phase191_host%") or
        like(webhook.processor_event_id, "evt_e2e_phase191%")
  )
)

Repo.delete_all(from(row in InvoiceItem, where: row.invoice_id in ^phase191_invoice_ids))

Repo.delete_all(from(row in InvoiceCoupon, where: row.invoice_id in ^phase191_invoice_ids))

Repo.delete_all(from(row in Refund, where: row.charge_id in ^phase191_charge_ids))

Repo.delete_all(
  from(row in SubscriptionItem, where: row.subscription_id in ^phase191_subscription_ids)
)

Repo.update_all(
  from(customer in Customer, where: customer.id in ^phase191_customer_ids),
  set: [default_payment_method_id: nil]
)

Repo.delete_all(from(invoice in Invoice, where: invoice.id in ^phase191_invoice_ids))
Repo.delete_all(from(charge in Charge, where: charge.id in ^phase191_charge_ids))

Repo.delete_all(
  from(payment_method in PaymentMethod,
    where:
      payment_method.processor == "fake" and
        (like(payment_method.processor_id, "pm_phase191_host%") or
           like(payment_method.processor_id, "pm_e2e_phase191%") or
           payment_method.customer_id in ^phase191_customer_ids)
  )
)

Repo.delete_all(
  from(subscription in Subscription, where: subscription.id in ^phase191_subscription_ids)
)

Repo.delete_all(
  from(promo in PromotionCode,
    where:
      promo.processor == "fake" and
        (like(promo.processor_id, "promo_phase191_host%") or
           like(promo.processor_id, "promo_e2e_phase191%"))
  )
)

Repo.delete_all(
  from(coupon in Accrue.Billing.Coupon,
    where:
      coupon.processor == "fake" and
        (like(coupon.processor_id, "coupon_phase191_host%") or
           like(coupon.processor_id, "coupon_e2e_phase191%"))
  )
)

Repo.delete_all(
  from(account in Account,
    where:
      like(account.stripe_account_id, "acct_phase191_host%") or
        like(account.stripe_account_id, "acct_e2e_phase191%")
  )
)

Repo.delete_all(from(customer in Customer, where: customer.id in ^phase191_customer_ids))

background_already_seeded? =
  Repo.exists?(
    from(event in Accrue.Events.Event,
      where: like(event.idempotency_key, "seed-bg-sub-%")
    )
  )

# This remains an eval_file chain so repeated runs in one BEAM node re-run the
# ordinary idempotent seeds. The background family uses random UUIDs; skip that
# bulk insert once its append-only seed events prove the family is present.
Code.eval_file("helpers.exs", __DIR__)
Code.eval_file("hero_accounts.exs", __DIR__)

# Startup hydration can leave an existing operator with an older credential.
# Reconcile only this Fake-backed ordinary preview account to the documented demo password.
operator = Repo.get_by!(AccrueHost.Accounts.User, email: "admin@example.com")

{:ok, {_operator, _expired_tokens}} =
  AccrueHost.Accounts.update_user_password(operator, %{
    password: AccrueHost.Seeds.Helpers.demo_password()
  })

unless background_already_seeded? do
  Code.eval_file("background_data.exs", __DIR__)
end

Code.eval_file("showcase.exs", __DIR__)
Code.eval_file("ordinary_payment_methods.exs", __DIR__)
Code.eval_file("ordinary_activity.exs", __DIR__)
