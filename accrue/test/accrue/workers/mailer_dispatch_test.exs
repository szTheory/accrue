defmodule Accrue.Workers.MailerDispatchTest do
  @moduledoc """
  Plan 06-07 Task 1: smoke test for `Accrue.Mailer.deliver/2` → worker
  resolve/render/enqueue pipeline.

  Runs against the `Accrue.Mailer.Test` adapter (configured in
  `config/test.exs`) — every `Accrue.Mailer.deliver/2` call becomes an
  `{:accrue_email_delivered, type, assigns}` message in the caller's
  mailbox. We assert exactly one message per type + scalar-only assigns
  propagation.

  Full `%Swoosh.Email{}` body assertions live in each template's own
  `*_test.exs` under `test/accrue/emails/` (Plans 05 + 06).
  """
  use ExUnit.Case, async: false
  use Accrue.Test.MailerAssertions

  setup do
    # Other test modules flip :mailer to Accrue.Mailer.Default for their
    # duration via `Application.put_env`. Since we rely on the test
    # adapter capturing the intent tuple synchronously in the calling
    # pid's mailbox, force it explicitly per-test and restore on exit.
    original = Application.get_env(:accrue, :mailer)
    Application.put_env(:accrue, :mailer, Accrue.Mailer.Test)

    on_exit(fn ->
      case original do
        nil -> Application.delete_env(:accrue, :mailer)
        v -> Application.put_env(:accrue, :mailer, v)
      end
    end)

    :ok
  end

  @catalogue [
    :receipt,
    :payment_failed,
    :trial_ending,
    :trial_ended,
    :invoice_finalized,
    :invoice_paid,
    :invoice_payment_failed,
    :subscription_canceled,
    :subscription_paused,
    :subscription_resumed,
    :refund_issued,
    :coupon_applied,
    :card_expiring_soon
  ]

  describe "Accrue.Mailer.deliver/2 → Accrue.Mailer.Test pipeline" do
    for type <- @catalogue do
      @tag type: type
      test "deliver(#{inspect(type)}, assigns) captures intent tuple" do
        type = unquote(type)
        assigns = %{customer_id: "cus_test", to: "jo@example.test"}

        assert {:ok, :test} = Accrue.Mailer.deliver(type, assigns)
        assert_email_sent(type, customer_id: "cus_test")
      end
    end
  end

  describe "kill switch short-circuits before dispatch" do
    test "disabled type returns {:ok, :skipped} without touching the adapter" do
      original = Application.get_env(:accrue, :emails, [])
      Application.put_env(:accrue, :emails, receipt: false)

      on_exit(fn -> Application.put_env(:accrue, :emails, original) end)

      assert {:ok, :skipped} =
               Accrue.Mailer.deliver(:receipt, %{customer_id: "cus_test"})

      refute_email_sent(:receipt)
    end
  end
end
