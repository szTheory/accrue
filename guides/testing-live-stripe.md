# Testing Against Live Stripe

Accrue ships two layers of test coverage for every Stripe-facing
behaviour that a human would otherwise need to validate manually:

1. **Fake-asserted correctness tests** — run on every `mix test`, use
   the in-process `Accrue.Processor.Fake`, and prove that every
   code path stays wired end-to-end. These run in CI on every PR.

2. **Live-Stripe fidelity tests** — run against real Stripe test mode,
   gated by the `:live_stripe` ExUnit tag (excluded by default) and
   by the presence of a `STRIPE_TEST_SECRET_KEY` environment variable.
   These prove that Stripe's real API responses still match Accrue's
   contracts when Stripe ships new API versions.

This guide covers layer (2). Most contributors never need to run it;
it executes automatically on a daily GitHub Actions schedule and can
be triggered on demand via the Actions tab.

This lane uses Stripe test mode and should be treated as `provider-parity checks`, not as the canonical local demo or the required release lane.

## What the live-Stripe suite covers

See `accrue/test/live_stripe/`. Current modules:

| Module | Purpose |
|---|---|
| `charge_3ds_live_test.exs` | `Billing.charge/3` with a 3DS-required test PM surfaces `{:ok, :requires_action, pi}` against real Stripe |
| `proration_fidelity_live_test.exs` | `preview_upcoming_invoice/2` line items match the committed invoice produced by `swap_plan/3` line-for-line |

Together these automate all 3 items in
`.planning/phases/03-core-subscription-lifecycle/03-HUMAN-UAT.md`
so Phase 3 ships with zero manual human verification gaps.

## Running locally

```bash
cd accrue
export STRIPE_TEST_SECRET_KEY=sk_test_...
export ACCRUE_LIVE_BASIC_PRICE=price_...   # optional, used by proration test
export ACCRUE_LIVE_PRO_PRICE=price_...     # optional, used by proration test

mix test.live
```

`mix test.live` is an alias (defined in `accrue/mix.exs`) for
`mix test --only live_stripe`. Without the env vars set, the tests
tag themselves `:skip` at module load time and produce a clean
"0 tests, X skipped" report — no errors.

Use Stripe test-mode credentials only. Set `STRIPE_TEST_SECRET_KEY`, not a live-mode key. This guide is for provider-parity checks in Stripe test mode. Do not paste webhook secrets, customer data, or PII into copied logs, screenshots, traces, or shared test notes.

## Running via `act` (local GitHub Actions replay)

`act` lets you run the `live-stripe` CI job locally in Docker. This
is useful for validating the workflow YAML without waiting on the
real GitHub Actions runner.

1. Install `act`: https://github.com/nektos/act
2. Copy the secrets template: `cp accrue/.secrets.example .secrets`
3. Populate `.secrets` with your real Stripe test-mode key. **Do NOT
   commit this file** — it is excluded in `.gitignore`. Keep customer
   data and PII out of the file and out of any copied terminal output.
4. Run:

   ```bash
   act workflow_dispatch \
     -W .github/workflows/ci.yml \
     -j live-stripe \
     --secret-file .secrets
   ```

## Running via GitHub Actions manual dispatch

1. Go to **Actions** → **CI** → **Run workflow** in the GitHub UI.
2. Select branch and confirm.
3. The `live-stripe` job runs with `STRIPE_TEST_SECRET_KEY` injected
   from repository secrets. `continue-on-error: true` means a failure
   in this job does NOT block the rest of CI — it is advisory, to
   catch Stripe API-version drift.

## Scheduled run

The `live-stripe` job also runs daily at 06:00 UTC via the workflow's
`schedule:` trigger. Failures are surfaced as annotated job summaries
and can be monitored alongside the `release-gate` and `host-integration`
results in the workflow summary.

## Philosophy

The live-Stripe suite exists to catch one specific class of bug:
**Stripe API contract drift**. Accrue's Fake adapter is the primary
test surface (D-20, see CLAUDE.md) and catches every logic bug
without needing real network I/O. The live suite is a belt-and-braces
canary for when Stripe ships a new API version or subtly changes a
response shape — the kind of change that would pass every Fake test
but break real integrations.

That is why this guide belongs in the `provider-parity checks` lane. It proves Stripe-backed behavior that Fake cannot, but it does not replace Fake and it does not become the required deterministic gate.

If a live-Stripe test starts failing while the corresponding Fake
test stays green, that is a signal that **the Fake processor needs to
be updated to mirror Stripe's new shape**, not a signal that the live
test is broken. Update the Fake first, then re-run the live test to
confirm.

For real host apps, signed webhook verification and runtime secrets still remain required on the app boundary. Use environment variables or GitHub secrets only, and keep real credentials, customer data, and PII out of shell history, logs, screenshots, traces, and issue reports.
