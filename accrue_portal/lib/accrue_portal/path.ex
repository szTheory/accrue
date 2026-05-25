defmodule AccruePortal.Path do
  @moduledoc false

  def home(base), do: base
  def subscriptions(base), do: base <> "/subscriptions"
  def payment_methods(base), do: base <> "/payment-methods"
  def payment_methods_new(base), do: base <> "/payment-methods/new"
  def invoices(base), do: base <> "/invoices"
  def checkout(base, token), do: base <> "/checkout/" <> token
  def payment_method_default(base, id), do: base <> "/payment-methods/" <> id <> "/default"
  def payment_method_delete(base, id), do: base <> "/payment-methods/" <> id <> "/delete"
  def checkout_complete(base, token), do: base <> "/checkout/" <> token <> "/complete"
end
