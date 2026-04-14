defmodule Accrue.Billing.Trial do
  @moduledoc """
  Trial end normalization (D3-38).

  Accepts the ergonomic Accrue shapes and produces what Stripe's
  `trial_end` parameter expects:

    * `:now` → `"now"` (Stripe magic string — ends trial immediately)
    * `%DateTime{}` → unix seconds
    * `{:days, N}` → unix seconds at `Accrue.Clock.utc_now/0 + N days`
    * `%Duration{}` → unix seconds at `Accrue.Clock.utc_now/0 + duration`

  Integers are deliberately rejected. A plain `1_800_000_000` is almost
  always a call-site bug (e.g. `DateTime.to_unix(dt)` inlined at the call
  site, making the value impossible to reason about at read time). We
  raise `ArgumentError` so the bug surfaces loudly. Likewise for the
  Stripe-native `:trial_period_days` atom — Accrue prefers the
  `{:days, N}` sugar because it is self-documenting.
  """

  @spec normalize_trial_end(term()) :: String.t() | pos_integer()
  def normalize_trial_end(:now), do: "now"

  def normalize_trial_end(%DateTime{} = dt), do: DateTime.to_unix(dt)

  def normalize_trial_end({:days, n}) when is_integer(n) and n > 0 do
    Accrue.Clock.utc_now()
    |> DateTime.add(n * 86_400, :second)
    |> DateTime.to_unix()
  end

  def normalize_trial_end(%Duration{} = d) do
    Accrue.Clock.utc_now()
    |> DateTime.shift(d)
    |> DateTime.to_unix()
  end

  def normalize_trial_end(:trial_period_days) do
    raise ArgumentError,
          "Accrue rejects :trial_period_days — use {:days, N} sugar instead " <>
            "(e.g. subscribe(user, price, trial_end: {:days, 14}))."
  end

  def normalize_trial_end(int) when is_integer(int) do
    raise ArgumentError,
          "unix ints rejected by Accrue.Billing.Trial.normalize_trial_end/1; " <>
            "pass :now, a %DateTime{}, {:days, N}, or a %Duration{} instead. " <>
            "See D3-38."
  end

  def normalize_trial_end(other) do
    raise ArgumentError,
          "invalid trial_end: #{inspect(other)}; expected " <>
            ":now | %DateTime{} | {:days, N} | %Duration{}"
  end
end
