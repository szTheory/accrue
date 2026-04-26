defmodule Accrue.Emails.CouponApplied do
  @moduledoc """
  Coupon applied notification.

  Mailglass-backed discount notification.
  """

  use Mailglass.Mailable, stream: :transactional
  use Phoenix.Component

  @spec subject(map()) :: String.t()
  def subject(assigns) when is_map(assigns) do
    coupon = coupon(assigns)
    promotion_code = promotion_code(assigns)

    cond do
      map_get(coupon, :name) ->
        "Discount applied — #{map_get(coupon, :name)}"

      map_get(promotion_code, :code) ->
        "Discount applied — #{map_get(promotion_code, :code)}"

      true ->
        "Discount applied"
    end
  end

  def subject(_), do: "Discount applied"

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
    |> Mailglass.Message.put_function(:coupon_applied)
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
          <.heading level={1}>Discount applied</.heading>

          <.text>
            Hi {@customer.name || "there"}, we've applied a discount to your account:
          </.text>

          <.text>
            <%= cond do %>
              <% @coupon.percent_off -> %>
                <strong>{@coupon.percent_off}% off</strong> via coupon <strong>{@coupon.name}</strong>
              <% @coupon.formatted_amount_off -> %>
                <strong>{@coupon.formatted_amount_off} off</strong> via coupon <strong>{@coupon.name}</strong>
              <% true -> %>
                coupon <strong>{@coupon.name}</strong>
            <% end %>
            <%= if @promotion_code do %>
              (promotion code: <strong>{@promotion_code.code}</strong>)
            <% end %>
          </.text>

          <.text>The discount will appear on your next invoice.</.text>
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
    coupon = normalize_map(map_get(context, :coupon) || map_get(assigns, :coupon) || %{})

    promotion_code =
      normalize_map(map_get(context, :promotion_code) || map_get(assigns, :promotion_code) || %{})

    %{
      context:
        context
        |> Map.put_new(:branding, branding)
        |> Map.put_new(:customer, customer)
        |> Map.put_new(:coupon, coupon)
        |> Map.put_new(:promotion_code, promotion_code)
        |> Map.put_new(:timezone, map_get(assigns, :timezone) || "Etc/UTC"),
      branding: branding,
      customer: customer,
      coupon: coupon,
      promotion_code: promotion_code,
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

  defp coupon(assigns) do
    context = context(assigns)
    map_get(context, :coupon) || map_get(assigns, :coupon) || %{}
  end

  defp promotion_code(assigns) do
    context = context(assigns)
    map_get(context, :promotion_code) || map_get(assigns, :promotion_code) || %{}
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
