defmodule Accrue.Emails.RefundIssued do
  @moduledoc """
  Refund issued notification.

  Mailglass-backed refund notification.
  """

  use Mailglass.Mailable, stream: :transactional
  use Phoenix.Component

  @spec subject(map()) :: String.t()
  def subject(assigns) when is_map(assigns) do
    refund = refund(assigns)
    branding = branding(assigns)

    cond do
      map_get(refund, :formatted_amount) ->
        "Refund issued: #{map_get(refund, :formatted_amount)}"

      map_get(branding, :business_name) ->
        "Refund issued by #{map_get(branding, :business_name)}"

      true ->
        "Refund issued"
    end
  end

  def subject(_), do: "Refund issued"

  @spec message(map()) :: Mailglass.Message.t()
  def message(assigns) when is_map(assigns) do
    assigns = template_assigns(assigns)

    new()
    |> Mailglass.Message.update_swoosh(fn email ->
      email
      |> from(
        {map_get(assigns.branding, :from_name) || "Acme Billing",
         map_get(assigns.branding, :from_email) || "billing@example.test"}
      )
      |> to(assigns.customer_email || assigns.to || map_get(assigns.customer, :email) || "")
      |> subject(assigns.subject)
      |> html_body(fn _ -> html(assigns) end)
    end)
    |> Mailglass.Message.put_function(:refund_issued)
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
          <.heading level={1}>Refund issued</.heading>

          <.text>
            Hi {@customer.name || "there"}, we've issued a refund of
            <strong>{@refund.formatted_amount}</strong> for charge <strong>{@charge.id}</strong>.
          </.text>

          <.heading level={2}>Fee breakdown</.heading>
          <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td>Refund amount</td>
              <td style="text-align:right;">{@refund.formatted_amount}</td>
            </tr>
            <tr>
              <td>Stripe fee refunded (stripe_fee_refunded_amount)</td>
              <td style="text-align:right;">{@refund.formatted_stripe_fee_refunded}</td>
            </tr>
            <tr>
              <td>Merchant loss (merchant_loss_amount)</td>
              <td style="text-align:right;">{@refund.formatted_merchant_loss}</td>
            </tr>
          </table>
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
    refund = normalize_map(map_get(context, :refund) || map_get(assigns, :refund) || %{})
    charge = normalize_map(map_get(context, :charge) || map_get(assigns, :charge) || %{})

    %{
      context:
        context
        |> Map.put_new(:branding, branding)
        |> Map.put_new(:customer, customer)
        |> Map.put_new(:refund, refund)
        |> Map.put_new(:charge, charge)
        |> Map.put_new(:timezone, map_get(assigns, :timezone) || "Etc/UTC"),
      branding: branding,
      customer: customer,
      refund: refund,
      charge: charge,
      subject: subject(assigns),
      customer_email: map_get(customer, :email),
      to: map_get(assigns, :to) || map_get(assigns, "to")
    }
  end

  defp context(assigns), do: map_get(assigns, :context) || %{}

  defp branding(assigns) do
    context = context(assigns)
    map_get(context, :branding) || map_get(assigns, :branding) || Accrue.Config.branding()
  end

  defp refund(assigns) do
    context = context(assigns)
    map_get(context, :refund) || map_get(assigns, :refund) || %{}
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
