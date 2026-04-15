defmodule Accrue.Emails.MultipartCoverageTest do
  @moduledoc """
  MAIL-15 multipart guard — every registered non-invoice email type in
  Plan 06-05 must export `subject/1`, `render/1`, and `render_text/1`
  and return non-empty binaries for a minimal context fixture.

  Also enforces D6-07 (no opt-out line in transactional emails) as a
  library-wide invariant across all 8 types.

  Dispatch uses `Accrue.Workers.Mailer.resolve_template/1` (public
  fall-through to the private `default_template/1` catalogue) so this
  test does not require exposing the default map.
  """

  use ExUnit.Case, async: true

  @types [
    :receipt,
    :payment_failed,
    :trial_ending,
    :trial_ended,
    :subscription_canceled,
    :subscription_paused,
    :subscription_resumed,
    :card_expiring_soon
  ]

  setup do
    context = %{
      branding: [
        business_name: "Acme",
        from_email: "no-reply@acme.test",
        support_email: "support@acme.test",
        font_stack: "Helvetica, Arial, sans-serif",
        logo_url: nil,
        company_address: nil,
        accent_color: "#1F6FEB",
        secondary_color: "#6B7280"
      ],
      customer: %{name: "Jo", email: "jo@acme.test"},
      invoice: %{number: "INV-1"},
      subscription: %{id: "sub_1", current_period_end: "2026-05-01"},
      formatted_total: "$10.00"
    }

    assigns = %{
      context: context,
      subject: "Test",
      preview: "Test preview",
      days_until_end: 3,
      brand: "visa",
      last4: "4242",
      exp_month: 12,
      exp_year: 2030,
      pause_behavior: "keep_as_draft",
      cta_url: "https://acme.test/billing",
      update_pm_url: "https://acme.test/pm"
    }

    {:ok, assigns: assigns}
  end

  for type <- @types do
    test "#{type} exports subject + render + render_text returning non-empty binaries",
         %{assigns: assigns} do
      type = unquote(type)
      module = Accrue.Workers.Mailer.resolve_template(type)

      assert is_atom(module) and not is_nil(module),
             "resolve_template(#{inspect(type)}) did not return a module"

      assert Code.ensure_loaded?(module)
      assert function_exported?(module, :subject, 1)
      assert function_exported?(module, :render, 1)
      assert function_exported?(module, :render_text, 1)

      subject = module.subject(assigns)
      html = module.render(assigns)
      text = module.render_text(assigns)

      assert is_binary(subject) and byte_size(subject) > 0,
             "#{inspect(type)} subject empty"

      assert is_binary(html) and byte_size(html) > 0,
             "#{inspect(type)} html empty"

      assert is_binary(text) and byte_size(text) > 0,
             "#{inspect(type)} text empty"

      assert html =~ ~r/<html|<!DOCTYPE/i,
             "#{inspect(type)} HTML body does not look like HTML"

      refute text =~ ~r/<html|<body|<script/i,
             "#{inspect(type)} plain text contains HTML tags"

      refute String.downcase(text) =~ "unsubscribe",
             "D6-07 violation: unsubscribe text in #{inspect(type)}"

      refute String.downcase(html) =~ "unsubscribe",
             "D6-07 violation: unsubscribe text in #{inspect(type)}"
    end
  end
end
