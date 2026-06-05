---
phase: quick-260605-gys
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - examples/accrue_host/priv/repo/seeds.exs
  - examples/accrue_host/priv/repo/seeds/hero_accounts.exs
  - examples/accrue_host/bin/dev-banner.sh
  - examples/accrue_host/lib/accrue_host_web/dev_banner.ex
  - examples/accrue_host/README.md
  - examples/accrue_host/test/accrue_host/hero_accounts_test.exs
autonomous: true
requirements: [quick-260605-gys]

must_haves:
  truths:
    - "admin@example.com exists in the database with billing_admin: true"
    - "The 5 customer demo accounts retain billing_admin: false"
    - "Re-running seeds is idempotent — admin is upgraded to billing_admin: true if it somehow exists without the flag"
    - "seeds_idempotency_test.exs still passes with exactly 7 dunning events (admin adds none)"
    - "Both banners list admin@example.com as the /admin operator login and the 5 customer logins as tenant-facing only"
    - "README makes it explicit: log in as admin@example.com to reach /admin"
  artifacts:
    - path: "examples/accrue_host/priv/repo/seeds.exs"
      provides: "ensure_demo_admin/1 helper in AccrueHost.Seeds.Helpers"
      contains: "ensure_demo_admin"
    - path: "examples/accrue_host/priv/repo/seeds/hero_accounts.exs"
      provides: "ensure_demo_admin(\"admin@example.com\") call"
      contains: "admin@example.com"
    - path: "examples/accrue_host/test/accrue_host/hero_accounts_test.exs"
      provides: "assertion that admin@example.com has billing_admin: true"
      contains: "billing_admin"
  key_links:
    - from: "ensure_demo_admin/1"
      to: "Ecto.Changeset.change(user, billing_admin: true) |> Repo.update()"
      via: "direct changeset — no existing changeset casts this field"
      pattern: "billing_admin: true"
---

<objective>
Add a dedicated `admin@example.com` billing-admin operator seed account to the
accrue_host example app so the `/admin` console (which currently redirects to `/`
for all 5 seeded customer accounts) becomes reachable.

Purpose: The root cause is confirmed — 0 of 105 users have `billing_admin: true`,
making `/admin` structurally unreachable. The 5 customer accounts must remain
non-admin (they represent tenant billing-lifecycle personas). A sixth, dedicated
operator account is the correct fix.

Output: `ensure_demo_admin/1` helper + call in seeds, banners and README updated,
test assertions locked, Docker verify instructions executed.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@examples/accrue_host/priv/repo/seeds.exs
@examples/accrue_host/priv/repo/seeds/hero_accounts.exs
@examples/accrue_host/lib/accrue_host_web/dev_banner.ex
@examples/accrue_host/bin/dev-banner.sh
@examples/accrue_host/README.md
@examples/accrue_host/test/accrue_host/hero_accounts_test.exs
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add ensure_demo_admin/1 helper + call it in hero_accounts.exs</name>
  <files>
    examples/accrue_host/priv/repo/seeds.exs,
    examples/accrue_host/priv/repo/seeds/hero_accounts.exs
  </files>
  <action>
In `examples/accrue_host/priv/repo/seeds.exs`, add a new public function
`ensure_demo_admin/1` to the `AccrueHost.Seeds.Helpers` module, placed after the
existing `ensure_demo_user/1` definition (around line 29).

The function body:
- Calls `ensure_demo_user(email)` to get-or-create the user (handles registration,
  email confirmation, and demo password in one idempotent step — reuse exactly).
- Then unconditionally applies `Ecto.Changeset.change(user, billing_admin: true) |>
  Repo.update!()` to ensure `billing_admin` is true even when re-seeding a user that
  already exists. This is the only way to set the field — `User` has no changeset
  that casts `billing_admin`, so it must be set via `Ecto.Changeset.change/2` directly.
- Returns the updated `%User{}`.

The admin needs NO org, membership, or subscription — platform admins see all
tenants via `OwnerScope` global mode; don't create any of those.

