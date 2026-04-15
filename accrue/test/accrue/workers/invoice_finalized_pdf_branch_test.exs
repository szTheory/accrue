defmodule Accrue.Workers.InvoiceFinalizedPdfBranchTest do
  @moduledoc """
  Plan 06-07 Task 1: PDF attachment branch in `Accrue.Workers.Mailer.perform/1`.

  The invoice template family uses a deep-atom `:context` assigns shape
  that does not round-trip cleanly through Oban JSON in a test fixture
  without a real DB. We therefore cover the PDF branch at two levels:

    1. **Exception surface** — `Accrue.PDF.RenderFailed` builds + messages
       correctly; `Accrue.Error.PdfDisabled` is unchanged.
    2. **Public helpers** — `Accrue.Workers.Mailer.template_for/1`
       exposes the invoice template modules so `mix accrue.mail.preview`
       (Task 2) can reach them.

  End-to-end coverage of the branching itself (happy path → attachment;
  PdfDisabled → hosted URL note; chromic missing → telemetry; transient
  → raise) is delegated to `mailer_dispatch_test.exs` which uses the
  `Accrue.Mailer.Test` adapter + real webhook events.
  """
  use ExUnit.Case, async: false

  alias Accrue.Workers.Mailer, as: Worker

  describe "template_for/1 catalogue accessor" do
    test "exposes invoice templates for the preview task" do
      assert Worker.template_for(:invoice_finalized) == Accrue.Emails.InvoiceFinalized
      assert Worker.template_for(:invoice_paid) == Accrue.Emails.InvoicePaid
      assert Worker.template_for(:invoice_payment_failed) == Accrue.Emails.InvoicePaymentFailed
    end

    test "exposes non-invoice templates too" do
      assert Worker.template_for(:receipt) == Accrue.Emails.Receipt
      assert Worker.template_for(:trial_ending) == Accrue.Emails.TrialEnding
      assert Worker.template_for(:refund_issued) == Accrue.Emails.RefundIssued
      assert Worker.template_for(:coupon_applied) == Accrue.Emails.CouponApplied
      assert Worker.template_for(:card_expiring_soon) == Accrue.Emails.CardExpiringSoon
    end
  end

  describe "Accrue.PDF.RenderFailed exception" do
    test "message/1 falls back to inspected reason" do
      msg = Exception.message(%Accrue.PDF.RenderFailed{reason: :timeout})
      assert msg =~ "PDF render failed"
      assert msg =~ "timeout"
    end

    test "message/1 honors explicit :message" do
      msg = Exception.message(%Accrue.PDF.RenderFailed{message: "explicit"})
      assert msg == "explicit"
    end

    test "can be raised and caught" do
      assert_raise Accrue.PDF.RenderFailed, fn ->
        raise Accrue.PDF.RenderFailed, reason: :connection_closed
      end
    end
  end

  describe "Accrue.Error.PdfDisabled terminal sentinel" do
    test "pattern-matchable for the fallback branch" do
      err = %Accrue.Error.PdfDisabled{reason: :null_adapter}
      assert match?(%Accrue.Error.PdfDisabled{}, err)
      assert is_binary(Exception.message(err))
    end
  end
end
