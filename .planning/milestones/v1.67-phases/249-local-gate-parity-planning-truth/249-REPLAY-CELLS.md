# Phase 249 Release-Gate Matrix Cell Replay (249-16)

- Replayed at HEAD: `87670b16456aa286421fd8dded28f1e4222772f5` (fresh `git clone --no-local` per cell, real `mix deps.get`)
- Date: 2026-10-25
- Tool: `249-replay-ci-job.py --job release-gate --run --skip 'Install Hex' --skip portal`
- Postgres: private scratch server on port 5439 (`--env PGPORT=5439`; shared 5432 near its connection limit), stopped and removed afterwards.
- No seed pinning, no retries. `accrue_portal` steps skipped (portal is not part of the matrix cells; covered by 249-12).
- Custody-bound host lanes and playwright-e2e are routed to Phase 250 (see 249-14 and 249-15) and are not part of this plan. The release-gate cells do not touch the host preview.

Shared env: `MIX_ENV=test PGUSER=postgres PGPASSWORD=postgres PGHOST=localhost PGPORT=5439`.

## Cells

| Cell | support | Toolchain | Env | Result |
|------|---------|-----------|-----|--------|
| Floor | required | `ASDF_ELIXIR_VERSION=1.19.0-otp-28` (`elixir --version` -> Elixir 1.19.0, OTP 28) | `ACCRUE_CI_SIGRA= ACCRUE_CI_OPENTELEMETRY= ACCRUE_OTEL_MATRIX=without_opentelemetry` | PASS=19 SKIP=6 |
| Primary + OpenTelemetry | required | default 1.19.5-otp-28 | `ACCRUE_CI_SIGRA= ACCRUE_CI_OPENTELEMETRY=1 ACCRUE_OTEL_MATRIX=with_opentelemetry` | PASS=19 SKIP=6 |
| Primary + Sigra | advisory | default 1.19.5-otp-28 | `ACCRUE_CI_SIGRA=1 ACCRUE_CI_OPENTELEMETRY= ACCRUE_OTEL_MATRIX=without_opentelemetry` | PASS=19 SKIP=6 |

Every cell passed accrue and accrue_admin: format, compile, test, credo, PLT create, dialyzer, docs, since-badges (accrue), retired-package audit.
The 6 skips are `Install Hex` and the 5 `accrue_portal` steps. An earlier Sigra attempt omitted the OpenTelemetry env vars (replay tool reported UNRESOLVED); it was discarded and re-run with the CI env above.

SIGRA: ADVISORY-PASS (all accrue and accrue_admin steps green; recorded as advisory, matching CI `continue-on-error`, not reclassified)

## Clone status classification

`git status --porcelain` after each replay (including untracked): empty for Floor, OpenTelemetry and Sigra clones. `deps/` and `_build/` are gitignored, and `mix.lock` did not change, so there was no lockfile churn to classify or copy back. All clones removed.

<!-- classified-clone-changes:begin -->
<!-- classified-clone-changes:end -->

## Fixes

None required: no floor-compatibility defect surfaced, so no source change was made.
