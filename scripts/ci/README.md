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

## ORG gates (v1.8 org billing proof)

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| ORG-09 | `scripts/ci/verify_adoption_proof_matrix.sh`; `examples/accrue_host/docs/adoption-proof-matrix.md` | `accrue/test/accrue/docs/organization_billing_guide_test.exs`; `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` | `.planning/phases/39-org-billing-proof-alignment/39-VERIFICATION.md` |

## INT gates (v1.16 integrator + proof continuity)

This table is **delta-maintained** for merge-blocking checks **touched by phases 59–61** on this milestone branch. The **normative** required-job set for every pull request remains **`.github/workflows/ci.yml`** plus **branch protection** — treat those as completeness SSOT, not this markdown registry alone.

| REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner |
|--------|-------------------------------|-------------------------|--------------------------|
| INT-06 | `accrue/guides/first_hour.md`; `examples/accrue_host/README.md`; `accrue/guides/quickstart.md`; `CONTRIBUTING.md` — scripts `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, `verify_adoption_proof_matrix.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `.planning/phases/59-golden-path-quickstart-coherence/59-VERIFICATION.md` |
| INT-07 | `examples/accrue_host/docs/adoption-proof-matrix.md`; `examples/accrue_host/docs/evaluator-walkthrough-script.md` — scripts `verify_adoption_proof_matrix.sh` (add `verify_package_docs.sh` only when pins touch matrix paths) | `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` when ORG-09 matrix literals change; else **—** | `.planning/phases/60-adoption-proof-ci-ownership-map/60-VERIFICATION.md` |
| INT-08 | Root `README.md` merge-blocking proof path + cross-package pins — `verify_package_docs.sh`; VERIFY-01 host README depth — `verify_verify01_readme_contract.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `.planning/phases/61-root-verify-hops-hex-doc-ssot/61-VERIFICATION.md` |

### Triage: verify_adoption_proof_matrix.sh

- **`verify_adoption_proof_matrix:`** (stderr prefix on failure) — treat as **ORG-09**: missing ORG-09 headings, primary/recipe lane markers, `phx.gen.auth` / `use Accrue.Billable` / `non-Sigra` literals, **ORG-07** / **ORG-08** advisory rows, or the self-referential script path in `adoption-proof-matrix.md`. Fix the matrix doc first; only change needles in the script after an intentional taxonomy edit.

## When package docs verification fails

Stderr lines from `verify_package_docs.sh` are prefixed with `[verify_package_docs]` so log scrapers and humans can tell this gate apart from other scripts. Use the triage bullets below to map the failing file or substring back to the ADOPT row before editing unrelated docs.

### Triage: verify_package_docs.sh

- `ADOPT-01` — failures mentioning root `README.md`, `## Proof path (VERIFY-01)`, `proof-and-verification`, or PR merge-blocking / `host-integration` wording in the root README pair.
- `ADOPT-02` — failures on `examples/accrue_host/README.md` sections (`## Proof and verification`, `### Verification modes`, VERIFY-01 markers); also run `bash scripts/ci/verify_verify01_readme_contract.sh` because VERIFY-01 depth is split across that script.
- `ADOPT-03` — failures on `accrue/guides/testing.md`, `accrue/guides/first_hour.md`, or `guides/testing-live-stripe.md` missing the merge-blocking one-liner / advisory lane text enforced by `require_fixed`.
- `ADOPT-04` — failures on `accrue/guides/first_hour.md` missing `upgrade.md#installer-rerun-behavior` or First Hour structure pins.
- `ADOPT-05` — failures on `accrue/guides/troubleshooting.md` (`mix accrue.install --check`), RELEASING/provider-parity phrasing, or other `require_fixed` clusters added in Phase 33.
- `ADOPT-06` — failures involving `.github/workflows/ci.yml` (not directly read here but referenced by docs), `CONTRIBUTING.md` UAT wording, or `guides/testing-live-stripe.md` / `RELEASING.md` keys such as `STRIPE_TEST_SECRET_KEY` / `release-gate` / `retain-on-failure`.
