defmodule Accrue.Billing.SubscriptionScheduleProjection do
  @moduledoc """
  Decomposes a Stripe/Fake SubscriptionSchedule payload into the flat
  attrs map consumed by `Accrue.Billing.SubscriptionSchedule.changeset/2`
  and `force_status_changeset/2`.

  Handles both atom-keyed (Fake) and string-keyed (Stripe) payloads
  via `SubscriptionProjection.get/2` dual-key lookup (Pattern §I).

  Computes `current_phase_index` by matching `current_phase.start_date`
  against the `phases[]` list (Pitfall 4 — index-less diff anchor so
  out-of-order webhook updates settle correctly).
  """

  alias Accrue.Billing.SubscriptionProjection

  @spec decompose(map()) :: {:ok, map()}
  def decompose(schedule) when is_map(schedule) do
    phases = SubscriptionProjection.get(schedule, :phases) || []
    current_phase = SubscriptionProjection.get(schedule, :current_phase)

    {:ok,
     %{
       processor_id: SubscriptionProjection.get(schedule, :id),
       status: to_string_or_nil(SubscriptionProjection.get(schedule, :status)),
       current_phase_index: compute_current_phase_index(phases, current_phase),
       phases_count: length(phases),
       next_phase_at: compute_next_phase_at(phases, current_phase),
       released_at:
         SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(schedule, :released_at)),
       canceled_at:
         SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(schedule, :canceled_at)),
       data: SubscriptionProjection.to_string_keys(schedule),
       metadata: SubscriptionProjection.get(schedule, :metadata) || %{}
     }}
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(v) when is_binary(v), do: v
  defp to_string_or_nil(v) when is_atom(v), do: Atom.to_string(v)

  defp compute_current_phase_index(_phases, nil), do: nil

  defp compute_current_phase_index(phases, current_phase) when is_list(phases) do
    # Pitfall 4: anchor on `current_phase.start_date` (not index). Out-of-order
    # webhook arrivals can otherwise settle a stale index.
    cp_start = SubscriptionProjection.get(current_phase, :start_date)

    case cp_start do
      nil ->
        nil

      start_date ->
        Enum.find_index(phases, fn phase ->
          SubscriptionProjection.get(phase, :start_date) == start_date
        end)
    end
  end

  defp compute_next_phase_at(phases, nil) do
    # Not yet started — next phase is the first one.
    case phases do
      [first | _] ->
        SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(first, :start_date))

      _ ->
        nil
    end
  end

  defp compute_next_phase_at(_phases, current_phase) do
    SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(current_phase, :end_date))
  end
end
