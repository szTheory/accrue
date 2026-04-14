defmodule Accrue.Billing.SubscriptionActions do
  @moduledoc false
  # Phase 3 Wave 2 (Plan 04) fills this module in.
  #
  # All functions below are declarative stubs so `Accrue.Billing`'s
  # `defdelegate` block compiles cleanly at Plan 03-01 time (without
  # stubs, modern Elixir reports `function is undefined` warnings and
  # `--warnings-as-errors` fails the build). Calling any of these before
  # Plan 04 lands raises `Accrue.Billing.SubscriptionActions.NotImplementedError`.

  defmodule NotImplementedError do
    @moduledoc false
    defexception [:function]

    @impl true
    def message(%{function: fun}),
      do: "Accrue.Billing.SubscriptionActions.#{fun} is implemented in Phase 3 Plan 04"
  end

  defp not_implemented!(fun), do: raise(NotImplementedError, function: fun)

  def subscribe(_user, _price_id_or_opts \\ [], _opts \\ []), do: not_implemented!("subscribe/3")
  def subscribe!(_user, _price_id_or_opts \\ [], _opts \\ []), do: not_implemented!("subscribe!/3")
  def get_subscription(_id, _opts \\ []), do: not_implemented!("get_subscription/2")
  def get_subscription!(_id, _opts \\ []), do: not_implemented!("get_subscription!/2")
  def swap_plan(_sub, _new_price_id, _opts), do: not_implemented!("swap_plan/3")
  def swap_plan!(_sub, _new_price_id, _opts), do: not_implemented!("swap_plan!/3")
  def cancel(_sub, _opts \\ []), do: not_implemented!("cancel/2")
  def cancel!(_sub, _opts \\ []), do: not_implemented!("cancel!/2")
  def cancel_at_period_end(_sub, _opts \\ []), do: not_implemented!("cancel_at_period_end/2")
  def cancel_at_period_end!(_sub, _opts \\ []), do: not_implemented!("cancel_at_period_end!/2")
  def resume(_sub, _opts \\ []), do: not_implemented!("resume/2")
  def resume!(_sub, _opts \\ []), do: not_implemented!("resume!/2")
  def pause(_sub, _opts \\ []), do: not_implemented!("pause/2")
  def pause!(_sub, _opts \\ []), do: not_implemented!("pause!/2")
  def unpause(_sub, _opts \\ []), do: not_implemented!("unpause/2")
  def unpause!(_sub, _opts \\ []), do: not_implemented!("unpause!/2")
  def update_quantity(_sub, _quantity, _opts \\ []), do: not_implemented!("update_quantity/3")
  def update_quantity!(_sub, _quantity, _opts \\ []), do: not_implemented!("update_quantity!/3")

  def preview_upcoming_invoice(_sub_or_customer, _opts \\ []),
    do: not_implemented!("preview_upcoming_invoice/2")

  def preview_upcoming_invoice!(_sub_or_customer, _opts \\ []),
    do: not_implemented!("preview_upcoming_invoice!/2")
end
