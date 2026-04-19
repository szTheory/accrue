defmodule Accrue.Invoices.Render do
  @moduledoc """
  Invoice render orchestration — builds a single `RenderContext` and
  exposes format-helper functions shared by the email + PDF pipelines.

  ## Contract

  `build_assigns/2` is the ONE point of entry. It:

    1. Loads the invoice (+ preloads items + customer) if given an id.
    2. Freezes `Accrue.Config.branding/0` into the struct ONCE (Pitfall 8).
    3. Resolves locale and timezone via the configured precedence ladder:
       `opts > customer column > "en" / "Etc/UTC"`.
    4. Pre-computes every `formatted_*` string via `format_money/3` and
       `format_datetime/3` so templates never call CLDR directly.

  ## Fail-safe locale + timezone (Pitfall 5)

  Both `format_money/3` and `format_datetime/3` wrap their underlying
  calls in `try`/`rescue`. On failure they emit a telemetry event and
  retry with the safe fallback (`"en"` / `"Etc/UTC"`); they NEVER raise.
  This keeps a bad `preferred_locale` or `preferred_timezone` string on
  a single customer from breaking the entire email pipeline (one poison
  row stays isolated).

  Events emitted:

    * `[:accrue, :email, :locale_fallback]` — metadata
      `%{requested: locale, currency: currency}` (no PII)
    * `[:accrue, :email, :timezone_fallback]` — metadata
      `%{requested: timezone}`
    * `[:accrue, :email, :format_money_failed]` — metadata
      `%{requested: locale, currency: currency}` (second-attempt failure)
  """

  alias Accrue.Billing.Invoice
  alias Accrue.Invoices.RenderContext

  @type opts :: [
          locale: String.t() | nil,
          timezone: String.t() | nil,
          customer: term() | nil,
          now: DateTime.t() | nil
        ]

  @doc """
  Builds a `RenderContext` from an `Invoice` struct or an invoice id.

  `opts`:
    * `:locale` — overrides customer.preferred_locale
    * `:timezone` — overrides customer.preferred_timezone
    * `:customer` — pre-loaded customer, skipping the Repo fetch
    * `:now` — pin the "issued at" timestamp (defaults to `DateTime.utc_now/0`)
  """
  @spec build_assigns(Invoice.t() | String.t(), opts()) :: RenderContext.t()
  def build_assigns(invoice_or_id, opts \\ []) do
    invoice = load_invoice(invoice_or_id)
    customer = Keyword.get(opts, :customer) || load_customer(invoice)

    # FREEZE POINT — Pitfall 8. Do not re-read Config.branding/0 downstream.
    branding = Accrue.Config.branding()

    locale = resolve_locale(opts, customer)
    timezone = resolve_timezone(opts, customer)
    currency = currency_atom(invoice.currency)
    now = Keyword.get(opts, :now) || DateTime.utc_now()

    subtotal = invoice.subtotal_minor
    discount = invoice.discount_minor
    tax = invoice.tax_minor
    total = invoice.total_minor

    issued_at = invoice.finalized_at || now

    %RenderContext{
      invoice: invoice,
      customer: customer,
      line_items: invoice_items(invoice),
      subtotal_minor: subtotal,
      discount_minor: discount,
      tax_minor: tax,
      total_minor: total,
      currency: currency,
      branding: branding,
      locale: locale,
      timezone: timezone,
      now: now,
      hosted_invoice_url: invoice.hosted_url,
      receipt_url: nil,
      formatted_total: format_money_opt(total, currency, locale),
      formatted_subtotal: format_money_opt(subtotal, currency, locale),
      formatted_discount: format_money_opt(discount, currency, locale),
      formatted_tax: format_money_opt(tax, currency, locale),
      formatted_issued_at: format_datetime(issued_at, timezone, locale)
    }
  end

  @doc """
  Formats an integer minor-unit amount into a human-readable currency
  string using the given locale.

  NEVER raises — on unknown locale/currency it emits a telemetry
  fallback event and retries with `"en"`; on second failure it emits a
  hard-failure event and returns a raw fallback like `"1000 usd"`.
  """
  @spec format_money(integer(), atom(), String.t()) :: String.t()
  def format_money(amount_minor, currency, locale)
      when is_integer(amount_minor) and is_atom(currency) and is_binary(locale) do
    try do
      do_format_money(amount_minor, currency, locale)
    rescue
      _error ->
        :telemetry.execute(
          [:accrue, :email, :locale_fallback],
          %{count: 1},
          %{requested: locale, currency: currency}
        )

        try do
          do_format_money(amount_minor, currency, "en")
        rescue
          _error2 ->
            :telemetry.execute(
              [:accrue, :email, :format_money_failed],
              %{count: 1},
              %{requested: locale, currency: currency}
            )

            raw_money_string(amount_minor, currency)
        end
    end
  end

  @doc """
  Formats a `DateTime` into a human-readable string in `timezone`.

  On timezone shift failure (unknown TZ or missing tzdata), emits
  `[:accrue, :email, :timezone_fallback]` and retries with `"Etc/UTC"`.
  Locale is accepted for forward-compatibility but v1.0 uses
  `Calendar.strftime/2` (en-only) — hosts override via a custom
  formatter in a future release.
  """
  @spec format_datetime(DateTime.t() | nil, String.t(), String.t()) :: String.t() | nil
  def format_datetime(nil, _timezone, _locale), do: nil

  def format_datetime(%DateTime{} = dt, timezone, _locale)
      when is_binary(timezone) do
    shifted =
      try do
        case DateTime.shift_zone(dt, timezone) do
          {:ok, in_zone} ->
            in_zone

          {:error, _reason} ->
            :telemetry.execute(
              [:accrue, :email, :timezone_fallback],
              %{count: 1},
              %{requested: timezone}
            )

            dt
        end
      rescue
        _error ->
          :telemetry.execute(
            [:accrue, :email, :timezone_fallback],
            %{count: 1},
            %{requested: timezone}
          )

          dt
      end

    Calendar.strftime(shifted, "%B %-d, %Y")
  end

  # --- internals ---------------------------------------------------------

  defp format_money_opt(nil, _currency, _locale), do: nil
  defp format_money_opt(amount, currency, locale), do: format_money(amount, currency, locale)

  defp do_format_money(amount_minor, currency, locale) do
    # ex_money expects a Decimal value in the *major* unit shifted from
    # the minor integer via the currency's CLDR iso_digits exponent.
    exponent = currency_exponent!(currency)

    decimal =
      amount_minor
      |> Decimal.new()
      |> Decimal.div(Decimal.new(power_of_10(exponent)))

    money = Money.new!(currency, decimal)

    case Money.to_string(money, locale: locale) do
      {:ok, str} when is_binary(str) ->
        str

      {:error, {exception, msg}} ->
        raise exception, msg
    end
  end

  defp currency_exponent!(currency) do
    case Money.Currency.currency_for_code(currency) do
      {:ok, %{iso_digits: digits}} when is_integer(digits) -> digits
      _ -> raise ArgumentError, "unknown currency: #{inspect(currency)}"
    end
  end

  defp power_of_10(0), do: 1
  defp power_of_10(1), do: 10
  defp power_of_10(2), do: 100
  defp power_of_10(3), do: 1000
  defp power_of_10(n) when is_integer(n) and n > 0, do: Integer.pow(10, n)

  defp raw_money_string(amount_minor, currency) do
    "#{amount_minor} #{currency}"
  end

  defp load_invoice(%Invoice{} = inv), do: preload_items(inv)

  defp load_invoice(id) when is_binary(id) do
    repo = Accrue.Config.get!(:repo)

    case repo.get(Invoice, id) do
      nil -> raise Ecto.NoResultsError, queryable: Invoice
      inv -> preload_items(inv)
    end
  end

  defp preload_items(%Invoice{} = inv) do
    if Ecto.assoc_loaded?(inv.items) do
      inv
    else
      repo = Accrue.Config.get!(:repo)
      repo.preload(inv, :items)
    end
  end

  defp load_customer(%Invoice{customer: %Accrue.Billing.Customer{} = c}), do: c

  defp load_customer(%Invoice{customer_id: nil}), do: nil

  defp load_customer(%Invoice{customer_id: customer_id}) when is_binary(customer_id) do
    repo = Accrue.Config.get!(:repo)
    repo.get(Accrue.Billing.Customer, customer_id)
  end

  defp load_customer(_), do: nil

  # Precedence ladder: opts > customer column > "en"
  defp resolve_locale(opts, customer) do
    Keyword.get(opts, :locale) ||
      maybe_field(customer, :preferred_locale) ||
      "en"
  end

  defp resolve_timezone(opts, customer) do
    Keyword.get(opts, :timezone) ||
      maybe_field(customer, :preferred_timezone) ||
      "Etc/UTC"
  end

  defp maybe_field(nil, _field), do: nil

  defp maybe_field(%{} = struct, field) do
    case Map.get(struct, field) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  defp currency_atom(nil), do: :usd

  defp currency_atom(atom) when is_atom(atom), do: atom

  defp currency_atom(bin) when is_binary(bin) do
    # Use to_existing_atom only — never create new atoms from untrusted
    # input (guard against oversized atom tables).
    try do
      String.to_existing_atom(String.downcase(bin))
    rescue
      ArgumentError -> :usd
    end
  end

  defp invoice_items(%Invoice{items: items}) when is_list(items), do: items
  defp invoice_items(_), do: []
end
