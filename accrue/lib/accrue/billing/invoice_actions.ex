defmodule Accrue.Billing.InvoiceActions do
  @moduledoc false
  # Phase 3 Wave 2 (Plan 05) fills this module in. See
  # SubscriptionActions for the stub rationale.

  defmodule NotImplementedError do
    @moduledoc false
    defexception [:function]

    @impl true
    def message(%{function: fun}),
      do: "Accrue.Billing.InvoiceActions.#{fun} is implemented in Phase 3 Plan 05"
  end

  defp not_implemented!(fun), do: raise(NotImplementedError, function: fun)

  def finalize_invoice(_invoice, _opts \\ []), do: not_implemented!("finalize_invoice/2")
  def finalize_invoice!(_invoice, _opts \\ []), do: not_implemented!("finalize_invoice!/2")
  def void_invoice(_invoice, _opts \\ []), do: not_implemented!("void_invoice/2")
  def void_invoice!(_invoice, _opts \\ []), do: not_implemented!("void_invoice!/2")
  def pay_invoice(_invoice, _opts \\ []), do: not_implemented!("pay_invoice/2")
  def pay_invoice!(_invoice, _opts \\ []), do: not_implemented!("pay_invoice!/2")
  def mark_uncollectible(_invoice, _opts \\ []), do: not_implemented!("mark_uncollectible/2")
  def mark_uncollectible!(_invoice, _opts \\ []), do: not_implemented!("mark_uncollectible!/2")
  def send_invoice(_invoice, _opts \\ []), do: not_implemented!("send_invoice/2")
  def send_invoice!(_invoice, _opts \\ []), do: not_implemented!("send_invoice!/2")
end
