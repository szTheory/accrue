defmodule Accrue.Billing.RefundActions do
  @moduledoc false
  # Phase 3 Wave 2 (Plan 06) fills this module in.

  defmodule NotImplementedError do
    @moduledoc false
    defexception [:function]

    @impl true
    def message(%{function: fun}),
      do: "Accrue.Billing.RefundActions.#{fun} is implemented in Phase 3 Plan 06"
  end

  defp not_implemented!(fun), do: raise(NotImplementedError, function: fun)

  def create_refund(_charge, _opts \\ []), do: not_implemented!("create_refund/2")
  def create_refund!(_charge, _opts \\ []), do: not_implemented!("create_refund!/2")
end
