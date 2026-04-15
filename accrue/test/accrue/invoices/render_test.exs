defmodule Accrue.Invoices.RenderTest do
  @moduledoc """
  Unit specs for `Accrue.Invoices.RenderContext` + `Accrue.Invoices.Render`.

  Covers:

    * `@enforce_keys` on `RenderContext`
    * `format_money/3` across two-/zero-/three-decimal currencies with
      locale-fallback telemetry
    * `format_datetime/3` timezone fallback
    * `build_assigns/2` branding-snapshot freeze (Pitfall 8) +
      locale-precedence ladder (D6-03)
  """

  use ExUnit.Case, async: false

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Invoice
  alias Accrue.Billing.InvoiceItem
  alias Accrue.Invoices.Render
  alias Accrue.Invoices.RenderContext

  # ---------- RenderContext @enforce_keys -------------------------------

  describe "RenderContext struct" do
    test "accepts a struct when all @enforce_keys are present" do
      ctx = %RenderContext{
        invoice: %{id: "inv_1"},
        customer: %{id: "cus_1"},
        branding: [from_email: "n@example.test", support_email: "s@example.test"],
        locale: "en",
        timezone: "Etc/UTC",
        currency: :usd
      }

      assert ctx.invoice.id == "inv_1"
      assert ctx.locale == "en"
    end

    test "raises at compile time when required key is missing" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn ->
        Code.eval_string("""
        %Accrue.Invoices.RenderContext{
          invoice: %{},
          customer: %{},
          branding: [],
          locale: "en",
          currency: :usd
          # :timezone missing
        }
        """)
      end
    end
  end

  # ---------- format_money/3 --------------------------------------------

  describe "format_money/3" do
    test "two-decimal currency (USD) renders correctly" do
      assert Render.format_money(1000, :usd, "en") == "$10.00"
    end

    test "zero-decimal currency (JPY) renders without decimals" do
      assert Render.format_money(1000, :jpy, "en") =~ "1,000"
      refute Render.format_money(1000, :jpy, "en") =~ "."
    end

    test "three-decimal currency (KWD) renders with three decimal digits" do
      out = Render.format_money(1000, :kwd, "en")
      assert is_binary(out)
      # KWD is three-decimal so 1000 minor = 1.000 KWD
      assert out =~ "1.000"
    end

    test "unknown locale falls back to en and emits telemetry" do
      test_pid = self()
      handler_id = "locale-fallback-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:accrue, :email, :locale_fallback],
        fn _event, measurements, meta, _cfg ->
          send(test_pid, {:telemetry, measurements, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      result = Render.format_money(1000, :usd, "zz-INVALID")

      assert is_binary(result)
      assert result =~ "10"
      assert_receive {:telemetry, _, %{requested: "zz-INVALID", currency: :usd}}, 500
    end

    test "never raises on unknown currency — returns a raw fallback binary" do
      test_pid = self()
      handler_id = "money-failed-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:accrue, :email, :format_money_failed],
        fn _event, _measurements, meta, _cfg ->
          send(test_pid, {:failed, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # :xxx is reserved, not a real ISO 4217 code with an entry in ex_money's table
      result = Render.format_money(1000, :xxx, "en")
      assert is_binary(result)
    end
  end

  # ---------- format_datetime/3 -----------------------------------------

  describe "format_datetime/3" do
    test "renders a formatted date string in UTC" do
      dt = ~U[2026-04-15 12:00:00Z]
      assert Render.format_datetime(dt, "Etc/UTC", "en") =~ "2026"
    end

    test "returns nil for nil input" do
      assert Render.format_datetime(nil, "Etc/UTC", "en") == nil
    end

    test "falls back to UTC and emits telemetry on unknown timezone" do
      test_pid = self()
      handler_id = "tz-fallback-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:accrue, :email, :timezone_fallback],
        fn _event, _measurements, meta, _cfg ->
          send(test_pid, {:tz, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      dt = ~U[2026-04-15 12:00:00Z]
      out = Render.format_datetime(dt, "Bogus/Nowhere", "en")

      assert is_binary(out)
      assert_receive {:tz, %{requested: "Bogus/Nowhere"}}, 500
    end
  end

  # ---------- build_assigns/2 -------------------------------------------

  describe "build_assigns/2 — branding snapshot freeze (Pitfall 8)" do
    setup do
      invoice = %Invoice{
        id: "inv_123",
        number: "INV-0001",
        currency: "usd",
        subtotal_minor: 1000,
        discount_minor: 0,
        tax_minor: 0,
        total_minor: 1000,
        hosted_url: "https://example.test/i/inv_123",
        items: [
          %InvoiceItem{
            description: "Widget",
            amount_minor: 1000,
            currency: "usd",
            quantity: 1
          }
        ],
        finalized_at: ~U[2026-04-15 12:00:00.000000Z]
      }

      customer = %Customer{
        id: "cus_123",
        name: "Test Customer",
        email: "test@example.test",
        preferred_locale: nil,
        preferred_timezone: nil
      }

      %{invoice: invoice, customer: customer}
    end

    test "freezes branding at build time — later app_env changes don't mutate ctx",
         %{invoice: invoice, customer: customer} do
      # Preserve original config
      original = Application.get_env(:accrue, :branding)

      on_exit(fn ->
        if original do
          Application.put_env(:accrue, :branding, original)
        else
          Application.delete_env(:accrue, :branding)
        end
      end)

      Application.put_env(:accrue, :branding,
        business_name: "BeforeCo",
        from_email: "a@example.test",
        support_email: "b@example.test"
      )

      ctx = Render.build_assigns(invoice, customer: customer)
      assert Keyword.fetch!(ctx.branding, :business_name) == "BeforeCo"

      Application.put_env(:accrue, :branding,
        business_name: "AfterCo",
        from_email: "a@example.test",
        support_email: "b@example.test"
      )

      # ctx.branding MUST NOT reflect the post-build env change
      assert Keyword.fetch!(ctx.branding, :business_name) == "BeforeCo"
    end

    test "resolves locale precedence: opts > customer.preferred_locale > en",
         %{invoice: invoice, customer: customer} do
      ctx1 = Render.build_assigns(invoice, customer: customer)
      assert ctx1.locale == "en"

      customer_with = %{customer | preferred_locale: "fr"}
      ctx2 = Render.build_assigns(invoice, customer: customer_with)
      assert ctx2.locale == "fr"

      ctx3 = Render.build_assigns(invoice, customer: customer_with, locale: "de")
      assert ctx3.locale == "de"
    end

    test "resolves timezone precedence: opts > customer.preferred_timezone > Etc/UTC",
         %{invoice: invoice, customer: customer} do
      ctx1 = Render.build_assigns(invoice, customer: customer)
      assert ctx1.timezone == "Etc/UTC"

      customer_with = %{customer | preferred_timezone: "America/Los_Angeles"}
      ctx2 = Render.build_assigns(invoice, customer: customer_with)
      assert ctx2.timezone == "America/Los_Angeles"

      ctx3 = Render.build_assigns(invoice, customer: customer_with, timezone: "Europe/Paris")
      assert ctx3.timezone == "Europe/Paris"
    end

    test "pre-formats money + issued-at strings into the context",
         %{invoice: invoice, customer: customer} do
      ctx = Render.build_assigns(invoice, customer: customer)

      assert ctx.formatted_total == "$10.00"
      assert ctx.formatted_subtotal == "$10.00"
      assert ctx.currency == :usd
      assert is_binary(ctx.formatted_issued_at)
      assert ctx.formatted_issued_at =~ "2026"
    end

    test "line_items are threaded through the context",
         %{invoice: invoice, customer: customer} do
      ctx = Render.build_assigns(invoice, customer: customer)
      assert [%InvoiceItem{description: "Widget"}] = ctx.line_items
    end
  end

  # ---------- Styles lookup ----------------------------------------------

  describe "Accrue.Invoices.Styles.for/2" do
    test "every documented key returns a non-empty binary" do
      branding = [
        accent_color: "#3B82F6",
        secondary_color: "#6B7280",
        font_stack: "Helvetica, Arial, sans-serif"
      ]

      keys = [
        :table_reset,
        :logo_cell,
        :number_cell,
        :line_items,
        :line_row,
        :th,
        :td,
        :td_num,
        :totals,
        :totals_row,
        :totals_label,
        :totals_value,
        :footer,
        :footer_line,
        :cta_button,
        :heading,
        :body
      ]

      for key <- keys do
        result = Accrue.Invoices.Styles.for(key, branding)
        assert is_binary(result), "expected binary for #{inspect(key)}"
        assert byte_size(result) > 0, "expected non-empty string for #{inspect(key)}"
      end
    end

    test "interpolates accent_color into :th" do
      branding = [accent_color: "#123456", secondary_color: "#6B7280", font_stack: "Arial"]
      assert Accrue.Invoices.Styles.for(:th, branding) =~ "#123456"
    end

    test "interpolates accent_color into :cta_button" do
      branding = [accent_color: "#AABBCC", secondary_color: "#6B7280", font_stack: "Arial"]
      assert Accrue.Invoices.Styles.for(:cta_button, branding) =~ "#AABBCC"
    end
  end
end
