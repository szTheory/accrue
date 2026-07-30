defmodule Accrue.Entitlements.Admin do
  @moduledoc """
  Internal read-only diagnostic seam for the `accrue_admin` entitlements tab
  (ENT-11).

  NOT a public gate API — there is no boolean `entitled?`-style surface here.
  `fetch_entitled/2` is closed and will-not-build: a Stripe-backed predicate
  makes authorization depend on a network call that can fail open under
  partition, while `Accrue.Entitlements.StripeSync.summary_for_customer/1` and
  `resolve_for_customer/1` already provide diagnostic observation. This module answers the
  operator question *"what does the resolver currently grant this customer, and
  what entitling `price_id`s is it silently discarding?"* by returning a
  `{resolved, unmapped_price_ids}` pair — never a grant/deny decision.

  ## One-way dependency

  `admin → billing/entitlements core`, never the reverse. Nothing under
  `Accrue.Billing` or the resolver references this module; it only reads through
  the resolver's SSOT fold.

  ## Resolver scope

  Hard-codes the default `Accrue.Entitlements.Resolver.LocalMap` resolver. The
  diagnostic re-derives the structurally-discarded unmapped drift, which is a
  property of the local plan→`price_id` catalog; custom resolvers are out of
  scope for this read-only diagnostic.

  ## Why a `{resolved, unmapped}` pair

  The resolver drops unmapped entitling `price_id`s under `:deny`
  (`Accrue.Entitlements.Resolver.LocalMap` `handle_unmapped/3`), so the resolved
  map can NEVER surface drift. `unmapped_entitling_price_ids/1` re-reads the
  customer's entitling items independently and returns only the `price_id`s the
  catalog does not map — the operator's drift signal.
  """

  alias Accrue.Entitlements.Resolver.LocalMap

  @doc """
  Returns `{resolved, unmapped_price_ids}` for `customer`:

    * `resolved` — the resolver's SSOT fold (`active_plans`, `features`,
      `quantities`, and the grace sets), reusing `LocalMap.fold_for_customer/1`
      (no re-implemented fold), and
    * `unmapped_price_ids` — the entitling `price_id`s the resolver structurally
      discards under `:deny`, via `LocalMap.unmapped_entitling_price_ids/1`.
  """
  @spec resolve_for_customer(Accrue.Billing.Customer.t()) ::
          {resolved :: map(), unmapped_price_ids :: [String.t()]}
  def resolve_for_customer(%Accrue.Billing.Customer{} = customer) do
    {LocalMap.fold_for_customer(customer), LocalMap.unmapped_entitling_price_ids(customer)}
  end
end
