# Contributing

Thanks for contributing to Accrue. This repository ships two sibling Mix packages:

- `accrue/` for the core billing library
- `accrue_admin/` for the LiveView admin UI

## Development setup

Install the supported toolchain first:

- Elixir 1.17+
- OTP 27+
- PostgreSQL 14+
- Node.js for browser UAT in `examples/accrue_host`

Then bootstrap both packages:

```bash
cd accrue
mix deps.get

cd ../accrue_admin
mix deps.get
npm ci
```

Use the package-local READMEs and guides for host-app wiring, browser UAT, and release-oriented docs checks.

## Conventional Commits

Accrue uses Conventional Commits so Release Please can cut package-local changelogs and version bumps correctly.

Use commit subjects like:

- `feat(accrue): add invoice retry helper`
- `fix(accrue_admin): preserve filter params on pagination`
- `docs: clarify webhook replay setup`

Keep the type accurate. `feat`, `fix`, and `docs` affect release notes and versioning.

## Running the release gate locally

Run the release gate from each package directory before opening a PR:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test --warnings-as-errors
mix credo --strict
mix dialyzer
mix docs --warnings-as-errors
mix hex.audit
```

For `accrue_admin`, use publish-mode dry runs when validating release packaging:

```bash
cd accrue_admin
export ACCRUE_ADMIN_HEX_RELEASE=1
mix hex.build
mix hex.publish --dry-run
```

For provider-parity checks against Stripe test mode, follow the setup in [`guides/testing-live-stripe.md`](guides/testing-live-stripe.md). That lane is advisory/manual, not part of the required deterministic release gate, and it exists to catch provider-parity drift rather than replace Fake. Please keep real credentials out of shell history and logs.

The required deterministic release gate still includes the checked-in trust review artifact, generated drift/docs drift, seeded performance smoke, compatibility floor/target checks, and browser accessibility/responsive checks. Keep webhook secrets, customer data, and PII out of docs, issue templates, screenshots, traces, and copied terminal output.

## No CLA

Accrue does not require a Contributor License Agreement at this time. By submitting a contribution, you confirm that you have the right to license your work under the repository's MIT license.
