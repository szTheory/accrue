# Phase 226 — CI and host setup ownership

This runbook separates the clean GitHub Actions runner from a maintainer's local
host. It does not create a second bootstrap script: the repository-owned entry
points remain [`accrue_host_uat.sh`](../../../scripts/ci/accrue_host_uat.sh) and
[`accrue_host_verify_browser.sh`](../../../scripts/ci/accrue_host_verify_browser.sh).

Run the complete repository/CI-equivalent host gate from the repository root:

```bash
bash scripts/ci/accrue_host_uat.sh
```

For native host work, use the same package-local contract:

```bash
cd examples/accrue_host && mix verify.full
```

## Ownership matrix

| Surface | CI owner and action | Host owner and action | First diagnostic command | Expected signal | Next safe action |
|---|---|---|---|---|---|
| Node runtime | `host-integration` and `playwright-e2e` use `actions/setup-node@v6` with Node `22`. | Maintainer supplies a working local Node/npm installation. | `node --version && npm --version` | Both commands report installed versions. | Install or select the required local Node runtime, then rerun the affected package command. |
| npm lock installation | CI runs `cd examples/accrue_host && npm ci` (and the host assets lock install). | Maintainer runs `cd examples/accrue_host && npm ci`. | `cd examples/accrue_host && npm ci` | Lockfile-resolved install completes without modifying `package-lock.json`. | Remove only local `node_modules` if needed; keep the committed lockfile and rerun `npm ci`. |
| Playwright package | CI installs the checked-in `@playwright/test` dependency through that lockfile. | Maintainer owns the same lockfile install. | `cd examples/accrue_host && npm ci` | `node_modules/@playwright` is present after a clean install. | Resolve the lock/install failure before changing test commands. |
| Chromium and system dependencies | CI owns runner browser setup: `npm run e2e:install` installs Chromium; the dedicated admin lane may use `npx playwright install --with-deps chromium`. | Maintainer owns local Chromium availability; the host command is `npm run e2e:install`. | `cd examples/accrue_host && npm run e2e:install` | Playwright reports Chromium installed. | Rerun the install after npm succeeds; investigate local OS prerequisites outside repository artifacts. |
| Docker versus Postgres service | CI owns its `postgres:15` service container. Docker evaluation owns its Compose database internally. | Native-host maintainer owns a reachable local Postgres and `PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD` overrides. | `pg_isready -h "${PGHOST:-localhost}" -p "${PGPORT:-5432}" -U "${PGUSER:-postgres}"` | PostgreSQL reports accepting connections. | Start or select the intended local database; do not copy credentials into baseline artifacts. |
| Database create and migrate | CI lets `accrue_host_verify_browser.sh` run `MIX_ENV=test mix ecto.create --quiet` and `mix ecto.migrate --quiet`. | Maintainer runs the existing full gate, which delegates to the same lifecycle. | `bash scripts/ci/accrue_host_uat.sh` | The host gate reaches its database phase without connection or migration errors. | Correct local Postgres readiness/configuration, then rerun the gate; the script owns test-database cleanup. |
| Deterministic fixture creation | CI invokes `scripts/ci/accrue_host_seed_e2e.exs` through the browser lifecycle script and validates it with `verify_e2e_fixture_jq.sh`. | Maintainer invokes the existing full gate; no hand-written fixture is needed. | `bash scripts/ci/accrue_host_uat.sh` | Browser phase produces and validates the transient fixture. | Rerun the owner script after fixing the reported seed/schema issue; do not retain fixture data as a baseline artifact. |
| Port selection | CI sets `ACCRUE_HOST_PORT=4100` and `ACCRUE_HOST_BROWSER_PORT=4101`. | Maintainer chooses free local ports with those environment variables. | `lsof -nP -iTCP:"${ACCRUE_HOST_BROWSER_PORT:-4101}" -sTCP:LISTEN` | No listener is reported before the browser gate starts. | Stop the local listener or set `ACCRUE_HOST_BROWSER_PORT` to a free port and rerun the full gate. |
| Phoenix server readiness | CI starts the bounded Phoenix server through `accrue_host_verify_browser.sh`. | Maintainer uses the same script via `mix verify.full`. | `curl --fail --silent --show-error "http://127.0.0.1:${ACCRUE_HOST_BROWSER_PORT:-4101}/"` | A ready server returns a successful HTTP response. | Read the transient server log path printed by the script and fix the reported boot issue; do not publish raw output in CI baseline files. |
| Playwright reuse and cleanup | CI sets `ACCRUE_HOST_REUSE_SERVER=1` after the script seeds once and starts its server. | Maintainer relies on the script's traps to stop its process tree and delete transient fixtures. | `bash scripts/ci/accrue_host_uat.sh` | The browser phase either completes or prints its retained local server-log path on failure. | Let the script clean up, then rerun it; use `ACCRUE_HOST_BROWSER_LOG` only for a local transient log you explicitly need. |
| Failure artifacts | CI retains reports, traces, screenshots, and server logs as Actions artifacts according to job policy. | Maintainer inspects local transient paths printed by the failing owner script. | `bash scripts/ci/accrue_host_uat.sh` | Failure output names the failing phase and, for browser failures, the log path. | Diagnose from the named local path or retained Actions artifact; never add raw logs, traces, screenshots, payloads, or secrets to the metadata-only baseline. |

## Proof semantics and provider policy

`docs-contracts-shift-left` runs the repository baseline contract. Its required,
advisory, skipped, and not-applicable vocabulary describes repository proof
taxonomy only. GitHub-enforced required checks come solely from the captured
effective-rules and classic-protection snapshot: an empty effective-rules response
with classic-protection `404` is `none-enforced`, not an inference from workflow
YAML or successful jobs.

For three-run baseline collection, use the credential-free local contract first:

```bash
bash scripts/ci/verify_ci_baseline_contract.sh
```

The read-only Actions collector is separately documented in
[`226-CI-BASELINE.md`](226-CI-BASELINE.md); it never downloads raw logs or
artifacts.
