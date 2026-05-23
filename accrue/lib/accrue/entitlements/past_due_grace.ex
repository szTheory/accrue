defmodule Accrue.Entitlements.PastDueGrace do
  @moduledoc """
  Pure, clock-driven past-due grace-window check (ENT-09, D-17).

  `within_grace?/2` answers whether a `:past_due` subscription is still
  inside a configured grace window measured from its `past_due_since`
  timestamp. The window is `now - past_due_since <= grace_days * 86_400`,
  computed against `Accrue.Clock.utc_now/0` (the testable clock, never the
  raw BEAM wall-clock) so the check is deterministic under the Fake test
  clock.

  Fail-closed by construction: a `nil` `past_due_since`, a non-positive
  `grace_days`, or a non-DateTime `past_due_since` all return `false`. A
  grant is therefore always an affirmative, resolved, configured decision —
  never a fail-open (preserving the headline fail-closed contract).

  Lives in the entitlements layer (it is config-coupled grace, reading the
  `:entitlements`/`:dunning` policy via the caller), never on
  `Accrue.Billing.Subscription`, which must not read config — keeping the
  one-way dependency entitlements -> billing clean.
  """

  @spec within_grace?(map(), pos_integer()) :: boolean()
  def within_grace?(%{past_due_since: nil}, _grace_days), do: false

  def within_grace?(%{past_due_since: %DateTime{} = since}, grace_days)
      when is_integer(grace_days) and grace_days > 0 do
    cutoff = DateTime.add(Accrue.Clock.utc_now(), -grace_days * 86_400, :second)
    # since >= cutoff -> still inside the window (mirrors, inverted, the
    # dunning sweeper's `past_due_since < cutoff` exhaustion check).
    DateTime.compare(since, cutoff) != :lt
  end

  def within_grace?(_sub, _grace_days), do: false
end
