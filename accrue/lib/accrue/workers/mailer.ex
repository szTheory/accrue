defmodule Accrue.Workers.Mailer do
  @moduledoc """
  Oban worker that delivers a transactional email asynchronously.

  ## Flow

  1. `Accrue.Mailer.Default.deliver/2` enqueues a job with string-keyed
     `%{"type" => "...", "assigns" => %{...}}` args (Oban-safe scalars only).
  2. `perform/1` rehydrates the assigns (locale/timezone/customer hydration
     via `enrich/2`), resolves the template module (honoring `:email_overrides`
     rung 2 MFA and rung 3 atom), builds a `%Swoosh.Email{}`, and
     delivers via `Accrue.Mailer.Swoosh`.

  ## Queue

  Host applications MUST configure an Oban queue named `:accrue_mailers`.
  Recommended concurrency: 20.

  ## Pitfall 7 defense

  `unique: [period: 60, fields: [:args, :worker]]` prevents double-dispatch
  when both a Billing action AND a webhook reducer try to enqueue the same
  email within 60s. DO NOT TOUCH this option — it's the only guard against
  the action+webhook duplication pitfall.
  """

  use Oban.Worker,
    queue: :accrue_mailers,
    max_attempts: 5,
    unique: [period: 60, fields: [:args, :worker]]

  # Phase 6 Plans 05 + 06 create these modules; listing them here silences
  # `mix compile --warnings-as-errors` on the forward references in
  # `default_template/1`. When Plans 05/06 land, this attribute becomes a
  # no-op (safe to leave in place).
  @compile {:no_warn_undefined,
            [
              Accrue.Emails.Receipt,
              Accrue.Emails.PaymentFailed,
              Accrue.Emails.TrialEnding,
              Accrue.Emails.TrialEnded,
              Accrue.Emails.InvoiceFinalized,
              Accrue.Emails.InvoicePaid,
              Accrue.Emails.InvoicePaymentFailed,
              Accrue.Emails.SubscriptionCanceled,
              Accrue.Emails.SubscriptionPaused,
              Accrue.Emails.SubscriptionResumed,
              Accrue.Emails.RefundIssued,
              Accrue.Emails.CouponApplied,
              Accrue.Emails.CardExpiringSoon
            ]}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type_str, "assigns" => assigns}}) do
    type = String.to_existing_atom(type_str)
    template_mod = resolve_template(type)
    enriched = enrich(type, assigns)
    # Phoenix.HTML.Engine (used by mjml_eex) fetches atom keys out of the
    # assigns, so we atomize before handing to the template module. Keys
    # came from Oban JSON round-trip as strings — we only atomize keys
    # that already exist as atoms in the VM (the template fields) to keep
    # this safe against untrusted input.
    atomized = atomize_known_keys(enriched)

    recipient = atomized[:to] || enriched["to"]

    if is_nil(recipient) or recipient == "" do
      {:cancel, :missing_recipient}
    else
      deliver_email(type, template_mod, atomized, recipient)
    end
  end

  defp deliver_email(type, template_mod, atomized, recipient) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(recipient)
      |> Swoosh.Email.from(
        {Accrue.Config.branding(:from_name), Accrue.Config.branding(:from_email)}
      )
      |> maybe_reply_to(Accrue.Config.branding(:reply_to_email))
      |> Swoosh.Email.subject(template_mod.subject(atomized))
      |> Swoosh.Email.html_body(template_mod.render(atomized))
      |> Swoosh.Email.text_body(template_mod.render_text(atomized))

    email =
      if needs_pdf?(type) do
        maybe_attach_pdf(email, atomized, type)
      else
        email
      end

    case Accrue.Mailer.Swoosh.deliver(email) do
      {:ok, _} = ok -> ok
      {:error, _} = err -> err
    end
  end

  @doc """
  Resolves the template module for an email type. Honors `:email_overrides`
  (Pay-style ladder D-23):

    * Rung 2 (MFA): `{Mod, :fun, args}` calls `Mod.fun(type, *args)` at
      runtime, letting hosts pick a template dynamically based on request-
      time context. The type atom is prepended to `args` as the first
      argument so MFA callbacks receive it.
    * Rung 3 (atom): `YourModule` replaces the default template module.
    * No override: falls through to `default_template/1`.
  """
  @spec resolve_template(atom()) :: module()
  def resolve_template(type) when is_atom(type) do
    overrides = Application.get_env(:accrue, :email_overrides, [])

    case Keyword.fetch(overrides, type) do
      {:ok, {mod, fun, args}}
      when is_atom(mod) and is_atom(fun) and is_list(args) ->
        apply(mod, fun, [type | args])

      {:ok, mod} when is_atom(mod) and not is_nil(mod) ->
        mod

      :error ->
        default_template(type)
    end
  end

  @doc """
  Public accessor for the default template module for a given email
  type. Used by `mix accrue.mail.preview` (D6-08) and by tests. Honors
  the full 13-type catalogue plus the `:payment_succeeded` legacy alias.
  """
  @spec template_for(atom()) :: module()
  def template_for(type) when is_atom(type), do: default_template(type)

  # Apply branding.reply_to_email when configured. No-op on nil so hosts
  # that don't set it fall through cleanly.
  defp maybe_reply_to(email, nil), do: email

  defp maybe_reply_to(email, reply_to) when is_binary(reply_to) and reply_to != "",
    do: Swoosh.Email.reply_to(email, reply_to)

  defp maybe_reply_to(email, _), do: email

  # Types that carry an invoice PDF attachment.
  defp needs_pdf?(:invoice_finalized), do: true
  defp needs_pdf?(:invoice_paid), do: true
  defp needs_pdf?(_), do: false

  # Builds a PDF via Accrue.Billing.render_invoice_pdf/2 and either
  # attaches it to the email, falls through to a hosted_invoice_url
  # note (terminal PDF errors), or re-raises Accrue.PDF.RenderFailed
  # so Oban backoff retries transient render errors.
  defp maybe_attach_pdf(email, assigns, type) do
    invoice_id =
      assigns[:invoice_id] ||
        case assigns[:invoice] do
          %{id: id} -> id
          %{"id" => id} -> id
          _ -> nil
        end

    case safe_render_invoice_pdf(invoice_id, assigns) do
      {:ok, binary} ->
        filename =
          "invoice-#{assigns[:invoice_number] || invoice_id || "unknown"}.pdf"

        Swoosh.Email.attachment(
          email,
          Swoosh.Attachment.new({:data, binary},
            filename: filename,
            content_type: "application/pdf"
          )
        )

      {:error, %Accrue.Error.PdfDisabled{}} ->
        append_hosted_url_note(email, assigns, type)

      {:error, :chromic_pdf_not_started} ->
        :telemetry.execute(
          [:accrue, :ops, :pdf_adapter_unavailable],
          %{count: 1},
          %{type: type}
        )

        append_hosted_url_note(email, assigns, type)

      {:error, reason} ->
        raise Accrue.PDF.RenderFailed, reason: reason
    end
  end

  # Missing invoice_id is treated as a terminal config error, not a
  # transient — surface via PdfDisabled so the fallback path kicks in.
  defp safe_render_invoice_pdf(nil, _assigns) do
    {:error,
     %Accrue.Error.PdfDisabled{
       reason: :missing_invoice_id,
       message: "cannot render invoice PDF without assigns[:invoice_id]"
     }}
  end

  defp safe_render_invoice_pdf(invoice_id, assigns) do
    Accrue.Billing.render_invoice_pdf(invoice_id,
      locale: assigns[:locale],
      timezone: assigns[:timezone]
    )
  end

  defp append_hosted_url_note(email, assigns, _type) do
    url =
      case assigns[:invoice] do
        %{hosted_invoice_url: u} when is_binary(u) and u != "" -> u
        %{"hosted_invoice_url" => u} when is_binary(u) and u != "" -> u
        _ -> assigns[:hosted_invoice_url]
      end

    if is_binary(url) and url != "" do
      new_text =
        (email.text_body || "") <>
          "\n\nView your invoice online: " <> url

      safe_url =
        url
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()

      new_html =
        (email.html_body || "") <>
          ~s(<p><a href="#{safe_url}">View your invoice online</a></p>)

      email
      |> Swoosh.Email.text_body(new_text)
      |> Swoosh.Email.html_body(new_html)
    else
      email
    end
  end

  # Full 13-type catalogue + :payment_succeeded legacy alias (Phase 6 MAIL-03..13).
  # Ordered by frequency: receipt → payment_failed → invoice_* etc. so the
  # most-common types match earliest in the pattern-match chain.
  defp default_template(:receipt), do: Accrue.Emails.Receipt
  defp default_template(:payment_failed), do: Accrue.Emails.PaymentFailed
  defp default_template(:trial_ending), do: Accrue.Emails.TrialEnding
  defp default_template(:trial_ended), do: Accrue.Emails.TrialEnded
  defp default_template(:invoice_finalized), do: Accrue.Emails.InvoiceFinalized
  defp default_template(:invoice_paid), do: Accrue.Emails.InvoicePaid
  defp default_template(:invoice_payment_failed), do: Accrue.Emails.InvoicePaymentFailed
  defp default_template(:subscription_canceled), do: Accrue.Emails.SubscriptionCanceled
  defp default_template(:subscription_paused), do: Accrue.Emails.SubscriptionPaused
  defp default_template(:subscription_resumed), do: Accrue.Emails.SubscriptionResumed
  defp default_template(:refund_issued), do: Accrue.Emails.RefundIssued
  defp default_template(:coupon_applied), do: Accrue.Emails.CouponApplied
  defp default_template(:card_expiring_soon), do: Accrue.Emails.CardExpiringSoon
  defp default_template(:payment_succeeded), do: Accrue.Emails.PaymentSucceeded

  @doc """
  Enriches raw Oban-arg assigns with locale, timezone, and (optionally)
  the hydrated `Accrue.Billing.Customer` struct (D6-03 precedence ladder).

  Precedence for locale:

    1. `assigns[:locale]` / `assigns["locale"]`
    2. `customer.preferred_locale` (hydrated via `assigns[:customer_id]`)
    3. `Accrue.Config.default_locale/0`
    4. Hardcoded `"en"` fallback

  Same ladder for timezone (swap `preferred_timezone` +
  `Accrue.Config.default_timezone/0` + `"Etc/UTC"`).

  Unknown locales/zones emit `[:accrue, :email, :locale_fallback]` /
  `[:accrue, :email, :timezone_fallback]` telemetry with
  `%{requested: value}` metadata (no PII) and fall back to `"en"` /
  `"Etc/UTC"`. `enrich/2` NEVER raises — pitfall 5 defense.
  """
  @spec enrich(atom(), map()) :: map()
  def enrich(_type, assigns) when is_map(assigns) do
    customer = maybe_load_customer(assigns)

    locale =
      Map.get(assigns, :locale) || Map.get(assigns, "locale") ||
        (customer && customer.preferred_locale) ||
        safe_config(:default_locale, "en")

    timezone =
      Map.get(assigns, :timezone) || Map.get(assigns, "timezone") ||
        (customer && customer.preferred_timezone) ||
        safe_config(:default_timezone, "Etc/UTC")

    {resolved_locale, resolved_tz} = safe_locale_timezone(locale, timezone)

    to =
      Map.get(assigns, :to) || Map.get(assigns, "to") ||
        (customer && Map.get(customer, :email))

    assigns
    |> Map.put(:locale, resolved_locale)
    |> Map.put(:timezone, resolved_tz)
    |> Map.put(:customer, customer)
    |> Map.put(:to, to)
  end

  # Hydrate the Customer struct from the DB via `assigns[:customer_id]`.
  # Returns nil on any failure (missing id, bad id, DB error, schema
  # mismatch) — enrich/2 then proceeds with application-default locale/TZ.
  # Keeping this best-effort means enrich/2 stays total.
  defp maybe_load_customer(assigns) do
    customer_id = Map.get(assigns, :customer_id) || Map.get(assigns, "customer_id")

    if is_binary(customer_id) and customer_id != "" do
      try do
        Accrue.Repo.get(Accrue.Billing.Customer, customer_id)
      rescue
        _ -> nil
      catch
        _, _ -> nil
      end
    else
      nil
    end
  end

  # Read an Accrue.Config key tolerantly. If the key is not in the schema
  # (older host app, misconfig) return the hard default rather than let
  # `Accrue.ConfigError` escape into enrich/2 — pitfall 5 no-raise rule.
  defp safe_config(key, fallback) do
    try do
      Accrue.Config.get!(key) || fallback
    rescue
      _ -> fallback
    end
  end

  # Validates a locale + timezone pair and returns a safe substitute on
  # failure. Emits telemetry on every fallback path so SREs can catch
  # silent locale drift. Metadata is `%{requested: value}` only — no
  # customer_id, email, or amount leaks through.
  defp safe_locale_timezone(locale, timezone) do
    resolved_locale =
      try do
        _ = Cldr.Locale.new!(to_string(locale), Accrue.Config.cldr_backend())
        to_string(locale)
      rescue
        _ ->
          :telemetry.execute(
            [:accrue, :email, :locale_fallback],
            %{count: 1},
            %{requested: locale}
          )

          "en"
      end

    resolved_tz =
      try do
        _ = DateTime.shift_zone!(DateTime.utc_now(), to_string(timezone))
        to_string(timezone)
      rescue
        _ ->
          :telemetry.execute(
            [:accrue, :email, :timezone_fallback],
            %{count: 1},
            %{requested: timezone}
          )

          "Etc/UTC"
      end

    {resolved_locale, resolved_tz}
  end

  # Converts string keys to atoms ONLY when the atom already exists in the
  # VM (via `String.to_existing_atom/1`). Unknown strings are dropped from
  # the atom-keyed view but preserved in the original map — safe against
  # atom-table exhaustion for untrusted input. DO NOT replace with
  # `String.to_atom/1`.
  defp atomize_known_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {k, v}, acc when is_atom(k) ->
        Map.put(acc, k, v)

      {k, v}, acc when is_binary(k) ->
        try do
          Map.put(acc, String.to_existing_atom(k), v)
        rescue
          ArgumentError -> acc
        end
    end)
  end
end
