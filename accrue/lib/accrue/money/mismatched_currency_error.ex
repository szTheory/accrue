defmodule Accrue.Money.MismatchedCurrencyError do
  @moduledoc """
  Raised when `Accrue.Money` arithmetic is attempted across two different
  currencies. Per D-04, cross-currency math never silently coerces or returns
  a tagged tuple — it raises at the call site so the bug surfaces immediately.
  """

  defexception [:left, :right, :message]

  @impl true
  def exception(opts) do
    left = Keyword.fetch!(opts, :left)
    right = Keyword.fetch!(opts, :right)

    message =
      Keyword.get(
        opts,
        :message,
        "cannot combine #{inspect(left)} and #{inspect(right)} — currencies differ"
      )

    %__MODULE__{left: left, right: right, message: message}
  end
end
