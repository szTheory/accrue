defmodule Accrue.Billing.ChargeActions do
  @moduledoc false
  # Phase 3 Wave 2 (Plan 06) fills this module in.

  defmodule NotImplementedError do
    @moduledoc false
    defexception [:function]

    @impl true
    def message(%{function: fun}),
      do: "Accrue.Billing.ChargeActions.#{fun} is implemented in Phase 3 Plan 06"
  end

  defp not_implemented!(fun), do: raise(NotImplementedError, function: fun)

  def charge(_customer, _amount_or_opts, _opts \\ []), do: not_implemented!("charge/3")
  def charge!(_customer, _amount_or_opts, _opts \\ []), do: not_implemented!("charge!/3")
  def create_payment_intent(_customer, _opts \\ []), do: not_implemented!("create_payment_intent/2")

  def create_payment_intent!(_customer, _opts \\ []),
    do: not_implemented!("create_payment_intent!/2")

  def create_setup_intent(_customer, _opts \\ []), do: not_implemented!("create_setup_intent/2")
  def create_setup_intent!(_customer, _opts \\ []), do: not_implemented!("create_setup_intent!/2")
end
