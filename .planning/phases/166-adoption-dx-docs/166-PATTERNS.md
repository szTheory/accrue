# Phase 166: Adoption DX Docs - Pattern Map

**Created:** 2026-06-02
**Status:** Ready for planning

## Scope Files

| File | Role | Closest Existing Analog | Pattern to Preserve |
|------|------|-------------------------|---------------------|
| `examples/accrue_host/config/dev.exs` | Phoenix dev endpoint and database config | Phase 164 `PGHOST` change in the same file | Environment-aware dev config that preserves bare-metal defaults while enabling Docker |
| `examples/accrue_host/README.md` | Primary adoption-facing doc | Existing host README `## First run`, `## Proof and verification`, `### Verification modes` | Ordered host story with stable command names and verifier-pinned support wording |
| `examples/accrue_host/demo/command_manifest.exs` | Command taxonomy | Existing `first_run`, `seeded_history`, `command_modes` maps | Compact command labels that mirror docs without becoming a second README |
| `scripts/ci/verify_package_docs.sh` | Package/docs structural gate | Existing `require_fixed "$ROOT_DIR/examples/accrue_host/README.md" ...` needles | Literal substring checks for load-bearing doc structure |
| `scripts/ci/verify_verify01_readme_contract.sh` | Host README proof-depth gate | Existing `require_substring` needles and stale-wording guards | Keep VERIFY-01/proof/support depth protected while avoiding inline CI inventory in README |
| `.github/workflows/ci.yml` | CI Docker smoke truth | `host-docker-smoke` job | Poll the same localhost URL the README claims for Docker |

## Concrete Patterns

### Environment-Aware Phoenix Config

`examples/accrue_host/config/dev.exs` already uses an environment variable for Docker database routing:

```elixir
hostname: System.get_env("PGHOST") || "localhost"
```

For endpoint binding, preserve the same dual-mode idea. Bare-metal development can remain simple, while Docker must be able to publish the Phoenix endpoint through `4000:4000`.

### Docker Compose Contract

`examples/accrue_host/docker-compose.yml` is the source of truth for the Start Here Docker command:

```yaml
web:
  ports:
    - "4000:4000"
  environment:
    PGHOST: db
```

README claims should use `http://localhost:4000` only if the web process listens on an address reachable from the host through the published port.

### Host README Command Vocabulary

Existing stable command names:

- `mix setup`
- `mix phx.server`
- `mix verify`
- `mix verify.full`
- `bash scripts/ci/accrue_host_uat.sh`

Phase 166 should add Docker-first evaluation without renaming these commands. Keep native Phoenix as the contributor path immediately after Docker.

### Doc Verifier Needles

`scripts/ci/verify_package_docs.sh` currently pins host README structure and native command strings:

- `## First run`
- `## Seeded history`
- `## Proof and verification`
- `### Verification modes`
- `mix setup`
- `mix phx.server`
- `/webhooks/stripe`

`scripts/ci/verify_verify01_readme_contract.sh` currently pins deeper proof details:

- `VERIFY-01`
- `host-integration`
- `bash scripts/ci/verify_adoption_proof_matrix.sh`
- `bash scripts/ci/accrue_host_uat.sh`
- `scripts/ci/README.md`
- `mix verify.full`
- provider-honest Stripe/Braintree wording

The executor should run both gates after README edits and update needles only for newly load-bearing Start Here claims.

## Implementation Notes for Planner

- Plan 1 should handle Docker truth before Plan 2 asks the README to promise Docker-first evaluation.
- Plan 2 should edit the README top-of-file only enough to make Start Here clear, then preserve or relocate existing proof/support depth.
- Plan 3 should handle verifier/script updates and proof ladder cleanup, not introduce new proof commands.
- Avoid schema-push tasks; no ORM schema files are in scope.
