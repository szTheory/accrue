---
phase: 166-adoption-dx-docs
status: passed
verified: 2026-06-02
plans_verified: [166-01, 166-02, 166-03]
requirements_verified: [DOC-01, DOC-02, DOC-03]
---

# Phase 166 Verification: Adoption DX Docs

## Verdict

PASSED. Phase 166 now gives adopters a Docker-first Start Here path, preserves the native Phoenix first-run spine, reorganizes proof-depth documentation into clear confidence lanes, and pins the new load-bearing claims in shift-left docs verification.

## Evidence

- Plan inventory: `gsd-sdk query phase-plan-index 166` reported all three plans with `has_summary: true` and `incomplete: []`.
- Package/docs contract: `bash scripts/ci/verify_package_docs.sh` passed for `accrue 1.4.0`, `accrue_admin 1.4.0`, and `accrue_portal 1.4.0`.
- VERIFY-01 README contract: `bash scripts/ci/verify_verify01_readme_contract.sh` passed.
- Adoption proof matrix: `bash scripts/ci/verify_adoption_proof_matrix.sh` passed.
- Host manifest docs test: `cd examples/accrue_host && MIX_ENV=test mix test test/demo/command_manifest_test.exs` passed, 3 tests.
- Package docs tests: `cd accrue && MIX_ENV=test mix test test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` passed, 3 tests.
- Docker compose config: `cd examples/accrue_host && docker compose config >/dev/null` passed.
- Whitespace check: `git diff --check -- examples/accrue_host/README.md scripts/ci/verify_package_docs.sh examples/accrue_host/config/dev.exs accrue/README.md accrue_admin/README.md accrue/guides/first_hour.md` passed.

## Scope Check

- `examples/accrue_host/config/dev.exs` now binds the Phoenix endpoint to `{0, 0, 0, 0}` only when `PGHOST=db`, preserving native loopback behavior otherwise.
- `examples/accrue_host/README.md` starts with a realistic local demo frame, a Docker-first command block, `http://localhost:4000`, `/app/billing`, `/billing`, `Accrue.Processor.Fake`, and `mix verify`.
- The Sigra/production trust boundary remains below the first evaluator path and points non-Sigra teams to First Hour plus Organization billing.
- The proof ladder distinguishes Explore, Focused proof, Full local gate, CI wrapper, Maintainer contracts, and Provider parity without renaming existing commands.
- `scripts/ci/verify_package_docs.sh` now pins Start Here, Docker, localhost, and Fake claims.

## Caveats

- Local Docker boot smoke was attempted during Plan 166-01 and built the dev image, but host port `4000` was already allocated, so Docker could not publish the web container. The stack was cleaned up with `docker compose down --volumes --remove-orphans`. The Compose config passes and the README claim is backed by the endpoint bind fix plus CI-oriented docs contracts; rerun the boot smoke on a machine with port `4000` free for local browser evidence.

## Result

Phase 166 is complete and ready for milestone closeout verification.
