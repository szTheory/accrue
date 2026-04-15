defmodule Accrue.Workers.MailerResolveTemplateTest do
  # async: false — uses Application.put_env for override manipulation.
  use ExUnit.Case, async: false

  alias Accrue.Workers.Mailer, as: W

  @types [
    {:receipt, Accrue.Emails.Receipt},
    {:payment_failed, Accrue.Emails.PaymentFailed},
    {:trial_ending, Accrue.Emails.TrialEnding},
    {:trial_ended, Accrue.Emails.TrialEnded},
    {:invoice_finalized, Accrue.Emails.InvoiceFinalized},
    {:invoice_paid, Accrue.Emails.InvoicePaid},
    {:invoice_payment_failed, Accrue.Emails.InvoicePaymentFailed},
    {:subscription_canceled, Accrue.Emails.SubscriptionCanceled},
    {:subscription_paused, Accrue.Emails.SubscriptionPaused},
    {:subscription_resumed, Accrue.Emails.SubscriptionResumed},
    {:refund_issued, Accrue.Emails.RefundIssued},
    {:coupon_applied, Accrue.Emails.CouponApplied},
    {:card_expiring_soon, Accrue.Emails.CardExpiringSoon},
    {:payment_succeeded, Accrue.Emails.PaymentSucceeded}
  ]

  setup do
    original = Application.get_env(:accrue, :email_overrides, [])
    on_exit(fn -> Application.put_env(:accrue, :email_overrides, original) end)
    Application.put_env(:accrue, :email_overrides, [])
    :ok
  end

  describe "default_template/1 catalogue (via resolve_template/1)" do
    for {type, expected} <- @types do
      @tag type: type
      test "resolves #{inspect(type)} → #{inspect(expected)}" do
        assert W.resolve_template(unquote(type)) == unquote(expected)
      end
    end

    test "unknown atom raises FunctionClauseError" do
      assert_raise FunctionClauseError, fn -> W.resolve_template(:not_a_type) end
    end
  end

  describe "resolve_template/1 override ladder" do
    defmodule FakeChooser do
      def pick(:receipt), do: Accrue.Emails.Receipt
      def pick(:receipt, :variant_a), do: __MODULE__.VariantA
    end

    defmodule CustomReceipt do
      def subject(_), do: "custom"
    end

    test "rung 3 atom override replaces the default module" do
      Application.put_env(:accrue, :email_overrides, receipt: CustomReceipt)
      assert W.resolve_template(:receipt) == CustomReceipt
    end

    test "rung 2 MFA override calls Mod.fun(type | args)" do
      Application.put_env(:accrue, :email_overrides, receipt: {FakeChooser, :pick, []})
      assert W.resolve_template(:receipt) == Accrue.Emails.Receipt
    end

    test "rung 2 MFA forwards extra args after the type" do
      Application.put_env(:accrue, :email_overrides, receipt: {FakeChooser, :pick, [:variant_a]})

      assert W.resolve_template(:receipt) == FakeChooser.VariantA
    end

    test "no override falls through to default_template/1" do
      assert W.resolve_template(:payment_failed) == Accrue.Emails.PaymentFailed
    end
  end

  describe "enrich/2 D6-03 precedence ladder" do
    setup do
      orig_locale = Application.get_env(:accrue, :default_locale)
      orig_tz = Application.get_env(:accrue, :default_timezone)

      on_exit(fn ->
        if orig_locale, do: Application.put_env(:accrue, :default_locale, orig_locale)
        if orig_tz, do: Application.put_env(:accrue, :default_timezone, orig_tz)
      end)

      :ok
    end

    test "caller-supplied assigns[:locale] wins over app default" do
      Application.put_env(:accrue, :default_locale, "en")
      out = W.enrich(:receipt, %{locale: "en"})
      assert out.locale == "en"
    end

    test "application default wins over hardcoded en when assigns empty" do
      Application.put_env(:accrue, :default_locale, "en")
      out = W.enrich(:receipt, %{})
      assert out.locale == "en"
    end

    test "unknown locale falls back to en + emits locale_fallback telemetry" do
      test_pid = self()
      handler_id = "locale-fallback-#{:rand.uniform(1_000_000)}"

      :telemetry.attach(
        handler_id,
        [:accrue, :email, :locale_fallback],
        fn name, meas, meta, _ ->
          send(test_pid, {:telem, name, meas, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      out = W.enrich(:receipt, %{locale: "zz-NOTREAL-XX"})
      assert out.locale == "en"

      assert_receive {:telem, [:accrue, :email, :locale_fallback], %{count: 1},
                      %{requested: "zz-NOTREAL-XX"}}
    end

    test "unknown timezone falls back to Etc/UTC + emits timezone_fallback telemetry" do
      test_pid = self()
      handler_id = "tz-fallback-#{:rand.uniform(1_000_000)}"

      :telemetry.attach(
        handler_id,
        [:accrue, :email, :timezone_fallback],
        fn name, meas, meta, _ ->
          send(test_pid, {:telem, name, meas, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      out = W.enrich(:receipt, %{timezone: "Not/Real"})
      assert out.timezone == "Etc/UTC"

      assert_receive {:telem, [:accrue, :email, :timezone_fallback], %{count: 1},
                      %{requested: "Not/Real"}}
    end

    test "never raises on pathological input (empty map, no customer, no defaults)" do
      # Temporarily wipe app defaults to force pure hardcoded fallback.
      Application.delete_env(:accrue, :default_locale)
      Application.delete_env(:accrue, :default_timezone)

      out = W.enrich(:receipt, %{})
      assert is_map(out)
      assert out.locale in ["en"]
      assert out.timezone in ["Etc/UTC"]

      Application.put_env(:accrue, :default_locale, "en")
      Application.put_env(:accrue, :default_timezone, "Etc/UTC")
    end

    test "does not pass %Customer{} struct through args — hydrates from customer_id" do
      # customer_id missing → customer=nil, still returns map, no raise
      out = W.enrich(:receipt, %{customer_id: nil})
      assert out.customer == nil
    end

    test "missing customer_id yields customer=nil + defaults applied" do
      out = W.enrich(:receipt, %{})
      assert out.customer == nil
      assert out.locale == "en"
      assert out.timezone == "Etc/UTC"
    end
  end
end
