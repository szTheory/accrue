# scripts/ci — contributor map

This directory hosts merge-adjacent bash gates and host-app checks. Use it as the first stop when CI fails on documentation or VERIFY-01 contracts.

## ADOPT gates (v1.7 adoption milestone)

Evidence columns are summarized from `.planning/phases/32-adoption-discoverability-doc-graph/32-VERIFICATION.md` and `.planning/phases/33-installer-host-contracts-ci-clarity/33-VERIFICATION.md`.

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| ADOPT-01 | `scripts/ci/verify_package_docs.sh` (root `README.md` proof path + merge-blocking labels); root `README.md` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` (invokes verifier end-to-end) | `.planning/phases/32-adoption-discoverability-doc-graph/32-VERIFICATION.md` |
| ADOPT-02 | `scripts/ci/verify_verify01_readme_contract.sh`; `examples/accrue_host/README.md` (VERIFY-01 / Playwright / host-integration prose) | — (bash-only contract; runs in `host-integration` CI job) | `32-VERIFICATION.md` |
| ADOPT-03 | `verify_package_docs.sh` pins on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, `guides/testing-live-stripe.md` | `package_docs_verifier_test.exs` | `32-VERIFICATION.md` |
| ADOPT-04 | `accrue/guides/first_hour.md` §4 + `upgrade.md#installer-rerun-behavior` anchor | `accrue/test/accrue/docs/first_hour_guide_test.exs` | `33-VERIFICATION.md` |
| ADOPT-05 | `verify_package_docs.sh` `require_fixed` / `require_regex` pins (First Hour, troubleshooting, host README, package READMEs) | `package_docs_verifier_test.exs` (fixture drift regressions) | `33-VERIFICATION.md` |
| ADOPT-06 | `.github/workflows/ci.yml` stable job-id header comments; `README.md` + `guides/testing-live-stripe.md` lane wording | `package_docs_verifier_test.exs` (workflow/contributor drift cases) | `33-VERIFICATION.md` |

## When package docs verification fails

Stderr lines from `verify_package_docs.sh` are prefixed with `[verify_package_docs]` so log scrapers and humans can tell this gate apart from other scripts. Use the triage bullets below to map the failing file or substring back to the ADOPT row before editing unrelated docs.

### Triage: verify_package_docs.sh

- `ADOPT-01` — failures mentioning root `README.md`, `## Proof path (VERIFY-01)`, `proof-and-verification`, or PR merge-blocking / `host-integration` wording in the root README pair.
- `ADOPT-02` — failures on `examples/accrue_host/README.md` sections (`## Proof and verification`, `### Verification modes`, VERIFY-01 markers); also run `bash scripts/ci/verify_verify01_readme_contract.sh` because VERIFY-01 depth is split across that script.
- `ADOPT-03` — failures on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, or `guides/testing-live-stripe.md` missing the merge-blocking one-liner / advisory lane text enforced by `require_fixed`.
- `ADOPT-04` — failures on `accrue/guides/first_hour.md` missing `upgrade.md#installer-rerun-behavior` or First Hour structure pins.
- `ADOPT-05` — failures on `accrue/guides/troubleshooting.md` (`mix accrue.install --check`), RELEASING/provider-parity phrasing, or other `require_fixed` clusters added in Phase 33.
- `ADOPT-06` — failures involving `.github/workflows/ci.yml` (not directly read here but referenced by docs), `CONTRIBUTING.md` UAT wording, or `guides/testing-live-stripe.md` / `RELEASING.md` keys such as `STRIPE_TEST_SECRET_KEY` / `release-gate` / `retain-on-failure`.
