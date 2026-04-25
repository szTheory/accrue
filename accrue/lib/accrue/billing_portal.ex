defmodule Accrue.BillingPortal do
  @moduledoc """
  Customer Billing Portal context.

  Thin facade over `Accrue.BillingPortal.Session.create/1`. The portal
  itself is hosted by Stripe — Accrue's job is wrapping session
  creation, masking the bearer-credential URL in `Inspect`, and
  providing the `:configuration` passthrough for hosts that pre-create
  a `bpc_*` configuration in the Stripe Dashboard.

  See `guides/portal_configuration_checklist.md` for the three
  Dashboard toggles every host app should enable to defend against
  the "cancel-without-dunning" footgun (Pitfall 6).
  """

  defdelegate create_session(params), to: Accrue.BillingPortal.Session, as: :create
  defdelegate create_session!(params), to: Accrue.BillingPortal.Session, as: :create!
end
