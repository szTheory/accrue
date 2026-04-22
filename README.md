# Accrue

Billing state, modeled clearly.

Accrue is an open-source billing library for Elixir, Ecto, and Phoenix. Your app owns the billing facade, routes, auth boundary, and runtime config; Accrue owns the billing engine behind them.

Start one Fake-backed subscription. Post one signed webhook. Inspect and replay the result in admin. Run the focused proof suite.

## Proof path (VERIFY-01)

Fake-first evaluation runs from **`examples/accrue_host`** (no live Stripe keys). Pull requests are merge-blocked on GitHub Actions job `host-integration`: it runs `bash scripts/ci/verify_verify01_readme_contract.sh` and `bash scripts/ci/verify_adoption_proof_matrix.sh`, then `bash scripts/ci/accrue_host_uat.sh` (which delegates to `cd examples/accrue_host && mix verify.full`), with `bash scripts/ci/accrue_host_hex_smoke.sh` on eligible runs (see `.github/workflows/ci.yml`). Use `mix verify` for a faster bounded Fake slice that is not CI-complete. Stripe test-mode parity uses job id `live-stripe` on manual runs and the daily schedule; that lane is advisory and not merge-blocking on PRs.

> **Hex vs `main`:** This repository’s `mix.exs` `@version` values are the numeric SSOT for the `accrue` / `accrue_admin` pair on the branch you are reading. [Hex.pm](https://hex.pm/packages/accrue) lists published artifacts when you are consuming from Hex rather than `main`.

```bash
# CI-equivalent local gate
cd examples/accrue_host && mix verify.full
```

[Merge-blocking proof, VERIFY-01 commands, and Playwright entry points](examples/accrue_host/README.md#proof-and-verification).

## Start here

- [Canonical local demo: Fake](examples/accrue_host/README.md) for the checked-in host app and the shortest path to a first subscription, signed webhook, admin inspection, and focused proof run.
- [Visual walkthrough (Fake screenshots)](examples/accrue_host/README.md#visual-walkthrough-fake-backed) for full-page PNGs of host + mounted admin via Playwright (`npm run e2e:visuals` in `examples/accrue_host`).
- [Package tutorial](accrue/guides/first_hour.md) for the same host-first story in package-facing terms.
- [Core package landing page](accrue/README.md) for install, guide index, and public setup boundaries.
- [Admin package landing page](accrue_admin/README.md) for the downstream admin mount, auth/session, and asset path.

## Packages

- `accrue` is the core billing library. Start there for generated `MyApp.Billing`, webhook wiring, test helpers, and upgrade guidance.
- `accrue_admin` is the mounted LiveView admin UI. Add it after the core billing and signed-webhook path is in place.

## Stable first-time setup surface

Supported public setup surfaces for first-time integration:

- `MyApp.Billing`
- `use Accrue.Webhook.Handler`
- `use Accrue.Test`
- `AccrueAdmin.Router.accrue_admin/2`
- `Accrue.Auth`
- `Accrue.ConfigError`

Generated files are host-owned after install. Accrue may refresh pristine stamped files on installer reruns, but user-edited generated files are left alone. Internal schemas, webhook/event structs, reducer modules, worker internals, and demo-only helpers are not app-facing APIs.

## Validation modes

- `Canonical local demo: Fake` keeps the front door deterministic and credential-free.
- `Provider parity: Stripe test mode` proves hosted Checkout behavior, signed Stripe webhook delivery, SCA/3DS branches, and response-shape drift that Fake does not cover.
- `Advisory/manual: live Stripe` is for final app-specific confidence before shipping your own product, not for evaluating Accrue or passing the normal release lane.

## Where to go next

- [examples/accrue_host/README.md](examples/accrue_host/README.md)
- [accrue/guides/first_hour.md](accrue/guides/first_hour.md)
- [accrue/README.md](accrue/README.md)
- [accrue_admin/README.md](accrue_admin/README.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [RELEASING.md](RELEASING.md)

