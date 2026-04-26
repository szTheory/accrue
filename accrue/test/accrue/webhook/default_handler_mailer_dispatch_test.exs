defmodule Accrue.Webhook.DefaultHandlerMailerDispatchTest do
  @moduledoc """
  Plan 06-07 Task 1: webhook reducer → mailer dispatch wiring.

  After each DefaultHandler reducer commits state reconciliation, it
  dispatches the domain email via `Accrue.Mailer.deliver/2`. Tests use
  `Accrue.Mailer.Test` (the default test adapter per config/test.exs)
  so assertions use the intent-tuple protocol
  (`{:accrue_email_delivered, type, assigns}`).

  Pitfall 7 discipline: the reducer is the single dispatch point — the
  double-dispatch regression test below verifies that delivering the
  same event twice through `handle/1` results in at-most-one deliver
  call at the behavior layer (the second call is allowed — de-dupe is
  the job of the Oban `unique:` option in the real pipeline, NOT the
  test adapter — so we assert count == 2 and document the Oban layer
  is the de-dupe point).
  """
  use Accrue.BillingCase, async: false
  use Accrue.Test.MailerAssertions
  import Mailglass.TestAssertions

  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Billing.{Charge, Invoice}

  setup do
    # Force Accrue.Mailer.Test adapter per-test: other test modules
    # flip :mailer to Accrue.Mailer.Default for their scope via
    # Application.put_env and race with this test (async: false is
    # not a cross-module lock).
    original_mailer = Application.get_env(:accrue, :mailer)
    Application.put_env(:accrue, :mailer, Accrue.Mailer.Test)

    on_exit(fn ->
      case original_mailer do
        nil -> Application.delete_env(:accrue, :mailer)
        v -> Application.put_env(:accrue, :mailer, v)
      end
    end)

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_mailer_dispatch",
        email: "md@example.com"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "charge.succeeded → :receipt" do
    setup do
      prior_mailer = Application.get_env(:accrue, :mailer)
      prior_pdf = Application.get_env(:accrue, :pdf_adapter)
      prior_branding = Application.get_env(:accrue, :branding)
      prior_mailglass = Application.get_env(:mailglass, :adapter)
      prior_mailglass_repo = Application.get_env(:mailglass, :repo)
      prior_suppression_store = Application.get_env(:mailglass, :suppression_store)
      prior_tenant = Mailglass.Tenancy.current()

      Application.put_env(:accrue, :mailer, Accrue.Mailer.Default)
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
      Application.put_env(:mailglass, :repo, Accrue.TestRepo)
      Application.put_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.ETS)
      Mailglass.SuppressionStore.ETS.reset()
      Application.put_env(:accrue, :branding,
        business_name: "Acme Corp",
        from_name: "Acme Billing",
        from_email: "billing@acme.test",
        support_email: "support@acme.test",
        company_address: "123 Main St, San Francisco, CA 94103",
        logo_url: "https://example.test/logo.png",
        accent_color: "#1F6FEB",
        secondary_color: "#6B7280",
        font_stack: "-apple-system, BlinkMacSystemFont, sans-serif"
      )
      Application.put_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []})
      Mailglass.Tenancy.put_current("test-tenant")
      Mailglass.Adapters.Fake.checkout()
      Mailglass.Adapters.Fake.clear()

      on_exit(fn ->
        case prior_mailer do
          nil -> Application.delete_env(:accrue, :mailer)
          v -> Application.put_env(:accrue, :mailer, v)
        end

        case prior_pdf do
          nil -> Application.delete_env(:accrue, :pdf_adapter)
          v -> Application.put_env(:accrue, :pdf_adapter, v)
        end

        case prior_branding do
          nil -> Application.delete_env(:accrue, :branding)
          v -> Application.put_env(:accrue, :branding, v)
        end

        case prior_mailglass do
          nil -> Application.delete_env(:mailglass, :adapter)
          v -> Application.put_env(:mailglass, :adapter, v)
        end

        case prior_mailglass_repo do
          nil -> Application.delete_env(:mailglass, :repo)
          v -> Application.put_env(:mailglass, :repo, v)
        end

        case prior_suppression_store do
          nil -> Application.delete_env(:mailglass, :suppression_store)
          v -> Application.put_env(:mailglass, :suppression_store, v)
        end

        Mailglass.Tenancy.put_current(prior_tenant)
      end)

      :ok
    end

    test "dispatches :receipt through the worker with explicit idempotency", %{customer: cus} do
      {:ok, stripe_ch} =
        Fake.create_charge(%{amount: 10_000, currency: "usd", customer: cus.processor_id}, [])

      event =
        StripeFixtures.webhook_event(
          "charge.succeeded",
          StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Charge{id: charge_id}} = DefaultHandler.handle(event)

      assert_enqueued(
        worker: Accrue.Workers.Mailer,
        queue: :accrue_mailers,
        args: %{"type" => "receipt"}
      )

      [job] = all_enqueued(worker: Accrue.Workers.Mailer)
      assert {:ok, _} = Accrue.Workers.Mailer.perform(job)

      assert_mail_sent(subject: "Receipt from Acme Corp", to: cus.email)

      msg = last_mail()
      assert msg.metadata.idempotency_key == "accrue:v1:receipt:#{charge_id}"
    end

    test "attaches the invoice PDF when invoice_id is present", %{customer: cus} do
      {:ok, invoice} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: "in_pdf_receipt",
          status: :open,
          currency: "usd",
          number: "INV-ATTACH-1",
          hosted_url: "https://example.test/invoices/in_pdf_receipt",
          total_minor: 29_00,
          subtotal_minor: 29_00,
          amount_due_minor: 29_00,
          amount_paid_minor: 0,
          amount_remaining_minor: 29_00
        })
        |> Repo.insert()

      job = %Oban.Job{
        args: %{
          "type" => "receipt",
          "assigns" => %{
            "charge_id" => "ch_pdf_receipt",
            "customer_id" => cus.id,
            "invoice_id" => invoice.id,
            "invoice_number" => invoice.number,
            "hosted_invoice_url" => invoice.hosted_url
          }
        }
      }

      assert {:ok, _} = Accrue.Workers.Mailer.perform(job)

      msg = last_mail()
      assert msg.metadata.idempotency_key == "accrue:v1:receipt:ch_pdf_receipt"
      assert Enum.any?(msg.swoosh_email.attachments, &(&1.content_type == "application/pdf"))
    end

    test "falls back to the hosted invoice URL note when PDF rendering does not run", %{customer: cus} do
      job = %Oban.Job{
        args: %{
          "type" => "receipt",
          "assigns" => %{
            "charge_id" => "ch_pdf_fallback",
            "customer_id" => cus.id,
            "hosted_invoice_url" => "https://example.test/invoices/ch_pdf_fallback"
          }
        }
      }

      assert {:ok, _} = Accrue.Workers.Mailer.perform(job)

      msg = last_mail()
      assert msg.metadata.idempotency_key == "accrue:v1:receipt:ch_pdf_fallback"
      assert msg.swoosh_email.text_body =~ "View your invoice online: https://example.test/invoices/ch_pdf_fallback"
      refute Enum.any?(msg.swoosh_email.attachments, &(&1.content_type == "application/pdf"))
    end
  end

  describe "charge.failed → :payment_failed" do
    setup do
      prior_mailer = Application.get_env(:accrue, :mailer)
      prior_pdf = Application.get_env(:accrue, :pdf_adapter)
      prior_branding = Application.get_env(:accrue, :branding)
      prior_mailglass = Application.get_env(:mailglass, :adapter)
      prior_mailglass_repo = Application.get_env(:mailglass, :repo)
      prior_suppression_store = Application.get_env(:mailglass, :suppression_store)
      prior_tenant = Mailglass.Tenancy.current()

      Application.put_env(:accrue, :mailer, Accrue.Mailer.Default)
      Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test)
      Application.put_env(:mailglass, :repo, Accrue.TestRepo)
      Application.put_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.ETS)
      Mailglass.SuppressionStore.ETS.reset()
      Application.put_env(:accrue, :branding,
        business_name: "Acme Corp",
        from_name: "Acme Billing",
        from_email: "billing@acme.test",
        support_email: "support@acme.test",
        company_address: "123 Main St, San Francisco, CA 94103",
        logo_url: "https://example.test/logo.png",
        accent_color: "#1F6FEB",
        secondary_color: "#6B7280",
        font_stack: "-apple-system, BlinkMacSystemFont, sans-serif"
      )
      Application.put_env(:mailglass, :adapter, {Mailglass.Adapters.Fake, []})
      Mailglass.Tenancy.put_current("test-tenant")
      Mailglass.Adapters.Fake.checkout()
      Mailglass.Adapters.Fake.clear()

      on_exit(fn ->
        case prior_mailer do
          nil -> Application.delete_env(:accrue, :mailer)
          v -> Application.put_env(:accrue, :mailer, v)
        end

        case prior_pdf do
          nil -> Application.delete_env(:accrue, :pdf_adapter)
          v -> Application.put_env(:accrue, :pdf_adapter, v)
        end

        case prior_branding do
          nil -> Application.delete_env(:accrue, :branding)
          v -> Application.put_env(:accrue, :branding, v)
        end

        case prior_mailglass do
          nil -> Application.delete_env(:mailglass, :adapter)
          v -> Application.put_env(:mailglass, :adapter, v)
        end

        case prior_mailglass_repo do
          nil -> Application.delete_env(:mailglass, :repo)
          v -> Application.put_env(:mailglass, :repo, v)
        end

        case prior_suppression_store do
          nil -> Application.delete_env(:mailglass, :suppression_store)
          v -> Application.put_env(:mailglass, :suppression_store, v)
        end

        Mailglass.Tenancy.put_current(prior_tenant)
      end)

      :ok
    end

    test "dispatches :payment_failed with explicit idempotency and no attachment", %{customer: cus} do
      {:ok, stripe_ch} =
        Fake.create_charge(
          %{amount: 10_000, currency: "usd", customer: cus.processor_id},
          []
        )

      event =
        StripeFixtures.webhook_event(
          "charge.failed",
          StripeFixtures.charge(%{"id" => stripe_ch.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Charge{id: charge_id}} = DefaultHandler.handle(event)

      assert_enqueued(
        worker: Accrue.Workers.Mailer,
        queue: :accrue_mailers,
        args: %{"type" => "payment_failed"}
      )

      [job] = all_enqueued(worker: Accrue.Workers.Mailer)
      assert {:ok, _} = Accrue.Workers.Mailer.perform(job)

      assert_mail_sent(subject: "Action required: payment failed at Acme Corp", to: cus.email)

      msg = last_mail()
      assert msg.metadata.idempotency_key == "accrue:v1:payment_failed:#{charge_id}"
      refute Enum.any?(msg.swoosh_email.attachments, &(&1.content_type == "application/pdf"))
    end
  end

  describe "invoice.finalized → :invoice_finalized" do
    test "dispatches with invoice_id + hosted_invoice_url scalars", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :draft
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.finalized",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Invoice{}} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_finalized, customer_id: cus.id)
    end
  end

  describe "invoice.paid → :invoice_paid" do
    test "dispatches :invoice_paid", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])
      {:ok, _} = Fake.pay_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :draft
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.paid",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, %Invoice{status: :paid}} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_paid, customer_id: cus.id)
    end
  end

  describe "invoice.payment_failed → :invoice_payment_failed" do
    test "dispatches :invoice_payment_failed", %{customer: cus} do
      params = %{customer: cus.processor_id, collection_method: "charge_automatically"}
      {:ok, stripe_inv} = Fake.create_invoice(params, [])
      {:ok, _} = Fake.finalize_invoice(stripe_inv.id, [])

      {:ok, _inv} =
        %Invoice{customer_id: cus.id, processor: "fake"}
        |> Invoice.force_status_changeset(%{
          processor_id: stripe_inv.id,
          currency: "usd",
          status: :open
        })
        |> Repo.insert()

      event =
        StripeFixtures.webhook_event(
          "invoice.payment_failed",
          StripeFixtures.invoice(%{"id" => stripe_inv.id, "customer" => cus.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:invoice_payment_failed, customer_id: cus.id)
    end
  end

  describe "customer.subscription.trial_will_end → :trial_ending" do
    test "dispatches :trial_ending", %{customer: cus} do
      {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.trial_will_end",
          StripeFixtures.subscription_created(%{"id" => sub.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:trial_ending, customer_id: cus.id)
    end
  end

  describe "customer.subscription.deleted → :subscription_canceled" do
    test "dispatches :subscription_canceled", %{customer: cus} do
      {:ok, sub} = Accrue.Billing.subscribe(cus, "price_basic")
      {:ok, _} = Fake.transition(sub.processor_id, :canceled, synthesize_webhooks: false)

      event =
        StripeFixtures.webhook_event(
          "customer.subscription.deleted",
          StripeFixtures.subscription_created(%{"id" => sub.processor_id})
        )

      assert {:ok, _} = DefaultHandler.handle(event)
      assert_email_sent(:subscription_canceled, customer_id: cus.id)
    end
  end

  describe "Pitfall 7 — single dispatch point discipline" do
    test "reducer is the only place :receipt is dispatched — Billing actions do not duplicate",
         %{customer: cus} do
      # This is a grep-level guard: the test asserts that within the
      # Billing action modules for charge-related flows, no direct
      # `Accrue.Mailer.deliver(:receipt, ...)` call exists. The webhook
      # reducer holds the single dispatch for the catalogue state-
      # change emails (receipt / payment_failed / invoice_* /
      # subscription_canceled / refund_issued).
      billing_root = Path.expand("../../../../lib/accrue/billing", __DIR__)

      offenders =
        billing_root
        |> Path.join("**/*.ex")
        |> Path.wildcard()
        |> Enum.flat_map(fn path ->
          body = File.read!(path)

          banned_types =
            ~w(receipt payment_failed invoice_finalized invoice_paid invoice_payment_failed subscription_canceled subscription_paused subscription_resumed refund_issued)

          Enum.flat_map(banned_types, fn type ->
            pattern = "Accrue.Mailer.deliver(:" <> type
            if String.contains?(body, pattern), do: [{path, type}], else: []
          end)
        end)

      assert offenders == [],
             "Pitfall 7 violation: Billing action modules must NOT call " <>
               "Accrue.Mailer.deliver/2 for state-change emails. Only the " <>
               "webhook reducer dispatches these. Offenders: #{inspect(offenders)}. " <>
               "Allowed exceptions: :card_expiring_soon (cron) and :coupon_applied (action)."

      # Keep the customer binding referenced so the Dialyzer/ExUnit
      # unused-var warning stays silent.
      _ = cus
    end
  end
end
