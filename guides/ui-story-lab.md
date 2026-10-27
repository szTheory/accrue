# Phase 252 subscription story lab

This lab supports disposable production-backed Storybook review for subscription details. It separates static render evidence, local database evidence, and mounted browser review. Every browser server is created by the Phase 252 launcher and tied to a fresh numeric partition, database, port, nonce, and process identity.

## Prerequisites

- Run commands from the repository root.
- PostgreSQL must already be running locally and accept the configured test role. The launcher only accepts loopback `PGHOST` and the `postgres` role. An existing local password configuration can be supplied through the environment; credentials are never printed.
- `mix`, `psql`, Node, and the already-installed `accrue_admin` npm dependencies must be available. No dependency installation is part of these commands.
- Use a fresh 8–16 digit numeric `MIX_TEST_PARTITION` when choosing a namespace yourself. The database name is derived from the lane; do not point the launcher at a shared or pre-existing database.

The first bootstrap compiles and migrates an empty disposable database. Startup time should be recorded separately from warm browser renders. Repeated review runs create and drop their own database again, so their costs are not interchangeable with warm renders. Budgets are provisional; Phase 254 owns frozen recurring selection and budgets.

## Interactive review

The browser helper chooses and prints the exact database, loopback address, port, PID, and process start identity before tests run. It opens only the dedicated Phase 252 Playwright configuration, which always rejects reuse of an existing process.

```sh
npm --prefix accrue_admin run phase252:browser -- --headed
```

The helper uses a random numeric partition when `MIX_TEST_PARTITION` is unset. To name one explicitly, provide a fresh value in the environment:

```sh
MIX_TEST_PARTITION=2521234567 npm --prefix accrue_admin run phase252:browser -- --headed
```

The browser lane is `admin-review`. Closing the Playwright run sends termination to the launcher, which checks the child PID, start time, command, port, nonce, and database ownership before dropping the database. If identity no longer matches, it preserves the uncertain process/database and lock for inspection rather than targeting another resource. Do not attach a browser to an independently started server.

For a longer manual session without Playwright, run the same ownership checks around the endpoint:

```sh
node scripts/dev/phase252_lab.mjs serve --lane admin-review --partition 2521234567 --port 43127
```

Use a fresh partition and an available port. The command prints the exact namespace and PID. Stop it with Ctrl-C; only launcher-owned resources with matching identity are removed.

An owned one-off command can use the `exec` entry point:

```sh
node scripts/dev/phase252_lab.mjs exec --lane admin-review --partition 2521234567 --port 43127 -- mix accrue_admin.e2e.server
```

`exec` owns lifecycle and cleanup but does not wait for health; use `serve` or `phase252:browser` for browser review.

## Evidence and lane boundaries

- Static rendering verifies story state and visual/semantic output. It does not prove mounted authorization, provider completion, dispatched action behavior, or persistence.
- The `admin-test` and `admin-review` lanes use distinct fresh `accrue_admin_test<partition>` databases and separate ports. The isolation suite writes related customer, subscription, and item markers to both, invokes the real reset endpoint only on `admin-test`, and reloads both sides. Its positive control proves the test marker was deleted; its negative control proves the review rows and relationships stayed byte-for-byte unchanged.
- `host-heldout` remains a separate lane with its existing fixed port 4102 and `PHASE248_PROOF_LANE=heldout` guard. It does not widen host database or SQL-sandbox authority.
- The review Playwright project performs a fresh health identity assertion before opening the mounted subscription detail story. Automated UAT requires fresh assertion evidence for the claim being made; a previous static render or a browser screenshot alone is not persisted/isolation evidence.

Run the local database isolation checks with:

```sh
npm --prefix accrue_admin run phase252:isolation
```

They create only disposable databases derived by the launcher and clean them up in `finally` paths. The final repository-root gate is:

```sh
npm --prefix accrue_admin run phase252:check
```

That command becomes available after plan 252-08 adds its runner and package script; do not run it before then.
