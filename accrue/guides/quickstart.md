# Quickstart

Use this page as the index into the host-first setup docs.

## Start with First Hour

The canonical setup walkthrough lives in [First Hour](first_hour.md). Open that guide and pick a **capsule** (**H** for an existing Hex app, **M** for this monorepo’s `examples/accrue_host`, **R** for read-only `mix verify` / `mix verify.full`) — each joins the same spine; this page stays a hub only.

The walkthrough follows
the Phoenix host-app order proved in `examples/accrue_host`:

- deps and `mix deps.get`
- `mix accrue.install`
- `config/runtime.exs`
- migrations and Oban
- `mix mailglass.install` then `mix ecto.migrate` — creates `mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`. See [the email guide](email.md#mailglass-migrations-phase-88-pipeline) for details.
- `/webhooks/stripe`
- `accrue_admin "/billing"`
- first Fake-backed subscription
- focused host tests

## Focused guides

- [Auth adapters](auth_adapters.md) — production **`Accrue.Auth`** wiring; pick an adapter instead of inventing callbacks.
- [Organization billing (non-Sigra)](organization_billing.md) — session→billable org path when the Stripe Customer should follow an organization, not only the signed-in user.
- [Troubleshooting](troubleshooting.md) for setup diagnostics and exact verify
  commands.
- [Webhooks](webhooks.md) for the public `use Accrue.Webhook.Handler` boundary,
  raw-body placement, signatures, and replay.
- [Testing](testing.md) for `use Accrue.Test` and Fake-backed host proofs.
- [Upgrade](upgrade.md) for generated-file ownership and installer rerun
  behavior.
