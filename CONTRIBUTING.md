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

## Library maintenance (v1.21+)

Doc PRs that touch **First Hour** or the **host README** proof spine must follow the **same-PR capsule parity** checklist in [`scripts/ci/README.md`](scripts/ci/README.md) (search for **First Hour + host README capsule parity** — **INT-11**). For **when Accrue is in maintenance posture** vs active feature milestones, read [`accrue/guides/maturity-and-maintenance.md`](accrue/guides/maturity-and-maintenance.md).

## Accrue Admin UI hygiene (v1.12+)

Pull requests that introduce **non-token** color or layout exceptions in `accrue_admin` must add a row to the theme exception register at [`accrue_admin/guides/theme-exceptions.md`](accrue_admin/guides/theme-exceptions.md) so reviewers can track intentional deviations (**D-13** / Phase 50).

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

## Adoption (ADOPT) CI contracts

v1.7 adoption requirements (ADOPT-01–ADOPT-06) are enforced mostly through documentation gates in `scripts/ci/`. When `verify_package_docs` or VERIFY-01 checks fail in CI, open [scripts/ci/README.md](scripts/ci/README.md) for the requirement → script → ExUnit map so you edit the owning files first instead of silencing unrelated prose.

**v1.16 integrator + proof (INT-06..INT-09):** Verifier ownership for those rows lives under **`## INT gates (v1.16 integrator + proof continuity)`** in [scripts/ci/README.md](scripts/ci/README.md) — edit that section (not this file) when INT-related merge-blocking checks or owning `VERIFICATION.md` paths change.

Before you open a PR that touches **First Hour**, the **root/host README**, **`accrue/guides/quickstart.md`**, or any **`verify_package_docs`** needle, run this **minimum local doc preflight** from the repository root (ordered; fast failures first). It mirrors job **`docs-contracts-shift-left`** and does **not** replace the **`host-integration`** merge-blocking job.

```bash
bash scripts/ci/verify_package_docs.sh && \
bash scripts/ci/verify_v1_17_friction_research_contract.sh && \
bash scripts/ci/verify_verify01_readme_contract.sh && \
bash scripts/ci/verify_production_readiness_discoverability.sh && \
bash scripts/ci/verify_adoption_proof_matrix.sh && \
bash scripts/ci/verify_core_admin_invoice_verify_ids.sh
```

**Hex-only `mix deps.get` vs `@version` on `main`:** When **`mix.exs` `@version`** bumps on **`main`** ahead of the matching **Hex** publish, **`mix deps.get`** against published **`~>`** pins can fail until the new artifacts ship. Prefer a **`path:`** dependency into this workspace, a **git** ref to the commit you need, or **wait for publish** before expecting Hex to resolve the newer number.

## Host proof (VERIFY-01)

Host integration proofs sit in **Layer B** and **Layer C** relative to the per-package release gate:

- **Layer A** — `accrue/` and `accrue_admin/` **`mix test`**, Credo, Dialyzer, docs, and related release checks (above).
- **Layer B** — from the repo root, `cd examples/accrue_host` then **`mix verify`** (fast Fake slice) or **`mix verify.full`** (CI-equivalent host stack). See [examples/accrue_host/README.md#proof-and-verification](examples/accrue_host/README.md#proof-and-verification) for VERIFY-01 detail.
- **Layer C** — merge-blocking PR jobs **`docs-contracts-shift-left`** (bash contracts) then **`host-integration`** (BEAM + Playwright) are the contract, not “I ran **`mix verify.full`** locally” alone; use [scripts/ci/README.md](scripts/ci/README.md) to map scripts and lanes before you change CI-facing prose.

## No CLA

Accrue does not require a Contributor License Agreement at this time. By submitting a contribution, you confirm that you have the right to license your work under the repository's MIT license.
