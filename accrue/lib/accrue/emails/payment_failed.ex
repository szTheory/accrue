defmodule Accrue.Emails.PaymentFailed do
  @moduledoc """
  Canonical payment-failed email.

  Mailglass-backed proof-of-concept port that preserves the adopter-visible
  retry guidance and CTA semantics.
  """

  use Mailglass.Mailable, stream: :transactional
  use Phoenix.Component

  @spec subject(map()) :: String.t()
  def subject(assigns) when is_map(assigns) do
    branding = branding(assigns)

    case map_get(branding, :business_name) do
      nil -> "Action required: payment failed"
      business_name -> "Action required: payment failed at #{business_name}"
    end
  end

  def subject(_), do: "Action required: payment failed"

  @spec message(map()) :: Mailglass.Message.t()
  def message(assigns) when is_map(assigns) do
    assigns = template_assigns(assigns)

    new()
    |> Mailglass.Message.update_swoosh(fn email ->
      email
      |> from({map_get(assigns.branding, :from_name) || "Acme Billing", map_get(assigns.branding, :from_email) || "billing@example.test"})
      |> to(assigns.customer_email || assigns.to || map_get(assigns.customer, :email) || "")
      |> subject(assigns.subject)
      |> html_body(fn _ -> html(assigns) end)
    end)
    |> Mailglass.Message.put_function(:payment_failed)
  end

  @spec render(map()) :: String.t()
  def render(assigns) when is_map(assigns) do
    {:ok, rendered} = Mailglass.Renderer.render(message(assigns))
    rendered.swoosh_email.html_body
  end

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    {:ok, rendered} = Mailglass.Renderer.render(message(assigns))
    rendered.swoosh_email.text_body
  end

  defp html(assigns) do
    assigns = template_assigns(assigns)

    ~H"""
    <Mailglass.Components.Layout.email_layout title={@subject}>
      <.container>
        <.section padding="24px 24px 8px 24px">
          <%= if @branding.logo_url do %>
            <.img src={@branding.logo_url} alt={@branding.business_name} width={180} />
          <% else %>
            <.text size="lg" tone="ink"><strong>{@branding.business_name}</strong></.text>
          <% end %>
        </.section>

        <.section padding="0 24px">
          <.heading level={1}>Payment failed</.heading>

          <.text>
            Hi {@customer.name || "there"}, your payment of
            <strong>{@formatted_total}</strong> for invoice
            <strong>{@invoice.number || @charge_id || "unknown"}</strong> could
            not be processed. To keep your subscription active, please update
            your payment method. We'll automatically retry once you do.
          </.text>

          <%= if @update_pm_url do %>
            <.button href={@update_pm_url}>Update payment method</.button>
          <% end %>
        </.section>

        <.section padding="0 24px 24px 24px">
          <Accrue.Invoices.Components.footer context={@context} />
        </.section>
      </.container>
    </Mailglass.Components.Layout.email_layout>
    """
  end

  defp template_assigns(assigns) do
    context = normalize_map(context(assigns))
    branding = normalize_map(branding(assigns))
    customer = normalize_map(map_get(context, :customer) || map_get(assigns, :customer) || %{})
    invoice = normalize_map(map_get(context, :invoice) || map_get(assigns, :invoice) || %{})
    charge = load_charge(assigns)
    locale = map_get(context, :locale) || map_get(assigns, :locale) || "en"

    formatted_total =
      map_get(context, :formatted_total) ||
        map_get(assigns, :formatted_total) ||
        formatted_total(charge, locale)

    invoice_number =
      map_get(invoice, :number) ||
        map_get(assigns, :invoice_number) ||
        map_get(assigns, :charge_id) ||
        "unknown"

    context =
      context
      |> Map.put_new(:branding, branding)
      |> Map.put_new(:customer, customer)
      |> Map.put_new(:invoice, Map.put(invoice, :number, invoice_number))
      |> Map.put_new(:formatted_total, formatted_total)
      |> Map.put_new(:locale, locale)
      |> Map.put_new(:timezone, map_get(assigns, :timezone) || "Etc/UTC")

    %{
      context: context,
      branding: branding,
      customer: customer,
      invoice: Map.put(invoice, :number, invoice_number),
      subject: subject(assigns),
      preview: map_get(assigns, :preview) || "Action required: payment failed",
      formatted_total: formatted_total,
      customer_email: map_get(customer, :email),
      to: map_get(assigns, :to) || map_get(assigns, "to"),
      update_pm_url: map_get(context, :update_pm_url) || map_get(assigns, :update_pm_url),
      charge_id: map_get(assigns, :charge_id)
    }
  end

  defp context(assigns), do: map_get(assigns, :context) || %{}

  defp branding(assigns) do
    context = context(assigns)
    map_get(context, :branding) || map_get(assigns, :branding) || Accrue.Config.branding()
  end

  defp load_charge(assigns) do
    case map_get(assigns, :charge_id) do
      nil -> nil
      charge_id -> Accrue.Repo.get_by(Accrue.Billing.Charge, processor_id: charge_id)
    end
  end

  defp formatted_total(%Accrue.Billing.Charge{} = charge, locale) do
    currency = currency_atom(charge.currency)

    Accrue.Invoices.Render.format_money(charge.amount_cents || 0, currency, locale)
  rescue
    _ -> "$0.00"
  end

  defp formatted_total(_, _locale), do: "$0.00"

  defp currency_atom(cur) when is_atom(cur), do: cur

  defp currency_atom(cur) when is_binary(cur) do
    cur
    |> String.upcase()
    |> String.to_existing_atom()
  rescue
    _ -> :usd
  end

  defp currency_atom(_), do: :usd

  defp map_get(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end

  defp map_get(list, key) when is_list(list) do
    Keyword.get(list, key) || Keyword.get(list, to_string(key))
  end

  defp map_get(_map, _key), do: nil

  defp normalize_map(value) when is_list(value), do: Map.new(value)
  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_), do: %{}
end
