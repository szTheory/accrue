defmodule Accrue do
  @moduledoc """
  Accrue — billing state, modeled clearly.

  Accrue is an open-source Elixir/Phoenix payments and billing library built
  idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS
  developers a batteries-included jumpstart for everything a real SaaS business
  needs on day one: subscriptions, checkout, invoices, coupons, emails, PDFs,
  webhooks, admin UI, and telemetry — without the migration pain and design
  regrets earlier libraries accumulated.

  Public APIs live on modules such as `Accrue.Billing`, `Accrue.Events`,
  `Accrue.Mailer`, `Accrue.PDF`, `Accrue.Auth`, and `Accrue.Processor`.
  Start with `guides/quickstart.md` and the ExDoc-generated guides list.

  ## Entitlement gate API

  The four fail-closed entitlement gate functions are surfaced directly on
  `Accrue` (delegating to `Accrue.Entitlements`) so host code can call them
  without reaching into a nested module: `has_active_plan?/2`, `entitled?/2`,
  `features_for/1`, and `entitlement_quantity/2`. Each fails closed —
  garbage/error/nil/unmapped inputs collapse to `false` / `[]` / `0`, and an
  affirmative resolved match is the SOLE path to `true`.
  """

  @doc """
  Returns `true` iff `billable` holds `plan` among its active plans.

  `plan` is a plan atom or a `price_id` string. Tests membership in the SET
  of ALL active plans — multi-active-plan correct. Fail-closed `false`.

  Delegates to `Accrue.Entitlements.has_active_plan?/2`.
  """
  @spec has_active_plan?(term(), atom() | String.t()) :: boolean()
  defdelegate has_active_plan?(billable, plan), to: Accrue.Entitlements

  @doc """
  Returns `true` iff `billable`'s resolved active feature set contains
  `feature`. Fail-closed `false` otherwise.

  Delegates to `Accrue.Entitlements.entitled?/2`.
  """
  @spec entitled?(term(), atom()) :: boolean()
  defdelegate entitled?(billable, feature), to: Accrue.Entitlements

  @doc """
  Returns the sorted, deduped list of features granted by `billable`'s
  active plans. Always a plain `[atom]`. Fail-closed `[]`.

  Delegates to `Accrue.Entitlements.features_for/1`.
  """
  @spec features_for(term()) :: [atom()]
  defdelegate features_for(billable), to: Accrue.Entitlements

  @doc """
  Returns the seat/quota count for `quota_key` (`min(cap, quantity)` where a
  cap exists, else the raw quantity). Fail-closed `0`.

  Delegates to `Accrue.Entitlements.entitlement_quantity/2`.
  """
  @spec entitlement_quantity(term(), atom()) :: non_neg_integer()
  defdelegate entitlement_quantity(billable, quota_key), to: Accrue.Entitlements
end
