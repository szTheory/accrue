defmodule Accrue.Billing.UpcomingInvoice do
  @moduledoc """
  Non-persistent struct representing a proration preview (BILL-10, D3-19).

  Returned from `Accrue.Billing.preview_upcoming_invoice/2` and never
  written to the database — Stripe's upcoming-invoice endpoint is the
  source of truth, and the result is always a snapshot at `fetched_at`.
  """

  alias Accrue.Money

  @type t :: %__MODULE__{
          subscription_id: String.t() | nil,
          currency: atom() | String.t(),
          subtotal: Money.t() | nil,
          total: Money.t() | nil,
          amount_due: Money.t() | nil,
          starting_balance: Money.t() | nil,
          period_start: DateTime.t() | nil,
          period_end: DateTime.t() | nil,
          proration_date: DateTime.t() | nil,
          lines: [__MODULE__.Line.t()],
          fetched_at: DateTime.t() | nil
        }

  defstruct [
    :subscription_id,
    :currency,
    :subtotal,
    :total,
    :amount_due,
    :starting_balance,
    :period_start,
    :period_end,
    :proration_date,
    :fetched_at,
    lines: []
  ]

  defmodule Line do
    @moduledoc "A single line on an upcoming-invoice preview."

    alias Accrue.Money

    @type t :: %__MODULE__{
            description: String.t() | nil,
            amount: Money.t() | nil,
            quantity: integer() | nil,
            period: {DateTime.t(), DateTime.t()} | nil,
            proration?: boolean(),
            price_id: String.t() | nil
          }

    defstruct [
      :description,
      :amount,
      :quantity,
      :period,
      :price_id,
      proration?: false
    ]
  end
end
