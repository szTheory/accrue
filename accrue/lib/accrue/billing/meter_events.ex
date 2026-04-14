defmodule Accrue.Billing.MeterEvents do
  @moduledoc """
  Phase 4 Plan 02 helper for asynchronous meter-event state transitions
  driven by Stripe webhooks (BILL-13, Pitfall 5).

  Kept separate from `Accrue.Billing.MeterEventActions` so the webhook
  path (`Accrue.Webhook.DefaultHandler`) doesn't pull the outbox/
  NimbleOptions surface into its dependency graph.
  """

  alias Accrue.Billing.MeterEvent
  alias Accrue.Repo

  @doc """
  Looks up the meter-event row by `identifier` and flips it to `failed`
  with the Stripe error-report object sanitized into `stripe_error`.
  Returns `{:ok, row}` on success or `{:error, :not_found}` if the
  identifier is unknown (late or synthetic report).
  """
  @spec mark_failed_by_identifier(String.t() | nil, map()) ::
          {:ok, MeterEvent.t()} | {:error, :not_found}
  def mark_failed_by_identifier(nil, _stripe_obj), do: {:error, :not_found}

  def mark_failed_by_identifier(identifier, stripe_obj) when is_binary(identifier) do
    case Repo.get_by(MeterEvent, identifier: identifier) do
      nil ->
        {:error, :not_found}

      %MeterEvent{} = row ->
        row
        |> MeterEvent.failed_changeset(stripe_obj)
        |> Repo.update()
    end
  end
end
