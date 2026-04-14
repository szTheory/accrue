defmodule Accrue.Billing.PaymentMethodActions do
  @moduledoc false
  # Phase 3 Wave 2 (Plan 06) fills this module in.

  defmodule NotImplementedError do
    @moduledoc false
    defexception [:function]

    @impl true
    def message(%{function: fun}),
      do: "Accrue.Billing.PaymentMethodActions.#{fun} is implemented in Phase 3 Plan 06"
  end

  defp not_implemented!(fun), do: raise(NotImplementedError, function: fun)

  def attach_payment_method(_customer, _pm_id_or_opts, _opts \\ []),
    do: not_implemented!("attach_payment_method/3")

  def attach_payment_method!(_customer, _pm_id_or_opts, _opts \\ []),
    do: not_implemented!("attach_payment_method!/3")

  def detach_payment_method(_payment_method, _opts \\ []),
    do: not_implemented!("detach_payment_method/2")

  def detach_payment_method!(_payment_method, _opts \\ []),
    do: not_implemented!("detach_payment_method!/2")

  def set_default_payment_method(_customer, _pm_id, _opts \\ []),
    do: not_implemented!("set_default_payment_method/3")

  def set_default_payment_method!(_customer, _pm_id, _opts \\ []),
    do: not_implemented!("set_default_payment_method!/3")
end
