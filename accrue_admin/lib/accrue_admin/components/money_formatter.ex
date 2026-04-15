defmodule AccrueAdmin.Components.MoneyFormatter do
  @moduledoc """
  Shared locale-aware money display for admin pages.
  """

  use Phoenix.Component

  alias Accrue.Invoices.Render
  alias Accrue.Money

  attr(:money, :any, default: nil)
  attr(:amount_minor, :integer, default: nil)
  attr(:currency, :any, default: nil)
  attr(:locale, :string, default: nil)
  attr(:customer, :map, default: nil)
  attr(:class, :string, default: nil)

  def money_formatter(assigns) do
    assigns = assign(assigns, :formatted_money, formatted_money(assigns))

    ~H"""
    <span class={["ax-money", @class]} data-locale={resolved_locale(@locale, @customer)}>
      <%= @formatted_money %>
    </span>
    """
  end

  defp formatted_money(assigns) do
    with {:ok, amount_minor, currency} <- resolve_money(assigns) do
      Render.format_money(amount_minor, currency, resolved_locale(assigns.locale, assigns.customer))
    else
      _ -> "--"
    end
  end

  defp resolve_money(%{money: %Money{amount_minor: amount_minor, currency: currency}}),
    do: {:ok, amount_minor, currency}

  defp resolve_money(%{amount_minor: amount_minor, currency: currency})
       when is_integer(amount_minor) do
    case normalize_currency(currency) do
      nil -> :error
      normalized -> {:ok, amount_minor, normalized}
    end
  end

  defp resolve_money(_assigns), do: :error

  defp normalize_currency(currency) when is_atom(currency), do: currency

  defp normalize_currency(currency) when is_binary(currency) do
    code = String.downcase(currency)

    try do
      String.to_existing_atom(code)
    rescue
      ArgumentError -> nil
    end
  end

  defp normalize_currency(_currency), do: nil

  defp resolved_locale(locale, customer) do
    locale ||
      customer_locale(customer) ||
      Accrue.Config.default_locale()
  end

  defp customer_locale(%{preferred_locale: locale}) when is_binary(locale) and locale != "", do: locale
  defp customer_locale(_customer), do: nil
end