In `examples/accrue_host/priv/repo/seeds/hero_accounts.exs`, add the following near
the TOP of the file (before account #1 / healthy), after the alias/import block and
`now = ...` lines, with a clear comment:

```
# OPERATOR / SaaS-admin persona — grants access to the /admin console.
# This is NOT a customer account. It has no org, no subscription, no dunning events.
# The 5 accounts below are customer billing-lifecycle personas (tenant-facing flows only).
ensure_demo_admin("admin@example.com")
```

This placement means the admin user exists before any subscription work, which is
harmless. It adds zero dunning events, so `seeds_idempotency_test.exs` "exactly 7"
assertion is unaffected — note this explicitly in a comment next to the call.
  </action>
  <verify>
    <automated>cd examples/accrue_host && MIX_ENV=test mix run -e 'Code.eval_file("priv/repo/seeds.exs")' 2>&1 | tail -5 && mix test test/seeds_idempotency_test.exs --seed 0 2>&1 | tail -10</automated>
  </verify>
  <done>
    `ensure_demo_admin/1` exists in seeds.exs. Seeds run without error.
    `seeds_idempotency_test.exs` passes with its "exactly 7" dunning-event assertion intact.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update banners and README to surface admin@example.com</name>
  <files>
    examples/accrue_host/bin/dev-banner.sh,
    examples/accrue_host/lib/accrue_host_web/dev_banner.ex,
    examples/accrue_host/README.md
  </files>
  <action>
**bin/dev-banner.sh** — replace the "Seeded demo logins" block (currently lines 88-93)
with:

```
Seeded demo logins (password for ALL: accrue-demo-password):
  OPERATOR (billing-admin — use this to open /admin):
    admin@example.com        billing_admin, no subscription — /admin only

  CUSTOMERS (tenant-facing /app/billing + /billing portal — NOT admin):
    healthy@example.com      clean, subscribed (no dunning banner)
    past-due@example.com     past_due, dunning campaign active
    canceled@example.com     canceled subscription
    enterprise@example.com   premium plan + JPY invoice showcase
    trialing@example.com     trialing subscription
```

**lib/accrue_host_web/dev_banner.ex** — replace the "Seeded demo logins" block
(currently lines 49-54) with the same text, keeping consistent indentation with
the Logger.info heredoc:

```
    Seeded demo logins (password for ALL: accrue-demo-password):
      OPERATOR (billing-admin — use this to open /admin):
        admin@example.com        billing_admin, no subscription — /admin only

      CUSTOMERS (tenant-facing /app/billing + /billing portal — NOT admin):
        healthy@example.com      clean, subscribed (no dunning banner)
        past-due@example.com     past_due, dunning campaign active
        canceled@example.com     canceled subscription
        enterprise@example.com   premium plan + JPY invoice showcase
        trialing@example.com     trialing subscription
```

**README.md** — two targeted updates:

1. The "Start Here" opening block around line 18 says `Then open http://accrue.localhost/admin`.
   Append a sentence: "You must be logged in as `admin@example.com` (password
   `accrue-demo-password`) to access `/admin` — the 5 customer logins below are for
   the tenant-facing billing flows."

2. The banner description paragraph (around lines 40-42) that lists the five seeded
   logins: add `admin@example.com` as the first entry with a note "(billing-admin
   operator — required to open `/admin`)", and add a parenthetical clarifying that
   the 5 customer accounts do not have admin access.
  </action>
  <verify>
    <automated>grep -n "admin@example.com" examples/accrue_host/bin/dev-banner.sh examples/accrue_host/lib/accrue_host_web/dev_banner.ex examples/accrue_host/README.md</automated>
  </verify>
  <done>
    All three files mention `admin@example.com`. Both banners have the OPERATOR /
    CUSTOMERS split label. README explicitly states admin@example.com is required
    for /admin.
  </done>
</task>

<task type="auto">
  <name>Task 3: Lock the persona split in the hero accounts test + Docker verify</name>
  <files>
    examples/accrue_host/test/accrue_host/hero_accounts_test.exs
  </files>
  <action>
