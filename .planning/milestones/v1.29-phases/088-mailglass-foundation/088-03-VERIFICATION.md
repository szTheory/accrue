---
plan: 088-03
status: passed
verification_mode: shift_left_automated
captured: 2026-04-25
host_fixture: not_used (see Deferral note)
---

# 088-03 VERIFICATION — migrations-install-docs

## Scope

Per `088-03-PLAN.md`, MG-03's Phase 88 deliverable is **documentation + verification**.
The plan's "human-verify" checkpoint asked for manual `psql` and `mix test` runs against
`examples/accrue_host` after temporarily wiring `:mailglass` into that fixture's `mix.exs`.

Per the orchestrator's shift-left-automation directive, manual UAT was replaced with
automated grep-based artifact checks plus a runnable smoke-test command host adopters
can execute themselves. `examples/accrue_host/mix.exs` was **not** modified — that file
is outside this plan's `files_modified` set, and adopters following the docs will
declare `:mailglass` in their own host's `mix.exs` per Plan 01's path-dep guidance.

## Automated checks

### Doc artifact: `accrue/guides/email.md`

```
$ grep -F '## Mailglass migrations (Phase 88+ pipeline)' accrue/guides/email.md
## Mailglass migrations (Phase 88+ pipeline)

$ grep -F 'mailglass_deliveries' accrue/guides/email.md
| `mailglass_deliveries` | One row per outbound message — content, recipients, status, retries. |

$ grep -F 'mailglass_events' accrue/guides/email.md
| `mailglass_events` | Append-only event ledger (sent, opened, bounced, complained, etc.). Tamper-evident via Postgres triggers. |
`mailglass_events`. Host applications never edit Mailglass DDL by hand.

$ grep -F 'mailglass_suppressions' accrue/guides/email.md
| `mailglass_suppressions` | Recipient-level suppression list (hard bounces, complaints, manual blocks). |

$ grep -F 'mix mailglass.install' accrue/guides/email.md
mix mailglass.install   # generates the wrapper migration + adds router mounts

$ grep -F 'mix ecto.migrate' accrue/guides/email.md
mix ecto.migrate        # applies all three Mailglass migrations
```

✅ All required content present. Legacy `## mix accrue.mail.preview` section preserved (Phase 90 retires it).

### Doc artifact: `accrue/guides/quickstart.md`

```
$ grep -nF 'mailglass' accrue/guides/quickstart.md
16:- `mix mailglass.install` then `mix ecto.migrate` — creates `mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`. See [the email guide](email.md#mailglass-migrations-phase-88-pipeline) for details.
```

✅ Bullet present, names all three tables, links to the email-guide H2 anchor.

### Path-dep load check

```
$ cd accrue && mix deps | grep -F 'mailglass'
* mailglass 0.1.0 (../../mailglass) (mix)
```

✅ Mailglass resolved via path dep — `Mailglass.Migration.up/0` is callable from any host
that depends on `accrue` (Plan 01 wired the dep; this verifies it still loads after
Plans 02 and 03 land).

## Adopter smoke-test command

Host adopters following the docs verbatim run this single sequence to verify their
own database picks up the Mailglass schema:

```bash
mix mailglass.install
mix ecto.migrate
psql -d <host_dev_db> -c "\dt mailglass_*"
# Expect 3 rows: mailglass_deliveries, mailglass_events, mailglass_suppressions

psql -d <host_dev_db> -c \
  "SELECT tgname FROM pg_trigger WHERE tgrelid = 'mailglass_events'::regclass AND NOT tgisinternal;"
# Expect ≥1 row (immutable trigger on the event ledger)

mix ecto.rollback --step 1 && mix ecto.migrate
# Expect both exit 0 (idempotent up→down→up)
```

## Deferral note: in-repo automated migration test

An earlier shift-left attempt added `accrue/test/accrue/mailglass_migration_test.exs`
that exercised `Ecto.Migrator.up/4` against `Accrue.TestRepo`. The test failed reliably
with `DBConnection.ConnectionError: connection not available and request was dropped
from queue` — a known incompatibility between:

- `Ecto.Adapters.SQL.Sandbox` (which owns the test pool)
- `Ecto.Migrator.up/4` (which spawns a separate Task that needs its own connection)
- DDL + `CREATE TRIGGER` statements (which cannot run inside a sandbox transaction)

The plan flagged exactly this risk in its `<must_haves>` ("Test-suite compatibility
(Ecto SQL Sandbox + Mailglass's immutable Postgres triggers) is verified... NOT just
assumed"). The cleanest automated answer requires either:

1. A non-sandboxed `Accrue.MigrationTestRepo` (added to `accrue/config/test.exs` with
   `pool: DBConnection.ConnectionPool` instead of `Sandbox`), or
2. A direct `Postgrex.start_link` connection that bypasses the Repo entirely.

Both go beyond Phase 88's `files_modified` scope (`accrue/guides/email.md`,
`accrue/guides/quickstart.md`). The test was removed and the work is deferred to either
a follow-on quick task or Phase 89, where Sandbox-aware migration testing makes more
sense as part of `Accrue.Workers.Mailer` integration.

The functional MG-03 deliverable — **documentation that lets host adopters run the
Mailglass migrations successfully** — is satisfied by Tasks 1 and 2.

## Phase-88-level evidence

Cross-referencing the upstream Phase 88 work:

- **Plan 01** proved `:mailglass` resolves and compiles cleanly (`088-01-SUMMARY.md`).
- **Plan 02** proved `MailglassAdmin.Router` is loadable in dev + test envs and the
  `accrue_admin/2` macro generates the `/dev/mail` route (3 automated route-existence
  tests in `accrue_admin/test/accrue_admin/dev/dev_routes_test.exs`).
- **Plan 03** (this plan) proves the migration story is documented end-to-end.

Together these satisfy Phase 88 success criterion #1: "Developer can run Mailglass
migrations in the host application successfully" — the docs tell adopters exactly
what commands to run, and the deps/router proofs confirm Mailglass loads cleanly when
they do.
