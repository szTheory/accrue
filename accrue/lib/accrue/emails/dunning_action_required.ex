defmodule Accrue.Emails.DunningActionRequired do
  @moduledoc """
  Dunning step-2 ("action required") email — D-01, D-02.

  The firmer second touch in the default dunning campaign (`after_days: 5`).
  The first payment retry has still failed; this email names the consequence
  (loss of access) and an approximate cutoff date, and deep-links the portal
  update-payment-method flow via the `@update_pm_url` CTA. Carries no invoice
  PDF (only `:invoice_finalized`/`:invoice_paid` attach one).

  Clones the `Accrue.Emails.CardExpiringSoon` Mailglass + `Phoenix.Component`
  convention. The new atom `:dunning_action_required` is the published-API
  commitment (resolved via `Accrue.Workers.Mailer.default_template/1`).
  """

  use Mailglass.Mailable, stream: :transactional
  use Phoenix.Component

  @spec subject(map()) :: String.t()
  def subject(assigns) when is_map(assigns) do
    branding = branding(assigns)

    case map_get(branding, :business_name) do
      nil -> "Action required: update your payment method"
      business_name -> "Action required: update your payment method for #{business_name}"
    end
  end

  def subject(_), do: "Action required: update your payment method"

  @spec message(map()) :: Mailglass.Message.t()
  def message(assigns) when is_map(assigns) do
    assigns = template_assigns(assigns)

    new()
    |> from(
      {map_get(assigns.branding, :from_name) || "Acme Billing",
       map_get(assigns.branding, :from_email) || "billing@example.test"}
    )
    |> to(assigns.customer_email || assigns.to || map_get(assigns.customer, :email) || "")
    |> subject(assigns.subject)
    |> html_body(html(assigns) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary())
    |> Mailglass.Message.put_function(:dunning_action_required)
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
          <.heading level={1}>Your payment is still failing</.heading>

          <.text>
            Hi {@customer.name || "there"}, we still couldn't process your payment at
            {@branding.business_name}. Update your card now to avoid losing access to your
            subscription. If payment keeps failing, your account may be suspended in the
            coming days.
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

    %{
      context:
        context
        |> Map.put_new(:branding, branding)
        |> Map.put_new(:customer, customer)
        |> Map.put_new(:timezone, map_get(assigns, :timezone) || "Etc/UTC"),
      branding: branding,
      customer: customer,
      subject: subject(assigns),
      customer_email: map_get(customer, :email),
      to: map_get(assigns, :to) || map_get(assigns, "to"),
      update_pm_url: map_get(context, :update_pm_url) || map_get(assigns, :update_pm_url)
    }
  end

  defp context(assigns), do: map_get(assigns, :context) || %{}

  defp branding(assigns) do
    context = context(assigns)
    map_get(context, :branding) || map_get(assigns, :branding) || Accrue.Config.branding()
  end

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