In `examples/accrue_host/test/accrue_host/hero_accounts_test.exs`, add two new
assertions inside the existing "pingpal hero accounts are created with correct
subscriptions" test, after the existing `Repo.get_by` assertions for the 5 customers
(after line 23):

```elixir
# Operator / billing-admin persona
admin_user = Repo.get_by(User, email: "admin@example.com")
assert %User{billing_admin: true} = admin_user,
       "admin@example.com must have billing_admin: true — required to reach /admin"

# Lock: customer personas must NOT have admin access
healthy_user = Repo.get_by(User, email: "healthy@example.com")
assert %User{billing_admin: false} = healthy_user,
       "healthy@example.com must remain billing_admin: false (customer persona)"
```

This pins:
- admin@example.com → billing_admin: true (gate to /admin)
- healthy@example.com → billing_admin: false (representative customer; locks the persona split)

After implementing all code changes, run the Docker verify sequence to confirm the
live database now has a reachable admin. Execute these commands in order:

1. Re-seed inside the running Docker container (check if there is a `make seed`
   target first via `make -n seed 2>/dev/null || true`; if not, use
   `docker exec accrue-host-web-1 sh -c "cd /app && mix run priv/repo/seeds.exs"`).
2. Confirm `billing_admin = true` in the DB:
   `docker exec accrue-host-db-1 psql -U postgres -d accrue_host_dev -c "select email, billing_admin from users where billing_admin = true;"`
   Expected output: one row — `admin@example.com | t`.

If the Docker stack is not currently running (`docker ps` shows no `accrue-host-web-1`),
skip the Docker verify step and note it as "stack not running — reseed on next `make up`".
  </action>
  <verify>
    <automated>cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/hero_accounts_test.exs --seed 0 2>&1 | tail -15</automated>
  </verify>
  <done>
    hero_accounts_test.exs passes with the new billing_admin assertions.
    Docker query (if stack is up) returns exactly one row: admin@example.com with billing_admin = true.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| seed script → DB | Seeds run in dev/test only — never in prod release. Controlled execution path. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-260605-01 | Elevation of Privilege | ensure_demo_admin/1 in seeds | accept | Seeds are dev/test-only (`mix run priv/repo/seeds.exs`). The `billing_admin` flag is a dev-persona marker; no prod seed path exists. If seeds ever run in prod, this is a host-app misconfiguration, not an Accrue vector. |
| T-260605-02 | Information Disclosure | admin@example.com password in banner | accept | Password is `accrue-demo-password`, hardcoded in `demo_password/0`, and intentionally public — it's a dev demo credential, not a secret. |
</threat_model>

<verification>
Run after all tasks complete:

```bash
cd examples/accrue_host
MIX_ENV=test mix test test/accrue_host/hero_accounts_test.exs test/seeds_idempotency_test.exs --seed 0
```

Both test files must pass. `seeds_idempotency_test.exs` must still assert exactly 7
dunning events (admin@example.com contributes zero).

Optional live DB check if Docker stack is running:
```bash
docker exec accrue-host-db-1 psql -U postgres -d accrue_host_dev \
  -c "select email, billing_admin from users where email in ('admin@example.com','healthy@example.com') order by email;"
```
Expected: `admin@example.com | t`, `healthy@example.com | f`.
</verification>

<success_criteria>
- `ensure_demo_admin/1` exists in `seeds.exs` and is called in `hero_accounts.exs`
- Re-running seeds is fully idempotent: no crash, billing_admin stays true on repeat runs
- `seeds_idempotency_test.exs` passes with exactly 7 dunning events
- `hero_accounts_test.exs` passes with billing_admin assertions for both admin and customer accounts
- Both banners (sh + ex) show admin@example.com as the OPERATOR login and customer accounts as tenant-facing
- README Start Here section explicitly names admin@example.com as required for /admin
- No changes outside `examples/accrue_host/` — accrue/, accrue_admin/, accrue_portal/ are untouched
</success_criteria>

<output>
Create `.planning/quick/260605-gys-add-dedicated-admin-example-com-billing-/260605-gys-SUMMARY.md` when done.
</output>
