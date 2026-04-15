defmodule Accrue.Emails.Fixtures do
  @moduledoc """
  Canned assigns for every `Accrue.Emails.*` type (D6-08).

  Lives in `lib/` (not `test/support/`) so that:

    * `mix accrue.mail.preview` (Plan 06-07) can import without
      `test`-env dependencies.
    * ExUnit tests can call it without setup boilerplate.
    * (Phase 7) `AccrueAdmin.EmailPreviewLive` can import via
      `import Accrue.Emails.Fixtures`.

  Pure data — zero side effects, no `Accrue.Repo` calls, no
  `DateTime.utc_now/0`. Deterministic: every call returns byte-identical
  output given no environment changes.

  ## Usage

      iex> Accrue.Emails.Fixtures.receipt()
      %{context: %{...}, subject: "Receipt", preview: "Thanks for your payment"}

      iex> Accrue.Emails.Fixtures.all()
      %{receipt: %{...}, payment_failed: %{...}, ...}
  """

  @doc """
  Base render context re-used by most email fixtures. Contains a
  frozen branding snapshot, a fake customer, a fake invoice, two
  line items, and pre-formatted money strings so templates can render
  without calling `Accrue.Invoices.Render.format_money/3`.
  """
  @spec base_context() :: map()
  def base_context do
    %{
      branding: [
        business_name: "Acme Corp",
        from_name: "Acme Billing",
        from_email: "billing@acme.test",
        support_email: "support@acme.test",
        company_address: "123 Main St, San Francisco, CA 94103",
        logo_url: "https://example.test/logo.png",
        accent_color: "#1F6FEB",
        secondary_color: "#6B7280",
        font_stack: "-apple-system, BlinkMacSystemFont, sans-serif"
      ],
      customer: %{id: "cus_fixture", name: "Jo Example", email: "jo@example.test"},
      invoice: %{
        id: "in_fixture",
        number: "INV-2026-0001",
        hosted_invoice_url: "https://example.test/invoices/in_fixture"
      },
      subscription: %{id: "sub_fixture"},
      line_items: [
        %{description: "Pro plan (monthly)", quantity: 1, amount_minor: 2000},
        %{description: "Additional seat", quantity: 3, amount_minor: 900}
      ],
      currency: :usd,
      locale: "en",
      timezone: "Etc/UTC",
      subtotal_minor: 2900,
      discount_minor: 0,
      tax_minor: 0,
      total_minor: 2900,
      formatted_subtotal: "$29.00",
      formatted_discount: nil,
      formatted_tax: nil,
      formatted_total: "$29.00",
      formatted_issued_at: "April 15, 2026"
    }
  end

  @doc "Fixture for `Accrue.Emails.Receipt` (MAIL-03)."
  def receipt do
    %{
      context: base_context(),
      subject: "Receipt",
      preview: "Thanks for your payment"
    }
  end

  @doc "Fixture for `Accrue.Emails.PaymentFailed` (MAIL-04)."
  def payment_failed do
    %{
      context: base_context(),
      subject: "Payment failed",
      preview: "Action required",
      update_pm_url: "https://example.test/billing/payment-methods"
    }
  end

  @doc "Fixture for `Accrue.Emails.TrialEnding` (MAIL-05)."
  def trial_ending do
    %{
      context: Map.put(base_context(), :days_until_end, 3),
      subject: "Your trial is ending",
      preview: "3 days left",
      days_until_end: 3,
      cta_url: "https://example.test/billing/upgrade"
    }
  end

  @doc "Fixture for `Accrue.Emails.TrialEnded` (MAIL-06)."
  def trial_ended do
    %{
      context: base_context(),
      subject: "Your trial has ended",
      preview: "Trial complete",
      cta_url: "https://example.test/billing/upgrade"
    }
  end

  @doc "Fixture for `Accrue.Emails.InvoiceFinalized` (MAIL-07)."
  def invoice_finalized do
    %{
      context: base_context(),
      subject: "Your invoice is ready",
      preview: "Invoice available"
    }
  end

  @doc "Fixture for `Accrue.Emails.InvoicePaid` (MAIL-08)."
  def invoice_paid do
    %{
      context: base_context(),
      subject: "Payment received",
      preview: "Thanks!"
    }
  end

  @doc "Fixture for `Accrue.Emails.InvoicePaymentFailed` (MAIL-09)."
  def invoice_payment_failed do
    %{
      context: base_context(),
      subject: "Action required",
      preview: "Invoice payment failed"
    }
  end

  @doc "Fixture for `Accrue.Emails.SubscriptionCanceled` (MAIL-10)."
  def subscription_canceled do
    %{
      context: base_context(),
      subject: "Subscription canceled",
      preview: "Your plan"
    }
  end

  @doc "Fixture for `Accrue.Emails.SubscriptionPaused` (MAIL-11a)."
  def subscription_paused do
    %{
      context: Map.put(base_context(), :pause_behavior, "keep_as_draft"),
      subject: "Subscription paused",
      preview: "Paused",
      pause_behavior: "keep_as_draft"
    }
  end

  @doc "Fixture for `Accrue.Emails.SubscriptionResumed` (MAIL-11b)."
  def subscription_resumed do
    %{
      context: base_context(),
      subject: "Subscription resumed",
      preview: "Resumed"
    }
  end

  @doc "Fixture for `Accrue.Emails.RefundIssued` (MAIL-12)."
  def refund_issued do
    %{
      context:
        Map.merge(base_context(), %{
          refund: %{
            id: "re_fixture",
            formatted_amount: "$10.00",
            formatted_stripe_fee_refunded: "$0.30",
            formatted_merchant_loss: "$0.00"
          },
          charge: %{id: "ch_fixture"}
        }),
      subject: "Refund issued",
      preview: "We refunded $10.00"
    }
  end

  @doc "Fixture for `Accrue.Emails.CouponApplied` (MAIL-13)."
  def coupon_applied do
    %{
      context:
        Map.merge(base_context(), %{
          coupon: %{name: "Welcome", percent_off: 10, formatted_amount_off: nil},
          promotion_code: %{code: "WELCOME10"}
        }),
      subject: "Discount applied",
      preview: "10% off"
    }
  end

  @doc "Fixture for `Accrue.Emails.CardExpiringSoon` (Phase 3 cron)."
  def card_expiring_soon do
    %{
      context:
        Map.merge(base_context(), %{
          last4: "4242",
          exp_month: 12,
          exp_year: 2030,
          brand: "visa"
        }),
      subject: "Your card is expiring soon",
      preview: "Update your card",
      brand: "visa",
      last4: "4242",
      exp_month: 12,
      exp_year: 2030,
      cta_url: "https://example.test/billing/payment-methods"
    }
  end

  @doc """
  Returns the full catalogue as a map of email type atom → fixture map.

  Used by `mix accrue.mail.preview` (Plan 06-07) to iterate every
  registered type and by ExUnit tests to drive coverage loops.
  """
  @spec all() :: %{atom() => map()}
  def all do
    %{
      receipt: receipt(),
      payment_failed: payment_failed(),
      trial_ending: trial_ending(),
      trial_ended: trial_ended(),
      invoice_finalized: invoice_finalized(),
      invoice_paid: invoice_paid(),
      invoice_payment_failed: invoice_payment_failed(),
      subscription_canceled: subscription_canceled(),
      subscription_paused: subscription_paused(),
      subscription_resumed: subscription_resumed(),
      refund_issued: refund_issued(),
      coupon_applied: coupon_applied(),
      card_expiring_soon: card_expiring_soon()
    }
  end
end
