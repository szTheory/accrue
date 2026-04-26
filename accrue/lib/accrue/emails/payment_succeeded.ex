defmodule Accrue.Emails.PaymentSucceeded do
  @moduledoc """
  Receipt-style confirmation for a successful payment.
  """

  use Mailglass.Mailable, stream: :transactional
  use Phoenix.Component

  @spec subject(map()) :: String.t()
  def subject(_assigns), do: "Receipt for your payment"

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
      |> to(assigns.customer_email || "customer@example.test")
      |> subject(assigns.subject)
      |> html_body(fn _ -> html(assigns) end)
    end)
    |> Mailglass.Message.put_function(:payment_succeeded)
  end

  def message(assigns) when is_list(assigns), do: message(Map.new(assigns))

  @spec render(map()) :: String.t()
  def render(assigns) when is_map(assigns) do
    {:ok, rendered} = Mailglass.Renderer.render(message(assigns))
    rendered.swoosh_email.html_body
  end

  def render(assigns) when is_list(assigns), do: render(Map.new(assigns))

  @spec render_text(map()) :: String.t()
  def render_text(assigns) when is_map(assigns) do
    {:ok, rendered} = Mailglass.Renderer.render(message(assigns))
    rendered.swoosh_email.text_body
  end

  def render_text(assigns) when is_list(assigns), do: render_text(Map.new(assigns))

  defp html(assigns) do
    assigns = template_assigns(assigns)

    ~H"""
    <Mailglass.Components.Layout.email_layout title={@subject}>
      <.container>
        <.section padding="24px">
          <.heading level={1}>Payment received</.heading>

          <.text>
            Hi {@customer_name}, we received your payment of <strong>{@amount}</strong>
            for invoice <strong>{@invoice_number}</strong>.
          </.text>

          <%= if @receipt_url do %>
            <.button href={@receipt_url}>View receipt</.button>
          <% end %>

          <.text tone="slate">
            If you have questions, reply to this email.
          </.text>

          <.text>
            — The {@business_name} team
          </.text>
        </.section>
      </.container>
    </Mailglass.Components.Layout.email_layout>
    """
  end

  defp template_assigns(assigns) do
    context = normalize_map(map_get(assigns, :context) || %{})

    branding =
      normalize_map(
        map_get(context, :branding) || map_get(assigns, :branding) || Accrue.Config.branding()
      )

    customer_name =
      map_get(assigns, :customer_name) ||
        map_get(context, :customer_name) ||
        map_get(map_get(context, :customer) || %{}, :name) ||
        "there"

    amount = map_get(assigns, :amount) || map_get(context, :formatted_total) || "$0.00"

    invoice_number =
      map_get(assigns, :invoice_number) ||
        map_get(map_get(context, :invoice) || %{}, :number) ||
        "unknown"

    receipt_url =
      map_get(assigns, :receipt_url) ||
        map_get(map_get(context, :invoice) || %{}, :hosted_invoice_url)

    business_name = map_get(branding, :business_name) || "Accrue"

    %{
      context: Map.put_new(context, :branding, branding),
      branding: branding,
      customer_name: customer_name,
      amount: amount,
      invoice_number: invoice_number,
      receipt_url: receipt_url,
      business_name: business_name,
      customer_email:
        map_get(assigns, :customer_email) || map_get(map_get(context, :customer) || %{}, :email),
      subject: subject(assigns)
    }
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
