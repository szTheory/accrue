# Quickstart

Use this page as the index into the host-first setup docs.

## Start with First Hour

The canonical setup walkthrough lives in [First Hour](first_hour.md). It follows
the Phoenix host-app order proved in `examples/accrue_host`:

- deps and `mix deps.get`
- `mix accrue.install`
- `config/runtime.exs`
- migrations and Oban
- `/webhooks/stripe`
- `accrue_admin "/billing"`
- first Fake-backed subscription
- focused host tests

## Focused guides

- [Troubleshooting](troubleshooting.md) for setup diagnostics and exact verify
  commands.
- [Webhooks](webhooks.md) for the public `use Accrue.Webhook.Handler` boundary,
  raw-body placement, signatures, and replay.
- [Testing](testing.md) for `use Accrue.Test` and Fake-backed host proofs.
- [Upgrade](upgrade.md) for generated-file ownership and installer rerun
  behavior.
